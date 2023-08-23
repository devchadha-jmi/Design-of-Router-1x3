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