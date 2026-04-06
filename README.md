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

## Exception Handling

This bridge does not forward unsupported AXI3 locked transactions to AXI4. Instead, it terminates them locally and returns an error response on the AXI3 side.

### Locked Write Handling

- `S_AXI3_AWLOCK=1` write commands are accepted on the AXI3 AW channel
- The locked write address is not forwarded to the AXI4 AW channel
- AXI3 write data is still consumed on the W channel so the AXI3 master can complete the burst cleanly
- After the final write beat, the bridge generates a local AXI3 write response:
  - `BID` matches the original AXI3 write ID
  - `BRESP = SLVERR (2'b10)`
- No AXI4 write response is involved for the locked transaction

### Locked Read Handling

- `S_AXI3_ARLOCK=1` read commands are accepted on the AXI3 AR channel
- The locked read address is not forwarded to the AXI4 AR channel
- The bridge generates a local AXI3 read response immediately as a single-beat error completion:
  - `RID` matches the original AXI3 read ID
  - `RRESP = SLVERR (2'b10)`
  - `RLAST = 1'b1`
- `RDATA = 0`
- No AXI4 read request or AXI4 read data is involved for the locked transaction
- Even if the incoming AXI3 locked read carries a burst length greater than zero, the bridge terminates it locally as a single-beat error response

### Backpressure and Resource Limits

- AXI3 AW acceptance is backpressured when the internal write tracking FIFO is full
- Non-locked AXI3 AW acceptance is also backpressured if the AXI4 write-address forwarding FIFO is full
- Locked AXI3 AW acceptance is backpressured if the local write-error response FIFO is full
- AXI3 AR acceptance is backpressured when the configured non-locked read outstanding limit is reached
- Non-locked AXI3 AR acceptance is also backpressured if the AXI4 read-address forwarding FIFO is full
- Locked AXI3 AR acceptance is backpressured if the local read-error response FIFO is full

### Response Arbitration Priority

- Local error responses for unsupported locked transactions take priority over incoming AXI4 responses on the AXI3-facing side
- While a local write error response is pending, AXI4 `BREADY` is deasserted and AXI4 write responses are temporarily held off
- While a local read error response is pending, AXI4 `RREADY` is deasserted and AXI4 read data is temporarily held off
- This guarantees that locally generated `SLVERR` completions are returned in a controlled way before normal forwarded AXI4 responses resume

### Reset Behavior

- On reset, all internal outstanding counters, FIFOs, local error queues, and in-flight AXI4 address valid signals are cleared
- Any partially tracked transaction state inside the bridge is discarded when `ARESETn` is asserted low
- After reset release, the bridge restarts from an empty state and only tracks newly accepted AXI3 transactions

### Other Unsupported Behavior

- AXI3 write interleaving is not supported
- Write bursts are serialized in AW order before being forwarded to AXI4
- `WID` is ignored by the bridge and does not select among interleaved write streams

### Error Containment Policy

- Unsupported locked accesses are handled locally on the AXI3-facing side
- Normal non-locked AXI3 read and write transactions continue to be translated and forwarded to AXI4
- AXI4 `AWQOS` and `ARQOS` are always driven to `0`

## Compliance

This implementation follows ARM's recommendations for AXI4 migration:
- Removal of locked transactions for improved performance
- Elimination of write interleaving for simplified design
- Proper protocol conversion between versions
