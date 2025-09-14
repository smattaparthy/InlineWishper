# InlineWhisper 🎤

[![macOS Version](https://img.shields.io/badge/macOS-15.0+-blue.svg)](https://www.apple.com/macos/)
[![Xcode Version](https://img.shields.io/badge/Xcode-16.0+-blue.svg)](https://developer.apple.com/xcode/)
[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Privacy-first, offline dictation for macOS** - Transform your speech into text in any application without sending data to external servers.

## 🌟 Features

### Core Functionality
- **🎙️ Real-time Speech-to-Text**: Powered by OpenAI's Whisper AI model
- **🔒 Completely Offline**: All processing happens locally on your Mac
- **⌨️ Universal Text Insertion**: Works with any application via clipboard + paste
- **🎯 Push-to-Talk**: Control dictation with system-wide hotkeys
- **📊 Audio Visualization**: Real-time audio level monitoring

### Privacy & Security
- **🛡️ Zero Network Requests**: No data transmission to external servers
- **🔐 App Sandbox**: Runs in secure macOS sandbox environment
- **📱 Permission-Based**: Only requests microphone and accessibility access
- **🏠 Local Processing**: AI model runs entirely on your device

### User Experience
- **🎯 Menu Bar Integration**: Always accessible from the menu bar
- **⚙️ Comprehensive Settings**: Hotkey configuration, audio settings, and more
- **🎓 Onboarding Flow**: Guided setup for permissions and initial configuration
- **🧪 Real-time Feedback**: Visual and audio feedback during dictation

## 🚀 Quick Start

### Prerequisites
- macOS 15.0 (Sequoia) or later
- Apple Silicon Mac (M1, M2, M3, or later)
- Xcode 16.0 or later
- Apple Developer Account (for code signing)

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/InlineWhisper.git
   cd InlineWhisper
   ```

2. **Run the setup script:**
   ```bash
   ./setup.sh
   ```

3. **Open in Xcode:**
   ```bash
   open InlineWhisper.xcodeproj
   ```

4. **Configure code signing:**
   - Select your Apple Developer team in Xcode
   - Update the bundle identifier if needed

5. **Build and run:**
   - Press `⌘+R` in Xcode to build and run

### First Launch
1. **Complete Onboarding:** Follow the guided setup for permissions
2. **Grant Permissions:** Allow microphone and accessibility access
3. **Test Dictation:** Press `Control + Option + D` to start dictating

## 🎯 Usage

### Basic Dictation
1. **Start Dictation:** Press `Control + Option + D` or click the menu bar icon
2. **Speak Clearly:** Use your normal speaking voice
3. **Stop Dictation:** Press the hotkey again or click "Stop Dictation"
4. **Text Insertion:** Transcribed text automatically appears in your active application

### Menu Bar Controls
- **Start/Stop:** Quick toggle for dictation
- **Settings:** Access configuration options
- **Help:** View onboarding and documentation
- **Quit:** Exit the application

### Settings Configuration
- **Hotkeys:** Customize keyboard shortcuts
- **Audio:** Select input device and test audio levels
- **Advanced:** Debug options and logging
- **Privacy:** Review permission status

## 🛠️ Development

### Project Structure
```
InlineWhisper/
├── app/                    # Main application code
│   ├── Views/             # SwiftUI views
│   └── InlineWhisperApp.swift
├── Modules/               # Swift packages
│   ├── DictationKit/      # Core dictation logic
│   ├── WhisperBridge/     # Whisper.cpp integration
│   └── SystemKit/         # System services
├── third_party/           # External dependencies
│   └── whisper.cpp/       # AI model integration
├── scripts/               # Build and setup scripts
├── configs/               # Configuration files
└── Tests/                # Unit tests
```

### Architecture
- **MVVM Pattern:** SwiftUI with ObservableObject
- **Modular Design:** Swift Package Manager architecture
- **Protocol-Oriented:** Clean abstractions for services
- **Offline-First:** No network dependencies

### Building from Source
```bash
# Build whisper.cpp
./scripts/build_whisper.sh

# Generate Xcode project
xcodegen generate --spec project.yml

# Open in Xcode
open InlineWhisper.xcodeproj
```

### Testing
Run tests in Xcode or via command line:
```bash
xcodebuild test -scheme InlineWhisper-Package
```

## 🔧 Configuration

### Hotkey Configuration
Default hotkey: `Control + Option + D`

Customize in Settings:
1. Open Settings from menu bar
2. Navigate to Hotkeys section
3. Click "Change" and press your desired combination
4. Must include at least one modifier key

### Audio Settings
- **Input Device:** Select microphone source
- **Audio Test:** Verify microphone functionality
- **Level Monitoring:** Visual feedback during dictation

### Model Management
- **Default Model:** Whisper tiny.en (~40MB)
- **Language:** English only (for MVP)
- **Optimization:** Optimized for real-time performance

## 🚨 Troubleshooting

### Common Issues

#### Microphone Access Denied
1. Go to System Settings > Privacy & Security > Microphone
2. Enable InlineWhisper
3. Restart the application

#### Accessibility Access Required
1. Go to System Settings > Privacy & Security > Accessibility
2. Add InlineWhisper to the allowed apps
3. Restart the application

#### Text Not Inserting
1. Ensure target application supports paste (Cmd+V)
2. Check clipboard permissions
3. Verify accessibility access

#### Poor Transcription Quality
1. Check microphone audio levels in Settings
2. Ensure quiet environment
3. Speak clearly and at normal pace
4. Verify Whisper model is properly loaded

### Debug Information
Enable debug mode in Settings > Advanced for detailed logging:
- View logs in Console.app
- Filter by "InlineWhisper"
- Check for error messages

## 📊 Performance

### System Requirements
- **CPU:** Apple Silicon (M1, M2, M3, or later)
- **Memory:** 4GB RAM minimum, 8GB recommended
- **Storage:** 100MB for application, 40MB for AI model
- **macOS:** 15.0 Sequoia or later

### Performance Metrics (MVP)
- **Latency:** < 2 seconds for first partial result
- **Memory:** < 300MB peak usage
- **CPU:** Optimized for real-time processing
- **Model Size:** ~40MB (tiny.en)

### Optimization Tips
- Close unnecessary applications for better performance
- Use the tiny.en model for fastest response
- Keep microphone at optimal distance
- Ensure good audio quality environment

## 🔒 Privacy

### Data Protection
- **No Network:** Zero external network requests
- **Local Processing:** All transcription happens locally
- **Secure Sandbox:** Runs in macOS app sandbox
- **Minimal Permissions:** Only requests essential access

### Data Flow
1. Audio captured from microphone
2. Processed by local Whisper AI model
3. Text inserted into target application
4. No data storage or transmission

### Transparency
- Open source codebase for audit
- Clear permission requirements
- No hidden data collection
- User control over all features

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🙏 Acknowledgments

- **OpenAI Whisper:** For the powerful speech recognition model
- **whisper.cpp:** For the efficient C++ implementation
- **Swift Community:** For excellent frameworks and tools
- **macOS:** For the secure and powerful platform

## 📞 Support

- **Documentation:** Check the help section in the app
- **Issues:** Report bugs on GitHub Issues
- **Discussions:** Join community discussions
- **Email:** support@inlineproject.com

---

**Built with ❤️ for privacy-first dictation**

*Your voice, your words, your Mac.*