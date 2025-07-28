#!/bin/bash

# Tailscale DERP Server Deployment Script
# This script handles the complete deployment of the DERP server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to setup environment
setup_environment() {
    print_status "Setting up environment..."
    
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "${SCRIPT_DIR}/.env.example" ]; then
            print_warning ".env file not found. Copying from .env.example"
            cp "${SCRIPT_DIR}/.env.example" "$ENV_FILE"
            print_warning "Please edit .env file with your configuration before running again"
            print_warning "Required: Set DERP_DOMAIN to your actual domain name"
            exit 1
        else
            print_error ".env file not found and .env.example is missing"
            exit 1
        fi
    fi
    
    # Source environment file to validate
    set -a
    source "$ENV_FILE"
    set +a
    
    # Validate required variables
    if [ -z "$DERP_DOMAIN" ] || [ "$DERP_DOMAIN" = "your-domain.com" ]; then
        print_error "DERP_DOMAIN is not set or still has default value. Please configure .env file"
        exit 1
    fi
    
    print_success "Environment setup completed"
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p "${SCRIPT_DIR}/data"
    mkdir -p "${SCRIPT_DIR}/logs"
    mkdir -p "${SCRIPT_DIR}/certs"
    
    # Set appropriate permissions
    chmod 755 "${SCRIPT_DIR}/data"
    chmod 755 "${SCRIPT_DIR}/logs"
    chmod 700 "${SCRIPT_DIR}/certs"
    
    print_success "Directories created"
}

# Function to check SSL certificates
check_certificates() {
    print_status "Checking SSL certificates..."
    
    if [ "$DERP_CERTMODE" = "manual" ]; then
        CERT_FILE="${SCRIPT_DIR}/certs/${DERP_DOMAIN}.crt"
        KEY_FILE="${SCRIPT_DIR}/certs/${DERP_DOMAIN}.key"
        
        if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
            print_warning "SSL certificates not found for manual mode"
            print_warning "Expected files:"
            print_warning "  - ${CERT_FILE}"
            print_warning "  - ${KEY_FILE}"
            print_warning "Continuing anyway - container will fail if certificates are required"
        else
            print_success "SSL certificates found"
        fi
    elif [ "$DERP_CERTMODE" = "letsencrypt" ]; then
        print_warning "Let's Encrypt mode enabled - certificates will be obtained automatically"
        print_warning "Make sure port 80 is accessible for certificate challenges"
    fi
}

# Function to pull/build images
build_images() {
    print_status "Building Docker images..."
    
    cd "$SCRIPT_DIR"
    
    # Build the main image
    docker-compose build --no-cache
    
    print_success "Docker images built successfully"
}

# Function to start services
start_services() {
    print_status "Starting services..."
    
    cd "$SCRIPT_DIR"
    
    # Start services
    docker-compose up -d
    
    print_success "Services started"
}

# Function to check service health
check_health() {
    print_status "Checking service health..."
    
    # Wait a bit for services to start
    sleep 10
    
    # Check if containers are running
    if docker-compose ps | grep -q "Up"; then
        print_success "Containers are running"
    else
        print_error "Some containers failed to start"
        docker-compose ps
        return 1
    fi
    
    # Check logs for any immediate errors
    print_status "Checking recent logs..."
    docker-compose logs --tail=20 derp
    
    print_success "Health check completed"
}

# Function to display connection information
display_info() {
    print_success "Deployment completed successfully!"
    echo
    echo "==================================="
    echo "DERP Server Information"
    echo "==================================="
    echo "Domain: $DERP_DOMAIN"
    echo "HTTPS Port: ${DERP_HTTPS_PORT:-443}"
    echo "HTTP Port: ${DERP_HTTP_PORT:-80}"
    echo "STUN Port: ${DERP_STUN_PORT:-3478}"
    echo "Certificate Mode: ${DERP_CERTMODE}"
    echo
    echo "Service URLs:"
    echo "  - DERP: https://${DERP_DOMAIN}:${DERP_HTTPS_PORT:-443}"
    echo "  - Health Check: http://${DERP_DOMAIN}:${DERP_HTTP_PORT:-80}/derp/probe"
    echo
    echo "Useful Commands:"
    echo "  - View logs: docker-compose logs -f derp"
    echo "  - Stop service: docker-compose down"
    echo "  - Restart service: docker-compose restart derp"
    echo "  - Check status: docker-compose ps"
    echo "==================================="
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --build-only     Only build images, don't start services"
    echo "  --no-build       Skip building, only start services"
    echo "  --restart        Restart existing services"
    echo "  --stop           Stop all services"
    echo "  --logs           Show service logs"
    echo "  --status         Show service status"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Full deployment (build and start)"
    echo "  $0 --build-only       # Only build images"
    echo "  $0 --restart          # Restart services"
    echo "  $0 --logs             # Show logs"
}

# Main deployment function
deploy() {
    echo "================================================"
    echo "Tailscale DERP Server Deployment"
    echo "================================================"
    
    check_prerequisites
    setup_environment
    create_directories
    check_certificates
    
    if [ "$BUILD_ONLY" != "true" ] && [ "$NO_BUILD" != "true" ]; then
        build_images
    elif [ "$NO_BUILD" != "true" ]; then
        build_images
    fi
    
    if [ "$BUILD_ONLY" != "true" ]; then
        start_services
        check_health
        display_info
    else
        print_success "Build completed. Use --no-build to start services."
    fi
}

# Parse command line arguments
BUILD_ONLY=false
NO_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        --restart)
            print_status "Restarting services..."
            cd "$SCRIPT_DIR"
            docker-compose restart
            print_success "Services restarted"
            exit 0
            ;;
        --stop)
            print_status "Stopping services..."
            cd "$SCRIPT_DIR"
            docker-compose down
            print_success "Services stopped"
            exit 0
            ;;
        --logs)
            cd "$SCRIPT_DIR"
            docker-compose logs -f
            exit 0
            ;;
        --status)
            cd "$SCRIPT_DIR"
            docker-compose ps
            exit 0
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run deployment
deploy