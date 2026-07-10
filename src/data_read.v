//==============================================================================
// File Name    : data_read.v
// Module Name  : data_read
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module data_read (
    input              sample_clock,
    input              resetn,
    input              rd_clock,
    input              sys_en_i,
    input              usb_wr_i,
    input              usb_ren_i,
    input              cons_mode_i,
    input              capture_done_i,
    input              rfifo_empty_i,
    input       [31:0] sample_data_i,
    input       [23:0] analyzer_prescale_i,
    input       [31:0] sample_depth_i,
    input       [31:0] trig_real_pos_i,
    input       [ 2:0] ddr_read_offset_i,
    input       [15:0] fifo_rdata_i,
    output wire [15:0] read_data_o,
    output wire        read_valid_o,
    output wire        rfifo_en_o,
    output wire        read_en_o
);


  reg          usb_wr_r1;
  wire         cons_channel2_sel;
  wire         cons_channel5_sel;
  wire         cons_channel8_sel;
  wire [  2:0] cons_ov_value;
  reg  [  2:0] cons_ov_cnt;
  wire [  2:0] cons_ov_cnt_nxt;
  wire         cons_ov;
  reg  [ 15:0] sample_data_r1;
  wire [ 15:0] sample_data_nxt;
  reg  [31:16] sample_hdata_r1;
  wire [31:16] sample_hdata_nxt;
  wire [ 31:0] sample_all_data_dly;
  reg          cons_fifo_wen_r1;
  reg          capture_done_r1;
  reg          read_en_r1;
  wire         read_done;
  wire         read_en_nxt;
  reg          rfifo_en_sync;
  reg          rfifo_en_sync_r1;
  wire [ 15:0] cons_rdata;
  wire         cons_empty;
  wire [ 14:0] rd_data_cnt;
  wire         rfifo_en_pos;
  wire         cons_valid;
  reg          header_read_r1;
  wire         header_read_done;
  wire         header_read_nxt;
  reg  [  7:0] header_cnt;
  wire [  7:0] header_cnt_nxt;
  wire [ 15:0] header_value;
  reg  [  2:0] nouse_cnt;
  wire         nouse_done;
  wire [  2:0] nouse_cnt_nxt;
  reg  [ 31:0] read_cnt;
  wire [ 31:0] read_cnt_nxt;
  reg          read_valid_r1;
  wire         read_Valid_nxt;
  reg  [ 15:0] read_data_r1;
  wire [ 15:0] read_data_nxt;

  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) usb_wr_r1 <= 1'b0;
    else usb_wr_r1 <= usb_wr_i;
  end

  assign cons_channel2_sel = analyzer_prescale_i < 24'd4;
  assign cons_channel5_sel = (analyzer_prescale_i >= 24'd4) & (analyzer_prescale_i < 24'd10);
  assign cons_channel8_sel = (analyzer_prescale_i >= 24'd10) & (analyzer_prescale_i < 24'd20);

  assign cons_ov_value = cons_channel2_sel ? 3'd7 : cons_channel5_sel ? 3'd2 : cons_channel8_sel ? 3'd1 : 3'd0;
  assign cons_ov = cons_ov_cnt == cons_ov_value;

  assign cons_ov_cnt_nxt = (~sys_en_i) ? 3'b0 : cons_ov ? 3'b0 : cons_mode_i ? cons_ov_cnt + 3'd1 : cons_ov_cnt;
  always @(posedge sample_clock or negedge resetn) begin
    if (!resetn) cons_ov_cnt <= 3'b0;
    else cons_ov_cnt <= cons_ov_cnt_nxt;
  end

  assign sample_data_nxt = cons_channel2_sel ? (cons_ov_cnt ==3'd0 ? {sample_data_r1[15:2], sample_data_i[1:0]}: 
                                                cons_ov_cnt ==3'd1 ? {sample_data_r1[15:4], sample_data_i[1:0],sample_data_r1[1:0]}: 
                                                cons_ov_cnt ==3'd2 ? {sample_data_r1[15:6], sample_data_i[1:0],sample_data_r1[3:0]}: 
                                                cons_ov_cnt ==3'd3 ? {sample_data_r1[15:8], sample_data_i[1:0],sample_data_r1[5:0]}: 
                                                cons_ov_cnt ==3'd4 ? {sample_data_r1[15:10], sample_data_i[1:0],sample_data_r1[7:0]}: 
                                                cons_ov_cnt ==3'd5 ? {sample_data_r1[15:12], sample_data_i[1:0],sample_data_r1[9:0]}: 
                                                cons_ov_cnt ==3'd6 ? {sample_data_r1[15:14], sample_data_i[1:0],sample_data_r1[11:0]}: 
                                                                     {sample_data_i[1:0],sample_data_r1[13:0]}):
                           cons_channel5_sel ? (cons_ov_cnt ==3'd0 ? {sample_data_r1[15:5], sample_data_i[4:0]}: 
                                                cons_ov_cnt ==3'd1 ? {sample_data_r1[15:10], sample_data_i[4:0],sample_data_r1[4:0]}: 
                                                                     {1'b0,sample_data_i[4:0],sample_data_r1[9:0]}): 
                           cons_channel8_sel ? (cons_ov_cnt ==3'd0 ? {sample_data_r1[15:8], sample_data_i[7:0]}: 
                                                                     {sample_data_i[7:0],sample_data_r1[7:0]}): 
                                                                     sample_data_i[15:0];
  always @(posedge sample_clock or negedge resetn) begin
    if (!resetn) sample_data_r1 <= 16'b0;
    else sample_data_r1 <= sample_data_nxt;
  end

  assign sample_hdata_nxt = cons_channel2_sel ? (cons_ov_cnt ==3'd0 ? {sample_hdata_r1[31:18], sample_data_i[17:16]}: 
                                                cons_ov_cnt ==3'd1 ? {sample_hdata_r1[31:20], sample_data_i[17:16],sample_hdata_r1[17:16]}: 
                                                cons_ov_cnt ==3'd2 ? {sample_hdata_r1[31:22], sample_data_i[17:16],sample_hdata_r1[19:16]}: 
                                                cons_ov_cnt ==3'd3 ? {sample_hdata_r1[31:24], sample_data_i[17:16],sample_hdata_r1[21:16]}: 
                                                cons_ov_cnt ==3'd4 ? {sample_hdata_r1[31:26], sample_data_i[17:16],sample_hdata_r1[23:16]}: 
                                                cons_ov_cnt ==3'd5 ? {sample_hdata_r1[31:28], sample_data_i[17:16],sample_hdata_r1[25:16]}: 
                                                cons_ov_cnt ==3'd6 ? {sample_hdata_r1[31:30], sample_data_i[17:16],sample_hdata_r1[27:16]}: 
                                                                     {sample_data_i[17:16],sample_hdata_r1[29:16]}):
                           cons_channel5_sel ? (cons_ov_cnt ==3'd0 ? {sample_hdata_r1[31:21], sample_data_i[20:16]}: 
                                                cons_ov_cnt ==3'd1 ? {sample_hdata_r1[31:26], sample_data_i[20:16],sample_hdata_r1[20:16]}: 
                                                                     {1'b0,sample_data_i[20:16],sample_hdata_r1[25:16]}): 
                           cons_channel8_sel ? (cons_ov_cnt ==3'd0 ? {sample_hdata_r1[31:24], sample_data_i[23:16]}: 
                                                                     {sample_data_i[23:16],sample_hdata_r1[23:16]}): 
                                                                      sample_data_i[31:16];
  always @(posedge sample_clock or negedge resetn) begin
    if (!resetn) sample_hdata_r1 <= 16'b0;
    else sample_hdata_r1 <= sample_hdata_nxt;
  end

  assign sample_all_data_dly = {sample_hdata_r1, sample_data_r1};

  always @(posedge sample_clock or negedge resetn) begin
    if (!resetn) cons_fifo_wen_r1 <= 1'b0;
    else cons_fifo_wen_r1 <= cons_ov;
  end

  always @(posedge sample_clock or negedge resetn) begin
    if (!resetn) capture_done_r1 <= 1'b0;
    else capture_done_r1 <= capture_done_i;
  end

  assign read_en_nxt = sys_en_i & (cons_mode_i | (capture_done_r1 | ((~read_done) & read_en_r1)));

  always @(posedge sample_clock or negedge resetn) begin
    if (!resetn) read_en_r1 <= 1'b0;
    else read_en_r1 <= read_en_nxt;
  end

  assign read_en_o = read_en_r1;

  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) rfifo_en_sync <= 1'b0;
    else rfifo_en_sync <= read_en_r1;
  end

  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) rfifo_en_sync_r1 <= 1'b0;
    else rfifo_en_sync_r1 <= rfifo_en_sync;
  end

  cons_fifo u_cons_fifo (
      .Data(sample_all_data_dly),
      .WrReset(~sys_en_i),
      .RdReset(~sys_en_i),
      .WrClk(sample_clock),
      .RdClk(rd_clock),
      .WrEn(cons_fifo_wen_r1),
      .RdEn((rfifo_en_sync_r1 & ~cons_empty & cons_mode_i & usb_wr_r1 & usb_ren_i)),
      .Q(cons_rdata),
      .Rnum(rd_data_cnt),
      .Empty(cons_empty),
      .Full()
  );

  assign rfifo_en_pos = rfifo_en_sync & ~rfifo_en_sync_r1;
  assign cons_valid = rd_data_cnt >= 15'd256;
  assign header_read_nxt = sys_en_i & (rfifo_en_pos | (~header_read_done & header_read_r1));

  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) header_read_r1 <= 1'b0;
    else header_read_r1 <= header_read_nxt;
  end

  assign header_cnt_nxt = (rfifo_en_pos | (~sys_en_i)) ? 8'b0: (header_read_nxt & (~header_read_done) & usb_wr_r1 & usb_ren_i) ? header_cnt + 8'd1 : header_cnt;

  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) header_cnt <= 8'b0;
    else header_cnt <= header_cnt_nxt;
  end

  assign header_read_done = header_cnt == 8'd255;
  assign header_value = header_cnt_nxt[0] ? trig_real_pos_i[31:16] : trig_real_pos_i[15:0];
  assign nouse_done = nouse_cnt == ddr_read_offset_i;
  assign nouse_cnt_nxt = (rfifo_en_pos | (~sys_en_i)) ? 2'b0: ((~rfifo_empty_i) & (~nouse_done)) ? nouse_cnt + 3'd1 : nouse_cnt;

  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) nouse_cnt <= 3'b0;
    else nouse_cnt <= nouse_cnt_nxt;
  end

  assign header_read_done = header_cnt == 8'd255;

  assign rfifo_en_o = rfifo_en_sync_r1 & ~rfifo_empty_i & ((~cons_mode_i & header_read_done & usb_wr_r1 & usb_ren_i) | (~nouse_done));
  assign read_cnt_nxt = (rfifo_en_pos | (~sys_en_i)) ? 32'b0:
                        (rfifo_en_sync_r1 & header_read_done & (~rfifo_empty_i) & usb_wr_r1 & usb_ren_i) ? read_cnt + 32'd1 : read_cnt;
  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) read_cnt <= 32'b0;
    else read_cnt <= read_cnt_nxt;
  end

  assign read_done = read_cnt == sample_depth_i + 32'd7000;
  assign Read_over = read_cnt >= sample_depth_i - 32'd8;


  assign read_Valid_nxt = (header_read_r1 & (~cons_mode_i)) ? 1'b1:
                          cons_mode_i ? ((rfifo_en_sync_r1 & cons_valid) ? 1'b1 : 1'b0):
                         ((~rfifo_en_sync_r1) | (rfifo_empty_i &  (~Read_over))) ? 1'b0:
                         (|ddr_read_offset_i) ? (nouse_done & (read_cnt <= (sample_depth_i + 32'd7000 - 4'd8 + ddr_read_offset_i))): 
                          (read_cnt <= sample_depth_i + 32'd7000) & (read_cnt > 32'b0);

  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) read_valid_r1 <= 1'b0;
    else read_valid_r1 <= read_Valid_nxt;
  end
  assign read_valid_o = read_valid_r1;


  assign read_data_nxt = (header_read_nxt & (~cons_mode_i)) ? header_value: 
                         (cons_mode_i & usb_ren_i) ? cons_rdata:
                         ((~cons_mode_i) & usb_ren_i) ? fifo_rdata_i : read_data_r1;
  always @(posedge rd_clock or negedge resetn) begin
    if (!resetn) read_data_r1 <= 16'b0;
    else read_data_r1 <= read_data_nxt;
  end

  assign read_data_o = read_data_r1;

endmodule
