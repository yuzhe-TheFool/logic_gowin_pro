//==============================================================================
// File Name    : logic_top.v
// Module Name  : logic_top
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-identifier: GPL-3.0-or-later
//==============================================================================
module logic_top (
    input              clock,
    input              resetn,
    input       [15:0] con_data_i,
    inout              d0_io,
    inout              d1_io,
    inout              d2_io,
    inout              d3_io,
    inout              d4_io,
    inout              d5_io,
    inout              d6_io,
    inout              d7_io,
    inout              d8_io,
    inout              d9_io,
    inout              d10_io,
    inout              d11_io,
    inout              d12_io,
    inout              d13_io,
    inout              d14_io,
    inout              d15_io,
    input              ifclk_i,
    input              ctl0_i,
    input              ctl1_i,
    input              sys_en_i,
    output wire        data_valid_o,
    inout       [15:0] ddr3_dq,
    inout       [ 1:0] ddr3_dqs_n,
    inout       [ 1:0] ddr3_dqs_p,
    output wire [13:0] ddr3_addr,
    output wire [ 2:0] ddr3_ba,
    output wire        ddr3_ras_n,
    output wire        ddr3_cas_n,
    output wire        ddr3_we_n,
    output wire        ddr3_reset_n,
    output wire        ddr3_ck_p,
    output wire        ddr3_ck_n,
    output wire        ddr3_cke,
    output wire        ddr3_cs_n,
    output wire [ 1:0] ddr3_dm,
    output wire        ddr3_odt
);




  wire [15:0] ddr_read_data;
  wire [15:0] con_wdata;
  wire        ddr3_init_done;
  wire        ui_reset;
  wire        core_resetn;
  wire        sys_resetn;
  wire [15:0] tmask0_stage0;
  wire [15:0] tvalue0_stage0;
  wire [15:0] tedge0_stage0;
  wire        usb_write_en;
  wire [ 7:0] usb_write_addr;
  wire [15:0] usb_write_data;
  wire        capture_done;
  wire        sample_en;
  wire        trig_en;
  wire        cons_mode;
  wire [23:0] sample_divider;
  wire [31:0] sample_depth;
  wire [31:0] trig_set_pos;
  wire [31:0] sample_data;
  wire [15:0] fifo_rdata;
  wire [31:0] ddr_raddr_begin;
  wire [31:0] trig_real_pos;
  wire [ 2:0] ddr_read_offset;
  wire        sample_clock;
  wire        rfifo_empty;
  reg         sys_en_r1;
  reg         sys_en_r2;
  wire        clock_200m;

  Gowin_rPLL u_ddr_pll (
      .clkout(ddr3_clock),  // output clkout
      .lock  (pll_lock),    // output lock
      .clkin (clock)        //input clkin
  );

  Gowin_rPLL1 u_sample_pll (
      .clkout(clock_200m),  //output clkout
      .clkin(clock)  //input clkin
  );


  cy_config_decoder u_cy_config_decoder (
      .usb_clock       (ifclk_i),         // input
      .resetn          (sys_resetn1),     // input
      .usb_wr_i        (ctl0_i),          // input
      .usb_wen_i       (~ctl1_i),         // input
      .usb_data_i      (con_wdata),       // input16
      .usb_write_en_o  (usb_write_en),    // output
      .usb_write_addr_o(usb_write_addr),  // output8
      .usb_write_data_o(usb_write_data)   // output16      
  );


  cy_config_reg u_cy_config_reg (
      .usb_clock       (ifclk_i),
      .sample_clock    (sample_clock),
      .resetn          (sys_resetn1),
      .usb_write_en_i  (usb_write_en),
      .sys_en_i        (sys_en_r2),
      .ddr3_init_done_i(ddr3_init_done),
      .capture_done_i  (capture_done),
      .sample_en_o     (sample_en),
      .usb_write_addr_i(usb_write_addr),
      .usb_write_data_i(usb_write_data),
      .trig_en_o       (trig_en),
      .test_mode_o     (test_mode),
      .cons_mode_o     (cons_mode),
      .sample_divider_o(sample_divider),
      .sample_depth_o  (sample_depth),
      .trig_set_pos_o  (trig_set_pos),
      .tmask0_stage0_o (tmask0_stage0),
      .tvalue0_stage0_o(tvalue0_stage0),
      .tedge0_stage0_o (tedge0_stage0)
  );



  sample_trig u_sample_trig (
      .sample_clock    (sample_clock),
      .core_resetn     (sys_resetn1),
      .con_data_i      (con_data_i),
      .test_mode_i     (test_mode),
      .tmask0_stage0_i (tmask0_stage0),
      .tvalue0_stage0_i(tvalue0_stage0),
      .tedge0_stage0_i (tedge0_stage0),
      .sample_data_o   (sample_data),
      .sample_en_i     (sample_en),
      .trig_en_i       (trig_en),
      .trig_hit_o      (trig_Hit)
  );

  data_capture u_data_capture (
      .clock            (sample_clock),
      .resetn           (sys_resetn1),
      .sys_en_i         (sys_en_r2),
      .cons_mode_i      (cons_mode),
      .sample_en_i      (sample_en),
      .sample_depth_i   (sample_depth),
      .trig_position_i  (trig_set_pos),
      .trig_en_i        (trig_en),
      .trig_hit_i       (trig_Hit),
      .trig_real_pos_o  (trig_real_pos),
      .capture_done_o   (capture_done),
      .ddr_raddr_begin_o(ddr_raddr_begin),
      .capture_en_o     (capture_en),
      .ddr_read_offset_o(ddr_read_offset)
  );

  data_read u_data_read (
      .sample_clock       (sample_clock),
      .resetn             (sys_resetn1),
      .rd_clock           (ifclk_i),
      .sys_en_i           (sys_en_r2),
      .usb_wr_i           (ctl0_i),
      .usb_ren_i          (~ctl1_i),
      .cons_mode_i        (cons_mode),
      .capture_done_i     (capture_done),
      .rfifo_empty_i      (rfifo_empty),
      .sample_data_i      (sample_data),
      .analyzer_prescale_i(sample_divider),
      .trig_real_pos_i    (trig_real_pos),
      .sample_depth_i     (sample_depth),
      .ddr_read_offset_i  (ddr_read_offset),
      .fifo_rdata_i       (fifo_rdata),
      .read_valid_o       (data_valid_o),
      .read_data_o        (ddr_read_data),
      .rfifo_en_o         (rfifo_en),
      .read_en_o          (read_en)
  );

  sample_clock_gen u_sample_clock_gen (
      .clock              (clock_200m),
      .resetn             (sys_resetn1),
      .analyzer_prescale_i(sample_divider),
      .sample_clock       (sample_clock)
  );


  axi4_ddr_unit u_axi4_ddr_unit (
      .ddr3_clock        (ddr3_clock),
      .clock             (clock),
      .pll_lock          (pll_lock),
      .sys_resetn        (resetn),
      .core_resetn       (core_resetn),
      .ddr3_dq           (ddr3_dq),
      .ddr3_dqs_n        (ddr3_dqs_n),
      .ddr3_dqs_p        (ddr3_dqs_p),
      .ddr3_addr         (ddr3_addr),
      .ddr3_ba           (ddr3_ba),
      .ddr3_ras_n        (ddr3_ras_n),
      .ddr3_cas_n        (ddr3_cas_n),
      .ddr3_we_n         (ddr3_we_n),
      .ddr3_reset_n      (ddr3_reset_n),
      .ddr3_ck_p         (ddr3_ck_p),
      .ddr3_ck_n         (ddr3_ck_n),
      .ddr3_cke          (ddr3_cke),
      .ddr3_cs_n         (ddr3_cs_n),
      .ddr3_dm           (ddr3_dm),
      .ddr3_odt          (ddr3_odt),
      .wbegin_addr_i     (32'h0),
      .wend_addr_i       ({sample_depth[30:0], 1'b0}),
      .fifo_wclock       (sample_clock),
      .wfifo_wen_i       (capture_en),
      .fifo_wdata_i      (sample_data),
      .fifo_wreset       (~sys_en_r2),
      .rone_time_en_i    (1'b1),
      .rread_begin_addr_i(ddr_raddr_begin),
      .rbegin_addr_i     (32'b0),
      .rend_addr_i       ({sample_depth[30:0], 1'b0}),
      .fifo_rclock       (ifclk_i),
      .rfifo_ren_i       (rfifo_en),
      .fifo_rdata_o      (fifo_rdata),
      .fifo_rreset       (~sys_en_r2),
      .read_enable_i     (read_en),
      .ui_clock          (ui_clock),
      .ui_reset          (ui_reset),
      .ddr3_init_done_o  (ddr3_init_done),
      .rfifo_empty_o     (rfifo_empty)
  );



  assign con_wdata[0] = d0_io;
  assign d0_io = ctl0_i ? ddr_read_data[0] : 1'bz;

  assign con_wdata[1] = d1_io;
  assign d1_io = ctl0_i ? ddr_read_data[1] : 1'bz;

  assign con_wdata[2] = d2_io;
  assign d2_io = ctl0_i ? ddr_read_data[2] : 1'bz;

  assign con_wdata[3] = d3_io;
  assign d3_io = ctl0_i ? ddr_read_data[3] : 1'bz;

  assign con_wdata[4] = d4_io;
  assign d4_io = ctl0_i ? ddr_read_data[4] : 1'bz;

  assign con_wdata[5] = d5_io;
  assign d5_io = ctl0_i ? ddr_read_data[5] : 1'bz;

  assign con_wdata[6] = d6_io;
  assign d6_io = ctl0_i ? ddr_read_data[6] : 1'bz;

  assign con_wdata[7] = d7_io;
  assign d7_io = ctl0_i ? ddr_read_data[7] : 1'bz;

  assign con_wdata[8] = d8_io;
  assign d8_io = ctl0_i ? ddr_read_data[8] : 1'bz;

  assign con_wdata[9] = d9_io;
  assign d9_io = ctl0_i ? ddr_read_data[9] : 1'bz;

  assign con_wdata[10] = d10_io;
  assign d10_io = ctl0_i ? ddr_read_data[10] : 1'bz;

  assign con_wdata[11] = d11_io;
  assign d11_io = ctl0_i ? ddr_read_data[11] : 1'bz;

  assign con_wdata[12] = d12_io;
  assign d12_io = ctl0_i ? ddr_read_data[12] : 1'bz;

  assign con_wdata[13] = d13_io;
  assign d13_io = ctl0_i ? ddr_read_data[13] : 1'bz;

  assign con_wdata[14] = d14_io;
  assign d14_io = ctl0_i ? ddr_read_data[14] : 1'bz;

  assign con_wdata[15] = d15_io;
  assign d15_io = ctl0_i ? ddr_read_data[15] : 1'bz;


  assign core_resetn = resetn & ~ui_reset & ddr3_init_done;
  assign sys_resetn1 = resetn & ~ui_reset;


  always @(posedge sample_clock or negedge sys_resetn1) begin
    if (!sys_resetn1) sys_en_r1 <= 1'b0;
    else sys_en_r1 <= sys_en_i;
  end


  always @(posedge sample_clock or negedge sys_resetn1) begin
    if (!sys_resetn1) sys_en_r2 <= 1'b0;
    else sys_en_r2 <= sys_en_r1;
  end


endmodule
