ARCHS=("amd64" "mips" "s390x" "riscv64" "armv7" "aarch64" "i386")

for arch in "${ARCHS[@]}"; do
    echo -e "\n\033[0;34m>>> 🔨 Building architecture: $arch \033[0m"
    
    docker build --no-cache \
        -t ghcr.io/ahmz1833/cross-arch:$arch \
        --build-arg LAB_ARCH=$arch \
        .
    
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m!!! Build failed for $arch \033[0m"
        exit 1
    fi

    echo -e "\033[0;32m>>> 🚀 Pushing $arch ... \033[0m"
    docker push ghcr.io/ahmz1833/cross-arch:$arch
    docker rmi ghcr.io/ahmz1833/cross-arch:$arch
done

echo -e "\n\033[1;32m✅ ALL IMAGES BUILT AND PUSHED SUCCESSFULLY! \033[0m"
