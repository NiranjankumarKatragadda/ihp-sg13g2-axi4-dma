`default_nettype none
module chip_core #(
  parameter NUM_INPUT_PADS=10, parameter NUM_OUTPUT_PADS=8,
  parameter NUM_BIDIR_PADS=8, parameter NUM_ANALOG_PADS=8
)(
  input logic clk, input logic rst_n,
  input wire [NUM_INPUT_PADS-1:0] input_in, output wire [NUM_OUTPUT_PADS-1:0] output_out,
  input wire [NUM_BIDIR_PADS-1:0] bidir_in, output wire [NUM_BIDIR_PADS-1:0] bidir_out,
  output wire [NUM_BIDIR_PADS-1:0] bidir_oe, inout wire [NUM_ANALOG_PADS-1:0] analog
);
  assign bidir_oe = 8'hFF;
  wire _unused = &{analog, input_in[7:5]};
  wire wr_en = input_in[9], rd_en = input_in[8];
  wire [4:0] csr_addr = input_in[4:0];
  wire [31:0] csr_wdata = {24'd0, bidir_in};
  wire irq, awr, wr, bv, arr, rv; wire [31:0] rdata;
  wire [15:0] m_awaddr, m_araddr; wire [31:0] m_wdata;
  wire m_awvalid, m_wvalid, m_bready, m_arvalid, m_rready;
  reg [31:0] mem [0:15]; reg m_bvalid, m_rvalid; reg [31:0] m_rdata;
  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_bvalid <= 0; m_rvalid <= 0; m_rdata <= 0;
      for (i=0; i<16; i=i+1) mem[i] <= 32'hA5A50000 + i;
    end else begin
      if (m_awvalid && m_wvalid && !m_bvalid) begin mem[m_awaddr[5:2]] <= m_wdata; m_bvalid <= 1; end
      else if (m_bvalid && m_bready) m_bvalid <= 0;
      if (m_arvalid && !m_rvalid) begin m_rdata <= mem[m_araddr[5:2]]; m_rvalid <= 1; end
      else if (m_rvalid && m_rready) m_rvalid <= 0;
    end
  end
  axi4_dma #(.ADDR_W(16), .DATA_W(32)) u_dma (
    .clk(clk), .rst_n(rst_n), .irq(irq),
    .s_axil_awaddr(csr_addr), .s_axil_awvalid(wr_en), .s_axil_awready(awr),
    .s_axil_wdata(csr_wdata), .s_axil_wstrb(4'hF), .s_axil_wvalid(wr_en), .s_axil_wready(wr),
    .s_axil_bresp(), .s_axil_bvalid(bv), .s_axil_bready(1'b1),
    .s_axil_araddr(csr_addr), .s_axil_arvalid(rd_en), .s_axil_arready(arr),
    .s_axil_rdata(rdata), .s_axil_rresp(), .s_axil_rvalid(rv), .s_axil_rready(1'b1),
    .m_axi_awid(), .m_axi_awaddr(m_awaddr), .m_axi_awlen(), .m_axi_awsize(), .m_axi_awburst(),
    .m_axi_awvalid(m_awvalid), .m_axi_awready(1'b1), .m_axi_wdata(m_wdata), .m_axi_wstrb(), .m_axi_wlast(),
    .m_axi_wvalid(m_wvalid), .m_axi_wready(1'b1), .m_axi_bid(4'd0), .m_axi_bresp(2'b00),
    .m_axi_bvalid(m_bvalid), .m_axi_bready(m_bready), .m_axi_arid(), .m_axi_araddr(m_araddr),
    .m_axi_arlen(), .m_axi_arsize(), .m_axi_arburst(), .m_axi_arvalid(m_arvalid), .m_axi_arready(1'b1),
    .m_axi_rid(4'd0), .m_axi_rdata(m_rdata), .m_axi_rresp(2'b00), .m_axi_rlast(1'b1),
    .m_axi_rvalid(m_rvalid), .m_axi_rready(m_rready)
  );
  assign output_out = rdata[7:0];
  assign bidir_out  = {5'd0, rv, bv, irq};
endmodule
`default_nettype wire
