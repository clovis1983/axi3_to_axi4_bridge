`timescale 1ns/1ps

module axi3_to_axi4_tb;

  localparam ID_WIDTH   = 8;
  localparam ADDR_WIDTH = 32;
  localparam DATA_WIDTH = 64;
  localparam integer MAX_WAIT_CYCLES = 200;

  reg ACLK;
  reg ARESETn;

  // AXI3 slave side (driver)
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
  reg  [DATA_WIDTH/8-1:0]  S_AXI3_WSTRB;
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

  // AXI4 master side (mock slave)
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
  wire [DATA_WIDTH/8-1:0]  M_AXI4_WSTRB;
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

  // clock
  initial begin
    ACLK = 1'b0;
    forever #5 ACLK = ~ACLK;
  end

  integer err_cnt;
  integer cycles;
  reg [1023:0] fsdb_name;

  // mock slave state
  reg [ID_WIDTH-1:0] awid_q [0:15];
  reg [7:0]          awlen_q[0:15];
  integer awh, awt, awc;
  reg [ID_WIDTH-1:0] bid_q [0:15];
  integer bh, bt, bc;
  reg [7:0]          cur_w_cnt;
  reg [7:0]          cur_w_len;
  reg                w_have_ctx;
  reg [ID_WIDTH-1:0] cur_w_id;

  reg [ID_WIDTH-1:0] arid_q [0:15];
  reg [7:0]          arlen_q[0:15];
  integer arh, art, arc;
  reg                r_sending;
  reg [ID_WIDTH-1:0] r_id;
  reg [7:0]          r_len;
  reg [7:0]          r_cnt;

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      M_AXI4_AWREADY <= 1'b1;
      M_AXI4_WREADY  <= 1'b1;
      M_AXI4_ARREADY <= 1'b1;
      M_AXI4_BVALID  <= 1'b0;
      M_AXI4_BID     <= '0;
      M_AXI4_BRESP   <= 2'b00;
      M_AXI4_RVALID  <= 1'b0;
      M_AXI4_RID     <= '0;
      M_AXI4_RDATA   <= '0;
      M_AXI4_RRESP   <= 2'b00;
      M_AXI4_RLAST   <= 1'b0;
      awh <= 0; awt <= 0; awc <= 0;
      bh <= 0; bt <= 0; bc <= 0;
      arh <= 0; art <= 0; arc <= 0;
      cur_w_cnt <= 0; cur_w_len <= 0; w_have_ctx <= 1'b0; cur_w_id <= '0;
      r_sending <= 1'b0; r_id <= '0; r_len <= 0; r_cnt <= 0;
    end else begin
      if (M_AXI4_AWVALID && M_AXI4_AWREADY) begin
        awid_q[awt]  <= M_AXI4_AWID;
        awlen_q[awt] <= M_AXI4_AWLEN;
        awt <= (awt + 1) & 15;
        awc <= awc + 1;
      end

      if (!w_have_ctx && (awc > 0)) begin
        cur_w_id  <= awid_q[awh];
        cur_w_len <= awlen_q[awh];
        cur_w_cnt <= 0;
        w_have_ctx <= 1'b1;
        awh <= (awh + 1) & 15;
        awc <= awc - 1;
      end

      if (M_AXI4_WVALID && M_AXI4_WREADY) begin
        if (!w_have_ctx) begin
          $display("ERROR: W beat without AW context @%0t", $time);
          err_cnt = err_cnt + 1;
        end else begin
          if ((cur_w_cnt == cur_w_len) != M_AXI4_WLAST) begin
            $display("ERROR: WLAST mismatch @%0t", $time);
            err_cnt = err_cnt + 1;
          end
          if (cur_w_cnt == cur_w_len) begin
            w_have_ctx <= 1'b0;
            bid_q[bt] <= cur_w_id;
            bt <= (bt + 1) & 15;
            bc <= bc + 1;
          end else begin
            cur_w_cnt <= cur_w_cnt + 1'b1;
          end
        end
      end

      if (!M_AXI4_BVALID && (bc > 0)) begin
        M_AXI4_BVALID <= 1'b1;
        M_AXI4_BID <= bid_q[bh];
        M_AXI4_BRESP <= 2'b00;
        bh <= (bh + 1) & 15;
        bc <= bc - 1;
      end else if (M_AXI4_BVALID && M_AXI4_BREADY) begin
        M_AXI4_BVALID <= 1'b0;
      end

      if (M_AXI4_ARVALID && M_AXI4_ARREADY) begin
        arid_q[art] <= M_AXI4_ARID;
        arlen_q[art] <= M_AXI4_ARLEN;
        art <= (art + 1) & 15;
        arc <= arc + 1;
      end

      if (!r_sending && arc > 0) begin
        r_sending <= 1'b1;
        r_id <= arid_q[arh];
        r_len <= arlen_q[arh];
        r_cnt <= 0;
        arh <= (arh + 1) & 15;
        arc <= arc - 1;
        M_AXI4_RVALID <= 1'b1;
        M_AXI4_RID <= arid_q[arh];
        M_AXI4_RRESP <= 2'b00;
        M_AXI4_RDATA <= {56'h0, arid_q[arh]};
        M_AXI4_RLAST <= (arlen_q[arh] == 0);
      end else if (r_sending && M_AXI4_RVALID && M_AXI4_RREADY) begin
        if (r_cnt == r_len) begin
          M_AXI4_RVALID <= 1'b0;
          M_AXI4_RLAST <= 1'b0;
          r_sending <= 1'b0;
        end else begin
          r_cnt <= r_cnt + 1'b1;
          M_AXI4_RDATA <= M_AXI4_RDATA + 1;
          M_AXI4_RLAST <= (r_cnt + 1'b1 == r_len);
        end
      end
    end
  end

  // protocol checks for this bridge policy
  always @(posedge ACLK) begin
    if (ARESETn) begin
      if (M_AXI4_AWVALID && M_AXI4_AWREADY) begin
        if (M_AXI4_AWQOS !== 4'h0) begin
          $display("ERROR: AWQOS not 0 @%0t", $time); err_cnt = err_cnt + 1;
        end
      end
      if (M_AXI4_ARVALID && M_AXI4_ARREADY) begin
        if (M_AXI4_ARQOS !== 4'h0) begin
          $display("ERROR: ARQOS not 0 @%0t", $time); err_cnt = err_cnt + 1;
        end
      end
    end
  end

  task wait_awvalid;
    integer i;
  begin
    i = 0;
    while (!M_AXI4_AWVALID && (i < MAX_WAIT_CYCLES)) begin
      i = i + 1;
      @(posedge ACLK);
    end
    if (!M_AXI4_AWVALID) begin
      $display("ERROR: Timeout waiting for M_AXI4_AWVALID @%0t", $time);
      err_cnt = err_cnt + 1;
    end
  end
  endtask

  task wait_arvalid;
    integer i;
  begin
    i = 0;
    while (!M_AXI4_ARVALID && (i < MAX_WAIT_CYCLES)) begin
      i = i + 1;
      @(posedge ACLK);
    end
    if (!M_AXI4_ARVALID) begin
      $display("ERROR: Timeout waiting for M_AXI4_ARVALID @%0t", $time);
      err_cnt = err_cnt + 1;
    end
  end
  endtask

  task do_aw(input [ID_WIDTH-1:0] id, input [31:0] addr, input [7:0] len, input lock);
    integer i;
  begin
    @(negedge ACLK);
    S_AXI3_AWID = id; S_AXI3_AWADDR = addr; S_AXI3_AWLEN = len;
    S_AXI3_AWSIZE = 3'b011; S_AXI3_AWBURST = 2'b01; S_AXI3_AWLOCK = lock;
    S_AXI3_AWCACHE = 4'h3; S_AXI3_AWPROT = 3'h0; S_AXI3_AWQOS = 4'hF;
    S_AXI3_AWVALID = 1'b1;
    i = 0;
    while (!S_AXI3_AWREADY && (i < MAX_WAIT_CYCLES)) begin
      i = i + 1;
      @(posedge ACLK);
    end
    if (!S_AXI3_AWREADY) begin
      $display("ERROR: Timeout waiting for S_AXI3_AWREADY @%0t", $time);
      err_cnt = err_cnt + 1;
    end
    @(negedge ACLK);
    S_AXI3_AWVALID = 1'b0;
  end
  endtask

  task do_wbeat(input [63:0] data, input last_hint);
    integer i;
  begin
    @(negedge ACLK);
    S_AXI3_WID = 8'hFF;
    S_AXI3_WDATA = data;
    S_AXI3_WSTRB = 8'hFF;
    S_AXI3_WLAST = last_hint;
    S_AXI3_WVALID = 1'b1;
    i = 0;
    while (!S_AXI3_WREADY && (i < MAX_WAIT_CYCLES)) begin
      i = i + 1;
      @(posedge ACLK);
    end
    if (!S_AXI3_WREADY) begin
      $display("ERROR: Timeout waiting for S_AXI3_WREADY @%0t", $time);
      err_cnt = err_cnt + 1;
    end
    @(negedge ACLK);
    S_AXI3_WVALID = 1'b0;
  end
  endtask

  task do_ar(input [ID_WIDTH-1:0] id, input [31:0] addr, input [7:0] len, input lock);
    integer i;
  begin
    @(negedge ACLK);
    S_AXI3_ARID = id; S_AXI3_ARADDR = addr; S_AXI3_ARLEN = len;
    S_AXI3_ARSIZE = 3'b011; S_AXI3_ARBURST = 2'b01; S_AXI3_ARLOCK = lock;
    S_AXI3_ARCACHE = 4'h3; S_AXI3_ARPROT = 3'h0; S_AXI3_ARQOS = 4'hA;
    S_AXI3_ARVALID = 1'b1;
    i = 0;
    while (!S_AXI3_ARREADY && (i < MAX_WAIT_CYCLES)) begin
      i = i + 1;
      @(posedge ACLK);
    end
    if (!S_AXI3_ARREADY) begin
      $display("ERROR: Timeout waiting for S_AXI3_ARREADY @%0t", $time);
      err_cnt = err_cnt + 1;
    end
    @(negedge ACLK);
    S_AXI3_ARVALID = 1'b0;
  end
  endtask

  task get_b(input [ID_WIDTH-1:0] exp_id, input [1:0] exp_resp);
    integer i;
  begin
    @(negedge ACLK);
    S_AXI3_BREADY = 1'b1;
    i = 0;
    while (!S_AXI3_BVALID && (i < MAX_WAIT_CYCLES)) begin
      i = i + 1;
      @(posedge ACLK);
    end
    if (!S_AXI3_BVALID) begin
      $display("ERROR: Timeout waiting for S_AXI3_BVALID @%0t", $time);
      err_cnt = err_cnt + 1;
    end
    if (S_AXI3_BID !== exp_id || S_AXI3_BRESP !== exp_resp) begin
      $display("ERROR: B mismatch exp id=%0h resp=%0h got id=%0h resp=%0h", exp_id, exp_resp, S_AXI3_BID, S_AXI3_BRESP);
      err_cnt = err_cnt + 1;
    end
    @(negedge ACLK);
    S_AXI3_BREADY = 1'b0;
  end
  endtask

  task get_rbeat(input [ID_WIDTH-1:0] exp_id, input exp_last, input [1:0] exp_resp);
    integer i;
  begin
    @(negedge ACLK);
    S_AXI3_RREADY = 1'b1;
    i = 0;
    while (!S_AXI3_RVALID && (i < MAX_WAIT_CYCLES)) begin
      i = i + 1;
      @(posedge ACLK);
    end
    if (!S_AXI3_RVALID) begin
      $display("ERROR: Timeout waiting for S_AXI3_RVALID @%0t", $time);
      err_cnt = err_cnt + 1;
    end
    if (S_AXI3_RID !== exp_id || S_AXI3_RLAST !== exp_last || S_AXI3_RRESP !== exp_resp) begin
      $display("ERROR: R mismatch exp id=%0h last=%0d resp=%0h got id=%0h last=%0d resp=%0h",
               exp_id, exp_last, exp_resp, S_AXI3_RID, S_AXI3_RLAST, S_AXI3_RRESP);
      err_cnt = err_cnt + 1;
    end
    @(negedge ACLK);
    S_AXI3_RREADY = 1'b0;
  end
  endtask

  task apply_reset;
  begin
    S_AXI3_AWVALID = 1'b0;
    S_AXI3_WVALID = 1'b0;
    S_AXI3_BREADY = 1'b0;
    S_AXI3_ARVALID = 1'b0;
    S_AXI3_RREADY = 1'b0;
    ARESETn = 1'b0;
    repeat (5) @(posedge ACLK);
    ARESETn = 1'b1;
    repeat (5) @(posedge ACLK);
  end
  endtask

  initial begin
    repeat (5000) @(posedge ACLK);
    $display("[TB] TIMEOUT");
    $finish;
  end

  initial begin
    if ($test$plusargs("DUMP_FSDB")) begin
      fsdb_name = "axi3_to_axi4.fsdb";
      if ($value$plusargs("FSDB_FILE=%s", fsdb_name)) begin
        $display("[TB] FSDB file from plusargs: %0s", fsdb_name);
      end else begin
        $display("[TB] FSDB file default: %0s", fsdb_name);
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
    S_AXI3_AWID=0; S_AXI3_AWADDR=0; S_AXI3_AWLEN=0; S_AXI3_AWSIZE=0; S_AXI3_AWBURST=0; S_AXI3_AWLOCK=0; S_AXI3_AWCACHE=0; S_AXI3_AWPROT=0; S_AXI3_AWQOS=0; S_AXI3_AWVALID=0;
    S_AXI3_WID=0; S_AXI3_WDATA=0; S_AXI3_WSTRB=0; S_AXI3_WLAST=0; S_AXI3_WVALID=0;
    S_AXI3_BREADY=0;
    S_AXI3_ARID=0; S_AXI3_ARADDR=0; S_AXI3_ARLEN=0; S_AXI3_ARSIZE=0; S_AXI3_ARBURST=0; S_AXI3_ARLOCK=0; S_AXI3_ARCACHE=0; S_AXI3_ARPROT=0; S_AXI3_ARQOS=0; S_AXI3_ARVALID=0;
    S_AXI3_RREADY=0;
    ARESETn = 0;
    repeat (5) @(posedge ACLK);
    ARESETn = 1;
    repeat (5) @(posedge ACLK);

    $display("[TB] Test1 locked write -> local SLVERR");
    do_aw(8'h11, 32'h1000, 8'd0, 1'b1);
    do_wbeat(64'h1111, 1'b1);
    get_b(8'h11, 2'b10);

    $display("[TB] Test2 locked read -> local SLVERR single beat");
    do_ar(8'h22, 32'h2000, 8'd3, 1'b1);
    get_rbeat(8'h22, 1'b1, 2'b10);

    $display("[TB] Test3 multiple read outstanding");
    do_ar(8'h31, 32'h3000, 8'd1, 1'b0);
    do_ar(8'h32, 32'h4000, 8'd0, 1'b0);
    get_rbeat(8'h31, 1'b0, 2'b00);
    get_rbeat(8'h31, 1'b1, 2'b00);
    get_rbeat(8'h32, 1'b1, 2'b00);

    $display("[TB] Test4 multi AW outstanding + serialized W bursts");
    do_aw(8'h41, 32'h5000, 8'd1, 1'b0); // 2 beats
    do_aw(8'h42, 32'h6000, 8'd0, 1'b0); // 1 beat
    do_wbeat(64'hAAAA, 1'b0);
    do_wbeat(64'hBBBB, 1'b1);
    do_wbeat(64'hCCCC, 1'b1);
    get_b(8'h41, 2'b00);
    get_b(8'h42, 2'b00);

    $display("[TB] Test5 AWLEN high-bit passthrough while stalled");
    M_AXI4_AWREADY = 1'b0;
    do_aw(8'h55, 32'h7000, 8'h80, 1'b0);
    wait_awvalid();
    if (M_AXI4_AWLEN !== 8'h80) begin
      $display("ERROR: AWLEN not passed through, got %0h @%0t", M_AXI4_AWLEN, $time);
      err_cnt = err_cnt + 1;
    end
    if (M_AXI4_AWQOS !== 4'h0) begin
      $display("ERROR: AWQOS not 0 during stall @%0t", $time);
      err_cnt = err_cnt + 1;
    end
    M_AXI4_AWREADY = 1'b1;
    apply_reset();

    $display("[TB] Test6 ARLEN high-bit passthrough while stalled");
    M_AXI4_ARREADY = 1'b0;
    do_ar(8'h66, 32'h8000, 8'h80, 1'b0);
    wait_arvalid();
    if (M_AXI4_ARLEN !== 8'h80) begin
      $display("ERROR: ARLEN not passed through, got %0h @%0t", M_AXI4_ARLEN, $time);
      err_cnt = err_cnt + 1;
    end
    if (M_AXI4_ARQOS !== 4'h0) begin
      $display("ERROR: ARQOS not 0 during stall @%0t", $time);
      err_cnt = err_cnt + 1;
    end
    M_AXI4_ARREADY = 1'b1;
    apply_reset();

    repeat(20) @(posedge ACLK);
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
