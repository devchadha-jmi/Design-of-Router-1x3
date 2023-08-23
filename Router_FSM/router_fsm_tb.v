module router_fsm_tb;
  // Inputs
  reg clock;
  reg resetn;
  reg pkt_valid;
  reg parity_done;
  reg [1:0] data_in;
  reg soft_reset_0;
  reg soft_reset_1;
  reg soft_reset_2;
  reg fifo_full;
  reg low_pkt_valid;
  reg fifo_empty_0;
  reg fifo_empty_1;
  reg fifo_empty_2;

  // Outputs
  wire busy;
  wire detect_add;
  wire ld_state;
  wire laf_state;
  wire full_state;
  wire write_enb_reg;
  wire rst_int_reg;
  wire lfd_state;

  // Instantiate the DUT (Design Under Test)
  router_fsm dut (
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .parity_done(parity_done),
    .data_in(data_in),
    .soft_reset_0(soft_reset_0),
    .soft_reset_1(soft_reset_1),
    .soft_reset_2(soft_reset_2),
    .fifo_full(fifo_full),
    .low_pkt_valid(low_pkt_valid),
    .fifo_empty_0(fifo_empty_0),
    .fifo_empty_1(fifo_empty_1),
    .fifo_empty_2(fifo_empty_2),
    .busy(busy),
    .detect_add(detect_add),
    .ld_state(ld_state),
    .laf_state(laf_state),
    .full_state(full_state),
    .write_enb_reg(write_enb_reg),
    .rst_int_reg(rst_int_reg),
    .lfd_state(lfd_state)
  );

  // Clock generation
  always #5 clock = ~clock;
  
  // VCD Files
  initial begin
   $dumpfile("dump.vcd");
   $dumpvars;
  end

  // Initial values
  initial begin
    clock = 0;
    resetn = 1;
    pkt_valid = 0;
    parity_done = 0;
    data_in = 2'b00;
    soft_reset_0 = 0;
    soft_reset_1 = 0;
    soft_reset_2 = 0;
    fifo_full = 0;
    low_pkt_valid = 0;
    fifo_empty_0 = 1;
    fifo_empty_1 = 1;
    fifo_empty_2 = 1;

    #5 resetn = 0; // Assert resetn
    #10 resetn = 1; // De-assert resetn

    // Test scenario 1: Load first data
    pkt_valid = 1;
    data_in = 2'b00;
    #50;
    pkt_valid = 0; // Finish loading data
    #20;

    // Test scenario 2: FIFO full state
    pkt_valid = 1;
    data_in = 2'b00;
    fifo_empty_0 = 0; // Simulate FIFO full
    #50;
    fifo_empty_0 = 1;
    #20;

    // Test scenario 1: Load first data - Address 0, FIFO 0 is empty
  pkt_valid = 1;
  data_in = 2'b00;
  fifo_empty_0 = 1;
  #50;
  pkt_valid = 0; // Finish loading data
  #20;

  // Test scenario 2: Load first data - Address 1, FIFO 1 is empty
  pkt_valid = 1;
  data_in = 2'b01;
  fifo_empty_1 = 1;
  #50;
  pkt_valid = 0; // Finish loading data
  #20;

  // Test scenario 3: Load first data - Address 2, FIFO 2 is empty
  pkt_valid = 1;
  data_in = 2'b10;
  fifo_empty_2 = 1;
  #50;
  pkt_valid = 0; // Finish loading data
  #20;

  // Test scenario 4: Wait till FIFO becomes empty
  pkt_valid = 1;
  data_in = 2'b01;
  fifo_empty_1 = 0; // FIFO not empty
  #50;
  fifo_empty_1 = 1; // FIFO becomes empty
  #20;
  pkt_valid = 0; // Finish loading data
  #20;

  // Test scenario 5: FIFO Full state - FIFO 0 is full
  pkt_valid = 1;
  data_in = 2'b00;
  fifo_empty_0 = 0; // FIFO not empty
  fifo_full = 1;   // FIFO full
  #50;
  fifo_empty_0 = 1; // FIFO becomes empty
  #20;

  // Test scenario 6: Parity error detected
  pkt_valid = 1;
  data_in = 2'b11; // Invalid address
  fifo_empty_0 = 1;
  #50;
  pkt_valid = 0; // Finish loading data
  #20;

  // Test scenario 7: Load data, then parity, then load after full
  pkt_valid = 1;
  data_in = 2'b01;
  fifo_empty_1 = 1;
  #50;
  pkt_valid = 0; // Finish loading data
  #20;
  // Parity done
  parity_done = 1;
  #50;
  // Load data after FIFO was full
  fifo_full = 1;
  #50;
  fifo_full = 0;
  #20;

  // Test scenario 8: Check reset behavior
  soft_reset_0 = 1;
  #20;
  soft_reset_0 = 0;
  #50;
  soft_reset_1 = 1;
  #20;
  soft_reset_1 = 0;
  #50;
  soft_reset_2 = 1;
  #20;
  soft_reset_2 = 0;
  #50;

    #100 $finish; // Finish simulation
  end

  // Monitor the state changes (optional, for debugging purposes)
  always @(posedge clock) begin
    $display("Current state: %b", dut.state);
    $display("Next state: %b", dut.next_state);
  end

endmodule