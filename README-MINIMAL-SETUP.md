# Veins Minimal Podman Setup

## Overview

This is a clean, minimal Podman setup for running Veins vehicular network simulations with **external SUMO orchestration**.

### Key Features
- **Simplified Management**: Only essential commands (build, run, interactive, stop)
- **External SUMO Focus**: Designed specifically for external SUMO orchestrator workflows
- **Fixed Basedir Issue**: SUMO files accessible to host orchestrator at `/tmp/veins-files/`
- **Well Documented**: Extensive comments explaining every component

## Architecture

```
Host System:
├── SUMO Orchestrator (port 9999) ←→ TraCI ←→ Veins Container
└── /tmp/veins-files/ ←→ Volume Mount ←→ Container:/tmp/veins-files/
```

### File Locations

| Purpose | Container Path | Host Path | Description |
|---------|---------------|-----------|-------------|
| **SUMO Files** | `/tmp/veins-files/` | `/tmp/veins-files/` | Where orchestrator finds simulation files |
| **Configuration** | `/app/examples/veins/omnetpp.ini` | `examples/veins/omnetpp.ini` | Main simulation config |
| **Launch Config** | `/app/examples/veins/erlangen-external.launchd.xml` | `examples/veins/erlangen-external.launchd.xml` | Basedir configuration |
| **Results** | `/app/examples/veins/results/` | `results/` | Simulation outputs |

## Quick Start

### 1. Build the Container
```bash
./docker-manager-minimal.sh build
```

### 2. Start External SUMO Orchestrator
Your SUMO orchestrator should:
- Listen on **port 9999**
- Look for files in `/tmp/veins-files/`

### 3. Run Simulation
```bash
./docker-manager-minimal.sh run
```

## Commands

| Command | Purpose | Usage |
|---------|---------|-------|
| `build` | Build Podman image with OMNeT++ + Veins | `./docker-manager-minimal.sh build` |
| `run` | Run simulation (connects to external SUMO) | `./docker-manager-minimal.sh run` |
| `interactive` | Start debugging shell inside container | `./docker-manager-minimal.sh interactive` |
| `stop` | Stop all containers | `./docker-manager-minimal.sh stop` |
| `help` | Show detailed help | `./docker-manager-minimal.sh help` |

## Configuration Files

### Main Configuration: `examples/veins/omnetpp.ini`
- **What it does**: Defines simulation parameters, network setup, TraCI connection
- **Key settings**:
  - `*.manager.host = "localhost"` - Connect to host SUMO orchestrator
  - `*.manager.port = 9999` - TraCI communication port
  - `*.manager.launchConfig = xmldoc("erlangen-external.launchd.xml")` - Launch configuration

### Launch Configuration: `examples/veins/erlangen-external.launchd.xml`
- **What it does**: Tells Veins where SUMO files are located
- **Key setting**: `<basedir path="/tmp/veins-files" />` - **This solves the basedir issue!**
- **Files copied**: `erlangen.net.xml`, `erlangen.rou.xml`, `erlangen.poly.xml`, `erlangen.sumo.cfg`

## How the Basedir Issue is Solved

### The Problem
- Veins runs inside container at `/app/examples/veins/`
- External SUMO orchestrator runs on host
- Orchestrator can't access container paths

### The Solution
1. **Volume Mount**: `examples/veins/` → `/tmp/veins-files/` (host-accessible)
2. **Launch Config**: `<basedir path="/tmp/veins-files" />`
3. **Result**: Orchestrator finds files at `/tmp/veins-files/` on host

## Podman Compose Structure

### Services
- **`veins-simulation`**: Main service for running simulations
- **`veins-interactive`**: Development service for debugging

### Key Configuration
- **Network**: `host` mode for TraCI communication
- **Volumes**: Examples mounted to `/tmp/veins-files/` for orchestrator access
- **Command**: `-u Cmdenv` for command-line simulation mode

## Development Workflow

### Interactive Mode
```bash
./docker-manager-minimal.sh interactive
# Inside container:
./run -u Cmdenv                    # Run simulation manually
opp_run -V                        # Check OMNeT++ version
ls /tmp/veins-files/              # Verify shared files
exit                              # Exit container
```

### Log Monitoring
```bash
podman logs veins-simulation     # View simulation logs
podman logs -f veins-simulation  # Follow logs in real-time
```

## File Structure

```
veins/
├── docker-manager-minimal.sh              # Main management script
├── podman-compose.yml                     # Container definitions
├── Dockerfile                             # Image build instructions
├── examples/veins/
│   ├── omnetpp.ini                        # Main simulation config
│   ├── erlangen-external.launchd.xml     # Launch config (new)
│   ├── erlangen.net.xml                   # Network file
│   ├── erlangen.rou.xml                   # Routes file
│   ├── erlangen.poly.xml                  # Polygons file
│   └── erlangen.sumo.cfg                  # SUMO config
└── results/                               # Simulation outputs
```

## Troubleshooting

### Container Won't Connect to SUMO
- Verify SUMO orchestrator is running on port 9999
- Check `podman logs veins-simulation` for connection errors
- Ensure host networking is enabled

### Files Not Found by Orchestrator
- Verify `/tmp/veins-files/` exists and has files
- Check volume mount in `podman-compose.yml`
- Verify launch config uses correct basedir path

### Build Issues
- Run `podman system prune` to clean up old builds
- Check Dockerfile for dependency issues
- Ensure sufficient disk space

## Migration from Old Setup

If you're coming from the complex setup:
1. Use `docker-manager-minimal.sh` instead of `docker-manager.sh`
2. Use `podman-compose.yml` for simpler container definitions
3. Configuration automatically uses `/tmp/veins-files/` for orchestrator access
4. No manual setup required - everything is automated

## Support

For issues:
1. Check container logs: `podman logs veins-simulation`
2. Verify orchestrator connection on port 9999
3. Ensure `/tmp/veins-files/` contains SUMO files
4. Use interactive mode for debugging: `./docker-manager-minimal.sh interactive`
