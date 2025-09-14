# InlineWhisper Build & Deployment Pipeline

## Build & Deployment Strategy

InlineWhisper requires a robust build and deployment pipeline that ensures consistent builds, security compliance, and reliable distribution while maintaining the privacy-first, offline-only nature of the application.

---

## Build Pipeline Architecture

### Overview
```
Source Code → Build → Test → Security Scan → Package → Sign → Notarize → Distribute
     │          │      │         │            │       │       │           │
     ▼          ▼      ▼         ▼            ▼       ▼       ▼           ▼
GitHub     Xcode  Unit    Entitlement    DMG    Developer  Apple    Direct
Actions    Build  Tests   Audit          PKG    ID Signing Notary   Download
```

### Build Stages

#### Stage 1: Environment Setup
```bash
# Environment variables
DEVELOPMENT_TEAM="XXXXXXXXXX"  # Apple Developer Team ID
BUNDLE_ID="com.yourorg.InlineWhisper"
APP_NAME="InlineWhisper"
MACOS_DEPLOYMENT_TARGET="15.0"

# Dependencies installation
./scripts/install_dependencies.sh
```

#### Stage 2: Code Preparation
```bash
# Submodule initialization
git submodule update --init --recursive

# Version management
./scripts/set_build_number.sh
./scripts/update_version.sh

# Code quality checks
swiftlint --strict
swiftformat --lint .
```

#### Stage 3: Dependency Building
```bash
# whisper.cpp compilation
./scripts/build_whisper.sh --configuration Release

# Third-party library validation
./scripts/verify_dependencies.sh
```

#### Stage 4: Xcode Project Generation
```bash
# Project generation
xcodegen generate --spec ./configs/project.yml

# Build configuration validation
./scripts/validate_build_config.sh
```

---

## CI/CD Pipeline Configuration

### GitHub Actions Workflow

#### Main CI Pipeline (.github/workflows/ci.yml)
```yaml
name: InlineWhisper CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  DEVELOPER_DIR: /Applications/Xcode_16.0.app/Contents/Developer

jobs:
  build-and-test:
    runs-on: macos-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        submodules: recursive
        lfs: true
    
    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: |
          ~/Library/Caches/Homebrew
          ~/.cache/pip
          build/
        key: ${{ runner.os }}-deps-${{ hashFiles('**/Package.resolved') }}
    
    - name: Install system dependencies
      run: |
        brew install cmake xcodegen jq swiftlint
        brew install imagemagick # For icon processing
    
    - name: Setup Xcode
      run: sudo xcode-select -s /Applications/Xcode_16.0.app
    
    - name: Build whisper.cpp
      run: ./scripts/build_whisper.sh --configuration Debug
      
    - name: Generate Xcode project
      run: xcodegen generate --spec ./configs/project.yml
    
    - name: Run unit tests
      run: |
        xcodebuild test \
          -scheme InlineWhisperModules-Package \
          -destination 'platform=macOS' \
          -enableCodeCoverage YES \
          -derivedDataPath build/DerivedData \
          -resultBundlePath build/TestResults.xcresult
    
    - name: Run integration tests
      run: |
        xcodebuild test \
          -scheme InlineWhisper \
          -destination 'platform=macOS' \
          -derivedDataPath build/DerivedData
    
    - name: Security audit
      run: ./scripts/security_audit.sh
    
    - name: Performance tests
      run: |
        xcodebuild test \
          -scheme InlineWhisperPerformanceTests \
          -destination 'platform=macOS' \
          -derivedDataPath build/DerivedData
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: build/TestResults.xcresult
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.lcov
        flags: unittests
        name: codecov-umbrella

  build-release:
    needs: build-and-test
    if: github.ref == 'refs/heads/main'
    runs-on: macos-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        submodules: recursive
        lfs: true
    
    - name: Install dependencies
      run: |
        brew install cmake xcodegen jq
    
    - name: Setup certificates
      env:
        BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
        P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
        KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
      run: ./scripts/setup_certificates.sh
    
    - name: Build release
      run: ./scripts/build_release.sh
    
    - name: Notarize
      env:
        APPLE_ID: ${{ secrets.APPLE_ID }}
        APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
        TEAM_ID: ${{ secrets.TEAM_ID }}
      run: ./scripts/notarize.sh build/Release/InlineWhisper.app
    
    - name: Create DMG
      run: ./scripts/create_dmg.sh
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: InlineWhisper-Release
        path: build/InlineWhisper-*.dmg
```

---

## Build Scripts

