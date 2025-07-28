#!/bin/bash

# GitHub Container Registry Deployment Script for Tailscale DERP Server
# This script builds and pushes the Docker image to GitHub Container Registry

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

# Default values
GITHUB_USERNAME=""
GITHUB_TOKEN=""
REPOSITORY_NAME=""
IMAGE_TAG="latest"
REGISTRY="ghcr.io"
PUSH_LATEST=true
BUILD_ARGS=""

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -u, --username USERNAME    GitHub username (can also set GITHUB_USERNAME env var)"
    echo "  -t, --token TOKEN          GitHub personal access token (can also set GITHUB_TOKEN env var)"
    echo "  -r, --repository REPO      Repository name (default: tailscale-derp)"
    echo "  -v, --version VERSION      Image tag/version (default: latest)"
    echo "  --no-latest               Don't push 'latest' tag"
    echo "  --build-arg ARG=VALUE     Pass build argument to docker build"
    echo "  --dry-run                 Show what would be done without executing"
    echo "  --help                    Show this help message"
    echo
    echo "Environment Variables:"
    echo "  GITHUB_USERNAME           GitHub username"
    echo "  GITHUB_TOKEN              GitHub personal access token"
    echo "  GITHUB_REPOSITORY         Repository name"
    echo
    echo "Examples:"
    echo "  $0 -u myuser -t ghp_xxx -r tailscale-derp"
    echo "  $0 -v v1.2.3 --no-latest"
    echo "  export GITHUB_USERNAME=myuser && export GITHUB_TOKEN=ghp_xxx && $0"
    echo
    echo "GitHub Token Requirements:"
    echo "  - write:packages scope for pushing to Container Registry"
    echo "  - read:packages scope for pulling base images (if needed)"
    echo
    echo "Setup GitHub Token:"
    echo "  1. Go to GitHub Settings > Developer settings > Personal access tokens"
    echo "  2. Generate new token with 'write:packages' scope"
    echo "  3. Copy the token and use it with -t option or GITHUB_TOKEN env var"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists git; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to validate configuration
validate_config() {
    print_status "Validating configuration..."
    
    if [ -z "$GITHUB_USERNAME" ]; then
        print_error "GitHub username is required. Use -u option or set GITHUB_USERNAME env var."
        show_usage
        exit 1
    fi
    
    if [ -z "$GITHUB_TOKEN" ]; then
        print_error "GitHub token is required. Use -t option or set GITHUB_TOKEN env var."
        show_usage
        exit 1
    fi
    
    if [ -z "$REPOSITORY_NAME" ]; then
        REPOSITORY_NAME="tailscale-derp"
        print_warning "Using default repository name: $REPOSITORY_NAME"
    fi
    
    print_success "Configuration validated"
}

# Function to authenticate with GitHub Container Registry
authenticate_registry() {
    print_status "Authenticating with GitHub Container Registry..."
    
    # Login to GitHub Container Registry
    echo "$GITHUB_TOKEN" | docker login "$REGISTRY" -u "$GITHUB_USERNAME" --password-stdin
    
    if [ $? -eq 0 ]; then
        print_success "Successfully authenticated with $REGISTRY"
    else
        print_error "Failed to authenticate with $REGISTRY"
        exit 1
    fi
}

