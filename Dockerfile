FROM --platform=linux/amd64 debian:bookworm-slim

ARG LAB_ARCH
ARG USERNAME=lab
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ENV DEBIAN_FRONTEND=noninteractive
ENV LAB_ARCH=${LAB_ARCH}
RUN test -n "$LAB_ARCH" || (echo "[!] ARG 'LAB_ARCH' is required." && false)

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates     \
    ncurses-term        \
    iproute2            \
    xz-utils            \
    curl wget           \
    file                \
    make                \
    sudo                \
    tmux tmuxinator	\
    nano                \
    gdb-multiarch       \
    && if [ "${LAB_ARCH}" = "amd64" ]; then                 \
         apt-get install -y --no-install-recommends         \
            gcc libc6-dev nasm;                             \
       fi                                                   \
    && apt-get clean                                        \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to avoid permission issues
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install QEMU static binary for non-amd64 architectures
RUN set -e; \
    if [ "${LAB_ARCH}" != "amd64" ] && [ "${LAB_ARCH}" != "x86_64" ]; then \
        QEMU_ARCH=$(echo "$LAB_ARCH" | sed 's/^mips$/mipsel/; s/^armv7$/arm/'); \
        echo ">>> Downloading QEMU for: $QEMU_ARCH"; \
        wget -q "https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-${QEMU_ARCH}-static" -O /usr/bin/qemu-${QEMU_ARCH}; \
        chmod +x /usr/bin/qemu-${QEMU_ARCH}; \
    else \
        echo ">>> Native architecture (amd64). Skipping QEMU."; \
    fi

# Install the scripts and make convenient symlinks
COPY scripts/setup.sh scripts/build.sh scripts/debug.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh /usr/local/bin/build.sh /usr/local/bin/debug.sh && \
    ln -sf /usr/local/bin/setup.sh /usr/local/bin/lab-setup && \
    ln -sf /usr/local/bin/build.sh /usr/local/bin/lab-build && \
    ln -sf /usr/local/bin/debug.sh /usr/local/bin/lab-debug

# Create an entrypoint script to load the lab environment on container startup
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo '# 1. Load system profiles (incl. lab-activate.sh)' >> /usr/local/bin/entrypoint.sh && \
    echo 'if [ -f /etc/profile ]; then . /etc/profile; fi' >> /usr/local/bin/entrypoint.sh && \
    echo '# 2. Explicitly load lab environment if missed' >> /usr/local/bin/entrypoint.sh && \
    echo 'if [ -f /etc/profile.d/lab-activate.sh ]; then . /etc/profile.d/lab-activate.sh; fi' >> /usr/local/bin/entrypoint.sh && \
    echo '# 3. Execute command' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Setup the cross-compilation toolchain for the specified architecture
RUN lab-setup -T "$LAB_ARCH" --force && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

# Parse the activate script to set PATH and create command wrappers for aliases
RUN ACTIVATE_SCRIPT="/opt/${LAB_ARCH}-lab/activate"; \
    if [ -f "$ACTIVATE_SCRIPT" ]; then \
        NEW_PATH=$(grep "export PATH=" "$ACTIVATE_SCRIPT" | cut -d'"' -f2); \
        if [ -n "$NEW_PATH" ]; then \
            echo "export PATH=$NEW_PATH:\$PATH" >> /etc/profile; \
            echo "export PATH=$NEW_PATH:\$PATH" >> /root/.bashrc; \
        fi; \
        grep "export QEMU_LD_PREFIX" "$ACTIVATE_SCRIPT" >> /etc/profile; \
        for _tool in gcc as g++ ld objdump readelf strip ar; do \
            _bin=$(find /opt/${LAB_ARCH}-lab/bin -name "*-linux-${_tool}" | head -n 1); \
            if [ -n "$_bin" ]; then \
                echo "Creating wrapper for lab-$_tool -> $_bin"; \
                echo "#!/bin/bash" > "/usr/local/bin/lab-$_tool"; \
                echo "exec $_bin \"\$@\"" >> "/usr/local/bin/lab-$_tool"; \
                chmod +x "/usr/local/bin/lab-$_tool"; \
            fi; \
        done; \
        echo "Creating lab-run wrapper"; \
        echo '#!/bin/bash' > /usr/local/bin/lab-run; \
        grep "alias lab-run=" "$ACTIVATE_SCRIPT" | sed 's/alias lab-run=//; s/^"/exec /; s/"$/\ "$@"/' >> /usr/local/bin/lab-run; \
        chmod +x /usr/local/bin/lab-run; \
    else \
        echo "Creating lab-run wrapper for amd64 native"; \
        echo '#!/bin/bash' > /usr/local/bin/lab-run; \
        echo 'exec "$@"' >> /usr/local/bin/lab-run; \
        chmod +x /usr/local/bin/lab-run; \
    fi

# Finalize entrypoint to load profiles and switch to non-root user
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo '. /etc/profile' >> /usr/local/bin/entrypoint.sh && \
    echo 'if [ -f /etc/bash.bashrc ]; then . /etc/bash.bashrc; fi' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
RUN chown -R $USERNAME:$USERNAME /workspace
USER ${USERNAME}

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD [ "bash", "-l" ]
