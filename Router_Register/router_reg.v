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