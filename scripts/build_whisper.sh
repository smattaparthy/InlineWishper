#!/bin/bash

# Build script for whisper.cpp integration
# This script compiles whisper.cpp and prepares it for Swift integration

set -e

# Configuration
WHISPER_DIR="third_party/whisper.cpp"
BUILD_DIR="build/whisper"
OUTPUT_DIR="Modules/WhisperBridge/Sources/WhisperBridge/csrc"
MODEL_DIR="models"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if whisper.cpp directory exists
    if [ ! -d "$WHISPER_DIR" ]; then
        log_error "whisper.cpp directory not found at $WHISPER_DIR"
        log_info "Please run: git submodule update --init --recursive"
        exit 1
    fi
    
    # Check cmake
    if ! command -v cmake &> /dev/null; then
        log_error "cmake is not installed"
        log_info "Please install with: brew install cmake"
        exit 1
    fi
    
    # Check for Metal support
    if [ ! -d "/System/Library/Frameworks/Metal.framework" ]; then
        log_warning "Metal framework not found. Falling back to CPU-only mode."
        USE_METAL=false
    else
        USE_METAL=true
    fi
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    rm -rf "$BUILD_DIR"
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$MODEL_DIR"
}

# Build whisper.cpp
build_whisper() {
    log_info "Building whisper.cpp..."
    
    cd "$WHISPER_DIR"
    
    # Create build directory
    mkdir -p build
    cd build
    
    # Configure with cmake
    if [ "$USE_METAL" = true ]; then
        log_info "Configuring with Metal support..."
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
            -DWHISPER_METAL=ON \
            -DWHISPER_METAL_EMBED_LIBRARY=ON \
            -DBUILD_SHARED_LIBS=OFF \
            -DWHISPER_BUILD_EXAMPLES=OFF \
            -DWHISPER_BUILD_TESTS=OFF
    else
        log_info "Configuring for CPU-only..."
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
            -DWHISPER_METAL=OFF \
            -DBUILD_SHARED_LIBS=OFF \
            -DWHISPER_BUILD_EXAMPLES=OFF \
            -DWHISPER_BUILD_TESTS=OFF
    fi
    
    # Build
    log_info "Building whisper.cpp library..."
    make -j$(sysctl -n hw.ncpu)
    
    # Copy artifacts
    log_info "Copying build artifacts..."
    cp libwhisper.a "$OUTPUT_DIR/"
    cp ggml-metal.metal "$OUTPUT_DIR/" 2>/dev/null || true
    
    cd ../..
}

# Download model if not present
download_model() {
    local model_file="$MODEL_DIR/ggml-tiny.en-f16.bin"
    
    if [ ! -f "$model_file" ]; then
        log_info "Downloading Whisper tiny.en model..."
        
        # Create models directory
        mkdir -p "$MODEL_DIR"
        
        # Download tiny.en model (approximately 40MB)
        MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en-f16.bin"
        
        log_info "Downloading from $MODEL_URL..."
        if command -v curl &> /dev/null; then
            curl -L -o "$model_file" "$MODEL_URL"
        elif command -v wget &> /dev/null; then
            wget -O "$model_file" "$MODEL_URL"
        else
            log_error "Neither curl nor wget found. Please install one of them."
            exit 1
        fi
        
        # Verify download
        if [ -f "$model_file" ]; then
            local file_size=$(stat -f%z "$model_file" 2>/dev/null || stat -c%s "$model_file" 2>/dev/null)
            log_info "Model downloaded successfully. Size: $file_size bytes"
            
            # Basic integrity check (tiny.en should be around 40MB)
            if [ "$file_size" -lt 35000000 ] || [ "$file_size" -gt 50000000 ]; then
                log_warning "Model file size seems unusual: $file_size bytes"
            fi
        else
            log_error "Model download failed"
            exit 1
        fi
    else
        local file_size=$(stat -f%z "$model_file" 2>/dev/null || stat -c%s "$model_file" 2>/dev/null)
        log_info "Model already exists. Size: $file_size bytes"
    fi
}

# Copy headers for Swift integration
copy_headers() {
    log_info "Copying whisper.cpp headers..."
    
    # Copy main whisper header
    cp "$WHISPER_DIR/whisper.h" "$OUTPUT_DIR/"
    
    # Copy ggml headers if they exist
    if [ -f "$WHISPER_DIR/ggml.h" ]; then
        cp "$WHISPER_DIR/ggml.h" "$OUTPUT_DIR/"
    fi
    
    # Copy ggml-impl.h from whisper.cpp if available
    if [ -f "$WHISPER_DIR/ggml-impl.h" ]; then
        cp "$WHISPER_DIR/ggml-impl.h" "$OUTPUT_DIR/"
    fi
}

# Create bridging header if needed
create_bridging_header() {
    log_info "Creating bridging header..."
    
    cat > "$OUTPUT_DIR/whisper-bridge.h" << 'EOF'
// Bridging header for whisper.cpp Swift integration

#ifndef WHISPER_BRIDGE_H
#define WHISPER_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "whisper.h"

// Helper functions for Swift integration
const char* whisper_get_system_info(void);
const char* whisper_print_system_info(void);

#ifdef __cplusplus
}
#endif

#endif // WHISPER_BRIDGE_H
EOF
}

# Verify build
verify_build() {
    log_info "Verifying build artifacts..."
    
    local required_files=(
        "$OUTPUT_DIR/libwhisper.a"
        "$OUTPUT_DIR/whisper.h"
        "$MODEL_DIR/ggml-tiny.en-f16.bin"
    )
    
    local all_good=true
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            log_info "✓ $(basename "$file") - Size: $size bytes"
        else
            log_error "✗ Missing: $file"
            all_good=false
        fi
    done
    
    if [ "$USE_METAL" = true ] && [ -f "$OUTPUT_DIR/ggml-metal.metal" ]; then
        log_info "✓ ggml-metal.metal - Metal shaders available"
    fi
    
    if [ "$all_good" = true ]; then
        log_info "Build verification successful!"
        return 0
    else
        log_error "Build verification failed!"
        return 1
    fi
}

# Main build process
main() {
    log_info "Starting whisper.cpp build process..."
    log_info "=================================="
    
    # Parse command line arguments
    local clean=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Usage: $0 [--clean]"
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_prerequisites
    
    # Clean if requested
    if [ "$clean" = true ]; then
        clean_build
    else
        mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$MODEL_DIR"
    fi
    
    # Build process
    build_whisper
    copy_headers
    create_bridging_header
    download_model
    
    # Verify everything is working
    verify_build
    
    log_info "=================================="
    log_info "whisper.cpp build completed successfully!"
    log_info "Ready for Xcode project generation."
}

# Run main function
main "$@"