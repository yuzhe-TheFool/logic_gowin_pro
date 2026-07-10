//==============================================================================
// File Name    : sample_clock_gen.v
// Module Name  : sample_clock_gen
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module sample_clock_gen (
    input         clock,
    input         resetn,
    input  [23:0] analyzer_prescale_i,
(*DONT_TOUCH="yes"*)    output wire   sample_clock
);

  wire        sample_clock_sel = (analyzer_prescale_i == 24'd1);
  wire        prescale_ov;
  wire        prescale_half_ov;
  reg  [15:0] prescale_cnt;
  wire [15:0] prescale_cnt_nxt;

  assign prescale_cnt_nxt = prescale_ov ? 16'd1 : prescale_cnt + 16'd1;
  always @(posedge clock or negedge resetn) begin
    if (!resetn) prescale_cnt <= 16'd1;
    else prescale_cnt <= prescale_cnt_nxt;
  end

  assign prescale_ov = (prescale_cnt == analyzer_prescale_i);

  assign prescale_half_ov = (prescale_cnt == (analyzer_prescale_i >> 1));

  reg  sample_clock1;
  wire sample_clock1_nxt = (prescale_ov | prescale_half_ov) ? ~sample_clock1 : sample_clock1;

  always @(posedge clock or negedge resetn) begin
    if (!resetn) sample_clock1 <= 1'b0;
    else sample_clock1 <= sample_clock1_nxt;
  end

  assign sample_clock = sample_clock_sel ? clock : sample_clock1;
endmodule