### Build whisper.cpp Script
```bash
#!/bin/bash
# scripts/build_whisper.sh

set -euo pipefail

CONFIGURATION=${1:-Debug}
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WHISPER_DIR="$ROOT_DIR/third_party/whisper.cpp"
BUILD_DIR="$WHISPER_DIR/build"

echo "Building whisper.cpp ($CONFIGURATION)..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure CMake
cmake -DCMAKE_BUILD_TYPE="$CONFIGURATION" \
      -DGGML_METAL=ON \
      -DWHISPER_COREML=OFF \
      -DWHISPER_METAL_EMBED_LIBRARY=ON \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
      ..

# Build
cmake --build . --config "$CONFIGURATION" --parallel

# Copy artifacts
DEST_DIR="$ROOT_DIR/Modules/WhisperBridge/Sources/WhisperBridge/csrc"
mkdir -p "$DEST_DIR"
cp libwhisper.a "$DEST_DIR/"
cp -r ../ggml/src/ggml-metal.metal "$DEST_DIR/" 2>/dev/null || true

echo "whisper.cpp built successfully"
```

### Security Audit Script
```bash
#!/bin/bash
# scripts/security_audit.sh

set -euo pipefail

APP_PATH=${1:-"build/Release/InlineWhisper.app"}
echo "Performing security audit on $APP_PATH..."

# Network entitlement check
echo "Checking for network entitlements..."
codesign -d --entitlements :- "$APP_PATH" | grep -q "network" && {
    echo "❌ ERROR: Network entitlements found!"
    exit 1
} || echo "✅ No network entitlements found"

# Symbol check for networking APIs
echo "Checking for networking symbols..."
SYMBOLS=$(nm -um "$APP_PATH/Contents/MacOS/"* | grep -iE "(CFNetwork|NSURLSession|NSURLConnection|getaddrinfo|CFStream)" || true)

if [ -n "$SYMBOLS" ]; then
    echo "❌ ERROR: Networking symbols found:"
    echo "$SYMBOLS"
    exit 1
else
    echo "✅ No networking symbols found"
fi

# Privacy entitlement check
echo "Checking privacy entitlements..."
ENTITLEMENTS=$(codesign -d --entitlements :- "$APP_PATH")
REQUIRED_PRIVACY=(
    "NSMicrophoneUsageDescription"
    "NSAppleEventsUsageDescription"
)
for entitlement in "${REQUIRED_PRIVACY[@]}"; do
    echo "$ENTITLEMENTS" | grep -q "$entitlement" && \
        echo "✅ $entitlement present" || \
        echo "⚠️  $entitlement missing"
done

# Hardened runtime check
echo "Checking hardened runtime..."
codesign -dv "$APP_PATH" 2>&1 | grep -q "runtime" && \
    echo "✅ Hardened runtime enabled" || \
    echo "❌ ERROR: Hardened runtime not enabled"

echo "Security audit complete"
```

### Build Release Script
```bash
#!/bin/bash
# scripts/build_release.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/Release"
ARCHIVE_PATH="$BUILD_DIR/InlineWhisper.xcarchive"

echo "Building InlineWhisper release..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build whisper.cpp for release
./scripts/build_whisper.sh Release

# Generate Xcode project
xcodegen generate --spec "$ROOT_DIR/configs/project.yml"

# Archive build
xcodebuild archive \
    -project "$ROOT_DIR/InlineWhisper.xcodeproj" \
    -scheme InlineWhisper \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    CODE_SIGN_STYLE="Manual"

# Export archive
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$BUILD_DIR" \
    -exportOptionsPlist "$ROOT_DIR/configs/export_options.plist"

echo "Release build complete: $BUILD_DIR/InlineWhisper.app"
```

---

## Signing & Notarization

### Certificate Setup
```bash
#!/bin/bash
# scripts/setup_certificates.sh

set -euo pipefail

CERTIFICATE_PATH="$RUNNER_TEMP/build_certificate.p12"
KEYCHAIN_PATH="$RUNNER_TEMP/app-signing.keychain-db"

# Decode certificate
echo -n "$BUILD_CERTIFICATE_BASE64" | base64 --decode -o "$CERTIFICATE_PATH"

# Create temporary keychain
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

# Import certificate
security import "$CERTIFICATE_PATH" \
    -P "$P12_PASSWORD" \
    -A -t cert -f pkcs12 \
    -k "$KEYCHAIN_PATH"

# Set keychain for codesign
security list-keychain -d user -s "$KEYCHAIN_PATH"
```

### Notarization Process
```bash
#!/bin/bash
# scripts/notarize.sh

set -euo pipefail

APP_PATH=${1:-"build/Release/InlineWhisper.app"}
BUNDLE_ID="com.yourorg.InlineWhisper"
ZIP_PATH="$APP_PATH.zip"

echo "Notarizing $APP_PATH..."

# Create ZIP for notarization
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

# Submit for notarization
xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

# Staple notarization ticket
xcrun stapler staple "$APP_PATH"

# Verify notarization
spctl -a -v "$APP_PATH"

echo "Notarization complete"
```

