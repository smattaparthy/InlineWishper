#!/bin/bash

# InlineWhisper Development Setup Script
# This script automates the setup of the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="InlineWhisper"
REQUIRED_MACOS_VERSION="15.0"
REQUIRED_XCODE_VERSION="16.0"

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

log_step() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    if [[ $(echo "$macos_version >= $REQUIRED_MACOS_VERSION" | bc -l) == 0 ]]; then
        log_error "macOS $REQUIRED_MACOS_VERSION or later is required. Current: $macos_version"
        exit 1
    fi
    log_info "macOS version: $macos_version ✓"
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode is not installed. Please install Xcode from the Mac App Store."
        exit 1
    fi
    
    local xcode_version=$(xcodebuild -version | head -n 1 | cut -d ' ' -f 2)
    log_info "Xcode version: $xcode_version"
}

install_homebrew_dependencies() {
    log_step "Installing Homebrew dependencies..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Update Homebrew
    log_info "Updating Homebrew..."
    brew update
    
    # Install dependencies
    local dependencies=("cmake" "xcodegen" "jq")
    
    for dep in "${dependencies[@]}"; do
        if ! brew list "$dep" &> /dev/null; then
            log_info "Installing $dep..."
            brew install "$dep"
        else
            log_info "$dep is already installed ✓"
        fi
    done
}

setup_git_submodules() {
    log_step "Setting up Git submodules..."
    
    # Initialize and update submodules
    if [ -d ".git" ]; then
        log_info "Initializing whisper.cpp submodule..."
        git submodule update --init --recursive
        
        if [ -d "third_party/whisper.cpp" ]; then
            log_info "whisper.cpp submodule initialized ✓"
        else
            log_warning "whisper.cpp submodule not found. Manual intervention may be required."
        fi
    else
        log_warning "Not a Git repository. Submodule setup skipped."
    fi
}

build_whisper_cpp() {
    log_step "Building whisper.cpp..."
    
    if [ -f "scripts/build_whisper.sh" ]; then
        chmod +x scripts/build_whisper.sh
        ./scripts/build_whisper.sh
        
        if [ $? -eq 0 ]; then
            log_info "whisper.cpp built successfully ✓"
        else
            log_warning "whisper.cpp build failed. Check build logs for details."
        fi
    else
        log_error "Build script not found: scripts/build_whisper.sh"
        exit 1
    fi
}

download_model() {
    log_step "Downloading Whisper model..."
    
    if [ -f "scripts/build_whisper.sh" ]; then
        ./scripts/build_whisper.sh
        
        local model_path="models/ggml-tiny.en-f16.bin"
        if [ -f "$model_path" ]; then
            local file_size=$(stat -f%z "$model_path" 2>/dev/null || stat -c%s "$model_path" 2>/dev/null)
            log_info "Model downloaded successfully. Size: $file_size bytes ✓"
        else
            log_warning "Model download may have failed. Check build logs."
        fi
    fi
}

generate_xcode_project() {
    log_step "Generating Xcode project..."
    
    if [ -f "project.yml" ]; then
        log_info "Generating project with XcodeGen..."
        xcodegen generate --spec project.yml
        
        if [ -d "InlineWhisper.xcodeproj" ]; then
            log_info "Xcode project generated successfully ✓"
        else
            log_error "Failed to generate Xcode project"
            exit 1
        fi
    else
        log_error "project.yml not found"
        exit 1
    fi
}

configure_app_info() {
    log_step "Configuring app information..."
    
    local app_info="configs/AppInfo.plist"
    local entitlements="app/InlineWhisper.entitlements"
    
    if [ -f "$app_info" ]; then
        log_info "AppInfo.plist exists ✓"
    else
        log_warning "AppInfo.plist not found. This may need to be created manually."
    fi
    
    if [ -f "$entitlements" ]; then
        log_info "Entitlements file exists ✓"
    else
        log_warning "Entitlements file not found. This may need to be created manually."
    fi
}

check_permissions() {
    log_step "Checking system permissions..."
    
    log_info "Checking microphone permissions..."
    if [ -d "/System/Library/Frameworks/AVFoundation.framework" ]; then
        log_info "AVFoundation framework available ✓"
    else
        log_warning "AVFoundation framework not found. Microphone access may not work."
    fi
    
    log_info "Checking accessibility permissions..."
    # This is handled by macOS when the app runs
    log_info "Accessibility permissions will be requested when the app launches"
}

create_directories() {
    log_step "Creating required directories..."
    
    local directories=(
        "models"
        "build"
        "logs"
        "resources"
        "Tests/DictationKitTests"
        "Tests/WhisperBridgeTests"
        "Tests/SystemKitTests"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    done
}

show_summary() {
    log_step "Setup Summary"
    
    echo -e "\n${GREEN}✅ InlineWhisper setup completed!${NC}"
    echo
    echo "Next steps:"
    echo "1. Open the project in Xcode:"
    echo "   open InlineWhisper.xcodeproj"
    echo
    echo "2. Configure your Apple Developer account for code signing"
    echo "3. Build and run the project (⌘+R)"
    echo
    echo "First run will show the onboarding flow to set up permissions."
    echo
    
    if command -v xed &> /dev/null; then
        echo "Would you like to open the project in Xcode now? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            xed .
        fi
    fi
}

# Main setup process
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                InlineWhisper Setup                      ║"
    echo "║        Privacy-First Dictation for macOS               ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    log_info "Starting setup for $PROJECT_NAME..."
    
    check_prerequisites
    create_directories
    install_homebrew_dependencies
    setup_git_submodules
    build_whisper_cpp
    download_model
    generate_xcode_project
    configure_app_info
    check_permissions
    
    show_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo
        echo "Options:"
        echo "  --help, -h    Show this help message"
        exit 0
        ;;
    --clean)
        log_step "Cleaning build artifacts..."
        rm -rf build/
        rm -rf models/
        rm -rf *.xcodeproj
        log_info "Clean completed"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac