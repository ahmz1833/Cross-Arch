#!/bin/bash

ARCHS=("amd64" "mips" "s390x" "riscv64" "armv7" "aarch64" "i386")
REGISTRY="ghcr.io/ahmz1833/cross-arch"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo ">>> Starting Sanity Check for 7 Architectures..."

cat <<EOF > hello.c
#include <stdio.h>
int main() {
    printf("Hello form Cross-Arch!");
    return 0;
}
EOF

test_image() {
    local arch=$1
    local image="$REGISTRY:$arch"
    
    echo -n "Testing $arch ... "
    
    docker run --rm --platform linux/amd64 \
        -v "$(pwd):/workspace" \
        "$image" \
        bash -c "lab-build hello.c -o hello"

    OUTPUT=$(docker run --rm --platform linux/amd64 \
        -v "$(pwd):/workspace" \
        "$image" \
        bash -c "lab-run ./hello")
        
    if [[ "$OUTPUT" == *"Hello form Cross-Arch!"* ]]; then
        echo -e "${GREEN}PASSED ✅${NC}"
        rm -f hello
    else
        echo -e "${RED}FAILED ❌${NC}"
        echo "Logs:"
        echo "$OUTPUT"
        return 1
    fi
}

FAILED_COUNT=0
for arch in "${ARCHS[@]}"; do
    test_image "$arch"
    if [ $? -ne 0 ]; then
        ((FAILED_COUNT++))
    fi
done

rm -f hello.c

echo "------------------------------------------------"
if [ $FAILED_COUNT -eq 0 ]; then
    echo -e "${GREEN}ALL SYSTEMS GO! 🚀${NC}"
else
    echo -e "${RED}$FAILED_COUNT architectures failed.${NC}"
    exit 1
fi
