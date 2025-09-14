# InlineWhisper Development Setup Requirements

## Prerequisites Overview

This document outlines all necessary hardware, software, accounts, and dependencies required to develop the InlineWhisper dictation application.

---

## Hardware Requirements

### Development Machine
- **Model**: Mac with Apple Silicon (M1, M2, M3, or later)
- **macOS Version**: macOS 15 Sequoia or later
- **RAM**: Minimum 16GB (32GB recommended for model development)
- **Storage**: 50GB free space (models + build artifacts)
- **Microphone**: Built-in or external for testing

### Testing Devices
- **Primary**: Same as development machine
- **Secondary**: Different M-series Mac for compatibility testing
- **Accessories**: External microphone for audio quality testing

---

## Software Requirements

### Development Tools
```bash
# Xcode (required)
# Download from Mac App Store or Apple Developer
# Minimum: Xcode 16.0
# Recommendation: Latest stable version

# Command Line Tools (automatic with Xcode)
xcode-select --install

# Homebrew (package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Build Dependencies
```bash
# Install via Homebrew
brew install cmake        # For whisper.cpp compilation
brew install xcodegen     # For Xcode project generation
brew install jq          # For JSON processing
brew install git-lfs     # For large files (optional)

# Verify installations
cmake --version    # ≥3.20
xcodegen --version # ≥2.40
```

### Optional Development Tools
```bash
# Code quality
brew install swiftlint    # Swift linting
brew install swiftformat  # Swift formatting

# Git tools
brew install git-flow     # Git workflow
brew install hub         # GitHub CLI

# Documentation
brew install graphviz    # For diagrams
brew install pandoc      # Document conversion
```

---

## Apple Developer Account Requirements

### Account Type
- **Requirement**: Apple Developer Program membership
- **Cost**: $99/year (personal or organization)
- **Purpose**: Code signing and notarization

### Required Certificates
1. **Developer ID Application**
   - For distributing outside Mac App Store
   - Required for notarization
   
2. **Developer ID Installer**
   - For installer packages
   - Optional for DMG distribution

### Provisioning Profiles
- **Mac Developer**: For development testing
- **Developer ID**: For distribution

### Setup Process
```bash
# In Xcode
# 1. Preferences → Accounts → Add Apple ID
# 2. Download manual profiles
# 3. Configure signing settings
```

---

## Project Setup Steps

### 1. Repository Setup
```bash
# Clone the repository
git clone https://github.com/your-org/InlineWhisper.git
cd InlineWhisper

# Initialize submodules (critical for whisper.cpp)
git submodule update --init --recursive

# Verify whisper.cpp is present
ls third_party/whisper.cpp/
# Should show whisper.cpp source files
```

### 2. Dependency Installation
```bash
# Install Homebrew dependencies
brew bundle install  # If Brewfile exists

# Manual installation if no Brewfile
brew install cmake xcodegen jq

# Verify installations
which cmake xcodegen jq
```

### 3. whisper.cpp Build Setup
```bash
# Run the build script
./scripts/build_whisper.sh

# Expected output:
# - libwhisper.a static library
# - ggml-metal.metal shader file
# - Build completion message

# Verify build artifacts
ls -la Modules/WhisperBridge/Sources/WhisperBridge/csrc/
# Should contain libwhisper.a and ggml-metal.metal
```

### 4. Xcode Project Generation
```bash
# Generate Xcode project
xcodegen generate --spec ./configs/project.yml

# Expected output:
# - InlineWhisper.xcodeproj created
# - All modules configured
# - Dependencies linked

# Open in Xcode
xed .
```

### 5. Model Setup
```bash
# Download Whisper small.en model
# Place in models/ directory
ls models/ggml-small.en-f16.bin

# Verify model integrity
./scripts/verify_model_hash.sh models/ggml-small.en-f16.bin

# Expected: Hash verification passes
```

---

## Configuration Requirements

### Project Configuration Files

#### configs/project.yml (XcodeGen)
```yaml
# Required customizations:
settings:
  DEVELOPMENT_TEAM: "YOUR_TEAM_ID"  # Replace with your team ID
  CODE_SIGN_IDENTITY: "Apple Development"
  
# Verify team ID in Apple Developer account
# https://developer.apple.com/account/#/membership
```

#### App Signing Configuration
```xml
<!-- app/InlineWhisper.entitlements -->
<!-- No customization needed for development -->
<!-- Distribution requires Developer ID certificate -->
```

#### Info.plist Settings
```xml
<!-- configs/AppInfo.plist -->
<!-- Update these values: -->
<key>CFBundleDisplayName</key>
<string>InlineWhisper</string>
<key>NSHumanReadableCopyright</key>
<string>© 2025 Your Name/Organization</string>
```

---

## Environment Verification

### Setup Validation Script
```bash
#!/bin/bash
# save as verify_setup.sh

echo "=== InlineWhisper Setup Verification ==="

# Check macOS version
echo "macOS Version:"
sw_vers -productVersion

# Check Xcode
echo -e "\nXcode Version:"
xcodebuild -version

# Check dependencies
echo -e "\nDependency Check:"
command -v cmake >/dev/null 2>&1 && echo "✓ CMake installed" || echo "✗ CMake missing"
command -v xcodegen >/dev/null 2>&1 && echo "✓ XcodeGen installed" || echo "✗ XcodeGen missing"
command -v jq >/dev/null 2>&1 && echo "✓ jq installed" || echo "✗ jq missing"

# Check submodules
echo -e "\nGit Submodules:"
if [ -d "third_party/whisper.cpp" ]; then
    echo "✓ whisper.cpp submodule initialized"
else
    echo "✗ whisper.cpp submodule missing"
fi

