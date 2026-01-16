#!/bin/bash

# Searvo Development Runner
# This script runs the Flutter web app in development mode

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

# Start SearXNG with Caddy (CORS-enabled)
start_searxng() {
    print_status "Starting SearXNG with Caddy reverse proxy..."
    
    # Check if containers are already running
    if docker ps --filter name=searvo-caddy --filter status=running | grep -q searvo-caddy; then
        print_status "SearXNG services are already running"
        return 0
    fi
    
    # Build and start services with docker-compose
    print_status "Building images..."
    docker compose build >/dev/null 2>&1
    
    print_status "Starting services on port 4000..."
    docker compose up -d >/dev/null 2>&1
    
    # Wait a moment for containers to start
    sleep 3
    
    if docker ps --filter name=searvo-caddy --filter status=running | grep -q searvo-caddy; then
        print_success "SearXNG + Caddy are running on http://localhost:4000"
        print_success "Qdrant vector database is running on http://localhost:6333"
        print_success "CORS is properly configured for cross-origin requests"
    else
        print_error "Failed to start services"
        docker compose logs
        exit 1
    fi
}

# Stop SearXNG and Caddy containers
stop_searxng() {
    print_status "Stopping SearXNG services..."
    if docker ps --filter name=searvo-caddy --filter status=running | grep -q searvo-caddy; then
        docker compose down >/dev/null 2>&1
        print_success "SearXNG services stopped"
    else
        print_status "SearXNG services are not running"
    fi
}

# Run Flutter web in development mode
run_dev() {
    print_status "Starting development environment..."
    
    # Start SearXNG first
    start_searxng
    
    print_status "Starting Flutter web development server..."
    
    # Enable web if not already enabled
    flutter config --enable-web >/dev/null 2>&1
    
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
    
    # Run the web app
    print_status "Starting Flutter development server on port 3000..."
    print_success "🚀 Development environment ready!"
    print_success "   Flutter Web: http://localhost:3000"
    print_success "   SearXNG API: http://localhost:4000"
    print_success "   Qdrant Vector DB: http://localhost:6333"
    print_status "Press Ctrl+C to stop all services"

    flutter run -d chrome --web-port 3000
}

# Build for production
build_prod() {
    print_status "Building Flutter web app for production..."
    
    flutter config --enable-web >/dev/null 2>&1
    flutter pub get
    flutter build web --release --web-renderer html
    
    print_success "Build completed! Files are in build/web/"
}

# Stop all development services
stop_dev() {
    print_status "Stopping all development services..."
    stop_searxng
    print_success "All services stopped"
}

# Show help
show_help() {
    echo "Searvo Development Script"
    echo "========================"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  dev      Start development environment (Flutter + SearXNG) (default)"
    echo "  build    Build Flutter app for production"
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
    echo "  - Flutter Web: http://localhost:3000"
    echo "  - SearXNG API: http://localhost:4000"
    echo "  - Qdrant Vector DB: http://localhost:6333"
}

# Main script logic
case "${1:-dev}" in
    "dev")
        echo "🚀 Starting Searvo Development Environment"
        echo "========================================="
        check_flutter
        check_docker
        run_dev
        ;;
    "build")
        echo "🏗️ Building Searvo for Production"
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