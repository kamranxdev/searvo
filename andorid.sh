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

# Start SearXNG container
start_searxng() {
    print_status "Starting SearXNG container..."
    
    # Check if container is already running
    if docker ps --filter name=searvo-searxng --filter status=running | grep -q searvo-searxng; then
        print_status "SearXNG container is already running"
        return 0
    fi
    
    # Remove existing container if it exists but is stopped
    if docker ps -a --filter name=searvo-searxng | grep -q searvo-searxng; then
        print_status "Removing existing SearXNG container..."
        docker rm searvo-searxng >/dev/null 2>&1
    fi
    
    # Build and run SearXNG container
    print_status "Building SearXNG image..."
    docker build -t searvo-searxng -f searxng.dockerfile . >/dev/null 2>&1
    
    print_status "Starting SearXNG on port 4000..."
    docker run -d \
        --name searvo-searxng \
        -p 4000:8080 \
        -e SEARXNG_BOTDETECTION_ENABLED=false \
        --restart unless-stopped \
        searvo-searxng >/dev/null 2>&1
    
    # Wait a moment for container to start
    sleep 2
    
    if docker ps --filter name=searvo-searxng --filter status=running | grep -q searvo-searxng; then
        print_success "SearXNG is running on http://localhost:4000"
    else
        print_error "Failed to start SearXNG container"
        exit 1
    fi
}

# Stop SearXNG container
stop_searxng() {
    print_status "Stopping SearXNG container..."
    if docker ps --filter name=searvo-searxng --filter status=running | grep -q searvo-searxng; then
        docker stop searvo-searxng >/dev/null 2>&1
        docker rm searvo-searxng >/dev/null 2>&1
        print_success "SearXNG container stopped"
    else
        print_status "SearXNG container is not running"
    fi
}

# Run Flutter Android in development mode
run_dev() {
    print_status "Starting development environment..."
    
    # Start SearXNG first
    start_searxng
    
    print_status "Starting Flutter Android development..."
    
    # Ensure Android tooling is available
    if ! command -v adb >/dev/null 2>&1; then
        print_error "adb (Android SDK platform-tools) is not available. Please install Android SDK platform-tools and ensure 'adb' is on PATH."
        exit 1
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

    # If no device connected, start an emulator if possible
    if ! adb devices | sed -n '2,$p' | awk '{print $2}' | grep -q device; then
        print_status "No Android device detected. Attempting to start the first available emulator..."
        if command -v emulator >/dev/null 2>&1; then
            # try to list AVDs
            AVD=$(emulator -list-avds | head -n 1 || true)
            if [ -n "$AVD" ]; then
                print_status "Starting AVD: $AVD"
                nohup emulator -avd "$AVD" -no-snapshot -no-audio -no-boot-anim >/dev/null 2>&1 &
                # Wait for device to be ready
                print_status "Waiting for emulator to boot (this may take 30-60s)..."
                adb wait-for-device
            else
                print_error "No AVDs available. Please create one using Android Studio or 'avdmanager'."
                exit 1
            fi
        else
            print_error "Android emulator is not available. Connect a device or install Android SDK emulator tools."
            exit 1
        fi
    fi

    # Run the app on the first available device
    print_status "Launching Flutter app on Android device/emulator..."
    print_success "🚀 Development environment ready!"
    print_success "   Android: will run on connected device/emulator"
    print_success "   SearXNG API: http://localhost:4000"
    print_status "Press Ctrl+C to stop all services"

    flutter run -d android
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
