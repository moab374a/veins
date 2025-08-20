#!/bin/bash

# Veins Podman Manager Script
# Provides easy commands for managing Veins simulations in podman

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display help
show_help() {
    echo "Veins Podman Manager"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build                 Build the Podman image"
    echo "  run [CONFIG]          Run a specific configuration"
    echo "  run-all              Run all default configurations"
    echo "  run-custom           Run custom configurations"
    echo "  run-parallel         Run multiple configurations in parallel"
    echo "  stop                 Stop all running containers"
    echo "  clean                Clean up containers and results"
    echo "  status               Show status of all containers"
    echo "  logs [CONFIG]        Show logs for a configuration"
    echo "  results              Show results summary"
    echo "  create-config [NAME] Create a new configuration file"
    echo "  list-configs         List available configurations"
    echo ""
    echo "Available Configurations:"
    echo "  default              Original omnetpp.ini (connects to external SUMO on port 9999)"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 run default"
    echo "  $0 run-all"
    echo "  $0 logs default"
}

# Function to build Podman image
build_image() {
    log_info "Building Veins Podman image..."
    podman-compose build
    log_success "Podman image built successfully"
}

# Function to run a specific configuration
run_config() {
    local config=${1:-default}

    case $config in
        default)
            log_info "Running veins-$config configuration..."
            log_info "Make sure your external SUMO service is running on port 9999"
            podman-compose up veins-$config
            ;;
        *)
            log_error "Unknown configuration: $config"
            log_info "Available configurations: default"
            log_info "Other configurations are commented out for now"
            exit 1
            ;;
    esac
}

# Function to run all default configurations
run_all() {
    log_info "Running default configuration..."
    log_info "Make sure your external SUMO service is running on port 9999"
    podman-compose up veins-default
}

# Function to run custom configurations
run_custom() {
    log_info "Running custom configurations..."
    podman-compose --profile custom up veins-custom1 veins-custom2
}

# Function to run multiple configurations in parallel
run_parallel() {
    log_info "Starting all configurations in parallel..."
    podman-compose up -d veins-default veins-beaconing veins-channel-switching
    podman-compose --profile custom up -d veins-custom1 veins-custom2
    log_success "All configurations started in background"
    log_info "Use '$0 status' to check progress"
    log_info "Use '$0 logs [config]' to view logs"
    log_info "Use '$0 stop' to stop all simulations"
}

# Function to stop all containers
stop_all() {
    log_info "Stopping all containers..."
    podman-compose down
    log_success "All containers stopped"
}

# Function to clean up
clean_up() {
    log_warning "This will remove all containers and result directories"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Stopping containers..."
        podman-compose down --volumes --remove-orphans

        log_info "Removing result directories..."
        rm -rf results-*

        log_info "Removing Podman images..."
        podman image prune -f

        log_success "Cleanup completed"
    else
        log_info "Cleanup cancelled"
    fi
}

# Function to show container status
show_status() {
    log_info "Container status:"
    podman-compose ps
    echo ""

    log_info "Resource usage:"
    podman stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || true
}

# Function to show logs
show_logs() {
    local config=${1:-}

    if [ -z "$config" ]; then
        log_info "Showing logs for all containers:"
        podman-compose logs --tail=50
    else
        case $config in
            default|beaconing|channel-switching|custom1|custom2)
                log_info "Showing logs for veins-$config:"
                podman-compose logs --tail=50 -f veins-$config
                ;;
            *)
                log_error "Unknown configuration: $config"
                exit 1
                ;;
        esac
    fi
}

# Function to show results summary
show_results() {
    log_info "Results summary:"
    for dir in results-*; do
        if [ -d "$dir" ]; then
            echo "  $dir:"
            find "$dir" -name "*.sca" -o -name "*.vec" 2>/dev/null | head -5 | sed 's/^/    /'
            local count=$(find "$dir" -name "*.sca" -o -name "*.vec" 2>/dev/null | wc -l)
            echo "    Total files: $count"
            echo ""
        fi
    done
}

# Function to create a new configuration
create_config() {
    local name=${1:-}

    if [ -z "$name" ]; then
        log_error "Please provide a configuration name"
        echo "Usage: $0 create-config [NAME]"
        exit 1
    fi

    local config_file="configs/omnetpp-$name.ini"

    if [ -f "$config_file" ]; then
        log_error "Configuration $config_file already exists"
        exit 1
    fi

    log_info "Creating new configuration: $config_file"
    cp "configs/omnetpp-custom1.ini" "$config_file"

    log_success "Configuration created: $config_file"
    log_info "Edit the file to customize your simulation parameters"
    log_info "Then add a new service to podman-compose.yml to use it"
}

# Function to list configurations
list_configs() {
    log_info "Available configuration files:"
    echo "  Default: examples/veins/omnetpp.ini"
    for config in configs/*.ini; do
        if [ -f "$config" ]; then
            echo "  $(basename "$config")"
        fi
    done

    echo ""
    log_info "Available Podman services:"
    podman-compose config --services | sed 's/^/  /'
}

# Function to setup directories
setup_directories() {
    mkdir -p configs
    mkdir -p results-default
    mkdir -p results-beaconing
    mkdir -p results-channel-switching
    mkdir -p results-custom1
    mkdir -p results-custom2
}

# Main script logic
case ${1:-help} in
    build)
        setup_directories
        build_image
        ;;
    run)
        run_config "$2"
        ;;
    run-all)
        run_all
        ;;
    run-custom)
        run_custom
        ;;
    run-parallel)
        run_parallel
        ;;
    stop)
        stop_all
        ;;
    clean)
        clean_up
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    results)
        show_results
        ;;
    create-config)
        create_config "$2"
        ;;
    list-configs)
        list_configs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
