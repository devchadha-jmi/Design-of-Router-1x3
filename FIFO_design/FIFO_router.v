module fifo_router#(
  parameter width = 8,
  parameter depth = 16)
  (input 	clock,						// Same clock to read and write, no CDC
   input 	resetn,
   input 	soft_reset,
   input 	write_enb,
   input 	read_enb,
   input 	lfd_state,
   input 	[width-1:0] data_in,
   output   [width-1:0] data_out,
   output	reg full,
   output	reg	empty);
  
  // Internal signals
  // Read and write pointer decides the write and read locations
  reg [3:0]rd_ptr;
  reg [3:0]wr_ptr;
  // fifo counter drives full and empty flags
  reg [3:0]fifo_counter;
  
  // Read and Write Logics
  wire READ  = !empty && read_enb;
  wire WRITE = !full  && write_enb;
  
  // Defining FIFO Memory
  // 9 bit wide fifo with a depth 16
  
  reg [8:0]FIFO[15:0];
  
  // Flag Driver-----------------------------------------------------------------------------
  always @ (fifo_counter)
    begin
      empty <= (fifo_counter == 4'b0000);
      full  <= (fifo_counter == 4'b1111);
    end
  
  // fifo_counter driver----------------------------------------------------------------------
  
  always @ (posedge clock)
    begin
      // fifo counter resets to 0 on reset being invoked
      if (~resetn | soft_reset)
        fifo_counter <= 4'b0;
      
      // fifo counter does not change on simultaneous read and write
      else if (READ && WRITE)
        fifo_counter <= fifo_counter;
      
      // fifo counter decrements on read
      else if (READ)
        fifo_counter <= fifo_counter-1;
      
      // fifo counter increments on write
      else if (WRITE)
        fifo_counter <= fifo_counter+1;
      
      else
        fifo_counter <= fifo_counter;   
    end
  
  // Memory READ and WRITE-----------------------------------------------------------------
  
  reg [8:0]data_out_9bit;
  
  always @ (posedge clock)
    begin
      // Data out is 0 when reset
      if (~resetn | soft_reset)
        data_out_9bit <= {width{1'b0}};
      
      // Simultaneous Read and Write
      else if (READ && WRITE)
        begin
          FIFO[wr_ptr]  <= {lfd_state, data_in};
          data_out_9bit <= FIFO[rd_ptr];
        end
      
      // Only READ
      else if (READ)
        data_out_9bit <= FIFO[rd_ptr];
      
      // Only WRITE
      else if (WRITE)
        FIFO[wr_ptr]  <= {lfd_state, data_in};
      
      else
        begin
          FIFO[wr_ptr]  <= FIFO[wr_ptr];
          data_out_9bit <= 9'b0;
        end   
    end
  
      // Data out is in High Impedance state for two scenarios
      // 1. When FIFO is empty
      // 2. When FIFO is in timeout stage
  	  // TIME-OUT - When counter goes to zero
      // Counter starts when lfd-state is 1
  
  // State Machine for Counter control
  // /*Three*/ Two states
  // 1. Counter Load
  // 2. Counter Decrement
  
  parameter counter_load = 2'b01;    // Value loaded to counter when lfd_state is 1
  parameter counter_dcr  = 2'b10;	 // Counter decrements after loading
  
  reg [6:0]counter;
  reg [1:0]state, next_state;
  
  always @ (*)
    begin
      case (state)
        counter_load: begin
          next_state <= (data_out_9bit[0]) ? counter_dcr : counter_load;
          counter <= (data_out_9bit[0]) ? data_out_9bit[8:3] + 1'b1 : 7'b0;
        end
        counter_dcr : begin 
          next_state <= (counter == 7'b0) ? counter_load : counter_dcr;
          //counter <= (counter != 7'b0) ? counter - 1'b1 : counter;
        end
      endcase
    end
  
  always @ (posedge clock)
    begin
      if (~resetn | soft_reset)
        state <= counter_load;
      else
        state <= next_state;
      
      // Synchronous decrement
        counter <= (counter != 7'b0) ? counter - 1'b1 : counter;
    end
  
  /* Load Counter
  always @ (posedge clock)
    begin
      if (~reset | soft_reset)
        counter <= 7'b0;
      
      else if (data_out_9bit[0])				// Load counter when lfd state is 1
        counter <= data_out_9bit[8:3] + 1'b1;
      
      else if (counter == 7'b0)					// When counter is 0 it stays at 0
        counter <= counter;
      
      else										// Else counter always decrements
        counter <= counter - 1'b1;
    end
    
    */
  
  assign data_out = (counter == 7'b0 | empty) ? 8'bz : data_out_9bit[8:1];  
  
  // rd_ptr and wr_ptr update--------------------------------------------------------------
  always @ (posedge clock)
    begin
      if (~resetn | soft_reset)
        begin
          rd_ptr <= 4'b0;
          wr_ptr <= 4'b0;
        end
      else if (READ && WRITE)
        begin
          rd_ptr <= rd_ptr + 4'b1;
          wr_ptr <= wr_ptr + 4'b1;
        end
      else if (READ)
        rd_ptr <= rd_ptr + 4'b1;
      else if (WRITE)
        wr_ptr <= wr_ptr + 4'b1;
      else
        begin
          wr_ptr <= wr_ptr;
          rd_ptr <= rd_ptr;
        end
    end

endmodule
                   