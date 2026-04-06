# AXI3 to AXI4 Bridge

A Verilog RTL implementation of an AXI3 to AXI4 bridge that converts AXI3 protocol to AXI4 protocol while maintaining compatibility and supporting advanced features.

## Features

- **AXI3 to AXI4 Conversion**: Full conversion from AXI3 slave interface to AXI4 master interface
- **No Locked Transactions**: Does not support AXI3 locked transactions (as per ARM recommendation)
- **No Write Interleaving**: Does not support AXI3 write data interleaving (as per ARM recommendation)
- **Multiple Outstanding Reads**: Supports multiple concurrent read transactions
- **Multiple AW Outstanding**: Supports multiple write address outstanding with serialized write data
- **Fixed QoS**: AxQOS signals fixed to 0
- **Zero-Extended Length**: AxLEN signals zero-extended from AXI3 to AXI4

## Design Overview

### Interface Signals

#### AXI3 Slave Interface (Input)
- `S_AXI3_*`: All standard AXI3 signals including AW, W, B, AR, R channels
- Includes LOCK and QoS signals (handled according to specifications)

#### AXI4 Master Interface (Output)  
- `M_AXI4_*`: All standard AXI4 signals with appropriate signal mapping
- Excludes LOCK signals (not present in AXI4)
- QoS signals fixed to 0

### Key Implementation Details

1. **Read Channel Handling**:
   - Supports multiple outstanding read transactions
   - Maintains read ID tracking for proper response routing
   - Handles burst length conversion (zero extension)

2. **Write Channel Handling**:
   - Supports multiple AW outstanding for pipelined operation
   - Serializes W channel data by burst (prevents interleaving)
   - Proper B response handling

3. **Protocol Compliance**:
   - Removes LOCK signal support (AXI4 does not have LOCK)
   - Fixes QoS to 0 as specified
   - Handles burst length differences between protocols

## Files

- `axi3_to_axi4_bridge.v`: Main bridge implementation
- `axi3_to_axi4_tb.v`: Comprehensive testbench
- `Makefile`: Compilation and simulation targets
- `README.md`: This documentation

## Usage

### Simulation
```bash
# Run basic simulation with VCS
make

# Run simulation with FSDB waveform generation
make simulate_with_wave

# View waveforms (requires DVE)
make view_wave

# Clean generated files
make clean
```

### Integration

To integrate the bridge into your design:

```verilog
axi3_to_axi4_bridge u_axi3_to_axi4 (
    .ACLK(clk),
    .ARESETn(reset_n),
    
    // Connect AXI3 slave interface to your AXI3 master
    .S_AXI3_AWID(axi3_awid),
    .S_AXI3_AWADDR(axi3_awaddr),
    // ... other AXI3 slave signals
    
    // Connect AXI4 master interface to your AXI4 slave
    .M_AXI4_AWID(axi4_awid),
    .M_AXI4_AWADDR(axi4_awaddr), 
    // ... other AXI4 master signals
);
```

## Verification

The testbench includes several test scenarios:
1. Single write transaction
2. Single read transaction  
3. Multiple outstanding read transactions
4. Multiple AW with serialized W data

## AXI Protocol Differences Handled

| Feature | AXI3 | AXI4 | Bridge Handling |
|---------|------|------|----------------|
| LOCK signal | Present | Removed | Ignored (not supported) |
| Write interleaving | Supported | Removed | Serialized by burst |
| Burst length | 4-bit (max 16) | 8-bit (max 256) | Zero extended |
| QoS | Present | Present | Fixed to 0 |
| WID | Present | Removed | Ignored |

## Limitations

- No support for AXI3 exclusive access (LOCK signal removed)
- No support for write data interleaving
- Maximum burst length limited by AXI3 (16 beats)
- Fixed QoS = 0 (configurable in future versions)

## Compliance

This implementation follows ARM's recommendations for AXI4 migration:
- Removal of locked transactions for improved performance
- Elimination of write interleaving for simplified design
- Proper protocol conversion between versions