---

## Package Creation

### DMG Creation
```bash
#!/bin/bash
# scripts/create_dmg.sh

set -euo pipefail

APP_PATH="build/Release/InlineWhisper.app"
DMG_NAME="InlineWhisper-$(cat VERSION).dmg"
DMG_PATH="build/$DMG_NAME"
VOLUME_NAME="InlineWhisper"

echo "Creating DMG: $DMG_PATH..."

# Clean previous DMG
rm -f "$DMG_PATH"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create DMG
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$TEMP_DIR"

echo "DMG created: $DMG_PATH"
```

### Package Structure
```
InlineWhisper.dmg
├── InlineWhisper.app/
│   ├── Contents/
│   │   ├── Info.plist
│   │   ├── MacOS/InlineWhisper (executable)
│   │   ├── Resources/ (assets, models)
│   │   ├── Frameworks/ (embedded frameworks)
│   │   └── _CodeSignature/ (code signing)
├── README.md
├── LICENSE
└── Quick Start Guide.pdf
```

---

## Distribution Channels

### Direct Distribution
```bash
# Upload to distribution server
rsync -avz --delete \
    build/InlineWhisper-*.dmg \
    user@distribution-server:/var/www/downloads/

# Update download page
./scripts/update_download_page.sh
```

### Update Mechanism
```bash
# Generate app cast for Sparkle (if using)
./scripts/generate_appcast.sh build/

# Manual update check
# Opens releases page in browser
# No auto-download to maintain privacy
```

---

## Quality Assurance Pipeline

### Automated Quality Checks

#### Entitlement Audit
```bash
#!/bin/bash
# scripts/entitlement_audit.sh

APP_PATH=${1:-"build/Release/InlineWhisper.app"}

echo "=== Entitlement Audit ==="

# Check for network entitlements
codesign -d --entitlements :- "$APP_PATH" | grep -E "(com.apple.security.network|network)" && {
    echo "❌ NETWORK ENTITLEMENTS FOUND - REJECTED"
    exit 1
}

# Verify required entitlements
REQUIRED=(
    "com.apple.security.app-sandbox"
    "com.apple.security.device.microphone"
)

for entitlement in "${REQUIRED[@]}"; do
    codesign -d --entitlements :- "$APP_PATH" | grep -q "$entitlement" || {
        echo "❌ Missing required entitlement: $entitlement"
        exit 1
    }
done

# Check for prohibited entitlements
PROHIBITED=(
    "com.apple.security.network.client"
    "com.apple.security.network.server"
    "com.apple.security.files.downloads"
)

for entitlement in "${PROHIBITED[@]}"; do
    codesign -d --entitlements :- "$APP_PATH" | grep -q "$entitlement" && {
        echo "❌ Prohibited entitlement found: $entitlement"
        exit 1
    }
done

echo "✅ Entitlement audit passed"
```

#### Model Integrity Verification
```bash
#!/bin/bash
# scripts/verify_model_integrity.sh

MODEL_PATH="build/Release/InlineWhisper.app/Contents/Resources/ggml-small.en-f16.bin"
EXPECTED_HASH="sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

echo "Verifying model integrity..."

if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Model file not found: $MODEL_PATH"
    exit 1
fi

ACTUAL_HASH=$(shasum -a 256 "$MODEL_PATH" | cut -d' ' -f1)

if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
    echo "❌ Model hash mismatch!"
    echo "Expected: $EXPECTED_HASH"
    echo "Actual:   $ACTUAL_HASH"
    exit 1
fi

echo "✅ Model integrity verified"
```

#### Performance Regression Detection
```bash
#!/bin/bash
# scripts/performance_regression.sh

# Compare current performance with baseline
CURRENT_PERF=$(./scripts/measure_performance.sh)
BASELINE_PERF=$(cat performance_baseline.json)

# Extract metrics
CURRENT_LATENCY=$(echo "$CURRENT_PERF" | jq '.first_partial_latency')
BASELINE_LATENCY=$(echo "$BASELINE_PERF" | jq '.first_partial_latency')

# Check for regression (5% threshold)
THRESHOLD=0.05
REGRESSION=$(echo "$CURRENT_LATENCY > $BASELINE_LATENCY * (1 + $THRESHOLD)" | bc -l)

if [ "$REGRESSION" -eq 1 ]; then
    echo "❌ Performance regression detected!"
    echo "Current: ${CURRENT_LATENCY}ms, Baseline: ${BASELINE_LATENCY}ms"
    exit 1
fi

echo "✅ Performance within acceptable range"
```

---

## Release Management

