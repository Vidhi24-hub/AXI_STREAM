`timescale 1ns/1ps
module axi_stream_processor #(
    parameter DATA_WIDTH = 32)(
    input  wire                      aclk,
    input  wire                      aresetn,

  // AXI-Stream act as Slave (Input from Master)
    input  wire [DATA_WIDTH-1:0]     s_axis_tdata,
    input  wire                      s_axis_tvalid,
    output wire                      s_axis_tready,
    input  wire                      s_axis_tlast,
    input  wire [DATA_WIDTH/8-1:0]   s_axis_tkeep,
    input  wire [DATA_WIDTH/8-1:0]   s_axis_tstrb,

  // AXI-Stream act as Master (Output to Slave)
    output reg  [DATA_WIDTH-1:0]     m_axis_tdata,
    output reg                       m_axis_tvalid,
    input  wire                      m_axis_tready,
    output reg                       m_axis_tlast,
    output reg  [DATA_WIDTH/8-1:0]   m_axis_tkeep,
    output reg  [DATA_WIDTH/8-1:0]   m_axis_tstrb,

    // AXI-Lite interface signals
    input  wire [1:0]                mode,          // 0 = passthrough, 1 = byte reverse, 2 = add
    input  wire [DATA_WIDTH-1:0]     add_value
);
  
  reg [DATA_WIDTH-1:0] reversed_data;
  integer i;  
  

  //reverse byte data for mode 2
  always@(*) begin
    reversed_data = 0;
    for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
      reversed_data[i*8 +: 8] = s_axis_tdata[(DATA_WIDTH-8) - (i*8) +: 8];
    end
  end

  always @(posedge aclk) 
    begin
      
      if (!aresetn) begin
        m_axis_tvalid <= 1'b0;
        m_axis_tdata  <= 'b0;
        m_axis_tlast  <= 1'b0;
        m_axis_tkeep  <= 'b0;
        m_axis_tstrb  <= 'b0;
    end 
      
      else if (s_axis_tvalid && m_axis_tready) begin
        m_axis_tvalid <= 1'b1;
        m_axis_tlast  <= s_axis_tlast;
        m_axis_tkeep  <= s_axis_tkeep;
        m_axis_tstrb  <= s_axis_tstrb;

        case (mode)          
          2'b00  : m_axis_tdata <= s_axis_tdata; 				// Pass-through
          2'b01  : m_axis_tdata <= reversed_data; 			    // Byte Reversal  
          2'b10  : m_axis_tdata <= s_axis_tdata + add_value;	// Add constant
          default: m_axis_tdata <= s_axis_tdata;
        endcase
      end 
      
      else if (m_axis_tready) begin 
        // Clear valid after handshake completes
        m_axis_tvalid <= 1'b0;
      end
      
      else begin
      // No valid transfer; clear valid signal and preserve last values
        m_axis_tvalid <= 1'b0;
        m_axis_tdata  <= 'bx;
        m_axis_tlast  <= 'bx;
        m_axis_tkeep  <= 'bx;
        m_axis_tstrb  <= 'bx;
      end
    end
  
  
  //backpressure handling
  assign s_axis_tready = m_axis_tready;

  
endmodule

