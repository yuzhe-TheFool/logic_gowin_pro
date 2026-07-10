//==============================================================================
// File Name    : cy_config_decoder.v
// Module Name  : cy_config_decoder
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-Identifier: GPL-3.0-or-later
//==============================================================================
module cy_config_decoder (
    input              usb_clock,
    input              resetn,
    input              usb_wr_i,
    input              usb_wen_i,
    input       [15:0] usb_data_i,
    output wire        usb_write_en_o,
    output wire [ 7:0] usb_write_addr_o,
    output wire [15:0] usb_write_data_o
);


  localparam USBFX2S_IDLE = 4'd0;
  localparam USBFX2S_SYNC = 4'd1;
  localparam USBFX2S_HEADER = 4'd2;
  localparam USBFX2S_DATA = 4'd3;

  reg  [15:0] usb_data_r1;
  reg         usb_write_en;
  wire        usb_write_en_nxt;
  reg  [ 3:0] usbfx2_state;
  reg  [ 3:0] usbfx2_state_nxt;
  wire        cfgdata_done;
  reg         usb_head_get;
  reg         usb_data_cnt_en;
  reg  [ 7:0] usb_cfg_addr;
  wire [ 7:0] usb_cfg_addr_nxt;
  reg  [ 7:0] usb_cfg_length;
  wire [ 7:0] usb_cfg_length_nxt;
  reg  [ 7:0] usb_data_cnt;
  wire [ 7:0] usb_data_cnt_nxt;

  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_data_r1 <= 16'b0;
    else usb_data_r1 <= usb_data_i;
  end

  assign usb_write_en_nxt = ~usb_wr_i & usb_wen_i;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_write_en <= 1'b0;
    else usb_write_en <= usb_write_en_nxt;
  end


  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usbfx2_state <= USBFX2S_IDLE;
    else usbfx2_state <= usbfx2_state_nxt;
  end

  always @(*) begin
    case (usbfx2_state)
      USBFX2S_HEADER: begin
        if (usb_write_en) begin
          if (usb_data_r1 == 16'hfa5a) usbfx2_state_nxt = USBFX2S_IDLE;
          else usbfx2_state_nxt = USBFX2S_DATA;
        end else usbfx2_state_nxt = USBFX2S_HEADER;
      end
      USBFX2S_DATA: begin
        if (usb_write_en) begin
          if (usb_data_r1 == 16'hfa5a) usbfx2_state_nxt = USBFX2S_IDLE;
          else if (cfgdata_done) usbfx2_state_nxt = USBFX2S_HEADER;
          else usbfx2_state_nxt = USBFX2S_DATA;
        end else usbfx2_state_nxt = USBFX2S_DATA;
      end
      default: begin
        if (usb_write_en & (usb_data_r1 == 16'hf5a5)) usbfx2_state_nxt = USBFX2S_HEADER;
        else usbfx2_state_nxt = USBFX2S_IDLE;
      end
    endcase
  end

  always @(*) begin
    usb_head_get = 1'b0;
    usb_data_cnt_en = 1'b0;
    case (usbfx2_state)
      USBFX2S_HEADER: usb_head_get = usb_write_en & (usb_data_r1 != 16'hfa5a);
      USBFX2S_DATA:   usb_data_cnt_en = usb_write_en & (usb_data_r1 != 16'hfa5a);
      default: begin
        usb_head_get = 1'b0;
        usb_data_cnt_en = 1'b0;
      end
    endcase
  end


  assign usb_cfg_addr_nxt = usb_head_get ? usb_data_r1[15:8] : usb_cfg_addr;

  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg_addr <= 8'b0;
    else usb_cfg_addr <= usb_cfg_addr_nxt;
  end


  assign usb_cfg_length_nxt = usb_head_get ? (usb_data_r1[7:0] - 8'd1) : usb_cfg_length;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_cfg_length <= 8'b0;
    else usb_cfg_length <= usb_cfg_length_nxt;
  end

  assign usb_data_cnt_nxt = (usb_head_get | cfgdata_done) ? 8'b0 : usb_data_cnt_en ? usb_data_cnt + 8'd1 : usb_data_cnt;
  always @(posedge usb_clock or negedge resetn) begin
    if (!resetn) usb_data_cnt <= 8'b0;
    else usb_data_cnt <= usb_data_cnt_nxt;
  end

  assign cfgdata_done = (usb_data_cnt == usb_cfg_length);
  assign usb_write_en_o = usb_data_cnt_en;
  assign usb_write_addr_o = usb_cfg_addr + usb_data_cnt;
  assign usb_write_data_o = usb_data_r1;

endmodule
