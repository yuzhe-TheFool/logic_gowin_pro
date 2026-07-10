//==============================================================================
// File Name    : axi4_wcontrol.v
// Module Name  : axi4_wcontrol
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module axi4_wcontrol (
    input               resetn,
    input               clock,
    output wire [  3:0] axi4_awid_o,
    output wire [ 31:0] axi4_awaddr_o,
    output wire [  7:0] axi4_awlen_o,
    output wire [  2:0] axi4_awsize_o,
    output wire [  1:0] axi4_awburst_o,
    output wire         axi4_awlock_o,
    output wire [  3:0] axi4_awcache_o,
    output wire [  2:0] axi4_awprot_o,
    output wire [  3:0] axi4_awqos_o,
    output wire         axi4_awvalid_o,
    input               axi4_awready_i,
    output wire [127:0] axi4_wdata_o,
    output wire [ 31:0] axi4_wstrb_o,
    output wire         axi4_wlast_o,
    output wire         axi4_wvalid_o,
    input               axi4_wready_i,
    input       [  3:0] axi4_bid_i,
    input       [  1:0] axi4_bresp_i,
    input               axi4_bvalid_i,
    output wire         axi4_bready_o,
    input               wr_start_i,
    input       [ 31:0] wr_addr_i,
    input       [  8:0] wr_len_i,
    output reg          wr_ready_o,
    output wire         wr_fifo_re_o,
    input       [127:0] wr_fifo_data_i,
    output reg          wr_done_o
);



  localparam AXI_WR_IDLE = 3'd0;
  localparam AXI_WA_WAIT = 3'd1;
  localparam AXI_WA_START = 3'd2;
  localparam AXI_WD_WAIT = 3'd3;
  localparam AXI_WD_PROC = 3'd4;
  localparam AXI_WR_WAIT = 3'd5;
  localparam AXI_WR_DONE = 3'd6;


  wire        axi4_wlen_done;
  reg  [ 2:0] axi4_wstate;
  reg  [ 2:0] axi4_wstate_nxt;
  reg         axi4_awaddr_Load;
  reg         axi4_awvalid_nxt;
  reg         axi4_wvalid_nxt;
  reg         axi4_wLast_nxt;
  reg         axi4_wlen_shift;
  reg         axi4_wlen_load;
  reg  [31:0] axi4_awaddr_r1;
  wire [31:0] axi4_awaddr_nxt;
  reg  [ 7:0] axi4_awlen_cnt;
  wire [ 7:0] axi4_awlen_nxt;
  reg         axi4_wvalid_r1;
  reg         axi4_awvalid_r1;

  always @(posedge clock or negedge resetn) begin
    if (!resetn) axi4_wstate <= AXI_WR_IDLE;
    else axi4_wstate <= axi4_wstate_nxt;
  end


  always @(*) begin
    case (axi4_wstate)
      AXI_WA_START: axi4_wstate_nxt = AXI_WD_WAIT;
      AXI_WD_WAIT: begin
        if (axi4_awready_i) axi4_wstate_nxt = AXI_WD_PROC;
        else axi4_wstate_nxt = AXI_WD_WAIT;
      end
      AXI_WD_PROC: begin
        if (axi4_wready_i & axi4_wlen_done) axi4_wstate_nxt = AXI_WR_WAIT;
        else axi4_wstate_nxt = AXI_WD_PROC;
      end
      AXI_WR_WAIT: begin
        if (axi4_bvalid_i) axi4_wstate_nxt = AXI_WR_DONE;
        else axi4_wstate_nxt = AXI_WR_WAIT;
      end
      AXI_WR_DONE:  axi4_wstate_nxt = AXI_WR_IDLE;
      default: begin
        if (wr_start_i) axi4_wstate_nxt = AXI_WA_START;
        else axi4_wstate_nxt = AXI_WR_IDLE;
      end
    endcase
  end



  always @(*) begin
    axi4_awaddr_Load = 1'b0;
    axi4_awvalid_nxt = 1'b0;
    axi4_wvalid_nxt = 1'b0;
    axi4_wLast_nxt = 1'b0;
    axi4_wlen_shift = 1'b0;
    axi4_wlen_load = 1'b0;
    wr_done_o = 1'b0;
    wr_ready_o = 1'b0;
    case (axi4_wstate)
      AXI_WA_START: begin
        axi4_awvalid_nxt = 1'b1;
      end
      AXI_WD_WAIT: begin
        axi4_wvalid_nxt = 1'b1;
        axi4_wlen_load  = axi4_awready_i;
      end
      AXI_WD_PROC: begin
        axi4_wvalid_nxt = ~(axi4_wready_i & axi4_wlen_done);
        axi4_wLast_nxt  = axi4_wready_i & axi4_wlen_done;
        axi4_wlen_shift = axi4_wready_i & ~axi4_wlen_done;
      end
      AXI_WR_WAIT: begin
        wr_ready_o = 1'b0;
        axi4_awvalid_nxt = 1'b0;
        axi4_wvalid_nxt = 1'b0;
        axi4_wlen_load = 1'b0;
      end
      AXI_WR_DONE: wr_done_o = 1'b1;
      default: begin
        axi4_awaddr_Load = wr_start_i;
        axi4_awvalid_nxt = 1'b0;
        axi4_wvalid_nxt = 1'b0;
        axi4_wlen_load = 1'b0;
        wr_ready_o = 1'b1;
      end
    endcase
  end

  assign axi4_awaddr_nxt = axi4_awaddr_Load ? wr_addr_i : axi4_awaddr_r1;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) axi4_awaddr_r1 <= 32'd0;
    else axi4_awaddr_r1 <= axi4_awaddr_nxt;
  end
  assign axi4_awaddr_o = axi4_awaddr_r1;


  assign axi4_awlen_nxt = axi4_wlen_load ? axi4_awlen_o: 
                          axi4_wlen_shift ? axi4_awlen_cnt - 8'd1 : axi4_awlen_cnt;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) axi4_awlen_cnt <= 8'd0;
    else axi4_awlen_cnt <= axi4_awlen_nxt;
  end

  assign axi4_wlen_done = (axi4_awlen_cnt == 8'd0);


  always @(posedge clock or negedge resetn) begin
    if (!resetn) axi4_wvalid_r1 <= 1'b0;
    else axi4_wvalid_r1 <= axi4_wvalid_nxt;
  end
  assign axi4_wvalid_o = axi4_wvalid_r1;


  always @(posedge clock or negedge resetn) begin
    if (!resetn) axi4_awvalid_r1 <= 1'b0;
    else axi4_awvalid_r1 <= axi4_awvalid_nxt;
  end
  assign axi4_awvalid_o = axi4_awvalid_r1;

  assign wr_fifo_re_o   = axi4_wvalid_nxt & axi4_wready_i;
  assign axi4_awid_o    = 4'b1111;
  assign axi4_awlen_o   = wr_len_i - 8'd1;
  assign axi4_awsize_o  = 3'b100;
  assign axi4_awburst_o = 2'b01;  // incr
  assign axi4_awlock_o  = 1'b0;
  assign axi4_awcache_o = 4'b0010;
  assign axi4_awprot_o  = 3'b000;
  assign axi4_awqos_o   = 4'b0000;
  assign axi4_wdata_o   = wr_fifo_data_i;
  assign axi4_wstrb_o   = 32'hffff;  //WStrb_width = data_width/8
  assign axi4_wlast_o   = axi4_wlen_done;
  assign axi4_bready_o  = axi4_bvalid_i;

endmodule
