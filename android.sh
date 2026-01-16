#!/bin/bash

# Searvo Development Runner (Android)
# This script runs the Flutter Android app in development mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v flutter >/dev/null 2>&1; then
        print_error "Flutter is not installed. Please install Flutter and try again."
        echo "Visit: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    print_success "Flutter is available"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed. Please install Docker and try again."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker is available"
}

# Start SearXNG with Caddy and Qdrant
start_searxng() {
    print_status "Starting SearXNG services (SearXNG + Caddy + Qdrant)..."
    
    # Check if containers are already running
    if docker ps --filter name=searvo-caddy --filter status=running | grep -q searvo-caddy; then
        print_status "SearXNG services are already running"
        return 0
    fi
    
    # Build and start services with docker compose
    print_status "Building images..."
    docker compose build >/dev/null 2>&1
    
    print_status "Starting services on port 4000..."
    docker compose up -d >/dev/null 2>&1
    
    # Wait a moment for containers to start
    sleep 3
    
    if docker ps --filter name=searvo-caddy --filter status=running | grep -q searvo-caddy; then
        print_success "SearXNG + Caddy are running on http://localhost:4000"
        print_success "Qdrant vector database is running on http://localhost:6333"
    else
        print_error "Failed to start services"
        docker compose logs
        exit 1
    fi
}

# Stop SearXNG and all services
stop_searxng() {
    print_status "Stopping SearXNG services..."
    if docker ps --filter name=searvo-caddy --filter status=running | grep -q searvo-caddy; then
        docker compose down >/dev/null 2>&1
        print_success "SearXNG services stopped"
    else
        print_status "SearXNG services are not running"
    fi
}

# Check if any Android devices are connected
check_android_device() {
    # If adb is not available, return failure gracefully
    if ! command -v adb >/dev/null 2>&1; then
        return 1
    fi
    
    # Get device list, skip header line, check if any device is online
    local device_count=$(adb devices 2>/dev/null | tail -n +2 | grep -c "device$" || echo "0")
    
    if [ "$device_count" -gt 0 ]; then
        return 0  # Device found
    else
        return 1  # No device found
    fi
}

# Check and setup Android SDK
check_android_sdk() {
    if ! command -v adb >/dev/null 2>&1; then
        print_error "adb (Android SDK platform-tools) is not available."
        echo ""
        echo "To set up Android development environment:"
        echo "1. Download and install Android SDK from: https://developer.android.com/studio"
        echo "2. Or use: brew install android-platform-tools (on macOS)"
        echo "3. Or add Android SDK platform-tools to your PATH"
        echo ""
        echo "For Searvo Android development, you also need:"
        echo "  - Android NDK"
        echo "  - Android emulator or physical device"
        echo ""
        return 1
    fi
    print_success "Android SDK tools available"
    return 0
}

