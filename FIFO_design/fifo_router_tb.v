module fifo_router_tb;

  // Parameters
  parameter width = 8;
  parameter depth = 16;

  // Inputs
  reg clock = 0;
  reg resetn;
  reg soft_reset;
  reg write_enb;
  reg read_enb;
  reg lfd_state;
  reg [width-1:0] data_in;

  // Outputs
  wire [width-1:0] data_out;
  wire full;
  wire empty;

  // Instantiate the FIFO Router
  fifo_router #(
    .width(width),
    .depth(depth)
  ) dut (
    .clock(clock),
    .resetn(resetn),
    .soft_reset(soft_reset),
    .write_enb(write_enb),
    .read_enb(read_enb),
    .lfd_state(lfd_state),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
  );

  // Clock Generation
  always #5 clock = ~clock;
  
    // VCD Files
   // initial begin
   // $dumpfile("dump.vcd");
   // $dumpvars(1);
  //end

  // Initialize Inputs
  initial begin
    resetn = 0;
    soft_reset = 1;
    write_enb = 0;
    read_enb = 0;
    lfd_state = 0;
    data_in = 0;
    #10;
    resetn = 1; // Release reset
    #50;
    soft_reset = 0; // Deactivate soft reset
  end

  // Stimulus
  initial begin
    // Test 1: Write some data into FIFO
    write_enb = 1;
    data_in = 8'b10101010;
    #50;
    write_enb = 1;

    // Test 2: Read data from FIFO
    read_enb = 1;
    #30;
    read_enb = 1;

    // Test 3: Test time-out feature
    lfd_state = 1; // Enable time-out
    data_in = $urandom%256; // Load 6 MSBs of timer, LSB doesn't matter for now
    #50;
    data_in = $urandom%256; // Reload the timer (counter_load)
    #120; // Wait for some clock cycles
    lfd_state = 1; // Disable time-out
    #200;

    // Test 4: Fill the FIFO
    for (int i = 0; i < depth; i = i + 1) begin
      write_enb = 1;
      lfd_state = 1;
      data_in = $urandom%256; // Writing consecutive numbers to the FIFO
      #20;
    end
    write_enb = 1;

    // Test 5: Read from full FIFO
    for (int i = 0; i < depth; i = i + 1) begin
      read_enb = 1;
      #20;
      read_enb = 1;
    end

    // Test 6: Empty the FIFO
    for (int i = 0; i < depth; i = i + 1) begin
      write_enb = 0;
      lfd_state = 1;
      data_in = $urandom%256;
      #20;
      write_enb = 1;
    end

    // Test 7: Read from empty FIFO
    for (int i = 0; i < depth; i = i + 1) begin
      read_enb = 1;
      #20;
      read_enb = 1;
    end

    // Test 8: Test reset functionality
    resetn = 0;
    #30;
    resetn = 1;
    #100;

    $display("Exhaustive test completed.");
    $finish; // End simulation
  end

  // Monitor
  always @(posedge clock) begin
    $display("FIFO State: Full=%b, Empty=%b, Counter=%b, write_enb=%b, lfd_state=%b, data_in=%b, read_enb=%b, data_out=%b", full, empty, dut.fifo_counter, write_enb, lfd_state, data_in, read_enb, data_out);
  end

endmodule
