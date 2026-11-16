`default_nettype none
module axi4_dma #(parameter ADDR_W=16, DATA_W=32) (
  input wire clk, input wire rst_n, output reg irq,
  input wire [4:0] s_axil_awaddr, input wire s_axil_awvalid, output reg s_axil_awready,
  input wire [31:0] s_axil_wdata, input wire [3:0] s_axil_wstrb, input wire s_axil_wvalid, output reg s_axil_wready,
  output wire [1:0] s_axil_bresp, output reg s_axil_bvalid, input wire s_axil_bready,
  input wire [4:0] s_axil_araddr, input wire s_axil_arvalid, output reg s_axil_arready,
  output reg [31:0] s_axil_rdata, output wire [1:0] s_axil_rresp, output reg s_axil_rvalid, input wire s_axil_rready,
  output wire [3:0] m_axi_awid, output reg [ADDR_W-1:0] m_axi_awaddr, output wire [7:0] m_axi_awlen,
  output wire [2:0] m_axi_awsize, output wire [1:0] m_axi_awburst, output reg m_axi_awvalid, input wire m_axi_awready,
  output reg [DATA_W-1:0] m_axi_wdata, output wire [3:0] m_axi_wstrb, output wire m_axi_wlast, output reg m_axi_wvalid, input wire m_axi_wready,
  input wire [3:0] m_axi_bid, input wire [1:0] m_axi_bresp, input wire m_axi_bvalid, output reg m_axi_bready,
  output wire [3:0] m_axi_arid, output reg [ADDR_W-1:0] m_axi_araddr, output wire [7:0] m_axi_arlen,
  output wire [2:0] m_axi_arsize, output wire [1:0] m_axi_arburst, output reg m_axi_arvalid, input wire m_axi_arready,
  input wire [3:0] m_axi_rid, input wire [DATA_W-1:0] m_axi_rdata, input wire [1:0] m_axi_rresp, input wire m_axi_rlast, input wire m_axi_rvalid, output reg m_axi_rready
);
  assign s_axil_bresp=0; assign s_axil_rresp=0; assign m_axi_awid=0; assign m_axi_awlen=0; assign m_axi_awsize=3'b010; assign m_axi_awburst=2'b01;
  assign m_axi_wstrb=4'hF; assign m_axi_wlast=1; assign m_axi_arid=0; assign m_axi_arlen=0; assign m_axi_arsize=3'b010; assign m_axi_arburst=2'b01;
  reg [ADDR_W-1:0] src_r, dst_r; reg [15:0] len_r, rem_r; reg go, done; reg [2:0] st;
  localparam IDLE=0, RDA=1, RDD=2, WRA=3, WRB=4;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s_axil_awready<=0; s_axil_wready<=0; s_axil_bvalid<=0; s_axil_arready<=0; s_axil_rvalid<=0; s_axil_rdata<=0; src_r<=0; dst_r<=0; len_r<=0; go<=0; end
    else begin
      go<=0; s_axil_awready<=(!s_axil_awready && s_axil_awvalid && s_axil_wvalid && !s_axil_bvalid); s_axil_wready<=(!s_axil_wready && s_axil_awvalid && s_axil_wvalid && !s_axil_bvalid);
      if (s_axil_awready && s_axil_awvalid && s_axil_wready && s_axil_wvalid) begin
        case (s_axil_awaddr[4:2]) 3'd0: go<=s_axil_wdata[0]; 3'd2: src_r<=s_axil_wdata[ADDR_W-1:0]; 3'd3: dst_r<=s_axil_wdata[ADDR_W-1:0]; 3'd4: len_r<=s_axil_wdata[15:0]; endcase
        s_axil_bvalid<=1;
      end else if (s_axil_bvalid && s_axil_bready) s_axil_bvalid<=0;
      s_axil_arready<=(!s_axil_arready && s_axil_arvalid && !s_axil_rvalid);
      if (s_axil_arready && s_axil_arvalid) begin
        case (s_axil_araddr[4:2]) 3'd1: s_axil_rdata<={30'd0,(st!=IDLE),done}; 3'd2: s_axil_rdata<={{(32-ADDR_W){1'b0}},src_r}; 3'd3: s_axil_rdata<={{(32-ADDR_W){1'b0}},dst_r}; 3'd4: s_axil_rdata<={16'd0,len_r}; default: s_axil_rdata<=32'h444D4131; endcase
        s_axil_rvalid<=1;
      end else if (s_axil_rvalid && s_axil_rready) s_axil_rvalid<=0;
    end
  end
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin st<=IDLE; done<=0; irq<=0; rem_r<=0; m_axi_arvalid<=0; m_axi_araddr<=0; m_axi_rready<=0; m_axi_awvalid<=0; m_axi_awaddr<=0; m_axi_wvalid<=0; m_axi_wdata<=0; m_axi_bready<=0; end
    else case (st)
      IDLE: if (go && len_r!=0) begin done<=0; irq<=0; m_axi_araddr<=src_r; m_axi_awaddr<=dst_r; rem_r<=len_r; st<=RDA; end
      RDA: begin m_axi_arvalid<=1; if (m_axi_arvalid && m_axi_arready) begin m_axi_arvalid<=0; m_axi_rready<=1; st<=RDD; end end
      RDD: if (m_axi_rvalid && m_axi_rready) begin m_axi_rready<=0; m_axi_awvalid<=1; m_axi_wvalid<=1; m_axi_wdata<=m_axi_rdata; st<=WRA; end
      WRA: begin if (m_axi_awvalid && m_axi_awready) m_axi_awvalid<=0; if (m_axi_wvalid && m_axi_wready) m_axi_wvalid<=0; if ((!m_axi_awvalid||m_axi_awready)&&(!m_axi_wvalid||m_axi_wready)) begin m_axi_bready<=1; st<=WRB; end end
      WRB: if (m_axi_bvalid && m_axi_bready) begin m_axi_bready<=0; if (rem_r==1) begin done<=1; irq<=1; st<=IDLE; end else begin rem_r<=rem_r-1; m_axi_araddr<=m_axi_araddr+4; m_axi_awaddr<=m_axi_awaddr+4; st<=RDA; end end
      default: st<=IDLE;
    endcase
  end
endmodule
`default_nettype wire