### Version Management
```bash
#!/bin/bash
# scripts/version_bump.sh

TYPE=${1:-"patch"}  # major, minor, patch

# Get current version
CURRENT_VERSION=$(cat VERSION)
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

# Bump version
case $TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "$NEW_VERSION" > VERSION

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" configs/AppInfo.plist

# Update build number (CI timestamp)
BUILD_NUMBER=$(date +%Y%m%d%H%M%S)
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" configs/AppInfo.plist

echo "Version bumped to $NEW_VERSION (build $BUILD_NUMBER)"
```

### Release Checklist
```markdown
## Pre-Release Checklist

### Code Quality
- [ ] All tests pass (unit + integration)
- [ ] Code coverage ≥80%
- [ ] SwiftLint warnings = 0
- [ ] No TODO/FIXME comments in release code

### Security & Privacy
- [ ] Entitlement audit passed
- [ ] No network APIs detected
- [ ] Privacy policy updated
- [ ] Security scan completed

### Performance
- [ ] Performance benchmarks meet targets
- [ ] Memory usage <500MB peak
- [ ] No memory leaks detected
- [ ] Thermal testing passed

### Accessibility
- [ ] VoiceOver testing completed
- [ ] Keyboard navigation verified
- [ ] High contrast mode tested
- [ ] Color contrast ratios verified

### Documentation
- [ ] User guide updated
- [ ] API documentation complete
- [ ] README.md current
- [ ] CHANGELOG.md updated

### Distribution
- [ ] Code signing certificates valid
- [ ] Notarization configured
- [ ] DMG creation tested
- [ ] Website updated
```

---

## Deployment Environments

### Development Environment
```yaml
# Development settings
Configuration: Debug
Code Signing: Development
Optimization: None
Assertions: Enabled
Logging: Verbose
```

### Beta Environment
```yaml
# Beta/TestFlight settings
Configuration: Release
Code Signing: Developer ID
Optimization: Speed
Assertions: Disabled
Logging: Error only
```

### Production Environment
```yaml
# Production settings
Configuration: Release
Code Signing: Developer ID
Optimization: Speed
Assertions: Disabled
Logging: Error only
Security: Hardened runtime
```

---

## Monitoring & Analytics

### Privacy-Compliant Metrics
```swift
// Anonymous usage metrics (opt-in, local only)
struct UsageMetrics {
    let sessionsStarted: Int
    let dictationDuration: TimeInterval
    let insertionStrategyUsed: String
    let modelUsed: String
    let errorsEncountered: [String: Int]
    
    // No personal data, no network transmission
    func export() -> Data? {
        // Local export only, user controlled
    }
}
```

### Crash Reporting
```bash
# Local crash log collection
./scripts/collect_crashes.sh ~/Library/Logs/DiagnosticReports/

# Privacy-preserving crash analysis
# No automatic transmission - user initiated only
```

---

## Rollback & Recovery

### Rollback Strategy
```bash
#!/bin/bash
# scripts/rollback_release.sh

PREVIOUS_VERSION=$(git tag --sort=-version:refname | head -2 | tail -1)

echo "Rolling back to version $PREVIOUS_VERSION..."

# Revert to previous version
git revert --no-commit HEAD
git commit -m "Rollback to version $PREVIOUS_VERSION"

# Rebuild previous version
git checkout "v$PREVIOUS_VERSION"
./scripts/build_release.sh

# Update distribution
./scripts/update_distribution.sh "$PREVIOUS_VERSION"

echo "Rollback complete"
```

### Emergency Response
```markdown
## Emergency Response Plan

### Critical Security Issue
1. Immediately disable downloads
2. Issue security advisory
3. Fix vulnerability
4. Rebuild and re-notarize
5. Distribute patched version

### Critical Performance Regression
1. Roll back to previous version
2. Investigate root cause
3. Fix performance issue
4. Re-test thoroughly
5. Re-release

### Critical Functional Bug
1. Assess severity and scope
2. Issue hotfix if possible
3. Otherwise rollback
4. Fix bug properly
5. Re-release
```

---

## Success Metrics

### Build Metrics
- **Build Success Rate**: ≥99%
- **Build Duration**: ≤10 minutes
- **Test Pass Rate**: ≥95%
- **Code Coverage**: ≥80%

### Deployment Metrics
- **Notarization Success**: ≥95%
- **DMG Creation Success**: ≥99%
- **Distribution Uptime**: ≥99.9%
- **Download Success**: ≥98%

### Quality Metrics
- **Security Audit Pass**: 100%
- **Performance Regression**: ≤5%
- **Zero Critical Bugs**: In production
- **User Satisfaction**: ≥4.5/5.0

This comprehensive build and deployment pipeline ensures InlineWhisper maintains the highest quality standards while preserving its privacy-first principles and delivering reliable updates to users.