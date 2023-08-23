// Code your design here
module router_top(
  input 		clock,
  input 		resetn,
  
  input 		read_enb_0,
  input 		read_enb_1,
  input 		read_enb_2,
  
  input [7:0]	data_in,
  input 		pkt_valid,
  
  
  output [7:0]	data_out_0,
  output [7:0]	data_out_1,
  output [7:0]	data_out_2,
  
  output		valid_output_0,
  output		valid_output_1,
  output		valid_output_2,
  
  output		error,
  output		busy
);
  
  // net declaration
  wire [2:0]write_enb;
  wire [2:0]soft_reset;
  wire [2:0]read_enb; 
  wire [2:0]empty;
  wire [2:0]full;
  wire [7:0]data_out_temp[2:0];
  wire [7:0]dout;
  
  // Submodules instantiation
  
  // Generate block to instantiate FIFO Block
  genvar i;
  
  generate
    for (i = 0; i<3; i++)
      begin: F
        router_fifo FIFO(
          .clock(clock),
          .resetn(resetn),
          .soft_reset(soft_reset[i]),
          .write_enb(write_enb[i]),
          .read_enb(read_enb[i]),
          .data_in({data_in, lfd_state_w}),
          .data_out(data_out_temp[i]),  // Yaha gadbad h
          .full(full[i]),
          .empty(empty[i])
        );
      end
  endgenerate
  
  wire fifo_full, rst_int_reg, detect_add, ld_state, laf_state, full_state, lfd_state_w, parity_done, low_pkt_valid, write_enb_reg;
  
  router_reg ROUTER(
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .data_in(data_in),
    .fifo_full(fifo_full),
    .rst_int_reg(rst_int_reg),
    .detect_add(detect_add),
    .ld_state(ld_state),
    .laf_state(laf_state),
    .full_state(full_state),
    .lfd_state(lfd_state_w),
    .parity_done(parity_done),
    .low_pkt_valid(low_pkt_valid),
    .err(error),
    .dout(dout)
);
  
  router_fsm FSM (
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .parity_done(parity_done),
    .data_in(data_in[1:0]),
    .soft_reset_0(soft_reset[0]),
    .soft_reset_1(soft_reset[1]),
    .soft_reset_2(soft_reset[2]),
    .fifo_full(fifo_full),
    .low_pkt_valid(low_pkt_valid),
    .fifo_empty_0(empty[0]),
    .fifo_empty_1(empty[1]),
    .fifo_empty_2(empty[2]),
    .busy(busy),
    .detect_add(detect_add),
    .ld_state(ld_state),
    .laf_state(laf_state),
    .full_state(full_state),
    .write_enb_reg(write_enb_reg),
    .rst_int_reg(rst_int_reg),
    .lfd_state(lfd_state_w)
);
  
  router_sync inst_router_sync (
    .clock(clock),
    .resetn(resetn),
    .detect_add(detect_add),
    .write_enb_reg(write_enb_reg),
    .data_in(data_in[1:0]),
    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),
    .empty_0(empty[0]),
    .empty_1(empty[1]),
    .empty_2(empty[2]),
    .full_0(full[0]),
    .full_1(full[1]),
    .full_2(full[2]),
    .vld_out_0(valid_output_0),
    .vld_out_1(valid_output_1),
    .vld_out_2(valid_output_2),
    .soft_reset_0(soft_reset[0]),
    .soft_reset_1(soft_reset[1]),
    .soft_reset_2(soft_reset[2]),
    .write_enb(write_enb),
    .fifo_full(fifo_full)
);
  
  assign read_enb[0]= read_enb_0;
  assign read_enb[1]= read_enb_1;
  assign read_enb[2]= read_enb_2;
  assign  data_out_0=data_out_temp[0];
  assign data_out_1=data_out_temp[1];
  assign data_out_2=data_out_temp[2];

endmodule

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