# Check build artifacts
echo -e "\nBuild Artifacts:"
if [ -f "Modules/WhisperBridge/Sources/WhisperBridge/csrc/libwhisper.a" ]; then
    echo "✓ whisper.cpp library built"
else
    echo "✗ whisper.cpp library missing"
fi

# Check model
echo -e "\nModel Check:"
if [ -f "models/ggml-small.en-f16.bin" ]; then
    echo "✓ Whisper model present"
else
    echo "✗ Whisper model missing"
fi

echo -e "\n=== Setup Complete ==="
```

### Expected Output
```
=== InlineWhisper Setup Verification ===

macOS Version:
15.0

Xcode Version:
Xcode 16.0
Build version 16Axxx

Dependency Check:
✓ CMake installed
✓ XcodeGen installed
✓ jq installed

Git Submodules:
✓ whisper.cpp submodule initialized

Build Artifacts:
✓ whisper.cpp library built

Model Check:
✓ Whisper model present

=== Setup Complete ===
```

---

## Development Workflow

### Daily Development
```bash
# 1. Update submodules (if needed)
git submodule update --recursive

# 2. Rebuild whisper.cpp (if whisper.cpp changed)
./scripts/build_whisper.sh

# 3. Regenerate Xcode project (if project.yml changed)
xcodegen generate --spec ./configs/project.yml

# 4. Open in Xcode
xed .

# 5. Build and run
# Use Xcode's build system (⌘+R)
```

### Before Committing
```bash
# Run tests
xcodebuild test -scheme InlineWhisperModules-Package

# Check entitlements (for network leaks)
./scripts/entitlement_audit.sh build/Debug/InlineWhisper.app

# Verify model hash
./scripts/verify_model_hash.sh models/ggml-small.en-f16.bin
```

---

## Troubleshooting Common Issues

### Issue 1: whisper.cpp Build Fails
```bash
# Error: CMake configuration failed
# Solution:
brew upgrade cmake
./scripts/build_whisper.sh --clean

# Error: Metal compilation failed
# Solution:
# Ensure macOS 15+ and Xcode 16+
# Check Metal framework availability
```

### Issue 2: Xcode Project Generation Fails
```bash
# Error: XcodeGen template issues
# Solution:
brew upgrade xcodegen
# Check project.yml syntax
xcodegen generate --spec ./configs/project.yml --verbose
```

### Issue 3: Module Import Errors
```bash
# Error: Cannot find module
# Solution:
# Clean build folder in Xcode
# Product → Clean Build Folder (⇧⌘+K)
# Rebuild whisper.cpp library
./scripts/build_whisper.sh --clean
```

### Issue 4: Permission Issues
```bash
# Error: Microphone access denied
# Solution:
# System Settings → Privacy & Security → Microphone
# Add Xcode and built app

# Error: Accessibility access denied
# Solution:
# System Settings → Privacy & Security → Accessibility
# Add built app
```

### Issue 5: Model Loading Issues
```bash
# Error: Model not found
# Solution:
# Ensure model file exists
ls -la models/ggml-small.en-f16.bin

# Verify file size (~200MB)
# Re-download if corrupted
```

---

## Security & Privacy Setup

### Development Security
```bash
# Enable app sandbox (already configured)
# Verify no network entitlements
./scripts/entitlement_audit.sh build/Debug/InlineWhisper.app

# Check for networking APIs
nm -um build/Debug/InlineWhisper.app/Contents/MacOS/InlineWhisper | grep -i network
# Should show no results
```

### Code Signing Setup
```bash
# Configure automatic signing in Xcode
# 1. Select project → InlineWhisper target
# 2. Signing & Capabilities → Team
# 3. Select your development team

# For distribution (later):
# 1. Change to Developer ID signing
# 2. Enable hardened runtime
# 3. Configure notarization
```

---

## Performance Optimization Setup

### Development Profile
```bash
# Create Instruments template for profiling
# 1. Open Instruments
# 2. Configure custom template:
#    - CPU usage
#    - Memory allocation
#    - Energy impact
#    - Audio processing
# 3. Save as "InlineWhisper Development"

# Profile regularly during development
```

### Testing Performance
```bash
# Latency measurement setup
# 1. Create test audio files
# 2. Set up automated timing
# 3. Measure end-to-end latency
# 4. Profile bottlenecks

# Memory testing
# 1. Test with various model sizes
# 2. Monitor peak memory usage
# 3. Check for memory leaks
# 4. Optimize allocations
```

---

## Team Collaboration Setup

### Git Configuration
```bash
# Set up git hooks (optional)
cp scripts/git-hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# Configure git LFS (if using large models)
git lfs install
git lfs track "*.bin"
```

### Code Standards
```bash
# Install Swift linting
brew install swiftlint
echo "swiftlint" > .git/hooks/pre-commit

# Configure formatting
brew install swiftformat
# Add format-on-save in Xcode preferences
```

---

## Final Verification Checklist

### Before Starting Development
- [ ] Hardware meets requirements (M-series Mac)
- [ ] macOS 15+ installed
- [ ] Xcode 16+ installed and updated
- [ ] Homebrew installed and working
- [ ] Developer account configured
- [ ] All dependencies installed
- [ ] Repository cloned with submodules
- [ ] whisper.cpp builds successfully
- [ ] Xcode project generates without errors
- [ ] Model file present and verified
- [ ] Permissions configured in System Settings
- [ ] Development workflow tested

### Ready to Develop
- [ ] App launches in Xcode
- [ ] All modules compile successfully
- [ ] Basic functionality works
- [ ] Audio capture permissions granted
- [ ] Accessibility permissions granted
- [ ] Development tools configured
- [ ] Testing framework ready

This setup guide ensures a complete development environment for building InlineWhisper.