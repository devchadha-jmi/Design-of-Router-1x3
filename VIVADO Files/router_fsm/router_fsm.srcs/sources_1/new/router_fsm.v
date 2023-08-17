`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.08.2023 17:40:11
// Design Name: 
// Module Name: router_fsm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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
