# AXI3 to AXI4 Bridge

A Verilog RTL implementation of an AXI3 to AXI4 bridge that converts AXI3 protocol to AXI4 protocol while maintaining compatibility and supporting advanced features.

## Features

- **AXI3 to AXI4 Conversion**: Full conversion from AXI3 slave interface to AXI4 master interface
- **LOCK Downgrade for AXI3->AXI4**: Accepts AXI3 `AWLOCK/ARLOCK`, but downgrades to normal AXI4 transfers
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
- No dedicated `AxLOCK` output in this subset bridge; incoming AXI3 lock requests are downgraded to normal transfers
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
   - Downgrades AXI3 locked requests to normal AXI4 requests (lock semantics are not preserved)
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
| LOCK signal | Present | Different encoding/semantics | Accepted then downgraded to normal transfer |
| Write interleaving | Supported | Removed | Serialized by burst |
| Burst length | 4-bit (max 16) | 8-bit (max 256) | Zero extended |
| QoS | Present | Present | Fixed to 0 |
| WID | Present | Removed | Ignored |

## Limitations

- AXI3 lock semantics are not preserved end-to-end (downgraded to normal accesses)
- No support for write data interleaving
- Maximum burst length limited by AXI3 (16 beats)
- Fixed QoS = 0 (configurable in future versions)

## Lock Handling

This bridge accepts AXI3 requests with `AWLOCK/ARLOCK=1`, but converts them into normal AXI4 read/write transactions.

### Locked Write Handling

- `S_AXI3_AWLOCK=1` write commands are accepted on AXI3 AW
- The write address is forwarded to AXI4 AW as a normal write transaction
- AXI3 W data is forwarded to AXI4 W in normal burst order
- Write response comes from AXI4 B channel and is returned to AXI3 directly
- No local `SLVERR` is generated only because `AWLOCK=1`

### Locked Read Handling

- `S_AXI3_ARLOCK=1` read commands are accepted on AXI3 AR
- The read address is forwarded to AXI4 AR as a normal read transaction
- Read data/response comes from AXI4 R channel and is returned to AXI3 directly
- No local single-beat error completion is generated only because `ARLOCK=1`

### Backpressure and Resource Limits

- AXI3 AW acceptance is backpressured when the internal write tracking FIFO is full
- AXI3 AW acceptance is also backpressured if the AXI4 write-address forwarding FIFO is full
- AXI3 AR acceptance is backpressured when the configured read outstanding limit is reached
- AXI3 AR acceptance is also backpressured if the AXI4 read-address forwarding FIFO is full

### Response Arbitration Priority

- AXI3-facing B/R responses follow AXI4 return ordering for forwarded transactions
- The bridge does not insert lock-specific local error responses

### Reset Behavior

- On reset, all internal outstanding counters, FIFOs, and in-flight AXI4 address valid signals are cleared
- Any partially tracked transaction state inside the bridge is discarded when `ARESETn` is asserted low
- After reset release, the bridge restarts from an empty state and only tracks newly accepted AXI3 transactions

### Other Unsupported Behavior

- AXI3 write interleaving is not supported
- Write bursts are serialized in AW order before being forwarded to AXI4
- `WID` is ignored by the bridge and does not select among interleaved write streams

### Error Containment Policy

- AXI3 locked and non-locked accesses are translated and forwarded to AXI4 in the same datapath
- Lock-related exclusivity/atomicity semantics are intentionally not preserved by this bridge
- AXI4 `AWQOS` and `ARQOS` are always driven to `0`

## Compliance

This implementation follows ARM's recommendations for AXI4 migration:
- AXI3 lock requests are accepted but downgraded to normal AXI4 transactions
- Elimination of write interleaving for simplified design
- Proper protocol conversion between versions
