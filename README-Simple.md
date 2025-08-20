# Veins Docker - Simple Setup

This is a simplified Docker setup for running a single Veins simulation container that connects to your external SUMO service.

## Quick Start

### 1. Build the Docker Image

```bash
./docker-manager.sh build
```

Or manually:
```bash
docker-compose build
```

### 2. Start Your External SUMO Service

Make sure your external SUMO service is running and listening on port 9999.

### 3. Run the Veins Simulation

```bash
./docker-manager.sh run default
```

Or manually:
```bash
docker-compose up veins-default
```

## What This Does

1. **Builds a container** with:
   - OMNeT++ 6.0.3
   - SUMO (for libraries, not daemon)
   - Veins framework
   - All necessary dependencies

2. **Runs the simulation** by:
   - Starting the container with `network_mode: "host"` to access your external service
   - Executing `./run -u Cmdenv` in `/app/examples/veins/`
   - Using the original `omnetpp.ini` configuration
   - Connecting to your external SUMO service on port 9999

3. **Saves results** to:
   - `./examples/veins/results/` (mounted volume)

## Container Details

- **Container name**: `veins-simulation-default`
- **Working directory**: `/app/examples/veins/`
- **Network mode**: `host` (to connect to your external service on port 9999)
- **Command executed**: `./run -u Cmdenv`

## Configuration

The simulation uses the original `omnetpp.ini` file which contains:

```ini
*.manager.host = "localhost"
*.manager.port = 9999
```

This will connect to your external SUMO service running on port 9999.

## Usage Examples

```bash
# Build the image
./docker-manager.sh build

# Run the simulation
./docker-manager.sh run default

# Check container status
./docker-manager.sh status

# View logs
./docker-manager.sh logs default

# Stop the container
./docker-manager.sh stop
```

## Manual Docker Commands

If you prefer direct Docker commands:

```bash
# Build
docker-compose build

# Run
docker-compose up veins-default

# Run in background
docker-compose up -d veins-default

# View logs
docker-compose logs -f veins-default

# Stop
docker-compose down
```

## Troubleshooting

1. **Connection refused**: Make sure your external SUMO service is running on port 9999
2. **Container exits immediately**: Check logs with `./docker-manager.sh logs default`
3. **Build errors**: Ensure you have Docker and docker-compose installed

## Next Steps

Once this basic setup works, you can:

1. Uncomment other services in `docker-compose.yml`
2. Add custom configuration files
3. Run multiple containers in parallel
4. Use the full feature set from the original setup

## File Structure

```
veins/
├── Dockerfile                 # Container definition
├── docker-compose.yml        # Single service configuration
├── docker-manager.sh         # Management script
├── examples/veins/
│   ├── omnetpp.ini           # Simulation configuration
│   ├── run                   # Simulation runner script
│   └── results/              # Results directory (mounted)
└── README-Simple.md          # This file
```
