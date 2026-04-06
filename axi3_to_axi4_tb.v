`timescale 1ns/1ps

module axi3_to_axi4_tb;

  localparam ID_WIDTH   = 8;
  localparam ADDR_WIDTH = 32;
  localparam DATA_WIDTH = 64;
  localparam STRB_WIDTH = DATA_WIDTH / 8;
  localparam integer MAX_WAIT_CYCLES = 200;
  localparam integer MEM_WORDS       = 256;
  localparam integer QUEUE_DEPTH     = 32;
  localparam integer SCRIPT_DEPTH    = 512;

  localparam [1:0] RESP_OKAY   = 2'b00;
  localparam [1:0] RESP_SLVERR = 2'b10;

  localparam [2:0] OP_AW    = 3'd0;
  localparam [2:0] OP_W     = 3'd1;
  localparam [2:0] OP_AR    = 3'd2;
  localparam [2:0] OP_EXP_B = 3'd3;
  localparam [2:0] OP_EXP_R = 3'd4;

  reg ACLK;
  reg ARESETn;

  reg  [ID_WIDTH-1:0]      S_AXI3_AWID;
  reg  [ADDR_WIDTH-1:0]    S_AXI3_AWADDR;
  reg  [7:0]               S_AXI3_AWLEN;
  reg  [2:0]               S_AXI3_AWSIZE;
  reg  [1:0]               S_AXI3_AWBURST;
  reg                      S_AXI3_AWLOCK;
  reg  [3:0]               S_AXI3_AWCACHE;
  reg  [2:0]               S_AXI3_AWPROT;
  reg  [3:0]               S_AXI3_AWQOS;
  reg                      S_AXI3_AWVALID;
  wire                     S_AXI3_AWREADY;

  reg  [ID_WIDTH-1:0]      S_AXI3_WID;
  reg  [DATA_WIDTH-1:0]    S_AXI3_WDATA;
  reg  [STRB_WIDTH-1:0]    S_AXI3_WSTRB;
  reg                      S_AXI3_WLAST;
  reg                      S_AXI3_WVALID;
  wire                     S_AXI3_WREADY;

  wire [ID_WIDTH-1:0]      S_AXI3_BID;
  wire [1:0]               S_AXI3_BRESP;
  wire                     S_AXI3_BVALID;
  reg                      S_AXI3_BREADY;

  reg  [ID_WIDTH-1:0]      S_AXI3_ARID;
  reg  [ADDR_WIDTH-1:0]    S_AXI3_ARADDR;
  reg  [7:0]               S_AXI3_ARLEN;
  reg  [2:0]               S_AXI3_ARSIZE;
  reg  [1:0]               S_AXI3_ARBURST;
  reg                      S_AXI3_ARLOCK;
  reg  [3:0]               S_AXI3_ARCACHE;
  reg  [2:0]               S_AXI3_ARPROT;
  reg  [3:0]               S_AXI3_ARQOS;
  reg                      S_AXI3_ARVALID;
  wire                     S_AXI3_ARREADY;

  wire [ID_WIDTH-1:0]      S_AXI3_RID;
  wire [DATA_WIDTH-1:0]    S_AXI3_RDATA;
  wire [1:0]               S_AXI3_RRESP;
  wire                     S_AXI3_RLAST;
  wire                     S_AXI3_RVALID;
  reg                      S_AXI3_RREADY;

  wire [ID_WIDTH-1:0]      M_AXI4_AWID;
  wire [ADDR_WIDTH-1:0]    M_AXI4_AWADDR;
  wire [7:0]               M_AXI4_AWLEN;
  wire [2:0]               M_AXI4_AWSIZE;
  wire [1:0]               M_AXI4_AWBURST;
  wire [3:0]               M_AXI4_AWCACHE;
  wire [2:0]               M_AXI4_AWPROT;
  wire [3:0]               M_AXI4_AWQOS;
  wire                     M_AXI4_AWVALID;
  reg                      M_AXI4_AWREADY;

  wire [DATA_WIDTH-1:0]    M_AXI4_WDATA;
  wire [STRB_WIDTH-1:0]    M_AXI4_WSTRB;
  wire                     M_AXI4_WLAST;
  wire                     M_AXI4_WVALID;
  reg                      M_AXI4_WREADY;

  reg  [ID_WIDTH-1:0]      M_AXI4_BID;
  reg  [1:0]               M_AXI4_BRESP;
  reg                      M_AXI4_BVALID;
  wire                     M_AXI4_BREADY;

  wire [ID_WIDTH-1:0]      M_AXI4_ARID;
  wire [ADDR_WIDTH-1:0]    M_AXI4_ARADDR;
  wire [7:0]               M_AXI4_ARLEN;
  wire [2:0]               M_AXI4_ARSIZE;
  wire [1:0]               M_AXI4_ARBURST;
  wire [3:0]               M_AXI4_ARCACHE;
  wire [2:0]               M_AXI4_ARPROT;
  wire [3:0]               M_AXI4_ARQOS;
  wire                     M_AXI4_ARVALID;
  reg                      M_AXI4_ARREADY;

  reg  [ID_WIDTH-1:0]      M_AXI4_RID;
  reg  [DATA_WIDTH-1:0]    M_AXI4_RDATA;
  reg  [1:0]               M_AXI4_RRESP;
  reg                      M_AXI4_RLAST;
  reg                      M_AXI4_RVALID;
  wire                     M_AXI4_RREADY;

  integer err_cnt;
  reg [1023:0] fsdb_name;

  reg [2:0]            script_op        [0:SCRIPT_DEPTH-1];
  reg [ID_WIDTH-1:0]   script_id        [0:SCRIPT_DEPTH-1];
  reg [ADDR_WIDTH-1:0] script_addr      [0:SCRIPT_DEPTH-1];
  reg [7:0]            script_len       [0:SCRIPT_DEPTH-1];
  reg [DATA_WIDTH-1:0] script_data      [0:SCRIPT_DEPTH-1];
  reg                  script_last      [0:SCRIPT_DEPTH-1];
  reg [1:0]            script_resp      [0:SCRIPT_DEPTH-1];
  integer script_count;

  integer drv_pc;
  reg [2:0] active_op;
  reg       active_valid;
  integer   active_wait;
  reg       tests_loaded;

  reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

  reg [ID_WIDTH-1:0]   awid_q   [0:QUEUE_DEPTH-1];
  reg [ADDR_WIDTH-1:0] awaddr_q [0:QUEUE_DEPTH-1];
  reg [7:0]            awlen_q  [0:QUEUE_DEPTH-1];
  integer aw_head, aw_tail, aw_count;

  reg [ID_WIDTH-1:0]   bid_q [0:QUEUE_DEPTH-1];
  integer b_head, b_tail, b_count;

  reg [ID_WIDTH-1:0]   arid_q   [0:QUEUE_DEPTH-1];
  reg [ADDR_WIDTH-1:0] araddr_q [0:QUEUE_DEPTH-1];
  reg [7:0]            arlen_q  [0:QUEUE_DEPTH-1];
  integer ar_head, ar_tail, ar_count;

  reg                  w_ctx_valid;
  reg [ID_WIDTH-1:0]   w_ctx_id;
  reg [ADDR_WIDTH-1:0] w_ctx_addr;
  reg [7:0]            w_ctx_len;
  reg [7:0]            w_ctx_beat;

  reg                  r_ctx_valid;
  reg [ID_WIDTH-1:0]   r_ctx_id;
  reg [ADDR_WIDTH-1:0] r_ctx_addr;
  reg [7:0]            r_ctx_len;
  reg [7:0]            r_ctx_beat;

  integer i;

  axi3_to_axi4_bridge #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MAX_OUTSTANDING_READS(4),
    .MAX_OUTSTANDING_WRITES(4)
  ) dut (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .S_AXI3_AWID(S_AXI3_AWID), .S_AXI3_AWADDR(S_AXI3_AWADDR), .S_AXI3_AWLEN(S_AXI3_AWLEN), .S_AXI3_AWSIZE(S_AXI3_AWSIZE),
    .S_AXI3_AWBURST(S_AXI3_AWBURST), .S_AXI3_AWLOCK(S_AXI3_AWLOCK), .S_AXI3_AWCACHE(S_AXI3_AWCACHE), .S_AXI3_AWPROT(S_AXI3_AWPROT),
    .S_AXI3_AWQOS(S_AXI3_AWQOS), .S_AXI3_AWVALID(S_AXI3_AWVALID), .S_AXI3_AWREADY(S_AXI3_AWREADY),
    .S_AXI3_WID(S_AXI3_WID), .S_AXI3_WDATA(S_AXI3_WDATA), .S_AXI3_WSTRB(S_AXI3_WSTRB), .S_AXI3_WLAST(S_AXI3_WLAST),
    .S_AXI3_WVALID(S_AXI3_WVALID), .S_AXI3_WREADY(S_AXI3_WREADY),
    .S_AXI3_BID(S_AXI3_BID), .S_AXI3_BRESP(S_AXI3_BRESP), .S_AXI3_BVALID(S_AXI3_BVALID), .S_AXI3_BREADY(S_AXI3_BREADY),
    .S_AXI3_ARID(S_AXI3_ARID), .S_AXI3_ARADDR(S_AXI3_ARADDR), .S_AXI3_ARLEN(S_AXI3_ARLEN), .S_AXI3_ARSIZE(S_AXI3_ARSIZE),
    .S_AXI3_ARBURST(S_AXI3_ARBURST), .S_AXI3_ARLOCK(S_AXI3_ARLOCK), .S_AXI3_ARCACHE(S_AXI3_ARCACHE), .S_AXI3_ARPROT(S_AXI3_ARPROT),
    .S_AXI3_ARQOS(S_AXI3_ARQOS), .S_AXI3_ARVALID(S_AXI3_ARVALID), .S_AXI3_ARREADY(S_AXI3_ARREADY),
    .S_AXI3_RID(S_AXI3_RID), .S_AXI3_RDATA(S_AXI3_RDATA), .S_AXI3_RRESP(S_AXI3_RRESP), .S_AXI3_RLAST(S_AXI3_RLAST),
    .S_AXI3_RVALID(S_AXI3_RVALID), .S_AXI3_RREADY(S_AXI3_RREADY),
    .M_AXI4_AWID(M_AXI4_AWID), .M_AXI4_AWADDR(M_AXI4_AWADDR), .M_AXI4_AWLEN(M_AXI4_AWLEN), .M_AXI4_AWSIZE(M_AXI4_AWSIZE),
    .M_AXI4_AWBURST(M_AXI4_AWBURST), .M_AXI4_AWCACHE(M_AXI4_AWCACHE), .M_AXI4_AWPROT(M_AXI4_AWPROT), .M_AXI4_AWQOS(M_AXI4_AWQOS),
    .M_AXI4_AWVALID(M_AXI4_AWVALID), .M_AXI4_AWREADY(M_AXI4_AWREADY), .M_AXI4_WDATA(M_AXI4_WDATA), .M_AXI4_WSTRB(M_AXI4_WSTRB),
    .M_AXI4_WLAST(M_AXI4_WLAST), .M_AXI4_WVALID(M_AXI4_WVALID), .M_AXI4_WREADY(M_AXI4_WREADY), .M_AXI4_BID(M_AXI4_BID),
    .M_AXI4_BRESP(M_AXI4_BRESP), .M_AXI4_BVALID(M_AXI4_BVALID), .M_AXI4_BREADY(M_AXI4_BREADY),
    .M_AXI4_ARID(M_AXI4_ARID), .M_AXI4_ARADDR(M_AXI4_ARADDR), .M_AXI4_ARLEN(M_AXI4_ARLEN), .M_AXI4_ARSIZE(M_AXI4_ARSIZE),
    .M_AXI4_ARBURST(M_AXI4_ARBURST), .M_AXI4_ARCACHE(M_AXI4_ARCACHE), .M_AXI4_ARPROT(M_AXI4_ARPROT), .M_AXI4_ARQOS(M_AXI4_ARQOS),
    .M_AXI4_ARVALID(M_AXI4_ARVALID), .M_AXI4_ARREADY(M_AXI4_ARREADY), .M_AXI4_RID(M_AXI4_RID), .M_AXI4_RDATA(M_AXI4_RDATA),
    .M_AXI4_RRESP(M_AXI4_RRESP), .M_AXI4_RLAST(M_AXI4_RLAST), .M_AXI4_RVALID(M_AXI4_RVALID), .M_AXI4_RREADY(M_AXI4_RREADY)
  );

  function integer word_index(input [ADDR_WIDTH-1:0] addr);
    integer idx;
  begin
    idx = (addr >> 3) % MEM_WORDS;
    if (idx < 0) begin
      idx = 0;
    end
    word_index = idx;
  end
  endfunction

  function [DATA_WIDTH-1:0] apply_wstrb(
    input [DATA_WIDTH-1:0] cur,
    input [DATA_WIDTH-1:0] data,
    input [STRB_WIDTH-1:0] strb
  );
    integer j;
    reg [DATA_WIDTH-1:0] next_val;
  begin
    next_val = cur;
    for (j = 0; j < STRB_WIDTH; j = j + 1) begin
      if (strb[j]) begin
        next_val[j*8 +: 8] = data[j*8 +: 8];
      end
    end
    apply_wstrb = next_val;
  end
  endfunction

  function [DATA_WIDTH-1:0] make_data(input integer seed);
    reg [31:0] seed_u32;
  begin
    seed_u32 = seed[31:0];
    make_data = {32'hC0000000 | seed_u32, 32'h5A5A0000 | ((seed_u32 * 32'd16) + 32'd3)};
  end
  endfunction

  task add_step(
    input [2:0] op,
    input [ID_WIDTH-1:0] id,
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [DATA_WIDTH-1:0] data,
    input last,
    input [1:0] resp
  );
  begin
    script_op[script_count]   = op;
    script_id[script_count]   = id;
    script_addr[script_count] = addr;
    script_len[script_count]  = len;
    script_data[script_count] = data;
    script_last[script_count] = last;
    script_resp[script_count] = resp;
    script_count = script_count + 1;
  end
  endtask

  task add_aw(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, input [7:0] len, input lock);
  begin
    add_step(OP_AW, id, addr, len, {DATA_WIDTH{1'b0}}, lock, RESP_OKAY);
  end
  endtask

  task add_w(input [ID_WIDTH-1:0] id, input [DATA_WIDTH-1:0] data, input last);
  begin
    add_step(OP_W, id, {ADDR_WIDTH{1'b0}}, 8'd0, data, last, RESP_OKAY);
  end
  endtask

  task add_ar(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, input [7:0] len, input lock);
  begin
    add_step(OP_AR, id, addr, len, {DATA_WIDTH{1'b0}}, lock, RESP_OKAY);
  end
  endtask

  task add_expect_b(input [ID_WIDTH-1:0] id, input [1:0] resp);
  begin
    add_step(OP_EXP_B, id, {ADDR_WIDTH{1'b0}}, 8'd0, {DATA_WIDTH{1'b0}}, 1'b0, resp);
  end
  endtask

  task add_expect_r(
    input [ID_WIDTH-1:0] id,
    input [DATA_WIDTH-1:0] data,
    input last,
    input [1:0] resp
  );
  begin
    add_step(OP_EXP_R, id, {ADDR_WIDTH{1'b0}}, 8'd0, data, last, resp);
  end
  endtask

  task build_write_only_test;
    integer idx;
  begin
    $display("[TB] Write-only sequence: 10 commands");
    for (idx = 0; idx < 10; idx = idx + 1) begin
      add_aw(idx[ID_WIDTH-1:0], 32'h1000 + idx * 8, 8'd0, 1'b0);
      add_w(idx[ID_WIDTH-1:0], make_data(idx), 1'b1);
      add_expect_b(idx[ID_WIDTH-1:0], RESP_OKAY);
    end
  end
  endtask

  task build_read_only_test;
    integer idx;
    reg [ID_WIDTH-1:0] id;
  begin
    $display("[TB] Read-only sequence: 10 commands");
    for (idx = 0; idx < 10; idx = idx + 1) begin
      id = 8'h40 + idx[7:0];
      add_ar(id, 32'h1000 + idx * 8, 8'd0, 1'b0);
      add_expect_r(id, make_data(idx), 1'b1, RESP_OKAY);
    end
  end
  endtask

  task build_mixed_test;
    integer idx;
    reg [ID_WIDTH-1:0] id;
  begin
    $display("[TB] Mixed read/write sequence: 10 commands");
    for (idx = 0; idx < 10; idx = idx + 1) begin
      id = 8'h80 + idx[7:0];
      if ((idx % 2) == 0) begin
        add_aw(id, 32'h2000 + (idx / 2) * 8, 8'd0, 1'b0);
        add_w(id, make_data(16 + idx), 1'b1);
        add_expect_b(id, RESP_OKAY);
      end else begin
        add_ar(id, 32'h2000 + (idx / 2) * 8, 8'd0, 1'b0);
        add_expect_r(id, make_data(16 + idx - 1), 1'b1, RESP_OKAY);
      end
    end
  end
  endtask

  task build_burst_test;
    integer beat;
  begin
    $display("[TB] Burst sequence: multi-beat write/read");
    add_aw(8'hA0, 32'h3000, 8'd3, 1'b0);
    for (beat = 0; beat < 4; beat = beat + 1) begin
      add_w(8'hA0, make_data(32 + beat), (beat == 3));
    end
    add_expect_b(8'hA0, RESP_OKAY);
    add_ar(8'hA1, 32'h3000, 8'd3, 1'b0);
    for (beat = 0; beat < 4; beat = beat + 1) begin
      add_expect_r(8'hA1, make_data(32 + beat), (beat == 3), RESP_OKAY);
    end

    add_aw(8'hA2, 32'h3040, 8'd1, 1'b0);
    for (beat = 0; beat < 2; beat = beat + 1) begin
      add_w(8'hA2, make_data(64 + beat), (beat == 1));
    end
    add_expect_b(8'hA2, RESP_OKAY);
    add_ar(8'hA3, 32'h3040, 8'd1, 1'b0);
    for (beat = 0; beat < 2; beat = beat + 1) begin
      add_expect_r(8'hA3, make_data(64 + beat), (beat == 1), RESP_OKAY);
    end
  end
  endtask

  task build_outstanding_test;
    integer beat;
  begin
    $display("[TB] Outstanding sequence: multiple AW/AR before responses");

    add_aw(8'hB0, 32'h4000, 8'd1, 1'b0);
    add_aw(8'hB1, 32'h4010, 8'd1, 1'b0);
    for (beat = 0; beat < 2; beat = beat + 1) begin
      add_w(8'hB0, make_data(96 + beat), (beat == 1));
    end
    for (beat = 0; beat < 2; beat = beat + 1) begin
      add_w(8'hB1, make_data(112 + beat), (beat == 1));
    end
    add_expect_b(8'hB0, RESP_OKAY);
    add_expect_b(8'hB1, RESP_OKAY);

    add_ar(8'hB2, 32'h4000, 8'd1, 1'b0);
    add_ar(8'hB3, 32'h4010, 8'd1, 1'b0);
    for (beat = 0; beat < 2; beat = beat + 1) begin
      add_expect_r(8'hB2, make_data(96 + beat), (beat == 1), RESP_OKAY);
    end
    for (beat = 0; beat < 2; beat = beat + 1) begin
      add_expect_r(8'hB3, make_data(112 + beat), (beat == 1), RESP_OKAY);
    end
  end
  endtask

  task build_lock_negative_test;
  begin
    $display("[TB] Negative sequence: locked write/read return local SLVERR");
    add_aw(8'hC0, 32'h5000, 8'd0, 1'b1);
    add_w(8'hC0, make_data(160), 1'b1);
    add_expect_b(8'hC0, RESP_SLVERR);

    add_ar(8'hC1, 32'h5000, 8'd0, 1'b1);
    add_expect_r(8'hC1, {DATA_WIDTH{1'b0}}, 1'b1, RESP_SLVERR);
  end
  endtask

  task build_mixed_burst_interleave_test;
    integer beat;
  begin
    $display("[TB] Mixed burst sequence: write/read interleave");
    add_aw(8'hD0, 32'h6000, 8'd2, 1'b0);
    for (beat = 0; beat < 3; beat = beat + 1) begin
      add_w(8'hD0, make_data(192 + beat), (beat == 2));
    end
    add_expect_b(8'hD0, RESP_OKAY);
    add_ar(8'hD1, 32'h6000, 8'd2, 1'b0);
    for (beat = 0; beat < 3; beat = beat + 1) begin
      add_expect_r(8'hD1, make_data(192 + beat), (beat == 2), RESP_OKAY);
    end

    add_aw(8'hD2, 32'h6040, 8'd2, 1'b0);
    add_ar(8'hD3, 32'h6000, 8'd0, 1'b0);
    for (beat = 0; beat < 3; beat = beat + 1) begin
      add_w(8'hD2, make_data(208 + beat), (beat == 2));
    end
    add_expect_b(8'hD2, RESP_OKAY);
    add_expect_r(8'hD3, make_data(192), 1'b1, RESP_OKAY);
    add_ar(8'hD4, 32'h6040, 8'd2, 1'b0);
    for (beat = 0; beat < 3; beat = beat + 1) begin
      add_expect_r(8'hD4, make_data(208 + beat), (beat == 2), RESP_OKAY);
    end
  end
  endtask

  task clear_master_outputs;
  begin
    S_AXI3_AWID    = '0;
    S_AXI3_AWADDR  = '0;
    S_AXI3_AWLEN   = '0;
    S_AXI3_AWSIZE  = '0;
    S_AXI3_AWBURST = '0;
    S_AXI3_AWLOCK  = 1'b0;
    S_AXI3_AWCACHE = '0;
    S_AXI3_AWPROT  = '0;
    S_AXI3_AWQOS   = '0;
    S_AXI3_AWVALID = 1'b0;

    S_AXI3_WID     = '0;
    S_AXI3_WDATA   = '0;
    S_AXI3_WSTRB   = '0;
    S_AXI3_WLAST   = 1'b0;
    S_AXI3_WVALID  = 1'b0;

    S_AXI3_BREADY  = 1'b0;

    S_AXI3_ARID    = '0;
    S_AXI3_ARADDR  = '0;
    S_AXI3_ARLEN   = '0;
    S_AXI3_ARSIZE  = '0;
    S_AXI3_ARBURST = '0;
    S_AXI3_ARLOCK  = 1'b0;
    S_AXI3_ARCACHE = '0;
    S_AXI3_ARPROT  = '0;
    S_AXI3_ARQOS   = '0;
    S_AXI3_ARVALID = 1'b0;

    S_AXI3_RREADY  = 1'b0;
  end
  endtask

  initial begin
    ACLK = 1'b0;
    forever #5 ACLK = ~ACLK;
  end

  always @(posedge ACLK) begin
    if (ARESETn) begin
      if (M_AXI4_AWVALID && M_AXI4_AWREADY && (M_AXI4_AWQOS !== 4'h0)) begin
        $display("ERROR: AWQOS expected 0, got %0h @%0t", M_AXI4_AWQOS, $time);
        err_cnt = err_cnt + 1;
      end
      if (M_AXI4_ARVALID && M_AXI4_ARREADY && (M_AXI4_ARQOS !== 4'h0)) begin
        $display("ERROR: ARQOS expected 0, got %0h @%0t", M_AXI4_ARQOS, $time);
        err_cnt = err_cnt + 1;
      end
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    integer mem_idx;
    reg [ADDR_WIDTH-1:0] beat_addr;
    reg [DATA_WIDTH-1:0] cur_word;
    if (!ARESETn) begin
      M_AXI4_AWREADY <= 1'b1;
      M_AXI4_WREADY  <= 1'b1;
      M_AXI4_ARREADY <= 1'b1;

      M_AXI4_BID     <= '0;
      M_AXI4_BRESP   <= RESP_OKAY;
      M_AXI4_BVALID  <= 1'b0;

      M_AXI4_RID     <= '0;
      M_AXI4_RDATA   <= '0;
      M_AXI4_RRESP   <= RESP_OKAY;
      M_AXI4_RLAST   <= 1'b0;
      M_AXI4_RVALID  <= 1'b0;

      aw_head        <= 0;
      aw_tail        <= 0;
      aw_count       <= 0;
      b_head         <= 0;
      b_tail         <= 0;
      b_count        <= 0;
      ar_head        <= 0;
      ar_tail        <= 0;
      ar_count       <= 0;

      w_ctx_valid    <= 1'b0;
      w_ctx_id       <= '0;
      w_ctx_addr     <= '0;
      w_ctx_len      <= '0;
      w_ctx_beat     <= '0;

      r_ctx_valid    <= 1'b0;
      r_ctx_id       <= '0;
      r_ctx_addr     <= '0;
      r_ctx_len      <= '0;
      r_ctx_beat     <= '0;

      for (i = 0; i < MEM_WORDS; i = i + 1) begin
        mem[i] <= '0;
      end
    end else begin
      if (M_AXI4_AWVALID && M_AXI4_AWREADY) begin
        awid_q[aw_tail]   <= M_AXI4_AWID;
        awaddr_q[aw_tail] <= M_AXI4_AWADDR;
        awlen_q[aw_tail]  <= M_AXI4_AWLEN;
        aw_tail           <= (aw_tail + 1) % QUEUE_DEPTH;
        aw_count          <= aw_count + 1;
      end

      if (!w_ctx_valid && (aw_count > 0)) begin
        w_ctx_valid <= 1'b1;
        w_ctx_id    <= awid_q[aw_head];
        w_ctx_addr  <= awaddr_q[aw_head];
        w_ctx_len   <= awlen_q[aw_head];
        w_ctx_beat  <= 0;
        aw_head     <= (aw_head + 1) % QUEUE_DEPTH;
        aw_count    <= aw_count - 1;
      end

      if (M_AXI4_WVALID && M_AXI4_WREADY) begin
        if (!w_ctx_valid) begin
          $display("ERROR: AXI4 W beat without AW context @%0t", $time);
          err_cnt = err_cnt + 1;
        end else begin
          beat_addr = w_ctx_addr + ({24'd0, w_ctx_beat} << 3);
          mem_idx = word_index(beat_addr);
          cur_word = mem[mem_idx];
          mem[mem_idx] <= apply_wstrb(cur_word, M_AXI4_WDATA, M_AXI4_WSTRB);

          if (M_AXI4_WLAST !== (w_ctx_beat == w_ctx_len)) begin
            $display("ERROR: WLAST mismatch beat=%0d len=%0d @%0t", w_ctx_beat, w_ctx_len, $time);
            err_cnt = err_cnt + 1;
          end

          if (w_ctx_beat == w_ctx_len) begin
            bid_q[b_tail] <= w_ctx_id;
            b_tail        <= (b_tail + 1) % QUEUE_DEPTH;
            b_count       <= b_count + 1;
            w_ctx_valid   <= 1'b0;
          end else begin
            w_ctx_beat    <= w_ctx_beat + 1;
          end
        end
      end

      if (!M_AXI4_BVALID && (b_count > 0)) begin
        M_AXI4_BVALID <= 1'b1;
        M_AXI4_BID    <= bid_q[b_head];
        M_AXI4_BRESP  <= RESP_OKAY;
        b_head        <= (b_head + 1) % QUEUE_DEPTH;
        b_count       <= b_count - 1;
      end else if (M_AXI4_BVALID && M_AXI4_BREADY) begin
        M_AXI4_BVALID <= 1'b0;
      end

      if (M_AXI4_ARVALID && M_AXI4_ARREADY) begin
        arid_q[ar_tail]   <= M_AXI4_ARID;
        araddr_q[ar_tail] <= M_AXI4_ARADDR;
        arlen_q[ar_tail]  <= M_AXI4_ARLEN;
        ar_tail           <= (ar_tail + 1) % QUEUE_DEPTH;
        ar_count          <= ar_count + 1;
      end

      if (!r_ctx_valid && (ar_count > 0) && !M_AXI4_RVALID) begin
        r_ctx_valid <= 1'b1;
        r_ctx_id    <= arid_q[ar_head];
        r_ctx_addr  <= araddr_q[ar_head];
        r_ctx_len   <= arlen_q[ar_head];
        r_ctx_beat  <= 0;
        ar_head     <= (ar_head + 1) % QUEUE_DEPTH;
        ar_count    <= ar_count - 1;

        beat_addr     = araddr_q[ar_head];
        mem_idx       = word_index(beat_addr);
        M_AXI4_RVALID <= 1'b1;
        M_AXI4_RID    <= arid_q[ar_head];
        M_AXI4_RRESP  <= RESP_OKAY;
        M_AXI4_RDATA  <= mem[mem_idx];
        M_AXI4_RLAST  <= (arlen_q[ar_head] == 0);
      end else if (M_AXI4_RVALID && M_AXI4_RREADY) begin
        if (r_ctx_beat == r_ctx_len) begin
          M_AXI4_RVALID <= 1'b0;
          M_AXI4_RLAST  <= 1'b0;
          r_ctx_valid   <= 1'b0;
        end else begin
          r_ctx_beat    <= r_ctx_beat + 1;
          beat_addr     = r_ctx_addr + (({24'd0, r_ctx_beat} + 32'd1) << 3);
          mem_idx       = word_index(beat_addr);
          M_AXI4_RID    <= r_ctx_id;
          M_AXI4_RRESP  <= RESP_OKAY;
          M_AXI4_RDATA  <= mem[mem_idx];
          M_AXI4_RLAST  <= ((r_ctx_beat + 1) == r_ctx_len);
        end
      end
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      drv_pc       <= 0;
      active_op    <= OP_AW;
      active_valid <= 1'b0;
      active_wait  <= 0;

      S_AXI3_AWID    <= '0;
      S_AXI3_AWADDR  <= '0;
      S_AXI3_AWLEN   <= '0;
      S_AXI3_AWSIZE  <= '0;
      S_AXI3_AWBURST <= '0;
      S_AXI3_AWLOCK  <= 1'b0;
      S_AXI3_AWCACHE <= '0;
      S_AXI3_AWPROT  <= '0;
      S_AXI3_AWQOS   <= '0;
      S_AXI3_AWVALID <= 1'b0;

      S_AXI3_WID     <= '0;
      S_AXI3_WDATA   <= '0;
      S_AXI3_WSTRB   <= '0;
      S_AXI3_WLAST   <= 1'b0;
      S_AXI3_WVALID  <= 1'b0;

      S_AXI3_BREADY  <= 1'b0;

      S_AXI3_ARID    <= '0;
      S_AXI3_ARADDR  <= '0;
      S_AXI3_ARLEN   <= '0;
      S_AXI3_ARSIZE  <= '0;
      S_AXI3_ARBURST <= '0;
      S_AXI3_ARLOCK  <= 1'b0;
      S_AXI3_ARCACHE <= '0;
      S_AXI3_ARPROT  <= '0;
      S_AXI3_ARQOS   <= '0;
      S_AXI3_ARVALID <= 1'b0;

      S_AXI3_RREADY  <= 1'b0;
    end else begin
      if (tests_loaded && (drv_pc < script_count)) begin
        if (!active_valid) begin
          active_valid <= 1'b1;
          active_op    <= script_op[drv_pc];
          active_wait  <= 0;

          case (script_op[drv_pc])
            OP_AW: begin
              S_AXI3_AWID    <= script_id[drv_pc];
              S_AXI3_AWADDR  <= script_addr[drv_pc];
              S_AXI3_AWLEN   <= script_len[drv_pc];
              S_AXI3_AWSIZE  <= 3'b011;
              S_AXI3_AWBURST <= 2'b01;
              S_AXI3_AWLOCK  <= script_last[drv_pc];
              S_AXI3_AWCACHE <= 4'h3;
              S_AXI3_AWPROT  <= 3'h0;
              S_AXI3_AWQOS   <= 4'hF;
              S_AXI3_AWVALID <= 1'b1;
            end
            OP_W: begin
              S_AXI3_WID     <= script_id[drv_pc];
              S_AXI3_WDATA   <= script_data[drv_pc];
              S_AXI3_WSTRB   <= {STRB_WIDTH{1'b1}};
              S_AXI3_WLAST   <= script_last[drv_pc];
              S_AXI3_WVALID  <= 1'b1;
            end
            OP_AR: begin
              S_AXI3_ARID    <= script_id[drv_pc];
              S_AXI3_ARADDR  <= script_addr[drv_pc];
              S_AXI3_ARLEN   <= script_len[drv_pc];
              S_AXI3_ARSIZE  <= 3'b011;
              S_AXI3_ARBURST <= 2'b01;
              S_AXI3_ARLOCK  <= script_last[drv_pc];
              S_AXI3_ARCACHE <= 4'h3;
              S_AXI3_ARPROT  <= 3'h0;
              S_AXI3_ARQOS   <= 4'hA;
              S_AXI3_ARVALID <= 1'b1;
            end
            OP_EXP_B: begin
              S_AXI3_BREADY  <= 1'b1;
            end
            OP_EXP_R: begin
              S_AXI3_RREADY  <= 1'b1;
            end
            default: begin
            end
          endcase
        end else begin
          active_wait <= active_wait + 1;

          case (active_op)
            OP_AW: begin
              if (S_AXI3_AWVALID && S_AXI3_AWREADY) begin
                S_AXI3_AWVALID <= 1'b0;
                S_AXI3_AWLOCK  <= 1'b0;
                active_valid   <= 1'b0;
                drv_pc         <= drv_pc + 1;
              end
            end
            OP_W: begin
              if (S_AXI3_WVALID && S_AXI3_WREADY) begin
                S_AXI3_WVALID  <= 1'b0;
                S_AXI3_WLAST   <= 1'b0;
                active_valid   <= 1'b0;
                drv_pc         <= drv_pc + 1;
              end
            end
            OP_AR: begin
              if (S_AXI3_ARVALID && S_AXI3_ARREADY) begin
                S_AXI3_ARVALID <= 1'b0;
                S_AXI3_ARLOCK  <= 1'b0;
                active_valid   <= 1'b0;
                drv_pc         <= drv_pc + 1;
              end
            end
            OP_EXP_B: begin
              if (S_AXI3_BVALID && S_AXI3_BREADY) begin
                if ((S_AXI3_BID !== script_id[drv_pc]) || (S_AXI3_BRESP !== script_resp[drv_pc])) begin
                  $display("ERROR: B mismatch exp id=%0h resp=%0h got id=%0h resp=%0h @%0t",
                           script_id[drv_pc], script_resp[drv_pc], S_AXI3_BID, S_AXI3_BRESP, $time);
                  err_cnt = err_cnt + 1;
                end
                S_AXI3_BREADY <= 1'b0;
                active_valid  <= 1'b0;
                drv_pc        <= drv_pc + 1;
              end
            end
            OP_EXP_R: begin
              if (S_AXI3_RVALID && S_AXI3_RREADY) begin
                if ((S_AXI3_RID !== script_id[drv_pc]) || (S_AXI3_RRESP !== script_resp[drv_pc]) ||
                    (S_AXI3_RLAST !== script_last[drv_pc]) || (S_AXI3_RDATA !== script_data[drv_pc])) begin
                  $display("ERROR: R mismatch exp id=%0h last=%0d data=%0h resp=%0h got id=%0h last=%0d data=%0h resp=%0h @%0t",
                           script_id[drv_pc], script_last[drv_pc], script_data[drv_pc], script_resp[drv_pc],
                           S_AXI3_RID, S_AXI3_RLAST, S_AXI3_RDATA, S_AXI3_RRESP, $time);
                  err_cnt = err_cnt + 1;
                end
                S_AXI3_RREADY <= 1'b0;
                active_valid  <= 1'b0;
                drv_pc        <= drv_pc + 1;
              end
            end
            default: begin
            end
          endcase

          if (active_valid && (active_wait >= MAX_WAIT_CYCLES)) begin
            $display("ERROR: Timeout waiting for script op %0d at pc=%0d @%0t", active_op, drv_pc, $time);
            err_cnt = err_cnt + 1;
            case (active_op)
              OP_AW: begin
                S_AXI3_AWVALID <= 1'b0;
                S_AXI3_AWLOCK  <= 1'b0;
              end
              OP_W: begin
                S_AXI3_WVALID <= 1'b0;
                S_AXI3_WLAST  <= 1'b0;
              end
              OP_AR: begin
                S_AXI3_ARVALID <= 1'b0;
                S_AXI3_ARLOCK  <= 1'b0;
              end
              OP_EXP_B: begin
                S_AXI3_BREADY <= 1'b0;
              end
              OP_EXP_R: begin
                S_AXI3_RREADY <= 1'b0;
              end
              default: begin
              end
            endcase
            active_valid <= 1'b0;
            drv_pc       <= drv_pc + 1;
          end
        end
      end
    end
  end

  initial begin
    repeat (5000) @(posedge ACLK);
    $display("[TB] TIMEOUT");
    $finish;
  end

  initial begin
    if ($test$plusargs("DUMP_FSDB")) begin
      fsdb_name = "axi3_to_axi4.fsdb";
      if ($value$plusargs("FSDB_FILE=%s", fsdb_name)) begin
        $display("[TB] Waveform file from plusargs: %0s", fsdb_name);
      end else begin
        $display("[TB] Waveform file default: %0s", fsdb_name);
      end
`ifdef VCS
      $fsdbDumpfile(fsdb_name);
      $fsdbDumpvars(0, axi3_to_axi4_tb);
`else
      $dumpfile(fsdb_name);
      $dumpvars(0, axi3_to_axi4_tb);
`endif
    end

    err_cnt = 0;
    script_count = 0;
    tests_loaded = 1'b0;
    clear_master_outputs();
    ARESETn = 1'b0;

    build_write_only_test();
    build_read_only_test();
    build_mixed_test();
    build_burst_test();
    build_outstanding_test();
    build_lock_negative_test();
    build_mixed_burst_interleave_test();

    repeat (5) @(posedge ACLK);
    ARESETn = 1'b1;
    tests_loaded = 1'b1;

    wait (drv_pc == script_count && !active_valid);
    repeat (10) @(posedge ACLK);

    if (err_cnt == 0) begin
      $display("[TB] PASS");
    end else begin
      $display("[TB] FAIL, err_cnt=%0d", err_cnt);
    end

    if ($test$plusargs("DUMP_FSDB")) begin
`ifdef VCS
      $fsdbDumpflush;
`else
      $dumpflush;
`endif
    end
    $finish;
  end

endmodule
