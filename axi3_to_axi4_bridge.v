`timescale 1ns/1ps

// AXI3 -> AXI4 Bridge (pragmatic subset)
// 1) AXI3 locked transaction is downgraded to normal AXI4 transaction
// 2) AXI3 write interleaving not supported: W channel serialized by AW order
// 3) Multiple read outstanding supported (for non-locked AR)
// 4) Multiple AW outstanding supported; W bursts forwarded serially
// 5) AxQOS fixed to 0
// 6) AxLEN only zero-extension

module axi3_to_axi4_bridge #(
    parameter integer ID_WIDTH               = 32,
    parameter integer ADDR_WIDTH             = 32,
    parameter integer DATA_WIDTH             = 64,
    parameter integer MAX_OUTSTANDING_READS  = 8,
    parameter integer MAX_OUTSTANDING_WRITES = 8
) (
    input  wire                   ACLK,
    input  wire                   ARESETn,

    // AXI3 slave side
    input  wire [ID_WIDTH-1:0]    S_AXI3_AWID,
    input  wire [ADDR_WIDTH-1:0]  S_AXI3_AWADDR,
    input  wire [7:0]             S_AXI3_AWLEN,
    input  wire [2:0]             S_AXI3_AWSIZE,
    input  wire [1:0]             S_AXI3_AWBURST,
    input  wire                   S_AXI3_AWLOCK,
    input  wire [3:0]             S_AXI3_AWCACHE,
    input  wire [2:0]             S_AXI3_AWPROT,
    input  wire [3:0]             S_AXI3_AWQOS,
    input  wire                   S_AXI3_AWVALID,
    output wire                   S_AXI3_AWREADY,

    input  wire [ID_WIDTH-1:0]    S_AXI3_WID,
    input  wire [DATA_WIDTH-1:0]  S_AXI3_WDATA,
    input  wire [DATA_WIDTH/8-1:0]S_AXI3_WSTRB,
    input  wire                   S_AXI3_WLAST,
    input  wire                   S_AXI3_WVALID,
    output wire                   S_AXI3_WREADY,

    output wire [ID_WIDTH-1:0]    S_AXI3_BID,
    output wire [1:0]             S_AXI3_BRESP,
    output wire                   S_AXI3_BVALID,
    input  wire                   S_AXI3_BREADY,

    input  wire [ID_WIDTH-1:0]    S_AXI3_ARID,
    input  wire [ADDR_WIDTH-1:0]  S_AXI3_ARADDR,
    input  wire [7:0]             S_AXI3_ARLEN,
    input  wire [2:0]             S_AXI3_ARSIZE,
    input  wire [1:0]             S_AXI3_ARBURST,
    input  wire                   S_AXI3_ARLOCK,
    input  wire [3:0]             S_AXI3_ARCACHE,
    input  wire [2:0]             S_AXI3_ARPROT,
    input  wire [3:0]             S_AXI3_ARQOS,
    input  wire                   S_AXI3_ARVALID,
    output wire                   S_AXI3_ARREADY,

    output wire [ID_WIDTH-1:0]    S_AXI3_RID,
    output wire [DATA_WIDTH-1:0]  S_AXI3_RDATA,
    output wire [1:0]             S_AXI3_RRESP,
    output wire                   S_AXI3_RLAST,
    output wire                   S_AXI3_RVALID,
    input  wire                   S_AXI3_RREADY,

    // AXI4 master side
    output reg  [ID_WIDTH-1:0]    M_AXI4_AWID,
    output reg  [ADDR_WIDTH-1:0]  M_AXI4_AWADDR,
    output reg  [7:0]             M_AXI4_AWLEN,
    output reg  [2:0]             M_AXI4_AWSIZE,
    output reg  [1:0]             M_AXI4_AWBURST,
    output reg  [3:0]             M_AXI4_AWCACHE,
    output reg  [2:0]             M_AXI4_AWPROT,
    output wire [3:0]             M_AXI4_AWQOS,
    output reg                    M_AXI4_AWVALID,
    input  wire                   M_AXI4_AWREADY,

    output wire [DATA_WIDTH-1:0]  M_AXI4_WDATA,
    output wire [DATA_WIDTH/8-1:0]M_AXI4_WSTRB,
    output wire                   M_AXI4_WLAST,
    output wire                   M_AXI4_WVALID,
    input  wire                   M_AXI4_WREADY,

    input  wire [ID_WIDTH-1:0]    M_AXI4_BID,
    input  wire [1:0]             M_AXI4_BRESP,
    input  wire                   M_AXI4_BVALID,
    output wire                   M_AXI4_BREADY,

    output reg  [ID_WIDTH-1:0]    M_AXI4_ARID,
    output reg  [ADDR_WIDTH-1:0]  M_AXI4_ARADDR,
    output reg  [7:0]             M_AXI4_ARLEN,
    output reg  [2:0]             M_AXI4_ARSIZE,
    output reg  [1:0]             M_AXI4_ARBURST,
    output reg  [3:0]             M_AXI4_ARCACHE,
    output reg  [2:0]             M_AXI4_ARPROT,
    output wire [3:0]             M_AXI4_ARQOS,
    output reg                    M_AXI4_ARVALID,
    input  wire                   M_AXI4_ARREADY,

    input  wire [ID_WIDTH-1:0]    M_AXI4_RID,
    input  wire [DATA_WIDTH-1:0]  M_AXI4_RDATA,
    input  wire [1:0]             M_AXI4_RRESP,
    input  wire                   M_AXI4_RLAST,
    input  wire                   M_AXI4_RVALID,
    output wire                   M_AXI4_RREADY
);

localparam integer WR_PTR_W  = (MAX_OUTSTANDING_WRITES <= 2) ? 1 : $clog2(MAX_OUTSTANDING_WRITES);
localparam integer RD_PTR_W  = (MAX_OUTSTANDING_READS  <= 2) ? 1 : $clog2(MAX_OUTSTANDING_READS);
localparam [WR_PTR_W:0] MAX_WR_CNT = MAX_OUTSTANDING_WRITES;
localparam [RD_PTR_W:0] MAX_RD_CNT = MAX_OUTSTANDING_READS;

assign M_AXI4_AWQOS = 4'b0000;
assign M_AXI4_ARQOS = 4'b0000;

// ============================================================
// Write-side structures
// ============================================================
reg [ID_WIDTH-1:0]    wr_id_fifo     [0:MAX_OUTSTANDING_WRITES-1];
reg [7:0]             wr_len_fifo    [0:MAX_OUTSTANDING_WRITES-1];
reg [WR_PTR_W-1:0]    wr_head_ptr, wr_tail_ptr;
reg [WR_PTR_W:0]      wr_count;

reg [ID_WIDTH-1:0]    awf_id_fifo    [0:MAX_OUTSTANDING_WRITES-1];
reg [ADDR_WIDTH-1:0]  awf_addr_fifo  [0:MAX_OUTSTANDING_WRITES-1];
reg [7:0]             awf_len_fifo   [0:MAX_OUTSTANDING_WRITES-1];
reg [2:0]             awf_size_fifo  [0:MAX_OUTSTANDING_WRITES-1];
reg [1:0]             awf_burst_fifo [0:MAX_OUTSTANDING_WRITES-1];
reg [3:0]             awf_cache_fifo [0:MAX_OUTSTANDING_WRITES-1];
reg [2:0]             awf_prot_fifo  [0:MAX_OUTSTANDING_WRITES-1];
reg [WR_PTR_W-1:0]    awf_head_ptr, awf_tail_ptr;
reg [WR_PTR_W:0]      awf_count;

reg                   w_active;
reg [7:0]             w_cur_len;
reg [7:0]             w_beat_cnt;
reg [WR_PTR_W:0]      wr_aw_credit;

wire wr_fifo_full   = (wr_count  == MAX_WR_CNT);
wire awf_fifo_full  = (awf_count == MAX_WR_CNT);
wire aw_accept_ok   = !wr_fifo_full && !awf_fifo_full;
wire aw_hs          = S_AXI3_AWVALID && S_AXI3_AWREADY;
wire awf_pop        = M_AXI4_AWVALID && M_AXI4_AWREADY;
wire awf_push       = aw_hs;

assign S_AXI3_AWREADY = aw_accept_ok;

wire w_fire         = S_AXI3_WVALID && S_AXI3_WREADY;
wire w_last_by_cnt  = (w_beat_cnt == w_cur_len);
wire w_can_start    = (wr_count != 0) && (wr_aw_credit != 0);
wire w_start_nonlocked = (!w_active && w_can_start);
wire wr_pop         = w_active && w_fire && w_last_by_cnt;
wire wr_push        = aw_hs;

assign M_AXI4_WDATA  = S_AXI3_WDATA;
assign M_AXI4_WSTRB  = S_AXI3_WSTRB;
assign M_AXI4_WLAST  = w_last_by_cnt;
assign M_AXI4_WVALID = w_active && S_AXI3_WVALID;
assign S_AXI3_WREADY = w_active && M_AXI4_WREADY;

assign S_AXI3_BVALID = M_AXI4_BVALID;
assign S_AXI3_BID    = M_AXI4_BID;
assign S_AXI3_BRESP  = M_AXI4_BRESP;
assign M_AXI4_BREADY = S_AXI3_BREADY;

// ============================================================
// Read-side structures
// ============================================================
reg [ID_WIDTH-1:0]    arf_id_fifo    [0:MAX_OUTSTANDING_READS-1];
reg [ADDR_WIDTH-1:0]  arf_addr_fifo  [0:MAX_OUTSTANDING_READS-1];
reg [7:0]             arf_len_fifo   [0:MAX_OUTSTANDING_READS-1];
reg [2:0]             arf_size_fifo  [0:MAX_OUTSTANDING_READS-1];
reg [1:0]             arf_burst_fifo [0:MAX_OUTSTANDING_READS-1];
reg [3:0]             arf_cache_fifo [0:MAX_OUTSTANDING_READS-1];
reg [2:0]             arf_prot_fifo  [0:MAX_OUTSTANDING_READS-1];
reg [RD_PTR_W-1:0]    arf_head_ptr, arf_tail_ptr;
reg [RD_PTR_W:0]      arf_count;

reg [RD_PTR_W:0]      rd_outstanding_cnt;

wire arf_fifo_full   = (arf_count == MAX_RD_CNT);
wire ar_accept_ok    = !arf_fifo_full && (rd_outstanding_cnt < MAX_RD_CNT);
wire ar_hs           = S_AXI3_ARVALID && S_AXI3_ARREADY;
wire arf_pop         = M_AXI4_ARVALID && M_AXI4_ARREADY;
wire arf_push        = ar_hs;

assign S_AXI3_ARREADY = ar_accept_ok;

wire rd_pop       = M_AXI4_RVALID && S_AXI3_RREADY && M_AXI4_RLAST && (rd_outstanding_cnt != 0);
assign S_AXI3_RVALID = M_AXI4_RVALID;
assign S_AXI3_RID    = M_AXI4_RID;
assign S_AXI3_RDATA  = M_AXI4_RDATA;
assign S_AXI3_RRESP  = M_AXI4_RRESP;
assign S_AXI3_RLAST  = M_AXI4_RLAST;
assign M_AXI4_RREADY = S_AXI3_RREADY;

// ============================================================
// Sequential logic
// ============================================================
always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        wr_head_ptr <= 'd0; wr_tail_ptr <= 'd0; wr_count <= 'd0;
        awf_head_ptr <= 'd0; awf_tail_ptr <= 'd0; awf_count <= 'd0;

        M_AXI4_AWID <= 'd0;
        M_AXI4_AWADDR <= 'd0;
        M_AXI4_AWLEN <= 'd0;
        M_AXI4_AWSIZE <= 'd0;
        M_AXI4_AWBURST <= 'd0;
        M_AXI4_AWCACHE <= 'd0;
        M_AXI4_AWPROT <= 'd0;
        M_AXI4_AWVALID <= 1'b0;

        w_active <= 1'b0;
        w_cur_len <= 'd0;
        w_beat_cnt <= 'd0;
        wr_aw_credit <= 'd0;

        arf_head_ptr <= 'd0; arf_tail_ptr <= 'd0; arf_count <= 'd0;
        rd_outstanding_cnt <= 'd0;

        M_AXI4_ARID <= 'd0;
        M_AXI4_ARADDR <= 'd0;
        M_AXI4_ARLEN <= 'd0;
        M_AXI4_ARSIZE <= 'd0;
        M_AXI4_ARBURST <= 'd0;
        M_AXI4_ARCACHE <= 'd0;
        M_AXI4_ARPROT <= 'd0;
        M_AXI4_ARVALID <= 1'b0;
    end else begin
        // ---------------- AW accept ----------------
        if (aw_hs) begin
            wr_id_fifo[wr_tail_ptr]   <= S_AXI3_AWID;
            wr_len_fifo[wr_tail_ptr]  <= S_AXI3_AWLEN;
            wr_tail_ptr <= wr_tail_ptr + 1'b1;

            awf_id_fifo[awf_tail_ptr]    <= S_AXI3_AWID;
            awf_addr_fifo[awf_tail_ptr]  <= S_AXI3_AWADDR;
            awf_len_fifo[awf_tail_ptr]   <= S_AXI3_AWLEN;
            awf_size_fifo[awf_tail_ptr]  <= S_AXI3_AWSIZE;
            awf_burst_fifo[awf_tail_ptr] <= S_AXI3_AWBURST;
            awf_cache_fifo[awf_tail_ptr] <= S_AXI3_AWCACHE;
            awf_prot_fifo[awf_tail_ptr]  <= S_AXI3_AWPROT;
            awf_tail_ptr <= awf_tail_ptr + 1'b1;
        end

        case ({wr_push, wr_pop})
            2'b10: wr_count <= wr_count + 1'b1;
            2'b01: wr_count <= wr_count - 1'b1;
            default: wr_count <= wr_count;
        endcase

        case ({awf_push, awf_pop})
            2'b10: awf_count <= awf_count + 1'b1;
            2'b01: awf_count <= awf_count - 1'b1;
            default: awf_count <= awf_count;
        endcase

        // ---------------- AW forward ----------------
        if (!M_AXI4_AWVALID && (awf_count != 0)) begin
            M_AXI4_AWID    <= awf_id_fifo[awf_head_ptr];
            M_AXI4_AWADDR  <= awf_addr_fifo[awf_head_ptr];
            M_AXI4_AWLEN   <= awf_len_fifo[awf_head_ptr];
            M_AXI4_AWSIZE  <= awf_size_fifo[awf_head_ptr];
            M_AXI4_AWBURST <= awf_burst_fifo[awf_head_ptr];
            M_AXI4_AWCACHE <= awf_cache_fifo[awf_head_ptr];
            M_AXI4_AWPROT  <= awf_prot_fifo[awf_head_ptr];
            M_AXI4_AWVALID <= 1'b1;
        end else if (awf_pop) begin
            M_AXI4_AWVALID <= 1'b0;
            awf_head_ptr <= awf_head_ptr + 1'b1;
        end

        // Credit of "AW already issued to AXI4 but W not started yet" for non-locked writes
        if (awf_pop && !w_start_nonlocked) begin
            wr_aw_credit <= wr_aw_credit + 1'b1;
        end else if (!awf_pop && w_start_nonlocked) begin
            wr_aw_credit <= wr_aw_credit - 1'b1;
        end

        // ---------------- W serialize by burst ----------------
        if (!w_active && w_can_start) begin
            w_active <= 1'b1;
            w_cur_len <= wr_len_fifo[wr_head_ptr];
            w_beat_cnt <= 8'd0;
        end else if (w_active && w_fire) begin
            if (w_last_by_cnt) begin
                w_active <= 1'b0;
                wr_head_ptr <= wr_head_ptr + 1'b1;
            end else begin
                w_beat_cnt <= w_beat_cnt + 1'b1;
            end
        end

        // ---------------- AR accept ----------------
        if (ar_hs) begin
            arf_id_fifo[arf_tail_ptr]    <= S_AXI3_ARID;
            arf_addr_fifo[arf_tail_ptr]  <= S_AXI3_ARADDR;
            arf_len_fifo[arf_tail_ptr]   <= S_AXI3_ARLEN;
            arf_size_fifo[arf_tail_ptr]  <= S_AXI3_ARSIZE;
            arf_burst_fifo[arf_tail_ptr] <= S_AXI3_ARBURST;
            arf_cache_fifo[arf_tail_ptr] <= S_AXI3_ARCACHE;
            arf_prot_fifo[arf_tail_ptr]  <= S_AXI3_ARPROT;
            arf_tail_ptr <= arf_tail_ptr + 1'b1;
        end

        case ({arf_push, arf_pop})
            2'b10: arf_count <= arf_count + 1'b1;
            2'b01: arf_count <= arf_count - 1'b1;
            default: arf_count <= arf_count;
        endcase

        case ({arf_push, rd_pop})
            2'b10: rd_outstanding_cnt <= rd_outstanding_cnt + 1'b1;
            2'b01: rd_outstanding_cnt <= rd_outstanding_cnt - 1'b1;
            default: rd_outstanding_cnt <= rd_outstanding_cnt;
        endcase

        // ---------------- AR forward ----------------
        if (!M_AXI4_ARVALID && (arf_count != 0)) begin
            M_AXI4_ARID    <= arf_id_fifo[arf_head_ptr];
            M_AXI4_ARADDR  <= arf_addr_fifo[arf_head_ptr];
            M_AXI4_ARLEN   <= arf_len_fifo[arf_head_ptr];
            M_AXI4_ARSIZE  <= arf_size_fifo[arf_head_ptr];
            M_AXI4_ARBURST <= arf_burst_fifo[arf_head_ptr];
            M_AXI4_ARCACHE <= arf_cache_fifo[arf_head_ptr];
            M_AXI4_ARPROT  <= arf_prot_fifo[arf_head_ptr];
            M_AXI4_ARVALID <= 1'b1;
        end else if (arf_pop) begin
            M_AXI4_ARVALID <= 1'b0;
            arf_head_ptr <= arf_head_ptr + 1'b1;
        end

    end
end

// Unused AXI3 inputs by policy
wire _unused_ok = &{1'b0, S_AXI3_WID[0], S_AXI3_WLAST, S_AXI3_AWQOS[0], S_AXI3_ARQOS[0], S_AXI3_AWLOCK, S_AXI3_ARLOCK};

endmodule
