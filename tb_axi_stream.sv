module tb_axi_stream;

reg clk = 0, resetn = 0;
always #5 clk = ~clk;

parameter DATA_WIDTH = 32;

reg [DATA_WIDTH-1:0] s_data;
reg s_valid, s_last;
reg [DATA_WIDTH/8-1:0] s_keep = 4'hF, s_strb = 4'hF;
wire s_ready;

wire [DATA_WIDTH-1:0] m_data;
wire m_valid, m_last;
reg  m_ready = 1;
wire [DATA_WIDTH/8-1:0] m_keep, m_strb;

reg [1:0] mode;
reg [DATA_WIDTH-1:0] add_value;

axi_stream #(.DATA_WIDTH(DATA_WIDTH)) dut (
    .aclk(clk),
    .aresetn(resetn),
    .s_axis_tdata(s_data),
    .s_axis_tvalid(s_valid),
    .s_axis_tready(s_ready),
    .s_axis_tlast(s_last),
    .s_axis_tkeep(s_keep),
    .s_axis_tstrb(s_strb),
    .m_axis_tdata(m_data),
    .m_axis_tvalid(m_valid),
    .m_axis_tready(m_ready),
    .m_axis_tlast(m_last),
    .m_axis_tkeep(m_keep),
    .m_axis_tstrb(m_strb),
    .mode(mode),
    .add_value(add_value)
);

initial begin
  
  //reset stimulus
  reset();

  //stimulus to check all three mode operations
  check_operation();
  
  //check if output drives garbage value or not incase of s_valid deasserted
  $display("s_valid deasserted");
  s_not_valid();  
  
  //check when slave is not ready to accept data before and after it will ready
  $display("m_ready deasserted");
  fork 
  m_ready = 0;
  check_operation();
    begin #200; m_ready = 1; $display($time); end
  join
  $display($time);  
    #100 $finish;
end


  //reset task
  task reset();
    @(negedge clk) resetn = 0;
    repeat(2) @(negedge clk); resetn = 1;
  endtask
    

  //mode operation task
  task check_operation;

    // Mode 0: Pass-through
    mode = 2'b00;
    send_data(32'hAABBCCDD, 1'b1);
    display();
    
    // Mode 1: Byte reversal
    mode = 2'b01;
    send_data(32'h12345678, 1'b1);
    display();
    
    // Mode 2: Add value
    mode = 2'b10;
    add_value = 32'h00000001;
    send_data(32'h00000010, 1'b1);
    display();
  endtask
    

  task send_data(input [DATA_WIDTH-1:0] data, input last);
    begin
      @(negedge clk);
      s_data  = data;
      s_valid = 1;
      s_last  = last;
      @(negedge clk);
     while (!s_ready) @(negedge clk);
      s_valid = 0;
    end
  endtask
  

  //task for s_valid is deasserted
  task s_not_valid;
        mode = 2'b10;
    add_value = 32'h00000001;
    svalid(32'h10110010, 1'b1);
    display();
  endtask
  

  task display();
    $display("s_data : %0b | m_data : %0b | mode : %d", s_data, m_data, mode);
  endtask
  

  task svalid(input [DATA_WIDTH-1:0] data, input last);
    begin
      @(negedge clk);
      s_data  = data;
      s_valid = 0;
      s_last  = last;
      @(negedge clk);
      while (!s_ready) @(negedge clk);
      s_valid = 0;
    end
  endtask

endmodule
