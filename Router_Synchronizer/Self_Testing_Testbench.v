/*
This is not a perfect testbench
Still learning self-testing testbenches
Would add a better version soon :/
*/


module router_sync_tb;
  
  // Declaring Input Variables
  reg clock, resetn, detect_add, write_enb_reg;
  reg read_enb_0, read_enb_1, read_enb_2;
  reg empty_0, empty_1, empty_2;
  reg full_0, full_1, full_2;
  reg [1:0] data_in;
  
  // Declaring output variables
  wire vld_out_0, vld_out_1, vld_out_2;
  wire soft_reset_0, soft_reset_1, soft_reset_2;
  wire fifo_full;
  wire [2:0] write_enb;
  
  // Design Instantiation
  router_sync dut (
    .clock(clock),
    .resetn(resetn),
    .detect_add(detect_add),
    .write_enb_reg(write_enb_reg),
    .data_in(data_in),
    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),
    .empty_0(empty_0),
    .empty_1(empty_1),
    .empty_2(empty_2),
    .full_0(full_0),
    .full_1(full_1),
    .full_2(full_2),
    .vld_out_0(vld_out_0),
    .vld_out_1(vld_out_1),
    .vld_out_2(vld_out_2),
    .soft_reset_0(soft_reset_0),
    .soft_reset_1(soft_reset_1),
    .soft_reset_2(soft_reset_2),
    .write_enb(write_enb),
    .fifo_full(fifo_full)
  );
  
  // Clock Generator
  initial clock = 1'b1;
  always #5 clock = ~clock;
  
  // VCD Files
  initial begin
   $dumpfile("dump.vcd");
   $dumpvars;
  end
  
  // Test for resetn
  wire RESET_TEST = (vld_out_0 != 1'b0) || (vld_out_1 != 1'b0) || (vld_out_2 != 1'b0) || (soft_reset_0 != 1'b0) || (soft_reset_1 != 1'b0) || (soft_reset_2 != 1'b0) || (write_enb != 3'b0) || (fifo_full != 1'b0);
  task RESET;
    begin
      resetn = 1'b0;
      @ (posedge clock);
      if (RESET_TEST)
        begin
          $display("RESET is not working");
          $display("Error at time %t", $time);
          $stop;
        end
      else
        $display("RESET is working fine");
      resetn = 1'b1;
    end
  endtask
  
  // Test for fifo_full_signal
  reg error;
  reg value = 1'b0;
  task fifo_full_signal_test;
    begin
      resetn = 1'b1;
      detect_add = 1'b1;
      full_0 = 1'b1;
      full_1 = 1'b0;
      full_2 = 1'b1;
      for (int i = 0; i < 20; i++)
        begin
          data_in = $random%2;
          case (data_in)
      		2'b00:  value = full_0;
      		2'b01:  value = full_1;
      		2'b10:  value = full_2;
      		default value = 1'b0;
    	endcase
          if (fifo_full != value)
            begin
              $display("Test failed");
          	  $display("Error at time %t", $time);
              error = 1'b1;
              //$stop;
            end
          else
            begin
              error = 1'b0;
              $display("Test passed");
            end
          #10;
        end
    end
  endtask
  
  // Test for vld_out_x
  reg vld_out_0_temp, vld_out_1_temp, vld_out_2_temp;
  
  task test_for_vld_out_x;
    begin
      resetn = 1'b1;
      for (int i = 0; i < 20; i++)
        begin
          empty_0 = 1'b1;
          empty_1 = 1'b0;
          empty_2 = 1'b1;
          vld_out_0_temp = ~empty_0;
          vld_out_1_temp = ~empty_1;
          vld_out_2_temp = ~empty_2;
          
          if ((vld_out_0_temp != vld_out_0) || (vld_out_1_temp != vld_out_1) || (vld_out_2_temp != vld_out_2))
            begin
              $display("Test failed");
          	  $display("Error at time %t", $time);
            end
          
          else
            $display("Test for vld_out_x passed");
          #10;
        end
    end
  endtask
  
  // write_enb signal test
  reg [2:0] write_enb_temp;
  task write_enb_test;
    begin
      resetn = 1'b1;
      write_enb_reg = 1'b1;
      detect_add = 1'b1;
      for (int i = 0; i < 10; i++)
        begin
          data_in = 2'b10;//$random%3;
          case (data_in)
            2'b00:  write_enb_temp = 3'b001;
          	2'b01:  write_enb_temp = 3'b010;
          	2'b10:  write_enb_temp = 3'b100;
          	default write_enb_temp = 3'b0;
          endcase
          if (write_enb_temp != write_enb)
            begin
              $display("Test for write_enb failed");
              $display("Error at time %t", $time);
            end
          else
            $display("Test for write_enb passed");
          #10;
        end
    end
  endtask
  
  // Test for soft_reset signal
  task soft_signal_test;
    begin
      resetn = 1'b1;
      detect_add = 1'b1;
      empty_0 = 1'b1;
      empty_1 = 1'b0;
      empty_2 = 1'b1;
      vld_out_0_temp = ~empty_0;
      vld_out_1_temp = ~empty_1;
      vld_out_2_temp = ~empty_2;
      
      data_in = 2'b01;
      
      #250;
      
      read_enb_1 = 1'b1;
      
      if (soft_reset_1 != 1'b1)
        begin
          $display("Test for soft_reset failed");
              $display("Error at time %t", $time);
            end
      else
        $display("Test Passes");
    end
  endtask
  
  
  // Applying TASKS
  initial begin
    RESET;
    fifo_full_signal_test;
    test_for_vld_out_x;
    write_enb_test;
    soft_signal_test;
    #400;
    $stop;
  end
 
endmodule