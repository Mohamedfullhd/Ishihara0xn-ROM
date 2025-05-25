#!/bin/bash
set -e

# Get base directory from first argument
BASE_DIR="$1"

# Define paths relative to base directory
WORK_DIR="${BASE_DIR}/firmware/work_dir"
PARTITIONS_DIR="${WORK_DIR}/partitions"
FIRMWARE_DIR="${BASE_DIR}/firmware"

# Ensure necessary folders exist
mkdir -p "$PARTITIONS_DIR"

echo "Working directory: $WORK_DIR"

check_required_images() {
    if [ -f "$PARTITIONS_DIR/system.img" ] && 
       [ -f "$PARTITIONS_DIR/odm.img" ] && 
       [ -f "$PARTITIONS_DIR/product.img" ]; then
        return 0
    else
        return 1
    fi
}

extract_firmware_package() {
    echo "- Searching for Redmi firmware package in ${FIRMWARE_DIR}..."
    FW_FILE=$(find "${FIRMWARE_DIR}" -type f \( -iname "*.tgz" -o -iname "*.zip" \) | head -n 1)

    if [ -z "$FW_FILE" ]; then
        echo "ERROR: No firmware package found in ${FIRMWARE_DIR}"
        exit 1
    fi

    echo "Extracting firmware: $FW_FILE..."
    mkdir -p "$WORK_DIR"
    
    if [[ "$FW_FILE" == *.tgz ]]; then
        tar -xzf "$FW_FILE" -C "$WORK_DIR"
    elif [[ "$FW_FILE" == *.zip ]]; then
        unzip -q "$FW_FILE" -d "$WORK_DIR"
    else
        echo "ERROR: Unsupported file format: $FW_FILE"
        exit 1
    fi
}

process_super_image() {
    echo "- Looking for super.img..."
    SUPER_IMG=$(find "$WORK_DIR" -type f -name "super.img" | head -n 1)
    
    if [ -z "$SUPER_IMG" ]; then
        echo "ERROR: super.img not found in extracted files."
        exit 1
    fi

    echo "Converting super.img (sparse) to raw image..."
    simg2img "$SUPER_IMG" "$WORK_DIR/super_raw.img"

    if [ $? -eq 0 ]; then
        echo "Conversion successful. Deleting sparse super.img..."
        rm -f "$SUPER_IMG"
    else
        echo "Error converting super.img to raw image. Exiting..."
        exit 1
    fi

    echo "Unpacking super_raw.img into partitions..."
    rm -rf "$PARTITIONS_DIR"
    mkdir -p "$PARTITIONS_DIR"
    
    lpunpack "$WORK_DIR/super_raw.img" "$PARTITIONS_DIR"
    
    if [ $? -eq 0 ]; then
        echo "Unpacking successful. Cleaning up..."
        rm -f "$WORK_DIR/super_raw.img"
    else
        echo "Error unpacking super_raw.img. Exiting..."
        exit 1
    fi
}

# Main execution flow
if check_required_images; then
    echo "[+] Required images found in $PARTITIONS_DIR. Skipping extraction steps."
else
    echo "[-] Required images missing. Running extraction..."
    extract_firmware_package
    process_super_image
fi

echo "All partitions processed. Check $PARTITIONS_DIR for results."
