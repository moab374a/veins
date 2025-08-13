# Veins - The Open Source Vehicular Network Simulation Framework

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Documentation](https://img.shields.io/badge/docs-available-brightgreen.svg)](http://veins.car2x.org/)

## Overview

Veins is a comprehensive open-source framework for simulating vehicular networks. It provides a complete solution for modeling and analyzing vehicle-to-vehicle (V2V) and vehicle-to-infrastructure (V2I) communications in realistic traffic scenarios.

## Key Features

- **TraCI Integration**: Seamless integration with SUMO (Simulation of Urban MObility) for realistic traffic simulation
- **IEEE 802.11p Support**: Full implementation of the WAVE (Wireless Access in Vehicular Environments) standard
- **Modular Architecture**: Extensible framework with support for custom applications and protocols
- **Multi-Platform**: Runs on Linux, macOS, and Windows
- **Comprehensive Documentation**: Extensive documentation and tutorials available

## Project Structure

```
veins/
├── bin/                    # Executable scripts
│   ├── veins_launchd      # SUMO launcher daemon (detailed below)
│   └── veins_format_code  # Code formatting utility
├── src/                    # Source code
│   └── veins/             # Core Veins modules
├── examples/              # Example simulations
├── doc/                   # Documentation
├── subprojects/          # Additional modules
│   ├── veins_inet/       # INET integration
│   ├── veins_inet3/      # INET 3.x integration
│   └── veins_testsims/   # Test simulations
└── images/               # Visual assets
```

## Installation

### Prerequisites

- **OMNeT++**: Version 5.6 or later
- **SUMO**: Version 1.8.0 or later
- **Python 3**: For running scripts
- **C++ Compiler**: GCC, Clang, or MSVC

### Building from Source

1. **Clone the repository**:

   ```bash
   git clone https://github.com/sommer/veins.git
   cd veins
   ```

2. **Configure the build**:

   ```bash
   ./configure
   ```

3. **Build the project**:

   ```bash
   make
   ```

4. **Set up environment**:
   ```bash
   source setenv
   ```

## Quick Start

1. **Start the SUMO launcher daemon**:

   ```bash
   ./bin/veins_launchd -vv
   ```

2. **Run an example simulation**:
   ```bash
   cd examples/veins
   ./run
   ```

## Detailed Documentation: veins_launchd

> **📚 For comprehensive technical documentation, see [VEINS_LAUNCHD_TECHNICAL_DOCUMENTATION.md](VEINS_LAUNCHD_TECHNICAL_DOCUMENTATION.md)**

The `veins_launchd` script is a critical component of the Veins framework that acts as a bridge between OMNeT++ simulations and SUMO traffic simulation. It's a Python-based daemon that manages SUMO instances and handles TraCI (Traffic Control Interface) communications.

### Purpose and Functionality

`veins_launchd` serves as a **SUMO launcher daemon** that:

- **Manages SUMO Instances**: Creates and controls individual SUMO simulation instances
- **Handles TraCI Communication**: Proxies TraCI messages between OMNeT++ and SUMO
- **Resource Management**: Allocates ports and manages temporary directories
- **Configuration Management**: Processes launch configurations and modifies SUMO config files

### Architecture Overview

```
OMNeT++ Simulation ←→ veins_launchd ←→ SUMO Instance
     (TraCI)              (Proxy)         (Traffic Sim)
```

### Key Components

#### 1. Connection Management

- **TCP Socket Server**: Listens for incoming connections on a configurable port
- **Multi-threaded**: Handles multiple simultaneous simulation instances
- **Connection Proxy**: Forwards TraCI messages between client and SUMO

#### 2. Launch Configuration Processing

The daemon expects a launch configuration in XML format:

```xml
<?xml version="1.0"?>
<launch>
  <basedir path="/path/to/simulation/files" />
  <seed value="1234" />
  <copy file="network.net.xml" />
  <copy file="routes.rou.xml" />
  <copy file="sumo.sumo.cfg" type="config" />
</launch>
```

#### 3. File Management

- **Temporary Directory Creation**: Creates isolated workspaces for each simulation
- **File Copying**: Copies simulation files to temporary directories
- **Configuration Modification**: Automatically modifies SUMO config files with:
  - Random seed values
  - TraCI server port assignments
  - Random number generation settings

#### 4. SUMO Process Management

- **Process Spawning**: Launches SUMO with appropriate parameters
- **Port Allocation**: Finds and assigns unused ports for TraCI communication
- **Process Monitoring**: Tracks SUMO process status and handles termination
- **Cleanup**: Manages temporary files and process cleanup

### Command Line Options

```bash
veins_launchd [options]

Options:
  -c, --command COMMAND     SUMO command to execute [default: sumo]
  -s, --shlex              Treat command as shell string
  -p, --port PORT          Listen port [default: 9999]
  -b, --bind ADDRESS       Bind address [default: 127.0.0.1]
  -L, --logfile LOGFILE    Log file path
  -v, --verbose            Increase verbosity
  -q, --quiet              Decrease verbosity
  -d, --daemon             Run as daemon
  -k, --kill               Kill existing daemon
  -P, --pidfile PIDFILE    PID file for daemon mode
  -t, --keep-temp          Keep temporary files
```

### Usage Examples

#### Basic Usage

```bash
# Start daemon with default settings
./bin/veins_launchd

# Start with verbose logging
./bin/veins_launchd -vv

# Start on custom port
./bin/veins_launchd -p 8888
```

#### Daemon Mode

```bash
# Run as background daemon
./bin/veins_launchd -d -P /tmp/veins_launchd.pid

# Kill existing daemon
./bin/veins_launchd -k -P /tmp/veins_launchd.pid
```

#### Custom SUMO Command

```bash
# Use custom SUMO binary
./bin/veins_launchd -c /usr/local/bin/sumo-gui

# Use shell command with parameters
./bin/veins_launchd -s -c "sumo-gui --no-warnings {}"
```

### TraCI Protocol Support

The daemon implements the TraCI protocol for communication:

#### Supported Commands

- **CMD_GET_VERSION (0x00)**: Version information exchange
- **CMD_FILE_SEND (0x75)**: File transfer for launch configuration

#### Message Format

```
[4 bytes: message length][1+ bytes: command length][1 byte: command ID][payload]
```

### Error Handling and Logging

#### Log Levels

- **ERROR**: Critical errors that prevent operation
- **WARN**: Warning messages about potential issues
- **INFO**: General information about operations
- **DEBUG**: Detailed debugging information

#### Common Error Scenarios

1. **Port Already in Use**: Automatically finds alternative ports
2. **SUMO Startup Failures**: Detailed error reporting and cleanup
3. **File Access Issues**: Comprehensive file existence and permission checks
4. **Network Connectivity**: Handles connection timeouts and retries

### Performance Considerations

#### Resource Management

- **Port Allocation**: Efficient unused port detection
- **Memory Usage**: Minimal memory footprint for proxy operations
- **File I/O**: Optimized file copying and configuration processing
- **Process Cleanup**: Automatic cleanup of terminated SUMO processes

#### Scalability

- **Multi-threading**: Supports multiple concurrent simulations
- **Connection Pooling**: Efficient connection handling
- **Resource Isolation**: Each simulation runs in isolated environment

### Security Features

#### Network Security

- **Local Binding**: Default binding to localhost (127.0.0.1)
- **Port Validation**: Ensures ports are within valid ranges
- **Connection Limits**: Configurable connection limits

#### File System Security

- **Path Validation**: Prevents directory traversal attacks
- **Temporary Directory Isolation**: Each simulation in separate directory
- **File Permission Checks**: Validates file access permissions

### Integration with Veins Framework

#### OMNeT++ Integration

The daemon integrates seamlessly with OMNeT++ simulations through:

1. **TraCI Interface**: Standard TraCI protocol implementation
2. **Configuration Management**: Automatic SUMO config modification
3. **Process Coordination**: Synchronized startup and shutdown

#### Simulation Workflow

1. **OMNeT++ starts**: Simulation begins
2. **Connection established**: OMNeT++ connects to veins_launchd
3. **Configuration sent**: Launch configuration transmitted
4. **SUMO started**: Daemon launches SUMO with modified config
5. **Proxy mode**: Daemon proxies all TraCI communication
6. **Simulation runs**: OMNeT++ and SUMO communicate through daemon
7. **Cleanup**: Daemon handles process termination and cleanup

### Troubleshooting

#### Common Issues

1. **"Connection refused" errors**:

   - Ensure veins_launchd is running
   - Check port configuration
   - Verify firewall settings

2. **SUMO startup failures**:

   - Check SUMO installation
   - Verify configuration files
   - Review log files for detailed errors

3. **Port conflicts**:
   - Use different port with `-p` option
   - Kill existing daemon with `-k` option

#### Debug Mode

```bash
# Enable maximum verbosity
./bin/veins_launchd -vvv

# Keep temporary files for inspection
./bin/veins_launchd -t -vv
```

#### Log Analysis

Log files contain detailed information about:

- Connection attempts and failures
- SUMO process status
- File operations
- Error conditions and stack traces

### Advanced Configuration

#### Custom SUMO Parameters

```bash
# Pass additional SUMO parameters
./bin/veins_launchd -s -c "sumo --no-warnings --collision.action warn {}"
```

#### Environment Variables

- `SUMO_HOME`: SUMO installation directory
- `VEINS_LAUNCHD_LOG`: Default log file location
- `VEINS_LAUNCHD_PORT`: Default port number

#### Configuration Files

The daemon can be configured through:

- Command line options (highest priority)
- Environment variables
- Configuration files (if implemented)

## Contributing

We welcome contributions to the Veins framework! Please see our contributing guidelines and code of conduct.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

Veins is released under the GNU General Public License v2.0 or later. See the [COPYING](COPYING) file for details.

## Support and Community

- **Website**: http://veins.car2x.org/
- **Documentation**: http://veins.car2x.org/documentation/
- **Mailing List**: veins-users@listserv.uni-kl.de
- **GitHub Issues**: https://github.com/sommer/veins/issues

## Acknowledgments

Veins is the result of contributions from many researchers and developers worldwide. Special thanks to all contributors and the open-source community.

---

For more detailed information about specific components, please refer to the documentation in the `doc/` directory and the Veins website.
