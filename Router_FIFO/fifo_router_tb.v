module fifo_router_tb;

  // Inputs
  reg clock = 1;
  reg resetn;
  reg soft_reset;
  reg write_enb;
  reg read_enb;
  reg lfd_state;
  reg [8:0] data_in;

  // Outputs
  wire [8:0] data_out;
  wire full;
  wire empty;

  // Instantiate the FIFO Router
  fifo_min_project dut (
    .clock(clock),
    .resetn(resetn),
    .soft_reset(soft_reset),
    .write_enb(write_enb),
    .read_enb(read_enb),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
  );

  // Clock Generation
  always #5 clock = ~clock;
  
   // VCD Files
    initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  // Tests
  initial begin
    // Testing resetn and soft_reset
    resetn <= 0;
    soft_reset <= 1;
    #10;
    resetn <= 1;
    soft_reset <= 0;
    #10;
    // Testing READ and WRITE
    write_enb = 1;
    read_enb = 0;
    data_in = 9'b000110101;
    #10;
    for (int i = 0; i < 20; i++)
      begin
        data_in = $random%512; 	// This can be tough to test
        						 	// unless we have a 
        						 	//self-testing testbench
       // data_in = 9'b101010100;
        #10;
      end
    write_enb = 0;
    #5;
    read_enb = 1;
    #220;
    read_enb = 0;
  end
  
  
  initial begin
    #450;
    $finish();
  end
  
  // Monitor
  always @(posedge clock) begin
    $display("FIFO State: Full=%b, Empty=%b, Counter=%b, write_enb=%b, data_in=%b, read_enb=%b, data_out=%b, rd_ptr=%b", full, empty, dut.fifo_counter, write_enb, /*lfd_state,*/ data_in, read_enb, data_out/*, dut.counter*/, dut.rd_ptr);
  end

endmodule
