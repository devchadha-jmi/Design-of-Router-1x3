module fifo_min_project#(parameter width = 9,
                         parameter depth = 16)(
  input 	clock,					// Synchronous FIFO
  input 	resetn,					// Active Low resetn
  input 	soft_reset,				// Active high soft_reset
  input 	write_enb,
  input 	read_enb,
  input 	[width-1:0]data_in,
  output 	[width-1:0]data_out,
  output reg full,
  output reg empty
);
  
  // Internal Signals for FIFO to function---------------
  reg [4:0] rd_ptr;     // Fifo depth is 16, pointer of 4 bit would be sufficient,
  reg [4:0] wr_ptr;		// but 4'b0 is untouched state, 
  						// so counter counts from 5'b00000 till 5'b10000
  
  // Fifo counter drives full and empty flags
  reg [4:0] fifo_counter;
  
  // Read and Write Logics
  wire READ  = ~(~resetn || soft_reset) &&!empty && read_enb;
  wire WRITE = ~(~resetn || soft_reset) &&!full  && write_enb;
  
  // Defining FIFO Memory
  // 9 bit wide fifo with a depth 16
  reg [width-1:0]FIFO[depth-1:0];
  
  // Temporary Data Out for adding timer logic to the IP
  reg [8:0]data_out_temp;
  
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
      if (~resetn | soft_reset)
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
      if (~resetn | soft_reset)
        begin
          for(int i = 0; i < 16; i++)
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
      if (~resetn | soft_reset)
        begin
          rd_ptr <= 'b0;
          wr_ptr <= 'b0;
        end
      
      else if (READ && WRITE)
        begin
          rd_ptr <= rd_ptr + 'b1;
          wr_ptr <= wr_ptr + 'b1;
        end
      
      else if (READ && ~WRITE)
        begin
          rd_ptr <= rd_ptr + 'b1;
          wr_ptr <= wr_ptr;
        end
        
      else if (~READ && WRITE)
        begin
          wr_ptr <= wr_ptr + 'b1;
          rd_ptr <= rd_ptr;
        end
      
      else if (~READ && ~WRITE)
        begin
          wr_ptr <= wr_ptr;
          rd_ptr <= rd_ptr;
        end
    end
  
  // Instantiate Timer module to main design block
  wire out_disable;    // Time out situation
  wire load_timer = data_out_temp[0] | 1'b0;
  Timer dut (.clock(clock),
             .resetn(resetn),
             .READ(READ),
             .soft_reset(soft_reset),
             .load_timer(load_timer),
             .data(data_out_temp[width-1:width-6]),
             .time_out(out_disable)
            );
  
  // Assign data_out
  assign data_out = (out_disable || data_out_temp == 'b0) ? 'bz: data_out_temp;
endmodule

module Timer (input clock,
              input resetn,
              input READ,
              input soft_reset,
  			  input load_timer,
              input [5:0]data,    // Upper 6 MSBs of Data_out responsible for loading counter
              output time_out     // Active high disable signal
             );
  // State Definition
  parameter idle = 2'b00,
  			out_enb = 2'b01,
  			first_byte = 2'b10;
  
  reg [1:0]state, next_state;
  
  always @ (posedge clock)
    begin
      if (~resetn || soft_reset)
        state <= idle;
      else
        state <= next_state;
    end
  
  always @ *
    begin
      case (state)
        idle:    	next_state = (READ) ? first_byte : idle;
        first_byte: next_state = (READ && load_timer) ? out_enb : idle;
        out_enb: 	next_state = (counter == 7'b0) ? idle : out_enb;
        default  	next_state = idle;
      endcase
    end
        
  reg [6:0]counter;
  
  always @ (posedge clock)
    begin
      if (~resetn || soft_reset)
        counter <= 7'b0;
      else if (load_timer)
        counter <= data + 1'b1;
      else if (counter != 7'b0 && (state == out_enb))
        counter <= counter - 1'b1;
      else
        counter <= counter;
    end
  
  assign time_out = (state == idle || (state == first_byte && ~load_timer)) ? 1'b1 : 1'b0;
  
endmodule