`default_nettype none
module chip_core #(parameter NUM_INPUT_PADS=10, NUM_OUTPUT_PADS=8, NUM_BIDIR_PADS=8, NUM_ANALOG_PADS=8)(
  input logic clk, rst_n, input wire [9:0] input_in, output wire [7:0] output_out,
  input wire [7:0] bidir_in, output wire [7:0] bidir_out, output wire [7:0] bidir_oe, inout wire [7:0] analog
);
  assign bidir_oe=8'hFF; wire _u=&{analog,input_in[7:5]};
  wire irq,bv,rv,maw,mw,mb,mar,mr; wire [15:0] aw,ar; wire [31:0] rdata,mwdata;
  reg [31:0] mem[0:15], mrdata; reg mbv, mrv; integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin mbv<=0; mrv<=0; mrdata<=0; for(i=0;i<16;i=i+1) mem[i]<=32'hA5A50000+i; end
    else begin
      if (maw&&mw&&!mbv) begin mem[aw[5:2]]<=mwdata; mbv<=1; end else if (mbv&&mb) mbv<=0;
      if (mar&&!mrv) begin mrdata<=mem[ar[5:2]]; mrv<=1; end else if (mrv&&mr) mrv<=0;
    end
  end
  axi4_dma u_dma(.clk(clk),.rst_n(rst_n),.irq(irq),.s_axil_awaddr(input_in[4:0]),.s_axil_awvalid(input_in[9]),.s_axil_awready(),.s_axil_wdata({24'd0,bidir_in}),.s_axil_wstrb(4'hF),.s_axil_wvalid(input_in[9]),.s_axil_wready(),.s_axil_bresp(),.s_axil_bvalid(bv),.s_axil_bready(1'b1),.s_axil_araddr(input_in[4:0]),.s_axil_arvalid(input_in[8]),.s_axil_arready(),.s_axil_rdata(rdata),.s_axil_rresp(),.s_axil_rvalid(rv),.s_axil_rready(1'b1),.m_axi_awid(),.m_axi_awaddr(aw),.m_axi_awlen(),.m_axi_awsize(),.m_axi_awburst(),.m_axi_awvalid(maw),.m_axi_awready(1'b1),.m_axi_wdata(mwdata),.m_axi_wstrb(),.m_axi_wlast(),.m_axi_wvalid(mw),.m_axi_wready(1'b1),.m_axi_bid(4'd0),.m_axi_bresp(2'b00),.m_axi_bvalid(mbv),.m_axi_bready(mb),.m_axi_arid(),.m_axi_araddr(ar),.m_axi_arlen(),.m_axi_arsize(),.m_axi_arburst(),.m_axi_arvalid(mar),.m_axi_arready(1'b1),.m_axi_rid(4'd0),.m_axi_rdata(mrdata),.m_axi_rresp(2'b00),.m_axi_rlast(1'b1),.m_axi_rvalid(mrv),.m_axi_rready(mr));
  assign output_out=rdata[7:0]; assign bidir_out={5'd0,rv,bv,irq};
endmodule
`default_nettype wire
