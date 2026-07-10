//==============================================================================
// File Name    : sample_trig.v
// Module Name  : sample_trig
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module sample_trig (
    input             sample_clock,
    input             core_resetn,
    input      [15:0] con_data_i,
    input             test_mode_i,
    input      [15:0] tmask0_stage0_i,
    input      [15:0] tvalue0_stage0_i,
    input      [15:0] tedge0_stage0_i,
    output reg [31:0] sample_data_o,
    input             sample_en_i,
    input             trig_en_i,
    output reg        trig_hit_o
);


  reg  [15:0] con_ldata_r1;
  wire [15:0] con_ldata_nxt;
  reg  [15:0] con_hdata_r1;
  wire [15:0] con_hdata_nxt;
  wire [31:0] sample_tdata_dly;
  wire [31:0] Sample_rddata_r1;
  reg         trig_all_match;
  wire        trig_hit_nxt;
  reg         sample_en_r1;
  wire        sample_en_pos;
  wire        sample_en_neg;
  wire        trig_hit_pos;
  wire [31:0] sample_data_nxt;
  reg  [31:0] pre_cmp_data;
  wire [31:0] cur_edge;
  wire        trig0_match_low;
  wire        trig0_match_high;
  wire        trig0_match_nxt;
  reg         match_stages_valid;
  wire        match_stages_valid_nxt;
  reg         trig_hit_r1;

  assign con_ldata_nxt = (~sample_en_i) ? 16'b0 : con_ldata_r1 + 16'd2;

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) con_ldata_r1 <= 16'b0;
    else con_ldata_r1 <= con_ldata_nxt;
  end

  assign con_hdata_nxt = (~sample_en_i) ? 16'd1 : con_hdata_r1 + 16'd2;

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) con_hdata_r1 <= 16'd1;
    else con_hdata_r1 <= con_hdata_nxt;
  end

  assign sample_tdata_dly = {con_hdata_r1, con_ldata_r1};


  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : gen_sample
      IDDR iddr (
          .Q0 (Sample_rddata_r1[i]),
          .Q1 (Sample_rddata_r1[i+16]),
          .D  (con_data_i[i]),
          .CLK(sample_clock)
      );
      defparam iddr.Q0_INIT = 1'b0; defparam iddr.Q1_INIT = 1'b0;
    end
  endgenerate

  wire [31:0] sample_ddata_nxt = test_mode_i ? sample_tdata_dly : Sample_rddata_r1;


  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) sample_en_r1 <= 1'b0;
    else sample_en_r1 <= sample_en_i;
  end

  assign sample_en_pos = sample_en_i & ~sample_en_r1;
  assign sample_en_neg = ~sample_en_i & sample_en_r1;


  reg [31:0] cur_cmp_data;

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) cur_cmp_data <= 32'b0;
    else cur_cmp_data <= sample_ddata_nxt;
  end

  reg [31:0] cur_cmp_data_r1;

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) cur_cmp_data_r1 <= 32'b0;
    else cur_cmp_data_r1 <= cur_cmp_data;
  end

  reg [31:0] cur_cmp_data_r2;

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) cur_cmp_data_r2 <= 32'b0;
    else cur_cmp_data_r2 <= cur_cmp_data_r1;
  end

  assign sample_data_nxt = trig_en_i ? cur_cmp_data_r2 : sample_ddata_nxt;

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) sample_data_o <= 32'b0;
    else sample_data_o <= sample_data_nxt;
  end

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) pre_cmp_data <= 32'b0;
    else pre_cmp_data <= cur_cmp_data;
  end

  assign cur_edge = cur_cmp_data ^ pre_cmp_data;


  assign trig0_match_low = (~|(((cur_cmp_data[15:0] ^ tvalue0_stage0_i) & ~tmask0_stage0_i) | 
                             (tedge0_stage0_i & ~cur_edge[15:0])));
  assign trig0_match_high = (~|(((cur_cmp_data[31:16] ^ tvalue0_stage0_i) & ~tmask0_stage0_i) | 
                             (tedge0_stage0_i & ~cur_edge[31:16])));
  assign trig0_match_nxt = sample_en_r1 & (trig0_match_low | trig0_match_high);

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) trig_all_match <= 1'b0;
    else trig_all_match <= trig0_match_nxt;
  end

  assign   match_stages_valid_nxt = sample_en_neg ? 1'b0 : (trig_all_match & sample_en_i) ? 1'b1 : match_stages_valid;

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) match_stages_valid <= 1'b0;
    else match_stages_valid <= match_stages_valid_nxt;
  end


  assign     trig_hit_nxt = sample_en_neg ? 1'b0 : (sample_en_pos & (~trig_en_i)) ? 1'b1 : (sample_en_i & match_stages_valid) ? 1'b1: trig_hit_o;
  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) trig_hit_o <= 1'b0;
    else trig_hit_o <= trig_hit_nxt;
  end

  always @(posedge sample_clock or negedge core_resetn) begin
    if (!core_resetn) trig_hit_r1 <= 1'b0;
    else trig_hit_r1 <= trig_hit_o;
  end

  assign trig_hit_pos = trig_hit_o & ~trig_hit_r1;

endmodule