# Function to get git information
get_git_info() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        GIT_COMMIT=$(git rev-parse --short HEAD)
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
        
        print_status "Git information:"
        print_status "  Commit: $GIT_COMMIT"
        print_status "  Branch: $GIT_BRANCH"
        if [ -n "$GIT_TAG" ]; then
            print_status "  Tag: $GIT_TAG"
        fi
    else
        print_warning "Not in a git repository - using default values"
        GIT_COMMIT="unknown"
        GIT_BRANCH="unknown"
        GIT_TAG=""
    fi
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image..."
    
    cd "$SCRIPT_DIR"
    
    # Construct full image name
    IMAGE_NAME="${REGISTRY}/${GITHUB_USERNAME}/${REPOSITORY_NAME}"
    FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
    
    # Add build arguments
    BUILD_CMD="docker build"
    
    # Add git information as build args
    BUILD_CMD="$BUILD_CMD --build-arg GIT_COMMIT=$GIT_COMMIT"
    BUILD_CMD="$BUILD_CMD --build-arg GIT_BRANCH=$GIT_BRANCH"
    BUILD_CMD="$BUILD_CMD --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    
    # Add custom build args
    if [ -n "$BUILD_ARGS" ]; then
        BUILD_CMD="$BUILD_CMD $BUILD_ARGS"
    fi
    
    # Add labels
    BUILD_CMD="$BUILD_CMD --label org.opencontainers.image.source=https://github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}"
    BUILD_CMD="$BUILD_CMD --label org.opencontainers.image.revision=$GIT_COMMIT"
    BUILD_CMD="$BUILD_CMD --label org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    
    # Add tags
    BUILD_CMD="$BUILD_CMD -t $FULL_IMAGE_NAME"
    
    if [ "$PUSH_LATEST" = "true" ] && [ "$IMAGE_TAG" != "latest" ]; then
        BUILD_CMD="$BUILD_CMD -t ${IMAGE_NAME}:latest"
    fi
    
    # Add context
    BUILD_CMD="$BUILD_CMD ."
    
    print_status "Build command: $BUILD_CMD"
    
    if [ "$DRY_RUN" = "true" ]; then
        print_warning "DRY RUN: Would execute: $BUILD_CMD"
        return 0
    fi
    
    # Execute build
    eval $BUILD_CMD
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully: $FULL_IMAGE_NAME"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to push Docker image
push_image() {
    if [ "$DRY_RUN" = "true" ]; then
        print_warning "DRY RUN: Would push image $FULL_IMAGE_NAME"
        if [ "$PUSH_LATEST" = "true" ] && [ "$IMAGE_TAG" != "latest" ]; then
            print_warning "DRY RUN: Would also push ${IMAGE_NAME}:latest"
        fi
        return 0
    fi
    
    print_status "Pushing Docker image to GitHub Container Registry..."
    
    # Push the specific tag
    docker push "$FULL_IMAGE_NAME"
    
    if [ $? -eq 0 ]; then
        print_success "Successfully pushed: $FULL_IMAGE_NAME"
    else
        print_error "Failed to push: $FULL_IMAGE_NAME"
        exit 1
    fi
    
    # Push latest tag if requested and different from current tag
    if [ "$PUSH_LATEST" = "true" ] && [ "$IMAGE_TAG" != "latest" ]; then
        LATEST_IMAGE_NAME="${IMAGE_NAME}:latest"
        print_status "Pushing latest tag..."
        
        docker push "$LATEST_IMAGE_NAME"
        
        if [ $? -eq 0 ]; then
            print_success "Successfully pushed: $LATEST_IMAGE_NAME"
        else
            print_error "Failed to push: $LATEST_IMAGE_NAME"
            exit 1
        fi
    fi
}

# Function to display final information
display_info() {
    print_success "Deployment to GitHub Container Registry completed!"
    echo
    echo "=============================================="
    echo "Image Information"
    echo "=============================================="
    echo "Registry: $REGISTRY"
    echo "Repository: ${GITHUB_USERNAME}/${REPOSITORY_NAME}"
    echo "Image: $FULL_IMAGE_NAME"
    if [ "$PUSH_LATEST" = "true" ] && [ "$IMAGE_TAG" != "latest" ]; then
        echo "Latest: ${IMAGE_NAME}:latest"
    fi
    echo
    echo "Pull Commands:"
    echo "  docker pull $FULL_IMAGE_NAME"
    if [ "$PUSH_LATEST" = "true" ] && [ "$IMAGE_TAG" != "latest" ]; then
        echo "  docker pull ${IMAGE_NAME}:latest"
    fi
    echo
    echo "GitHub Package URL:"
    echo "  https://github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}/pkgs/container/${REPOSITORY_NAME}"
    echo "=============================================="
}

# Function to setup environment from file
setup_environment() {
    if [ -f "$ENV_FILE" ]; then
        print_status "Loading environment from .env file..."
        set -a
        source "$ENV_FILE"
        set +a
    fi
    
    # Override with environment variables if set
    GITHUB_USERNAME=${GITHUB_USERNAME:-$GITHUB_USERNAME}
    GITHUB_TOKEN=${GITHUB_TOKEN:-$GITHUB_TOKEN}
    REPOSITORY_NAME=${REPOSITORY_NAME:-$GITHUB_REPOSITORY}
}

# Main deployment function
deploy() {
    echo "================================================"
    echo "GitHub Container Registry Deployment"
    echo "Tailscale DERP Server"
    echo "================================================"
    
    check_prerequisites
    setup_environment
    validate_config
    get_git_info
    
    if [ "$DRY_RUN" != "true" ]; then
        authenticate_registry
    fi
    
    build_image
    push_image
    
    if [ "$DRY_RUN" != "true" ]; then
        display_info
    else
        print_success "DRY RUN completed - no actual changes made"
    fi
}

# Parse command line arguments
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            GITHUB_USERNAME="$2"
            shift 2
            ;;
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -r|--repository)
            REPOSITORY_NAME="$2"
            shift 2
            ;;
        -v|--version)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --no-latest)
            PUSH_LATEST=false
            shift
            ;;
        --build-arg)
            BUILD_ARGS="$BUILD_ARGS --build-arg $2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
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