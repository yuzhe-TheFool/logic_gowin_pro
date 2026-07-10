//==============================================================================
// File Name    : axi4_control.v
// Module Name  : axi4_control
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module axi4_control (
    input               ui_clock,
    input               ui_reset,
    input               core_resetn,
    input       [ 31:0] wbegin_addr_i,
    input       [ 31:0] wend_addr_i,
    input               fifo_wclock,
    input               wfifo_wen_i,
    input       [ 31:0] fifo_wdata_i,
    input               fifo_wreset,
    input               rone_time_en_i,
    input       [ 31:0] rread_begin_addr_i,
    input       [ 31:0] rbegin_addr_i,
    input       [ 31:0] rend_addr_i,
    input               fifo_rclock,
    input               rfifo_ren_i,
    output wire [ 15:0] fifo_rdata_o,
    input               fifo_rreset,
    input               read_enable_i,
    output wire         wburst_req_o,
    output wire [ 31:0] wburst_addr_o,
    output      [  8:0] wburst_len_o,
    input               wready_i,
    input               wfifo_ren_i,
    output      [127:0] wfifo_data_o,
    input               wburst_finish_i,
    output wire         rburst_req_o,
    output wire [ 31:0] rburst_addr_o,
    output wire [  8:0] rburst_len_o,
    input               rready_i,
    input               rfifo_wen_i,
    input       [127:0] rfifo_data_i,
    input               rburst_finish_i,
    output wire         rfifo_empty_o
);


  wire [ 9:0] wfifo_rdata_cnt;
  wire [ 9:0] rfifo_wdata_cnt;
  reg  [ 8:0] wburst_len_r1;
  reg  [ 8:0] rburst_len_r1;
  reg         fifo_wreset_r1;
  reg         fifo_wreset_r2;
  reg         fifo_rreset_r1;
  reg         fifo_rreset_r2;
  reg         wburst_req_r1;
  wire        wburst_req_nxt;
  wire [31:0] empty_space_128bit;
  wire        ddr_cycle_last;
  wire [ 8:0] wburst_len_nxt;
  reg         ddr_loop_r1;
  wire        ddr_loop_nxt;
  wire        wburst_addr_over;
  reg  [31:0] wburst_addr_r1;
  wire [31:0] wburst_addr_nxt;
  reg         read_enable_r1;
  reg         read_enable_r2;
  wire        read_enable_pos;
  wire        ddr_read_ov_nxt;
  reg         rburst_req_r1;
  wire        rburst_req_nxt;
  reg  [31:0] ddr_read_cnt;
  wire [31:0] empty_rspace_128bit;
  wire        ddr_rcycle_last;
  wire        ddr_read_under;
  wire [ 8:0] rburst_len_nxt;
  reg         ddr_rloop_r1;
  wire        ddr_rloop_nxt;
  wire        rburst_addr_over;
  reg  [31:0] rburst_addr_r1;
  wire [31:0] rburst_addr_nxt;
  wire [31:0] ddr_read_value;
  wire [31:0] ddr_read_cnt_nxt;
  reg         ddr_read_ov_r1;
  reg         rfifo_wen_r1;
  wire        rfifo_wen;

  assign wburst_len_o = wburst_len_r1;
  assign rburst_len_o = rburst_len_r1;



  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) fifo_wreset_r1 <= 1'b0;
    else fifo_wreset_r1 <= fifo_wreset;
  end
  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) fifo_wreset_r2 <= 1'b0;
    else fifo_wreset_r2 <= fifo_wreset_r1;
  end

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) fifo_rreset_r1 <= 1'b0;
    else fifo_rreset_r1 <= fifo_rreset;
  end

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) fifo_rreset_r2 <= 1'b0;
    else fifo_rreset_r2 <= fifo_rreset_r1;
  end

  assign wburst_req_nxt = (wfifo_rdata_cnt > 10'd0) && wready_i;

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) wburst_req_r1 <= 1'b0;
    else wburst_req_r1 <= wburst_req_nxt;
  end
  assign wburst_req_o = wburst_req_r1;

  assign empty_space_128bit = (wend_addr_i - wburst_addr_o) >> 4;
  assign ddr_cycle_last = wfifo_rdata_cnt >= empty_space_128bit;
  assign wburst_len_nxt = (wburst_req_nxt & ~wburst_req_o) ? ((wfifo_rdata_cnt >= 128) ? 9'd128:
                                                               ddr_cycle_last ? empty_space_128bit: wfifo_rdata_cnt):
                                                               wburst_len_r1;
  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) wburst_len_r1 <= 9'b0;
    else wburst_len_r1 <= wburst_len_nxt;
  end

  assign ddr_loop_nxt = (wburst_req_nxt & ~wburst_req_o) ? ddr_cycle_last : (~wburst_req_nxt & wburst_req_o) ? 1'b0 : ddr_loop_r1;

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) ddr_loop_r1 <= 1'b0;
    else ddr_loop_r1 <= ddr_loop_nxt;
  end

  assign wburst_addr_over = (~wburst_req_nxt & wburst_req_o) & ddr_loop_r1;

  assign wburst_addr_nxt = ((fifo_wreset_r1 &  ~fifo_wreset_r2) | wburst_addr_over) ? wbegin_addr_i :
                           (~wburst_req_nxt & wburst_req_o) ? wburst_addr_r1 + (wburst_len_r1 << 4) : wburst_addr_r1;

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) wburst_addr_r1 <= wbegin_addr_i;
    else wburst_addr_r1 <= wburst_addr_nxt;
  end
  assign wburst_addr_o = wburst_addr_r1;

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) read_enable_r1 <= 1'b0;
    else read_enable_r1 <= read_enable_i;
  end

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) read_enable_r2 <= 1'b0;
    else read_enable_r2 <= read_enable_r1;
  end

  assign read_enable_pos = read_enable_r1 & ~read_enable_r2;
  assign rburst_req_nxt = (rfifo_wdata_cnt + 1'b1 <= (512 - 128)) & ~ddr_read_ov_nxt & rready_i & read_enable_r2;

  always @(posedge ui_clock or negedge core_resetn)
    if (!core_resetn) rburst_req_r1 <= 1'b0;
    else rburst_req_r1 <= rburst_req_nxt;

  assign rburst_req_o = rburst_req_r1;

  assign empty_rspace_128bit = (rend_addr_i - rburst_addr_o) >> 4;
  assign ddr_rcycle_last = empty_rspace_128bit <= 128;
  assign ddr_read_under = ddr_read_cnt[31:4] < 128;
  assign rburst_len_nxt = (rburst_req_nxt & ~rburst_req_r1) ? (ddr_rcycle_last ? empty_rspace_128bit : ddr_read_under ? ddr_read_cnt[31:4] : 9'd128) : rburst_len_r1;
  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) rburst_len_r1 <= 9'b0;
    else rburst_len_r1 <= rburst_len_nxt;
  end

  assign ddr_rloop_nxt = (rburst_req_nxt & ~rburst_req_r1) ? ddr_rcycle_last : (~rburst_req_nxt & rburst_req_r1) ? 1'b0 : ddr_rloop_r1;

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) ddr_rloop_r1 <= 1'b0;
    else ddr_rloop_r1 <= ddr_rloop_nxt;
  end

  assign rburst_addr_over = (~rburst_req_nxt & rburst_req_r1) & ddr_rloop_r1;

  assign rburst_addr_nxt = ((fifo_rreset_r1 & ~fifo_rreset_r2) | rburst_addr_over) ? rbegin_addr_i:
                             read_enable_pos ? rread_begin_addr_i :
                            (~rburst_req_nxt & rburst_req_r1) ? rburst_addr_r1 + (rburst_len_r1 << 4) : rburst_addr_r1;
  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) rburst_addr_r1 <= rbegin_addr_i;
    else rburst_addr_r1 <= rburst_addr_nxt;
  end

  assign rburst_addr_o = rburst_addr_r1;


  assign ddr_read_value = rend_addr_i - rbegin_addr_i;
  assign ddr_read_cnt_nxt = (read_enable_pos | ~rone_time_en_i) ? ddr_read_value:
                            (~rburst_req_nxt & rburst_req_r1) ? ddr_read_cnt - (rburst_len_r1 << 4) : ddr_read_cnt;
  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) ddr_read_cnt <= 32'b0;
    else ddr_read_cnt <= ddr_read_cnt_nxt;
  end

  assign   ddr_read_ov_nxt = (rone_time_en_i & read_enable_r2 & ddr_read_cnt == 32'b0) | (~read_enable_pos & ddr_read_ov_r1);

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) ddr_read_ov_r1 <= 1'b0;
    else ddr_read_ov_r1 <= ddr_read_ov_nxt;
  end

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) ddr_rloop_r1 <= 1'b0;
    else ddr_rloop_r1 <= ddr_rloop_nxt;
  end

  always @(posedge ui_clock or negedge core_resetn) begin
    if (!core_resetn) rfifo_wen_r1 <= 1'b0;
    else rfifo_wen_r1 <= rfifo_wen_i;
  end

  assign rfifo_wen = rfifo_wen_r1 & rfifo_wen_i;

  write_fifo u_write_fifo (
      .Data(fifo_wdata_i),
      .WrReset(fifo_wreset || ui_reset),
      .RdReset(fifo_wreset || ui_reset),
      .WrClk(fifo_wclock),
      .RdClk(ui_clock),
      .WrEn(wfifo_wen_i),
      .RdEn(wfifo_ren_i),
      .Rnum(wfifo_rdata_cnt),
      .Q(wfifo_data_o),
      .Empty(),
      .Full()
  );
  read_fifo u_read_fifo (
      .Data(rfifo_data_i),
      .WrReset(fifo_rreset || ui_reset),
      .RdReset(fifo_rreset || ui_reset),
      .WrClk(ui_clock),
      .RdClk(fifo_rclock),
      .WrEn(rfifo_wen),
      .RdEn(rfifo_ren_i),
      .Wnum(rfifo_wdata_cnt),
      .Q(fifo_rdata_o),
      .Empty(rfifo_empty_o),
      .Full()
  );
endmodule
