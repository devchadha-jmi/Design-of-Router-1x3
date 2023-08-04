module router_sync(
  input 		clock,
  input 		resetn,
  input 		detect_add,   
  input 		write_enb_reg,
  input [1:0] 	data_in,
  input 		read_enb_0,
  input 		read_enb_1,
  input 		read_enb_2,
  input 		empty_0,
  input			empty_1,
  input 		empty_2,
  input 		full_0,
  input 		full_1,
  input 		full_2,
  output		vld_out_0,
  output 		vld_out_1,
  output		vld_out_2,
  output 		soft_reset_0,
  output 		soft_reset_1,
  output		soft_reset_2,
  output [2:0]	write_enb,
  output 		fifo_full
);
  // fifo_full signal--------------------
  reg fifo_full_temp;
  always @ (*)
    begin
      if (~resetn)
        fifo_full_temp = 1'b0;
      else if (detect_add) begin
    	case (data_in)
      		2'b00:  fifo_full_temp = full_0;
      		2'b01:  fifo_full_temp = full_1;
      		2'b10:  fifo_full_temp = full_2;
      		default fifo_full_temp = 1'b0;
    	endcase
      end
      else
        fifo_full_temp = 1'b0;
  	end
  
  assign fifo_full = fifo_full_temp;
  
  // vld_out_x signal--------------------
  assign vld_out_0 = (~resetn) ? 1'b0 : ~empty_0;
  assign vld_out_1 = (~resetn) ? 1'b0 : ~empty_1;
  assign vld_out_2 = (~resetn) ? 1'b0 : ~empty_2;
  
  // write_enb signal--------------------
  reg [2:0] write_enb_temp;
  	// write_enb_temp[0] for FIFO_0
  	// write_enb_temp[1] for FIFO_1
  	// write_enb_temp[2] for FIFO_2
  
  always @ (*)
    begin
      	if (!resetn)
        	write_enb_temp = 3'b0;
      else if(write_enb_reg && detect_add)
      		begin
        		case (data_in)
          			2'b00:  write_enb_temp = 3'b001;
          			2'b01:  write_enb_temp = 3'b010;
          			2'b10:  write_enb_temp = 3'b100;
          			default write_enb_temp = 3'b0;
        		endcase
      		end
  		else
      		write_enb_temp = 3'b0;
  	end
  
  assign write_enb = write_enb_temp;
  
  // soft_reset_x signal
  wire start_counter = (data_in == 2'b00 && vld_out_0) | (data_in == 2'b01 && vld_out_1) | (data_in == 2'b10 && vld_out_2);
  reg soft_reset_x;
  
  Timer dut (.clock(clock),
             .timer_enable(start_counter),
             .resetn(!resetn || read_enb_0 || read_enb_1 || read_enb_2),
             .time_out(soft_reset_x));
  
  assign soft_reset_0 = (soft_reset_x && vld_out_0);
  assign soft_reset_1 = (soft_reset_x && vld_out_1);
  assign soft_reset_2 = (soft_reset_x && vld_out_2);
  
endmodule

module Timer (input clock,
              input timer_enable,
              input resetn,
              output time_out);
  
  reg [4:0] counter;
  
  always @ (posedge clock)
    begin
      if (resetn)
        counter <= 5'b0;
      else if (timer_enable && counter == 5'b0)
        counter <= 5'b11110;
      else if (counter != 5'b0)
        counter <= counter - 1'b1;
      else
        counter <= counter;  
    end
  
  assign time_out = (!resetn && timer_enable && counter == 5'b0);
  
endmodule