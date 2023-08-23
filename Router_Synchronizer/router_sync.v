module router_sync(
  input 			clock,
  input 			resetn,
  input 			detect_add,   
  input 			write_enb_reg,
  input [1:0] 		data_in,
  input 			read_enb_0,
  input 			read_enb_1,
  input 			read_enb_2,
  input 			empty_0,
  input				empty_1,
  input 			empty_2,
  input 			full_0,
  input 			full_1,
  input 			full_2,
  output			vld_out_0,
  output 			vld_out_1,
  output			vld_out_2,
  output reg		soft_reset_0,
  output reg		soft_reset_1,
  output reg		soft_reset_2,
  output reg [2:0]	write_enb,
  output reg		fifo_full
);
					
reg [1:0]temp;
reg [4:0]count0,count1,count2;

  always@(posedge clock)
	begin
		if(!resetn)
			temp <= 2'd0;
		else if(detect_add)
			temp<=data_in;
	end
	
//for fifo full
always@(*)
	begin
		case(temp)
			2'b00: fifo_full=full_0;                // fifo fifo_full takes the value of full of fifo_0
			2'b01: fifo_full=full_1;                // fifo fifo_full takes the value of full of fifo_1
			2'b10: fifo_full=full_2;				// fifo fifo_full takes the value of full of fifo_2
			default fifo_full=0;
		endcase
	end

//write enable
always@(*)
	begin 
				if(write_enb_reg)
				begin
					case(temp)
						2'b00: write_enb=3'b001;				
						2'b01: write_enb=3'b010;
						2'b10: write_enb=3'b100;
						default: write_enb=3'b000;
					endcase
				end
				else
					write_enb = 3'b000;		
	end

//valid out
assign vld_out_0 = !empty_0;
assign vld_out_1 = !empty_1;
assign vld_out_2 = !empty_2;

//soft reset counter 
  always@(posedge clock)
	begin
		if(!resetn)
			count0<=5'b0;
		else if(vld_out_0)
			begin
				if(!read_enb_0)
					begin
						if(count0==5'b11110)	
							begin
								soft_reset_0<=1'b1;
								count0<=1'b0;
							end
						else
							begin
								count0<=count0+1'b1;
								soft_reset_0<=1'b0;
							end
					end
				else count0<=5'd0;
			end
		else count0<=5'd0;
	end
	
  always@(posedge clock)
	begin
		if(!resetn)
			count1<=5'b0;
		else if(vld_out_1)
			begin
				if(!read_enb_1)
					begin
						if(count1==5'b11110)	
							begin
								soft_reset_1<=1'b1;
								count1<=1'b0;
							end
						else
							begin
								count1<=count1+1'b1;
								soft_reset_1<=1'b0;
							end
					end
				else count1<=5'd0;
			end
		else count1<=5'd0;
	end
	
  always@(posedge clock)
	begin
		if(!resetn)
			count2<=5'b0;
		else if(vld_out_2)
			begin
				if(!read_enb_2)
					begin
						if(count2==5'b11110)	
							begin
								soft_reset_2<=1'b1;
								count2<=1'b0;
							end
						else
							begin
								count2<=count2+1'b1;
								soft_reset_2<=1'b0;
							end
					end
				else count2<=5'd0;
			end
		else count2<=5'd0;
	end
	
	
endmodule