# AXI3 to AXI4 Bridge

A Verilog RTL implementation of an AXI3 to AXI4 bridge that converts AXI3 protocol to AXI4 protocol while maintaining compatibility and supporting advanced features.

## Features

- **AXI3 to AXI4 Conversion**: Full conversion from AXI3 slave interface to AXI4 master interface
- **AXI3 2-bit LOCK Policy**: Explicitly supports `00` (normal) and `01` (exclusive), rejects `10/11` with local `SLVERR`
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
- Exposes AXI4 `M_AXI4_AWLOCK/M_AXI4_ARLOCK` and performs explicit lock encoding conversion
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
   - AXI3 `AxLOCK=01` is mapped to AXI4 `AxLOCK=1` (exclusive)
   - AXI3 `AxLOCK=00` is mapped to AXI4 `AxLOCK=0` (normal)
   - AXI3 `AxLOCK=10/11` is completed locally with `SLVERR` (not forwarded)
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
| LOCK signal | 2-bit | 1-bit | `00->0`, `01->1`, `10/11->SLVERR` |
| Write interleaving | Supported | Removed | Serialized by burst |
| Burst length | 4-bit (max 16) | 8-bit (max 256) | Zero extended |
| QoS | Present | Present | Fixed to 0 |
| WID | Present | Removed | Ignored |

## Limitations

- AXI3 `AxLOCK=10/11` is unsupported and completed with local `SLVERR`
- Exclusive support requires downstream AXI4 fabric/target to implement exclusive monitor semantics
- No support for write data interleaving
- Maximum burst length limited by AXI3 (16 beats)
- Fixed QoS = 0 (configurable in future versions)

## Lock Handling

This bridge interprets AXI3 `AWLOCK/ARLOCK` as 2-bit fields and uses the policy below:

- `2'b00`: supported normal access
- `2'b01`: supported exclusive access (with restrictions)
- `2'b10`: unsupported, local `SLVERR`
- `2'b11`: illegal/reserved, local `SLVERR`

### Exclusive Write Handling (`AWLOCK=2'b01`)

- AXI4 `M_AXI4_AWLOCK` is driven to `1`
- Supported only when all conditions are met:
  - single-beat (`AWLEN==0`)
  - address aligned to transfer size
  - no 4KB boundary crossing
  - no other exclusive transaction already in-flight
- If any condition fails, transaction is not forwarded; W beats are drained locally and B returns `SLVERR`

### Exclusive Read Handling (`ARLOCK=2'b01`)

- AXI4 `M_AXI4_ARLOCK` is driven to `1`
- Same restrictions as exclusive write (single-beat/aligned/no-crossing/single outstanding exclusive)
- If condition fails, transaction is not forwarded; bridge returns single-beat `RRESP=SLVERR`, `RLAST=1`, `RDATA=0`

### Backpressure and Resource Limits

- AXI3 AW acceptance is backpressured when the internal write tracking FIFO is full
- AXI3 AW acceptance is also backpressured if the AXI4 write-address forwarding FIFO is full
- AXI3 AR acceptance is backpressured when the configured read outstanding limit is reached
- AXI3 AR acceptance is also backpressured if the AXI4 read-address forwarding FIFO is full
- AXI3 AR acceptance is backpressured if local read-error completion FIFO is full

### Response Arbitration Priority

- AXI3-facing B/R muxes local error responses and forwarded AXI4 responses
- Local lock-policy error responses have priority over forwarded responses when both are pending

### Reset Behavior

- On reset, all internal outstanding counters, FIFOs, and in-flight AXI4 address valid signals are cleared
- Any partially tracked transaction state inside the bridge is discarded when `ARESETn` is asserted low
- After reset release, the bridge restarts from an empty state and only tracks newly accepted AXI3 transactions

### Other Unsupported Behavior

- AXI3 write interleaving is not supported
- Write bursts are serialized in AW order before being forwarded to AXI4
- `WID` is ignored by the bridge and does not select among interleaved write streams

### Error Containment Policy

- Unsupported/illegal lock requests are explicitly reported with `SLVERR`
- No silent downgrade from exclusive/locked to normal transaction
- AXI4 `AWQOS` and `ARQOS` are always driven to `0`

## Compliance

This implementation follows an explicit lock policy for AXI3-to-AXI4 migration:
- AXI3 lock requests are mapped or rejected explicitly (`00/01` supported, `10/11` rejected)
- Elimination of write interleaving for simplified design
- Proper protocol conversion between versions