module router_fsm (
  input 		clock,
  input 		resetn,
  input 		pkt_valid,
  input			parity_done,
  input [1:0]	data_in,
  input 		soft_reset_0,
  input 		soft_reset_1,
  input 		soft_reset_2,
  input 		fifo_full,
  input 		low_pkt_valid,
  input 		fifo_empty_0,
  input			fifo_empty_1,
  input 		fifo_empty_2,
  
  output 		busy,
  output		detect_add,
  output		ld_state,
  output 		laf_state,
  output		full_state,
  output 		write_enb_reg,
  output		rst_int_reg,
  output		lfd_state
);
  
  reg [2:0]state, next_state;
  
  parameter DECODE_ADDRESS		= 	3'b000,
  			LOAD_FIRST_DATA		=	3'b001,
  			LOAD_DATA			=	3'b010,
  			LOAD_PARITY			=	3'b011,
  			FIFO_FULL_STATE		=	3'b100,
  			LOAD_AFTER_FULL		=	3'b101,
  			WAIT_TILL_EMPTY		=	3'b110,
  			CHECK_PARITY_ERROR	=	3'b111;
  
  // State Change Logic
  always @ (*)
    begin
      case (state)
        DECODE_ADDRESS: next_state = ((pkt_valid && (data_in[1:0] == 2'b00) && fifo_empty_0)|
                                      (pkt_valid && (data_in[1:0] == 2'b01) && fifo_empty_1)| 
                                      (pkt_valid && (data_in[1:0] == 2'b10) && fifo_empty_2)) ? LOAD_FIRST_DATA : 
          ((pkt_valid && (data_in[1:0] == 2'b00) && !fifo_empty_0)|
           (pkt_valid && (data_in[1:0] == 2'b01) && !fifo_empty_1)| 
           (pkt_valid && (data_in[1:0] == 2'b10) && !fifo_empty_2)) ? WAIT_TILL_EMPTY : DECODE_ADDRESS;
        
        LOAD_FIRST_DATA: next_state <= LOAD_DATA;
        LOAD_DATA: next_state <= (fifo_full) ? FIFO_FULL_STATE : (!fifo_full && !pkt_valid) ? LOAD_PARITY : LOAD_DATA;
        LOAD_PARITY: next_state <= CHECK_PARITY_ERROR;
        FIFO_FULL_STATE: next_state <= (fifo_full) ? FIFO_FULL_STATE : LOAD_AFTER_FULL;
        LOAD_AFTER_FULL: next_state <= (parity_done) ? DECODE_ADDRESS : 
          							   (!parity_done && low_pkt_valid) ? LOAD_PARITY : 
          							   (!parity_done && !low_pkt_valid) ? LOAD_DATA : LOAD_AFTER_FULL;
        WAIT_TILL_EMPTY: next_state <= (((data_in[1:0] == 2'b00) && fifo_empty_0)|
                                       ((data_in[1:0] == 2'b01) && fifo_empty_1)| 
                                        ((data_in[1:0] == 2'b10) && fifo_empty_2)) ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
        CHECK_PARITY_ERROR: next_state <= (fifo_full) ? FIFO_FULL_STATE : DECODE_ADDRESS;
        default next_state <= DECODE_ADDRESS;
      endcase
    end
  
  // State Transition
  always @ (posedge clock)
    begin
      if (!resetn || (soft_reset_0 || soft_reset_1 || soft_reset_2))
        state <= DECODE_ADDRESS;
      else
        state <= next_state;
    end
  
  // Ouputs based on current states
  assign busy = ((state == LOAD_DATA) || (state == DECODE_ADDRESS)) ? 1'b0 : 1'b1;
  assign detect_add = (state == DECODE_ADDRESS);
  assign ld_state = (state == LOAD_DATA);
  assign laf_state= (state == LOAD_AFTER_FULL);
  assign full_state = (state == FIFO_FULL_STATE);
  assign write_enb_reg = ((state == LOAD_DATA) || (state == LOAD_PARITY) || (state == LOAD_AFTER_FULL));
  assign rst_int_reg = (state == CHECK_PARITY_ERROR);
  assign lfd_state = (state == LOAD_FIRST_DATA);;

endmodule 
  
  
 module router_reg (
  input 		clock,
  input 		resetn,
  input 		pkt_valid,
  input	[7:0]	data_in,
  input  		fifo_full,
  input 		rst_int_reg,
  input 		detect_add,
  input 		ld_state,
  input 		laf_state,
  input 		full_state,
  input 		lfd_state,
  
  output reg		parity_done,
  output reg		low_pkt_valid,
  output reg 		err,
  output reg [7:0]	dout
);
  
  // Latch registers
  reg [7:0] header_latch;
  reg [7:0] FIFO_Full_latch;
  reg [7:0] Internal_Parity_latch;
  reg [7:0] Packet_Parity_latch;
  
  // Always block for parity_done
  always @ (posedge clock)
    begin
      if (!resetn || detect_add)
        begin
          parity_done 	<= 	1'b0;
        end
      
      else if ((ld_state && !fifo_full && !pkt_valid) || (laf_state && low_pkt_valid && !parity_done))  //hosakta h yaha galti ho
        begin
          parity_done 	<= 	1'b1;
        end
    end
  
  // Always block for low_pkt_valid
  always @ (posedge clock)
    begin
      if (!resetn || rst_int_reg)
        begin
          low_pkt_valid <= 1'b0;
        end
      else if (ld_state && !pkt_valid)
        begin
          low_pkt_valid <= 1'b1;
        end
    end
  
  // Always block for err
  always @ (posedge clock)
    begin
      if (!resetn)
        begin
          err <= 1'b0;
        end
      else if (parity_done && (Internal_Parity_latch != Packet_Parity_latch))
        err <= 1'b1;
      else
        err <= 1'b0;
    end
  
  
  // Data Latching
  always @ (posedge clock)
    begin
      if (!resetn)
        begin
          dout					<=	8'b0;
          header_latch 			<= 	8'b0;
          FIFO_Full_latch 		<=	8'b0;
          Internal_Parity_latch	<=	8'b0;
          Packet_Parity_latch	<=	8'b0;
        end
      else if (detect_add && pkt_valid)
        header_latch <=	data_in;
      
      else if (lfd_state)
        begin
          dout <=	header_latch;
        end
      
      else if (ld_state && !fifo_full)
        dout <= data_in;
      
      else if (ld_state && fifo_full)
        FIFO_Full_latch <= data_in;
      
      else 
        begin
          if (laf_state)
        	dout <= FIFO_Full_latch;
        end 
      
    end
  
  always @ (posedge clock)
    begin
      if (!resetn)
        begin
          Internal_Parity_latch	<=	8'b0;
          Packet_Parity_latch	<=	8'b0;
        end
      else if (lfd_state)
        Internal_Parity_latch	<=	Internal_Parity_latch ^ header_latch;
      
      else if (detect_add)
        Internal_Parity_latch <= 8'b0;
      
      else if(ld_state && pkt_valid && !full_state)
		Internal_Parity_latch <= Internal_Parity_latch ^ data_in;
      
      else if (!pkt_valid && ld_state)
		Packet_Parity_latch <= data_in;
    end
  
  
endmodule 

module router_fifo		#(parameter width = 8,
                         parameter depth = 16)(
  input 	clock,					// Synchronous FIFO
  input 	resetn,					// Active Low resetn
  input 	soft_reset,				// Active high soft_reset
  input 	write_enb,
  input 	read_enb,
  input 	[width:0]data_in,
  output 	[width-1:0]data_out,
  output reg full,
  output reg empty
);
  
  // Internal Signals for FIFO to function---------------
  reg [$clog2(depth)-1:0] rd_ptr,wr_ptr;     // Fifo depth is 16, pointer of 4 bit would be sufficient,
 		// but 4'b0 is untouched state, 
  						// so counter counts from 5'b00000 till 5'b10000
  
  // Fifo counter drives full and empty flags
  reg [$clog2(depth):0] fifo_counter;
  
  // Read and Write Logics
  wire READ  = ~(~resetn /*|| soft_reset*/) && !empty && read_enb;
  wire WRITE = ~(~resetn /*|| soft_reset*/) && !full  && write_enb;
  
  // Defining FIFO Memory
  // 9 bit wide fifo with a depth 16
  reg [width-1:0]FIFO[depth];
  
  // Temporary Data Out for adding timer logic to the IP
  reg [width:0]data_out_temp;
  
  // FLAGS Driving Logic ---------------------------------
  always @ (*)
    begin
      empty <= (fifo_counter == 0);
      full  <= (fifo_counter == depth);
    end
  
  // fifo_counter driver----------------------------------
  always @ (posedge clock)
    begin
      // fifo counter resets to 0 on reset being invoked
      if (~resetn /*| soft_reset*/)
        fifo_counter <= 'b0;
      
      // fifo counter does not change on simultaneous read and write
      else if (READ && WRITE)
        fifo_counter <= fifo_counter;
      
      // fifo counter decrements on read
      else if (READ && ~WRITE)
        fifo_counter <= fifo_counter-1;
      
      // fifo counter increments on write
      else if (~READ && WRITE)
        fifo_counter <= fifo_counter+1;
      
      else
        fifo_counter <= fifo_counter;   
    end
  
  // Memory READ and WRITE--------------------------------
  always @ (posedge clock)
    begin
      // Data out is 0 when reset
      if (~resetn /*| soft_reset*/)
        begin
          for(int i = 0; i < depth; i++)
            begin
              FIFO[i] <= 'b0;
            end
        end
      
      // Simultaneous Read and Write
      else if (READ && WRITE)
        begin
          FIFO[wr_ptr]  <= data_in;
          data_out_temp <= FIFO[rd_ptr];
        end
      
      // Only READ
      else if (READ && ~WRITE)
        begin
          FIFO[wr_ptr]  <= FIFO[wr_ptr];
          data_out_temp <= FIFO[rd_ptr];
        end
      
      // Only WRITE
      else if (~READ && WRITE)
        begin
          FIFO[wr_ptr]  <= data_in;
          data_out_temp <= 'b0;
        end

      else
        begin
          FIFO[wr_ptr]  <= FIFO[wr_ptr];
          data_out_temp <= 'b0;
        end   
    end
  
  // rd_ptr and wr_ptr update--------------------------------
  always @ (posedge clock)
    begin
      if (~resetn /*| soft_reset*/)
        begin
          rd_ptr <= 0;
          wr_ptr <= 0;
        end
      
      else if (READ && WRITE)
        begin
          rd_ptr <= rd_ptr + 1;
          wr_ptr <= wr_ptr + 1;
        end
      
      else if (READ && ~WRITE)
        begin
          rd_ptr <= rd_ptr + 1;
          wr_ptr <= wr_ptr;
        end
        
      else if (~READ && WRITE)
        begin
          wr_ptr <= wr_ptr + 1;
          rd_ptr <= rd_ptr;
        end
      
      else
        begin
          wr_ptr <= wr_ptr;
          rd_ptr <= rd_ptr;
        end
    end
  
  // Instantiate Timer module to main design block
  wire out_disable;    // Time out situation
  wire load_timer = data_out_temp[0];
  Timer2 dut (.clock(clock),
             .resetn(resetn),
             .READ(READ),
             .soft_reset(soft_reset),
             .load_timer(load_timer),
             .data(data_out_temp[width : width-5]),
             .time_out(out_disable)
            );
  
  // Assign data_out
  assign data_out = (out_disable || data_out_temp == 'b0) ? 'bz: data_out_temp[width:1];
endmodule

module Timer2 (input clock,
              input resetn,
              input READ,
              input soft_reset,
  			  input load_timer,
              input [5:0]data,    // Upper 6 MSBs of Data_out responsible for loading counter
              output time_out     // Active high disable signal
             );
 reg [6:0]counter;
  
  always @ (posedge clock)
    begin
      if (~resetn /*|| soft_reset*/)
        counter <= 'b0;
      else if (READ && counter == 'b0)
        counter <= data + 1'b1;
      else if (READ && counter != 'b0 /*&& (state == out_enb)*/)
        counter <= counter - 1'b1;
      else
        counter <= 'b0;
    end
  
  assign time_out = (~load_timer && counter == 'b0) ? 1'b1 : 1'b0;
  
endmodule