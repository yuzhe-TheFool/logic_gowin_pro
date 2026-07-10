//==============================================================================
// File Name    : data_capture.v
// Module Name  : data_capture
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module data_capture (
    input             clock,
    input             resetn,
    input             sys_en_i,
    input             cons_mode_i,
    input             sample_en_i,
    input      [31:0] sample_depth_i,
    input      [31:0] trig_position_i,
    input             trig_en_i,
    input             trig_hit_i,
    output reg [31:0] trig_real_pos_o,
    output reg        capture_done_o,
    output reg [31:0] ddr_raddr_begin_o,
    output reg        capture_en_o,
    output reg [ 2:0] ddr_read_offset_o
);


  wire [31:0] sample_depth_cvalue;
  wire [31:0] sample_before_addr;
  wire [31:0] trig_position_cvalue;
  wire [31:0] after_trig_depth;
  wire        capture_done_nxt;
  reg         sample_en_r1;
  wire        sample_en_nxt;
  reg         sample_en_r2;
  reg         sample_en_r3;
  reg         sample_en_r4;
  reg         sample_en_r5;
  reg         sample_en_r6;
  wire        sample_en_pos;
  wire        sample_en_dly;
  wire        sample_en_pre;
  wire        trig_hit_nxt;
  reg         trig_hit_r1;
  wire        trig_hit_pos;
  reg         cycle0_r1;
  reg  [31:0] capture_cnt;
  wire        capture_cnt_over;
  wire        capture_cnt_cycle_ready;
  wire [31:0] capture_cnt_nxt;
  wire        capture_en_nxt;
  reg         set_before_real;
  wire        set_before_real_nxt;
  reg  [31:0] trig_real_start_addr;
  wire        trig_real_start_addr_over;
  wire [31:0] trig_real_start_addr_nxt;
  wire [31:0] ddr_raddr_begin_nxt;
  wire [ 2:0] ddr_read_offset_nxt;
  reg  [31:0] trig_real_pos_r1;
  wire [31:0] trig_real_pos_nxt;
  wire [31:0] trig_real_pos_updata;
  wire        cycle0_nxt;

  assign sample_depth_cvalue = sample_depth_i - 32'd1;
  assign sample_before_addr = (|trig_position_i) ? sample_depth_i - trig_position_i : 32'b0;
  assign trig_position_cvalue = (|trig_position_i) ? trig_position_i - 32'd1 : 32'b0;
  assign after_trig_depth = sample_depth_cvalue - trig_position_i;
  assign sample_en_nxt = ~(capture_done_nxt | capture_done_o) & sample_en_i & sys_en_i;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) sample_en_r1 <= 1'b0;
    else sample_en_r1 <= sample_en_nxt;
  end
  always @(posedge clock or negedge resetn) begin
    if (!resetn) sample_en_r2 <= 1'b0;
    else sample_en_r2 <= sample_en_r1;
  end
  always @(posedge clock or negedge resetn) begin
    if (!resetn) sample_en_r3 <= 1'b0;
    else sample_en_r3 <= sample_en_r2;
  end
  always @(posedge clock or negedge resetn) begin
    if (!resetn) sample_en_r4 <= 1'b0;
    else sample_en_r4 <= sample_en_r3;
  end
  always @(posedge clock or negedge resetn) begin
    if (!resetn) sample_en_r5 <= 1'b0;
    else sample_en_r5 <= sample_en_r4;
  end
  always @(posedge clock or negedge resetn) begin
    if (!resetn) sample_en_r6 <= 1'b0;
    else sample_en_r6 <= sample_en_r5;
  end

  assign sample_en_pos = sample_en_r4 & ~sample_en_r5;
  assign sample_en_dly = trig_en_i ? sample_en_r5 : sample_en_r2;
  assign sample_en_pre = trig_en_i ? sample_en_r4 : sample_en_r1;
  assign trig_hit_nxt  = trig_en_i & sample_en_dly & trig_hit_i;


  always @(posedge clock or negedge resetn) begin
    if (!resetn) trig_hit_r1 <= 1'b0;
    else trig_hit_r1 <= trig_hit_nxt;
  end

  assign trig_hit_pos = trig_hit_nxt & ~trig_hit_r1;

  assign capture_cnt_over = sample_en_dly & (capture_cnt == {sample_depth_cvalue[31:1], 1'b0});
  assign capture_cnt_cycle_ready = trig_hit_pos & ~(cycle0_r1 & (capture_cnt < trig_position_cvalue));
  assign capture_cnt_nxt = (capture_done_o | capture_cnt_over | capture_cnt_cycle_ready | cons_mode_i | (~sys_en_i)) ? 32'b0 :sample_en_dly ? capture_cnt + 32'd2 : capture_cnt;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) capture_cnt <= 32'b0;
    else capture_cnt <= capture_cnt_nxt;
  end

  assign capture_en_nxt = ~(capture_done_nxt | capture_done_o) & sample_en_pre & sample_en_i & ~cons_mode_i & sys_en_i;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) capture_en_o <= 1'b0;
    else capture_en_o <= capture_en_nxt;
  end

  assign set_before_real_nxt =  ((trig_hit_pos & cycle0_r1 & (capture_cnt < trig_position_cvalue)) | (~capture_done_o & set_before_real)) & sys_en_i;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) set_before_real <= 1'b0;
    else set_before_real <= set_before_real_nxt;
  end

  assign trig_real_start_addr_over = ~trig_hit_nxt & (trig_real_start_addr == {sample_depth_cvalue[31:1],1'b0});
  assign trig_real_start_addr_nxt = sample_en_pos ? sample_before_addr : trig_real_start_addr_over ? 32'b0 : set_before_real ? 32'b0: (~trig_hit_nxt) ? trig_real_start_addr + 32'd2 : trig_real_start_addr;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) trig_real_start_addr <= 32'b0;
    else trig_real_start_addr <= trig_real_start_addr_nxt;
  end


  assign ddr_raddr_begin_nxt = (capture_done_o & (set_before_real | ~trig_hit_nxt)) ? 32'b0: capture_done_o ? {trig_real_start_addr[30:3],3'b0,1'b0} : ddr_raddr_begin_o;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) ddr_raddr_begin_o <= 32'b0;
    else ddr_raddr_begin_o <= ddr_raddr_begin_nxt;
  end

  assign ddr_read_offset_nxt = (capture_done_o & (set_before_real | ~trig_hit_nxt)) ? 3'b0 : capture_done_o ?  trig_real_start_addr[2:0] : ddr_read_offset_o;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) ddr_read_offset_o <= 3'b0;
    else ddr_read_offset_o <= ddr_read_offset_nxt;
  end

  assign trig_real_pos_nxt = ((~trig_en_i) | sample_en_pos | cons_mode_i | (~sys_en_i)) ? 32'b0 : (~trig_hit_nxt & (trig_real_pos_r1 < trig_position_i)) ? trig_real_pos_r1 + 32'd2 : trig_real_pos_r1;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) trig_real_pos_r1 <= 32'b0;
    else trig_real_pos_r1 <= trig_real_pos_nxt;
  end

  assign trig_real_pos_updata = ((~trig_en_i) | cons_mode_i) ? 32'b0: capture_done_o ? trig_real_pos_r1 : trig_real_pos_o;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) trig_real_pos_o <= 32'b0;
    else trig_real_pos_o <= trig_real_pos_updata;
  end

  assign cycle0_nxt = (capture_done_o | (~sys_en_i)) ? 1'b1 : ((sample_en_dly & (capture_cnt >= {trig_position_cvalue[31:1],1'b0}))) ? 1'b0 : cycle0_r1;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) cycle0_r1 <= 1'b1;
    else cycle0_r1 <= cycle0_nxt;
  end

  assign capture_done_nxt = (capture_done_o | cons_mode_i | (~sys_en_i)) ? 1'b0 :
                          ((~trig_en_i) &  sample_en_dly &  (capture_cnt == {sample_depth_cvalue[31:1],1'b0})) ? 1'b1 :
                          (trig_hit_nxt &  set_before_real &  (capture_cnt == {sample_depth_cvalue[31:1],1'b0})) ? 1'b1 :
                          (trig_hit_nxt &  (~set_before_real) & (capture_cnt == {after_trig_depth[31:1],1'b0})) ? 1'b1 :  capture_done_o;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) capture_done_o <= 1'b0;
    else capture_done_o <= capture_done_nxt;
  end

endmodule
