//==============================================================================
// File Name    : axi4_ddr_unit.v
// Module Name  : axi4_ddr_unit
// Author       : TheFool
// Created Date : 2026-07-07
// SPDX-FileCopyrightText: 2026 TheFool
// SPDX-License-identifier: GPL-3.0-or-later
//==============================================================================
module axi4_ddr_unit (
    input              ddr3_clock,
    input              clock,
    input              pll_lock,
    input              sys_resetn,
    input              core_resetn,
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
    output wire        ddr3_odt,
    input       [31:0] wbegin_addr_i,
    input       [31:0] wend_addr_i,
    input              fifo_wclock,
    input              wfifo_wen_i,
    input       [31:0] fifo_wdata_i,
    input              fifo_wreset,
    input              rone_time_en_i,
    input       [31:0] rread_begin_addr_i,
    input       [31:0] rbegin_addr_i,
    input       [31:0] rend_addr_i,
    input              fifo_rclock,
    input              rfifo_ren_i,
    output wire [15:0] fifo_rdata_o,
    input              fifo_rreset,
    input              read_enable_i,
    output wire        ui_clock,
    output wire        ui_reset,
    output wire        ddr3_init_done_o,
    output wire        rfifo_empty_o
);



  wire [  3:0] axi4_awid;
  wire [ 31:0] axi4_awaddr;
  wire [  7:0] axi4_awlen;
  wire [  2:0] axi4_awsize;
  wire [  1:0] axi4_awburst;
  wire [  0:0] axi4_awlock;
  wire [  3:0] axi4_awcache;
  wire [  2:0] axi4_awprot;
  wire [  3:0] axi4_awqos;
  wire         axi4_awvalid;
  wire         axi4_awready;
  wire [127:0] axi4_wdata;
  wire [ 31:0] axi4_wstrb;
  wire         axi4_wlast;
  wire         axi4_wvalid;
  wire         axi4_wready;
  wire [  3:0] axi4_bid;
  wire [  1:0] axi4_bresp;
  wire         axi4_bvalid;
  wire         axi4_bready;
  wire [  3:0] axi4_arid;
  wire [ 31:0] axi4_araddr;
  wire [  7:0] axi4_arlen;
  wire [  2:0] axi4_arsize;
  wire [  1:0] axi4_arburst;
  wire         axi4_arlock;
  wire [  3:0] axi4_arcache;
  wire [  2:0] axi4_arprot;
  wire [  3:0] axi4_arqos;
  wire         axi4_arvalid;
  wire         axi4_arready;
  wire [  3:0] axi4_rid;
  wire [127:0] axi4_rdata;
  wire [  1:0] axi4_rresp;
  wire         axi4_rlast;
  wire         axi4_rvalid;
  wire         axi4_rready;

  wire         wr_start;
  wire [ 31:0] wr_addr;
  wire [  8:0] wr_len;
  wire         wr_wready;
  wire         wfifo_ren;
  wire [127:0] wfifo_data;
  wire         wburst_finish;
  wire         rd_start;
  wire [ 31:0] rd_addr;
  wire [  8:0] rd_len;
  wire         rd_rready;
  wire         rfifo_wen;
  wire [127:0] rfifo_data;
  wire         rburst_finish;


  axi4_control u_axi4_control (
      .ui_clock          (ui_clock),
      .ui_reset          (ui_reset),
      .core_resetn       (core_resetn),
      .wbegin_addr_i     (wbegin_addr_i),
      .wend_addr_i       (wend_addr_i),
      .fifo_wclock       (fifo_wclock),
      .wfifo_wen_i       (wfifo_wen_i),
      .fifo_wdata_i      (fifo_wdata_i),
      .fifo_wreset       (fifo_wreset),
      .rone_time_en_i    (rone_time_en_i),
      .rread_begin_addr_i(rread_begin_addr_i),
      .rbegin_addr_i     (rbegin_addr_i),
      .rend_addr_i       (rend_addr_i),
      .fifo_rclock       (fifo_rclock),
      .rfifo_ren_i       (rfifo_ren_i),
      .fifo_rdata_o      (fifo_rdata_o),
      .fifo_rreset       (fifo_rreset),
      .read_enable_i     (read_enable_i),
      .wburst_req_o      (wr_start),
      .wburst_addr_o     (wr_addr),
      .wburst_len_o      (wr_len),
      .wready_i          (wr_wready),
      .wfifo_ren_i       (wfifo_ren),
      .wfifo_data_o      (wfifo_data),
      .wburst_finish_i   (wburst_finish),
      .rburst_req_o      (rd_start),
      .rburst_addr_o     (rd_addr),
      .rburst_len_o      (rd_len),
      .rready_i          (rd_rready),
      .rfifo_wen_i       (rfifo_wen),
      .rfifo_data_i      (rfifo_data),
      .rburst_finish_i   (rburst_finish),
      .rfifo_empty_o     (rfifo_empty_o)
  );


  axi4_wcontrol u_axi4_wcontrol (
      .resetn        (core_resetn),
      .clock         (ui_clock),
      .axi4_awid_o   (axi4_awid),
      .axi4_awaddr_o (axi4_awaddr),
      .axi4_awlen_o  (axi4_awlen),
      .axi4_awsize_o (axi4_awsize),
      .axi4_awburst_o(axi4_awburst),
      .axi4_awlock_o (axi4_awlock),
      .axi4_awcache_o(axi4_awcache),
      .axi4_awprot_o (axi4_awprot),
      .axi4_awqos_o  (axi4_awqos),
      .axi4_awvalid_o(axi4_awvalid),
      .axi4_awready_i(axi4_awready),
      .axi4_wdata_o  (axi4_wdata),
      .axi4_wstrb_o  (axi4_wstrb),
      .axi4_wlast_o  (axi4_wlast),
      .axi4_wvalid_o (axi4_wvalid),
      .axi4_wready_i (axi4_wready),
      .axi4_bid_i    (axi4_bid),
      .axi4_bresp_i  (axi4_bresp),
      .axi4_bvalid_i (axi4_bvalid),
      .axi4_bready_o (axi4_bready),
      .wr_start_i    (wr_start),
      .wr_addr_i     (wr_addr),
      .wr_len_i      (wr_len),
      .wr_ready_o    (wr_wready),
      .wr_fifo_re_o  (wfifo_ren),
      .wr_fifo_data_i(wfifo_data),
      .wr_done_o     (wburst_finish)
  );


  axi4_rcontrol u_axi4_rcontrol (
      .resetn        (core_resetn),
      .clock         (ui_clock),
      .axi4_arid_o   (axi4_arid),
      .axi4_araddr_o (axi4_araddr),
      .axi4_arlen_o  (axi4_arlen),
      .axi4_arsize_o (axi4_arsize),
      .axi4_arburst_o(axi4_arburst),
      .axi4_arlock_o (axi4_arlock),
      .axi4_arcache_o(axi4_arcache),
      .axi4_arport_o (axi4_arprot),
      .axi4_arqos_o  (axi4_arqos),
      .axi4_arvalid_o(axi4_arvalid),
      .axi4_arready_i(axi4_arready),
      .axi4_rid_i    (axi4_rid),
      .axi4_rdata_i  (axi4_rdata),
      .axi4_rresp_i  (axi4_rresp),
      .axi4_rlast_i  (axi4_rlast),
      .axi4_rvalid_i (axi4_rvalid),
      .axi4_rready_o (axi4_rready),
      .rd_start_i    (rd_start),
      .rd_adddr_i    (rd_addr),
      .rd_len_i      (rd_len),
      .rd_ready_o    (rd_rready),
      .rd_fifo_we_o  (rfifo_wen),
      .rd_fifo_data_o(rfifo_data),
      .rd_done_o     (rburst_finish)
  );

  DDR3_Memory_Interface_Top u_ddr3_control (
      .clk(clock),  //input clk
      .memory_clk(ddr3_clock),  //input memory_clk
      .pll_lock(pll_lock),  //input pll_lock
      .rst_n(sys_resetn),  //input rst_n
      .clk_out(ui_clock),  //output clk_out
      .ddr_rst(ui_reset),  //output ddr_rst
      .init_calib_complete(ddr3_init_done_o),  //output init_calib_complete
      .s_axi_awvalid(axi4_awvalid),  //input s_axi_awvalid
      .s_axi_awready(axi4_awready),  //output s_axi_awready
      .s_axi_awid(axi4_awid),  //input [3:0] s_axi_awid
      .s_axi_awaddr(axi4_awaddr[27:0]),  //input [27:0] s_axi_awaddr
      .s_axi_awlen(axi4_awlen),  //input [7:0] s_axi_awlen
      .s_axi_awsize(axi4_awsize),  //input [2:0] s_axi_awsize
      .s_axi_awburst(axi4_awburst),  //input [1:0] s_axi_awburst
      .s_axi_wvalid(axi4_wvalid),  //input s_axi_wvalid
      .s_axi_wready(axi4_wready),  //output s_axi_wready
      .s_axi_wdata(axi4_wdata),  //input [127:0] s_axi_wdata
      .s_axi_wstrb(axi4_wstrb[15:0]),  //input [15:0] s_axi_wstrb
      .s_axi_wlast(axi4_wlast),  //input s_axi_wlast
      .s_axi_bvalid(axi4_bvalid),  //output s_axi_bvalid
      .s_axi_bready(axi4_bready),  //input s_axi_bready
      .s_axi_bresp(axi4_bresp),  //output [1:0] s_axi_bresp
      .s_axi_bid(axi4_bid),  //output [3:0] s_axi_bid
      .s_axi_arvalid(axi4_arvalid),  //input s_axi_arvalid
      .s_axi_arready(axi4_arready),  //output s_axi_arready
      .s_axi_arid(axi4_arid),  //input [3:0] s_axi_arid
      .s_axi_araddr(axi4_araddr[27:0]),  //input [27:0] s_axi_araddr
      .s_axi_arlen(axi4_arlen),  //input [7:0] s_axi_arlen
      .s_axi_arsize(axi4_arsize),  //input [2:0] s_axi_arsize
      .s_axi_arburst(axi4_arburst),  //input [1:0] s_axi_arburst
      .s_axi_rvalid(axi4_rvalid),  //output s_axi_rvalid
      .s_axi_rready(axi4_rready),  //input s_axi_rready
      .s_axi_rdata(axi4_rdata),  //output [127:0] s_axi_rdata
      .s_axi_rresp(axi4_rresp),  //output [1:0] s_axi_rresp
      .s_axi_rid(axi4_rid),  //output [3:0] s_axi_rid
      .s_axi_rlast(axi4_rlast),  //output s_axi_rlast
      .sr_req(1'b0),  //input sr_req
      .ref_req(1'b0),  //input ref_req
      .sr_ack(),  //output sr_ack
      .ref_ack(),  //output ref_ack
      .burst(1'b1),  //input burst
      .O_ddr_addr(ddr3_addr),  //output [13:0] O_ddr_addr
      .O_ddr_ba(ddr3_ba),  //output [2:0] O_ddr_ba
      .O_ddr_cs_n(ddr3_cs_n),  //output O_ddr_cs_n
      .O_ddr_ras_n(ddr3_ras_n),  //output O_ddr_ras_n
      .O_ddr_cas_n(ddr3_cas_n),  //output O_ddr_cas_n
      .O_ddr_we_n(ddr3_we_n),  //output O_ddr_we_n
      .O_ddr_clk(ddr3_ck_p),  //output O_ddr_clk
      .O_ddr_clk_n(ddr3_ck_n),  //output O_ddr_clk_n
      .O_ddr_cke(ddr3_cke),  //output O_ddr_cke
      .O_ddr_odt(ddr3_odt),  //output O_ddr_odt
      .O_ddr_reset_n(ddr3_reset_n),  //output O_ddr_reset_n
      .O_ddr_dqm(ddr3_dm),  //output [1:0] O_ddr_dqm
      .IO_ddr_dq(ddr3_dq),  //inout [15:0] IO_ddr_dq
      .IO_ddr_dqs(ddr3_dqs_p),  //inout [1:0] IO_ddr_dqs
      .IO_ddr_dqs_n(ddr3_dqs_n)  //inout [1:0] IO_ddr_dqs_n
  );

endmodule
