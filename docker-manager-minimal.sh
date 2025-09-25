#!/bin/bash

#============================================================================
# Veins podman Manager - Minimal Version
#
# Purpose: Simple container management for Veins vehicular network simulation
# Focus: External SUMO orchestration with proper file access
#
# Architecture:
# - Veins runs inside container
# - External SUMO orchestrator runs on host
# - Communication via TraCI on port 9999
# - Files shared via mounted directory for orchestrator access
#============================================================================

# Exit on any error for safety
set -e

# Get script directory and ensure we're working from project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

#============================================================================
# COLOR DEFINITIONS
# Used for colored terminal output to improve readability
#============================================================================
RED='\033[0;31m'     # Error messages
GREEN='\033[0;32m'   # Success messages
YELLOW='\033[1;33m'  # Warning messages
BLUE='\033[0;34m'    # Info messages
NC='\033[0m'         # No Color - reset to default

#============================================================================
# LOGGING FUNCTIONS
# Standardized logging with colors for different message types
#============================================================================

# Log informational messages in blue
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Log success messages in green
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Log warning messages in yellow
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Log error messages in red
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

#============================================================================
# HELP FUNCTION
# Display usage information and available commands
#============================================================================
show_help() {
    echo "Veins podman Manager - Minimal Version"
    echo "======================================"
    echo ""
    echo "Purpose: Manage Veins simulation containers for external SUMO orchestration"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Available Commands:"
    echo "  build        Build the Podman image"
    echo "  run          Run simulation container (works with external SUMO on port 9999)"
    echo "  interactive  Start interactive shell inside container"
    echo "  stop         Stop all running containers"
    echo "  help         Show this help message"
    echo ""
    echo "Configuration Details:"
    echo "  - Script reads configuration from: examples/veins/omnetpp.ini"
    echo "  - SUMO files mounted at: ......... (accessible to host orchestrator)"
    echo "  - TraCI communication: localhost:9999"
    echo "  - Launch config: examples/veins/erlangen-external.launchd.xml"
    echo ""
    echo "External SUMO Setup:"
    echo "  1. Run: $0 build"
    echo "  2. Start your SUMO orchestrator on port 9999"
    echo "  3. Run: $0 run"
    echo "  4. Orchestrator will find files in ..........."
    echo ""
    echo "Examples:"
    echo "  $0 build                    # Build container image"
    echo "  $0 run                     # Run simulation with external SUMO"
    echo "  $0 interactive             # Explore container interactively"
    echo "  $0 stop                    # Stop all containers"
}

#============================================================================
# BUILD FUNCTION
# Creates the podman image with OMNeT++ and Veins
#============================================================================
build_image() {
    log_info "Building Veins podman image..."
    log_info "This includes: Ubuntu 22.04 + OMNeT++ + Veins + SUMO tools"

    # Create required directories before building
    setup_directories

    # Build using podman-compose for consistency
    podman-compose build

    log_success "podman image built successfully!"
    log_info "Image is ready for external SUMO orchestration"
}

#============================================================================
# RUN FUNCTION
# Starts the simulation container
# Container expects external SUMO orchestrator on port 9999
#============================================================================
run_simulation() {
    log_info "Starting Veins simulation container..."
    log_info "Configuration file: examples/veins/omnetpp.ini"
    log_info "Launch configuration: examples/veins/erlangen.launchd.xml"
    log_info "Files will be accessible to orchestrator at: ..............."

    log_warning "IMPORTANT: Make sure your external SUMO orchestrator is running on port 9999"
    log_info "The container will connect to localhost:9999 for TraCI communication"

    # Start the container in foreground so we can see output
    podman-compose up veins-simulation
}

#============================================================================
# INTERACTIVE FUNCTION
# Starts a container with interactive shell for debugging/exploration
#============================================================================
run_interactive() {
    log_info "Starting interactive container..."
    log_info "This keeps the container alive for exploration and debugging"

    # Check if interactive container is already running
    if podman ps --format "table {{.Names}}" | grep -q "veins-interactive"; then
        log_info "Interactive container already running, connecting..."
        podman exec -it veins-interactive /bin/bash
    else
        log_info "Starting new interactive container..."

        # Start container in background
        podman-compose up -d veins-interactive

        # Wait for container to fully start
        sleep 3

        log_success "Interactive container started!"
        log_info "Available commands inside container:"
        log_info "  - Run simulation: ./run -u Cmdenv"
        log_info "  - Check OMNeT++ version: opp_run -V"
        log_info "  - View files: ls -la"
        log_info "  - Exit shell: exit or Ctrl+D"
        log_info "Host workspace available at: /app/host-workspace"

        # Connect to container
        podman exec -it veins-interactive /bin/bash
    fi
}

#============================================================================
# STOP FUNCTION
# Stops all running containers and cleans up
#============================================================================
stop_containers() {
    log_info "Stopping all Veins containers..."

    # Stop all containers defined in podman-compose
    podman-compose down

    log_success "All containers stopped"
    log_info "Container data is preserved for next run"
}

#============================================================================
# SETUP FUNCTION
# Creates necessary directories and prepares environment
#============================================================================
setup_directories() {
    log_info "Setting up required directories..."

    # Create directory for simulation results
    mkdir -p results

    # Create shared directory where external SUMO orchestrator can access files
    # This solves the basedir path issue
    mkdir -p /tmp/veins-files
    chmod 755 /tmp/veins-files

    log_info "Created ........ for external SUMO orchestrator access"
    log_info "Created results/ directory for simulation outputs"
}

#============================================================================
# MAIN COMMAND DISPATCHER
# Processes command line arguments and calls appropriate functions
#============================================================================

# If no arguments provided, show help
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Process the command
case "${1}" in
    build)
        log_info "Command: Build podman image"
        build_image
        ;;
    run)
        log_info "Command: Run simulation"
        run_simulation
        ;;
    interactive|shell)
        log_info "Command: Interactive mode"
        run_interactive
        ;;
    stop)
        log_info "Command: Stop containers"
        stop_containers
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        log_info "Available commands: build, run, interactive, stop, help"
        echo ""
        show_help
        exit 1
        ;;
esac

#============================================================================
# END OF SCRIPT
#============================================================================
