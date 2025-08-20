# Veins Docker Containerization

This setup allows you to run multiple Veins simulations in Docker containers, each with different `omnetpp.ini` configurations.

## Quick Start

### 1. Build the Docker Image

```bash
docker-compose build
```

### 2. Run Default Simulations

Run the predefined simulation configurations:

```bash
# Run all default simulations
docker-compose up

# Run specific simulations
docker-compose up veins-default
docker-compose up veins-beaconing
docker-compose up veins-channel-switching
```

### 3. Run Custom Simulations

```bash
# Enable custom profiles and run custom simulations
docker-compose --profile custom up veins-custom1
docker-compose --profile custom up veins-custom2
```

## Available Configurations

### Default Configurations

1. **veins-default**: Uses the original `omnetpp.ini` configuration
   - Port: 9999
   - Results: `./results-default/`

2. **veins-beaconing**: Enables beaconing for both RSU and vehicles
   - Port: 10000
   - Results: `./results-beaconing/`
   - Config: `configs/omnetpp-beaconing.ini`

3. **veins-channel-switching**: Enables channel switching
   - Port: 10001
   - Results: `./results-channel-switching/`
   - Config: `configs/omnetpp-channel-switching.ini`

### Custom Configurations

4. **veins-custom1**: Extended simulation with larger playground
   - Port: 10002
   - Results: `./results-custom1/`
   - Config: `configs/omnetpp-custom1.ini`
   - Features:
     - 400s simulation time
     - 5000m x 5000m playground
     - Higher TX power (50mW)
     - Extended communication range (5000m)
     - More frequent beaconing (0.5s)

5. **veins-custom2**: Compact testing scenario
   - Port: 10003
   - Results: `./results-custom2/`
   - Config: `configs/omnetpp-custom2.ini`
   - Features:
     - 100s simulation time
     - 1000m x 1000m playground
     - Lower TX power (10mW) for interference testing
     - Very frequent updates (0.1s)
     - Higher bitrate (12Mbps)

## Directory Structure

```
veins/
├── Dockerfile                 # Container definition
├── docker-compose.yml        # Multi-container orchestration
├── configs/                   # Configuration files
│   ├── omnetpp-beaconing.ini
│   ├── omnetpp-channel-switching.ini
│   ├── omnetpp-custom1.ini
│   └── omnetpp-custom2.ini
├── results-*/                 # Results directories (auto-created)
└── examples/veins/            # Original simulation files
```

## Creating Custom Configurations

### Method 1: Create New Config File

1. Create a new `.ini` file in the `configs/` directory:
```bash
cp configs/omnetpp-custom1.ini configs/omnetpp-my-config.ini
# Edit the file as needed
```

2. Add a new service to `docker-compose.yml`:
```yaml
veins-my-config:
  build: .
  container_name: veins-simulation-my-config
  volumes:
    - ./configs:/app/configs:ro
    - ./results-my-config:/app/results
  environment:
    - CONFIG_FILE=omnetpp-my-config.ini
    - START_SUMO_DAEMON=true
  command: ["-u", "Cmdenv"]
  networks:
    - veins-network
  ports:
    - "10004:9999"
```

### Method 2: Runtime Configuration Override

You can override any configuration at runtime:

```bash
# Run with custom simulation time
docker run --rm -v $(pwd)/configs:/app/configs:ro \
  -e CONFIG_FILE=omnetpp-custom1.ini \
  veins-veins-default ./run -u Cmdenv --sim-time-limit=600s

# Run with different configuration section
docker run --rm -v $(pwd)/configs:/app/configs:ro \
  -e CONFIG_FILE=omnetpp-beaconing.ini \
  veins-veins-default ./run -u Cmdenv -c WithChannelSwitching
```

## Advanced Usage

### Running Individual Containers

```bash
# Build the image
docker build -t veins-sim .

# Run with default config
docker run --rm -p 9999:9999 veins-sim

# Run with custom config
docker run --rm -p 9999:9999 \
  -v $(pwd)/configs:/app/configs:ro \
  -v $(pwd)/my-results:/app/results \
  -e CONFIG_FILE=omnetpp-custom1.ini \
  veins-sim

# Run with additional arguments
docker run --rm -p 9999:9999 veins-sim -u Cmdenv -c WithBeaconing --sim-time-limit=300s
```

### Parallel Execution

Run multiple simulations in parallel:

```bash
# Start all simulations in background
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs veins-beaconing

# Stop all
docker-compose down
```

### Results Management

Results are automatically saved to separate directories:

```bash
# View results
ls -la results-*/

# Copy results out of container
docker cp veins-simulation-beaconing:/app/examples/veins/results ./results-beaconing-backup/

# Clean up results
rm -rf results-*
```

## Configuration Parameters

### Key Parameters You Can Modify

| Parameter | Description | Example Values |
|-----------|-------------|----------------|
| `sim-time-limit` | Simulation duration | `100s`, `200s`, `400s` |
| `*.playgroundSizeX/Y` | Simulation area size | `1000m`, `2500m`, `5000m` |
| `*.manager.updateInterval` | SUMO update frequency | `0.1s`, `0.5s`, `1s` |
| `*.**.nic.mac1609_4.txPower` | Transmission power | `10mW`, `20mW`, `50mW` |
| `*.connectionManager.maxInterfDist` | Communication range | `1500m`, `2600m`, `5000m` |
| `*.appl.beaconInterval` | Beaconing frequency | `0.1s`, `0.5s`, `1s` |
| `*.**.nic.mac1609_4.useServiceChannel` | Channel switching | `true`, `false` |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CONFIG_FILE` | Custom config file name | (uses default omnetpp.ini) |
| `START_SUMO_DAEMON` | Start SUMO daemon | `true` |

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure each container uses a unique port
2. **SUMO connection**: Check that SUMO daemon is running and accessible
3. **Configuration errors**: Validate your `.ini` files before running
4. **Resource limits**: Monitor CPU/memory usage for parallel simulations

### Debugging

```bash
# Run container interactively
docker run -it --entrypoint /bin/bash veins-sim

# Check logs
docker-compose logs -f veins-beaconing

# Inspect running container
docker exec -it veins-simulation-beaconing /bin/bash
```

### Performance Tips

1. **Resource allocation**: Limit CPU/memory per container if running many parallel simulations
2. **Results cleanup**: Regularly clean up old results to save disk space
3. **Configuration optimization**: Use appropriate update intervals and simulation times
4. **Network isolation**: Use separate networks for different simulation groups

## Examples

### Run a Quick Test

```bash
# Build and run a 60-second test simulation
docker build -t veins-sim .
docker run --rm veins-sim -u Cmdenv --sim-time-limit=60s
```

### Parameter Sweep

```bash
# Run simulations with different transmission powers
for power in 10mW 20mW 50mW; do
  echo "Running simulation with TX power: $power"
  docker run --rm \
    -v $(pwd)/results-$power:/app/results \
    veins-sim -u Cmdenv \
    --**.nic.mac1609_4.txPower=$power
done
```

### Batch Processing

```bash
# Run all configurations and collect results
docker-compose up -d
sleep 300  # Wait for simulations to complete
docker-compose down
tar -czf simulation-results-$(date +%Y%m%d).tar.gz results-*
```
