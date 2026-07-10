//==============================================================================
// File Name    : axi4_rcontrol.v
// Module Name  : axi4_rcontrol
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module axi4_rcontrol (
    input               resetn,
    input               clock,
    output wire [  3:0] axi4_arid_o,
    output wire [ 31:0] axi4_araddr_o,
    output wire [  7:0] axi4_arlen_o,
    output wire [  2:0] axi4_arsize_o,
    output wire [  1:0] axi4_arburst_o,
    output wire         axi4_arlock_o,
    output wire [  3:0] axi4_arcache_o,
    output wire [  2:0] axi4_arport_o,
    output wire [  3:0] axi4_arqos_o,
    output wire         axi4_arvalid_o,
    input               axi4_arready_i,
    input       [  3:0] axi4_rid_i,
    input       [127:0] axi4_rdata_i,
    input       [  1:0] axi4_rresp_i,
    input               axi4_rlast_i,
    input               axi4_rvalid_i,
    output wire         axi4_rready_o,
    input               rd_start_i,
    input       [ 31:0] rd_adddr_i,
    input       [  8:0] rd_len_i,
    output reg          rd_ready_o,
    output wire         rd_fifo_we_o,
    output wire [127:0] rd_fifo_data_o,
    output reg          rd_done_o
);


  localparam AXI_RD_IDLE = 3'd0;
  localparam AXI_RA_WAIT = 3'd1;
  localparam AXI_RA_START = 3'd2;
  localparam AXI_RD_WAIT = 3'd3;
  localparam AXI_RD_PROC = 3'd4;
  localparam AXI_RD_DONE = 3'd5;


  reg  [ 2:0] axi4_rstate;
  reg  [ 2:0] axi4_rstate_nxt;
  reg         axi4_araddr_load;
  reg         axi4_arvalid_nxt;
  reg  [31:0] axi4_araddr_r1;
  wire [31:0] axi4_araddr_nxt;

  always @(posedge clock or negedge resetn) begin
    if (!resetn) axi4_rstate <= AXI_RD_IDLE;
    else axi4_rstate <= axi4_rstate_nxt;
  end


  always @(*) begin
    case (axi4_rstate)
      AXI_RA_WAIT:  axi4_rstate_nxt = AXI_RA_START;
      AXI_RA_START: axi4_rstate_nxt = AXI_RD_WAIT;
      AXI_RD_WAIT: begin
        if (axi4_arready_i) axi4_rstate_nxt = AXI_RD_PROC;
        else axi4_rstate_nxt = AXI_RD_WAIT;
      end
      AXI_RD_PROC: begin
        if (axi4_rvalid_i & axi4_rlast_i) axi4_rstate_nxt = AXI_RD_DONE;
        else axi4_rstate_nxt = AXI_RD_PROC;
      end
      AXI_RD_DONE:  axi4_rstate_nxt = AXI_RD_IDLE;
      default: begin
        if (rd_start_i) axi4_rstate_nxt = AXI_RA_WAIT;
        else axi4_rstate_nxt = AXI_RD_IDLE;
      end
    endcase
  end


  always @(*) begin
    axi4_araddr_load = 1'b0;
    axi4_arvalid_nxt = 1'b0;
    rd_done_o = 1'b0;
    rd_ready_o = 1'b0;
    case (axi4_rstate)
      AXI_RD_IDLE: begin
        axi4_araddr_load = rd_start_i;
        rd_ready_o = 1'b1;
      end
      AXI_RA_START: begin
        axi4_arvalid_nxt = 1'b1;
      end
      AXI_RD_WAIT: begin
        axi4_arvalid_nxt = ~axi4_arready_i;
      end
      AXI_RD_DONE: rd_done_o = 1'b1;
      default: begin
        axi4_araddr_load = 1'b0;
        axi4_arvalid_nxt = 1'b0;
        rd_done_o = 1'b0;
      end
    endcase
  end

  assign axi4_araddr_nxt = axi4_araddr_load ? rd_adddr_i : axi4_araddr_r1;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) axi4_araddr_r1 <= 32'd0;
    else axi4_araddr_r1 <= axi4_araddr_nxt;
  end

  assign axi4_araddr_o = axi4_araddr_r1;

  reg axi4_arvalid_r1;

  always @(posedge clock or negedge resetn) begin
    if (!resetn) axi4_arvalid_r1 <= 1'b0;
    else axi4_arvalid_r1 <= axi4_arvalid_nxt;
  end

  assign axi4_arvalid_o = axi4_arvalid_r1;


  assign axi4_arid_o = 4'b1111;
  assign axi4_arlen_o = rd_len_i - 8'd1;
  assign axi4_arsize_o = 3'b100;
  assign axi4_arburst_o = 2'b01;
  assign axi4_arlock_o = 1'b0;
  assign axi4_arcache_o = 4'b0011;
  assign axi4_arport_o = 3'b000;
  assign axi4_arqos_o = 4'b0000;
  assign axi4_rready_o = axi4_rvalid_i;
  assign rd_fifo_we_o = axi4_rvalid_i;
  assign rd_fifo_data_o = axi4_rdata_i;

endmodule
