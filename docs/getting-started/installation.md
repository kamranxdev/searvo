# Installation Guide

This guide will help you install and set up Searvo on your system.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.8.0 or higher)
  - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (3.8.0 or higher) - comes with Flutter
- **Git** for version control
- **IDE** - VS Code, Android Studio, or IntelliJ IDEA recommended

### Platform-Specific Requirements

#### Android
- Android Studio
- Android SDK (API level 21 or higher)
- Java Development Kit (JDK) 11 or higher

#### iOS (macOS only)
- Xcode 14.0 or higher
- CocoaPods

#### Linux
- CMake
- Ninja build system
- GTK 3.0 development libraries

#### Windows
- Visual Studio 2022 with C++ development tools

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/kamranxdev/searvo-community.git
cd searvo-community
```

### 2. Install Dependencies

Run Flutter's package manager to install all required dependencies:

```bash
flutter pub get
```

This will install all packages defined in `pubspec.yaml`, including:
- LangChain packages for LLM integration
- UI components and utilities
- Voice recognition libraries
- And more...

### 3. Verify Installation

Check that Flutter is properly set up:

```bash
flutter doctor
```

This command checks your environment and displays a report of the status of your Flutter installation. Fix any issues reported.

### 4. Run the Application

You can now run Searvo on your preferred platform:

#### Desktop (Linux/macOS/Windows)
```bash
flutter run -d linux    # For Linux
flutter run -d macos    # For macOS
flutter run -d windows  # For Windows
```

#### Mobile
```bash
flutter run -d android  # For Android
flutter run -d ios      # For iOS (macOS only)
```

#### Web
```bash
flutter run -d chrome   # For web browsers
```

Or use the convenient shell scripts:

```bash
./linux.sh    # Run on Linux
./android.sh  # Run on Android
./web.sh      # Run on Web
```

## Docker Setup (Optional)

Searvo includes Docker support for running SearXNG (search engine):

### Prerequisites
- Docker
- Docker Compose

### Running with Docker

```bash
docker-compose up -d
```

This will start:
- SearXNG search engine (port 8080)
- Caddy reverse proxy (configured via Caddyfile)

## Configuration

After installation, you'll need to configure:

1. **LLM Provider** - Choose and configure your AI provider (OpenAI, Google, Anthropic, Ollama, or OpenRouter)
2. **Search Provider** - Configure SearXNG or other search backends
3. **Permissions** - Grant microphone access for voice features

See [Configuration Guide](configuration.md) for detailed instructions.

## Troubleshooting

### Common Issues

#### Flutter Doctor Issues
- **Android toolchain issues**: Install/update Android SDK via Android Studio
- **Xcode issues**: Update Xcode and accept licenses with `sudo xcodlicense --agree-only`
- **VS Code/IntelliJ issues**: Install Flutter and Dart plugins

#### Build Errors
- Run `flutter clean` then `flutter pub get`
- Delete `pubspec.lock` and run `flutter pub get` again
- Check that you're using Flutter 3.8.0 or higher

#### Permission Errors (Voice Features)
- Android: Add microphone permission in `android/app/src/main/AndroidManifest.xml`
- iOS: Check `Info.plist` for microphone usage description
- Linux: Ensure PulseAudio or PipeWire is running

#### Docker Issues
- Ensure ports 8080 and 443 are not in use
- Check Docker daemon is running: `docker ps`
- View logs: `docker-compose logs -f`

## Next Steps

- [Configuration Guide](configuration.md) - Set up your LLM providers
- [Overview](overview.md) - Learn about Searvo's features
- [Contributing](../development/contributing.md) - Help improve Searvo

## Getting Help

- [GitHub Issues](https://github.com/kamranxdev/searvo-community/issues)
- [GitHub Discussions](https://github.com/kamranxdev/searvo-community/discussions)
- [Discord Community](https://discord.gg/Bq67m6NYaa)
