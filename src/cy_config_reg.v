//==============================================================================
// File Name    : cy_config_reg.v
// Module Name  : cy_config_reg
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module cy_config_reg (
    input              usb_clock,
    input              sample_clock,
    input              resetn,
    input              usb_write_en_i,
    input              sys_en_i,
    input              ddr3_init_done_i,
    input              capture_done_i,
    output reg         sample_en_o,
    input       [ 7:0] usb_write_addr_i,
    input       [15:0] usb_write_data_i,
    output wire        trig_en_o,
    output wire        test_mode_o,
    output wire        cons_mode_o,
    output wire [23:0] sample_divider_o,
    output wire [31:0] sample_depth_o,
    output wire [31:0] trig_set_pos_o,

    output reg [15:0] tmask0_stage0_o,
    output reg [15:0] tvalue0_stage0_o,
    output reg [15:0] tedge0_stage0_o
);

  wire        usb_write0;
  wire        usb_write1;
  wire        usb_write2;
  wire        usb_write3;
  wire        usb_write4;
  wire        usb_write5;
  wire        usb_write6;
  wire        usb_write64;
  wire        usb_write66;
  wire        usb_write68;
  reg  [15:0] usb_cfg0_reg;
  wire [15:0] usb_cfg0_nxt;
  reg  [15:0] usb_cfg1_reg;
  wire [15:0] usb_cfg1_nxt;
  reg  [15:0] usb_cfg2_reg;
  wire [15:0] usb_cfg2_nxt;
  reg  [15:0] usb_cfg3_reg;
  wire [15:0] usb_cfg3_nxt;
  reg  [15:0] usb_cfg4_reg;
  wire [15:0] usb_cfg4_nxt;
  reg  [15:0] usb_cfg5_reg;
  wire [15:0] usb_cfg5_nxt;
  reg  [15:0] usb_cfg6_reg;
  wire [15:0] usb_cfg6_nxt;
  wire [15:0] tmask0_stage0_nxt;
  wire [15:0] tvalue0_stage0_nxt;
  wire [15:0] tedge0_stage0_nxt;
  reg         sys_en_r1;
  wire        sys_en_nxt;
  wire        sys_en_pos;
  wire        sys_en_neg;
  wire        sample_en_nxt;


  assign usb_write0   = usb_write_en_i & (usb_write_addr_i == 8'd0);
  assign usb_write1   = usb_write_en_i & (usb_write_addr_i == 8'd1);
  assign usb_write2   = usb_write_en_i & (usb_write_addr_i == 8'd2);
  assign usb_write3   = usb_write_en_i & (usb_write_addr_i == 8'd3);
  assign usb_write4   = usb_write_en_i & (usb_write_addr_i == 8'd4);
  assign usb_write5   = usb_write_en_i & (usb_write_addr_i == 8'd5);
  assign usb_write6   = usb_write_en_i & (usb_write_addr_i == 8'd6);
  assign usb_write64  = usb_write_en_i & (usb_write_addr_i == 8'd64);
  assign usb_write66  = usb_write_en_i & (usb_write_addr_i == 8'd66);
  assign usb_write68  = usb_write_en_i & (usb_write_addr_i == 8'd68);

  assign usb_cfg0_nxt = usb_write0 ? usb_write_data_i : usb_cfg0_reg;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg0_reg <= 16'b0;
    else usb_cfg0_reg <= usb_cfg0_nxt;
  end
  assign usb_cfg1_nxt = usb_write1 ? usb_write_data_i : usb_cfg1_reg;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg1_reg <= 16'd1;
    else usb_cfg1_reg <= usb_cfg1_nxt;
  end
  assign usb_cfg2_nxt = usb_write2 ? usb_write_data_i : usb_cfg2_reg;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg2_reg <= 16'b0;
    else usb_cfg2_reg <= usb_cfg2_nxt;
  end
  assign usb_cfg3_nxt = usb_write3 ? usb_write_data_i : usb_cfg3_reg;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg3_reg <= 16'b0;
    else usb_cfg3_reg <= usb_cfg3_nxt;
  end
  assign usb_cfg4_nxt = usb_write4 ? usb_write_data_i : usb_cfg4_reg;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg4_reg <= 16'b0;
    else usb_cfg4_reg <= usb_cfg4_nxt;
  end
  assign usb_cfg5_nxt = usb_write5 ? usb_write_data_i : usb_cfg5_reg;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg5_reg <= 16'b0;
    else usb_cfg5_reg <= usb_cfg5_nxt;
  end
  assign usb_cfg6_nxt = usb_write6 ? usb_write_data_i : usb_cfg6_reg;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg6_reg <= 16'b0;
    else usb_cfg6_reg <= usb_cfg6_nxt;
  end
  assign trig_en_o = usb_cfg0_reg[0];
  assign cons_mode_o = usb_cfg0_reg[12];
  assign test_mode_o = usb_cfg0_reg[15];
  assign sample_divider_o = {usb_cfg2_reg[7:0], usb_cfg1_reg};
  assign trig_set_pos_o = {usb_cfg6_reg, usb_cfg5_reg};
  assign  sample_depth_o = ((|trig_set_pos_o[2:0]) & trig_en_o) ? {usb_cfg4_reg,usb_cfg3_reg} + 32'd8 : {usb_cfg4_reg,usb_cfg3_reg};
  assign tmask0_stage0_nxt = usb_write64 ? usb_write_data_i : tmask0_stage0_o;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) tmask0_stage0_o <= 15'b0;
    else tmask0_stage0_o <= tmask0_stage0_nxt;
  end
  assign tvalue0_stage0_nxt = usb_write66 ? usb_write_data_i : tvalue0_stage0_o;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) tvalue0_stage0_o <= 15'b0;
    else tvalue0_stage0_o <= tvalue0_stage0_nxt;
  end
  assign tedge0_stage0_nxt = usb_write68 ? usb_write_data_i : tedge0_stage0_o;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) tedge0_stage0_o <= 15'b0;
    else tedge0_stage0_o <= tedge0_stage0_nxt;
  end

  assign sys_en_nxt = sys_en_i & ddr3_init_done_i;
  always @(posedge sample_clock or negedge resetn) begin
    if (!resetn) sys_en_r1 <= 1'b0;
    else sys_en_r1 <= sys_en_nxt;
  end
  assign sys_en_pos = sys_en_nxt & ~sys_en_r1;
  assign sys_en_neg = ~sys_en_nxt & sys_en_r1;

  assign sample_en_nxt = sys_en_pos | (~(capture_done_i | sys_en_neg) & sample_en_o);
  always @(posedge sample_clock or negedge resetn) begin
    if (!resetn) sample_en_o <= 1'b0;
    else sample_en_o <= sample_en_nxt;
  end

endmodule