# Run Flutter Android in development mode
run_dev() {
    print_status "Starting development environment..."
    
    # Start SearXNG first
    start_searxng
    
    print_status "Starting Flutter Android development..."
    
    # Ensure Android tooling is available
    if ! check_android_sdk; then
        print_status "Attempting to continue without adb for pubspec setup..."
        print_status "Note: You will need Android SDK to run on device/emulator"
    fi

    # Get dependencies
    print_status "Getting dependencies..."
    flutter pub get

    # Set up cleanup trap for graceful shutdown
    cleanup() {
        print_status "Shutting down development environment..."
        stop_searxng
        exit 0
    }
    trap cleanup INT TERM

    # Check if adb is available for device management
    if ! command -v adb >/dev/null 2>&1; then
        print_error "Android SDK platform-tools not installed (adb not found)"
        print_error "Cannot run on Android device/emulator without it."
        echo ""
        echo "To install Android SDK platform-tools:"
        echo "  macOS:   brew install android-platform-tools"
        echo "  Linux:   Download from https://developer.android.com/studio/releases/platform-tools"
        echo "  Windows: Download from https://developer.android.com/studio/releases/platform-tools"
        echo ""
        print_status "Good news: SearXNG backend is running at http://localhost:4000"
        print_status "You can connect your Android app to it once you have the SDK installed."
        print_status ""
        print_status "To continue with backend only (no app launch), you can:"
        echo "  1. Install Android SDK platform-tools"
        echo "  2. Connect an Android device or start an emulator"
        echo "  3. Run this script again"
        echo ""
        stop_searxng
        exit 0
    fi

    # Check for connected devices
    if ! check_android_device; then
        print_status "No Android device detected. Attempting to start an emulator..."
        
        if command -v emulator >/dev/null 2>&1; then
            # Get list of available AVDs
            AVD=$(emulator -list-avds 2>/dev/null | head -n 1 || echo "")
            
            if [ -n "$AVD" ]; then
                print_status "Starting AVD: $AVD"
                nohup emulator -avd "$AVD" -no-snapshot -no-audio -no-boot-anim >/dev/null 2>&1 &
                
                # Wait for device to be ready
                print_status "Waiting for emulator to boot (this may take 30-60s)..."
                adb wait-for-device
                
                # Give the emulator a bit more time to fully initialize
                sleep 5
            else
                print_error "No AVDs available."
                print_error "Please create one using Android Studio or run: flutter emulators --create"
                cleanup
            fi
        else
            print_error "Android emulator is not available."
            print_error "Connect a physical device or install Android SDK emulator tools."
            cleanup
        fi
    fi

    # Verify we have a device now
    if ! check_android_device; then
        print_error "No Android device available after attempting to start emulator."
        print_error "Please ensure a device is connected or an emulator is running."
        cleanup
    fi

    # Run the app on the first available device
    # Get the specific device ID
    DEVICE_ID=$(adb devices | tail -n +2 | grep "device$" | head -n 1 | awk '{print $1}')
    
    if [ -z "$DEVICE_ID" ]; then
        print_error "Failed to detect a valid Android device ID."
        cleanup
    fi

    # Run the app on the specific device
    print_status "Launching Flutter app on Android device ($DEVICE_ID)..."
    print_success "🚀 Development environment ready!"
    print_success "   Android: will run on device $DEVICE_ID"
    print_success "   SearXNG API: http://localhost:4000"
    print_success "   Qdrant Vector DB: http://localhost:6333"
    print_status "Press Ctrl+C to stop all services"

    flutter run -d "$DEVICE_ID"
}

# Build for production (Android)
build_prod() {
    print_status "Building Flutter Android app for production..."

    flutter pub get
    flutter build apk --release

    print_success "Build completed! APK(s) are in build/app/outputs/flutter-apk/"
}

# Stop all development services
stop_dev() {
    print_status "Stopping all development services..."
    stop_searxng
    print_success "All services stopped"
}

# Show help
show_help() {
    echo "Searvo Development Script (Android)"
    echo "================================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  dev      Start development environment (Flutter Android + SearXNG) (default)"
    echo "  build    Build Flutter app for production (APK)"
    echo "  stop     Stop all development services"
    echo "  help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0           # Start development environment"
    echo "  $0 dev       # Start development environment"
    echo "  $0 build     # Build for production"
    echo "  $0 stop      # Stop all services"
    echo ""
    echo "Services:"
    echo "  - Flutter Android: runs on connected device/emulator"
    echo "  - SearXNG API: http://localhost:4000"
    echo "  - Qdrant Vector DB: http://localhost:6333"
}

# Main script logic
case "${1:-dev}" in
    "dev")
        echo "🚀 Starting Searvo Development Environment (Android)"
        echo "========================================="
        check_flutter
        check_docker
        run_dev
        ;;
    "build")
        echo "🏗️ Building Searvo for Production (Android)"
        echo "================================"
        check_flutter
        build_prod
        ;;
    "stop")
        echo "🛑 Stopping Searvo Development Services"
        echo "======================================"
        check_docker
        stop_dev
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' to see available commands"
        exit 1
        ;;
esac