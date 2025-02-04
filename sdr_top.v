//top module for SDRAM CONTROLLER


//`include "sdr_para.v"
//`include "sdram_control.v"
//`include "sdr_signals.v"
//`include "sdr_data.v"

module sdr_top(
  sys_R_Wn,      // read/write#
  sys_ADSn,      // address strobe
  sys_DLY_100US, // sdr power and clock stable for 100 us
  sys_CLK,       // sdr clock
  sys_RESET,     // reset signal
  sys_REF_REQ,   // sdr auto-refresh request
  sys_REF_ACK,   // sdr auto-refresh acknowledge
  sys_A,         // address bus
  sys_Data,         // data bus
  sys_D_VALID,   // data valid
  sys_CYC_END,
  sys_INIT_DONE, // initialization completed,ready for normal operation

  sdr_DQ,        // sdr data
  sdr_A,         // sdr address
  sdr_BA,        // sdr bank address
  sdr_CKE,       // sdr clock enable
  sdr_CSn,       // sdr chip select
  sdr_RASn,      // sdr row address
  sdr_CASn,      // sdr column select
  sdr_WEn,       // sdr write enable
  sdr_DQM        // sdr write data mask
);
        `include "sdr_para.v"
		
		input                      sys_R_Wn;
		input                      sys_ADSn;
		input                      sys_DLY_100US;
		input                      sys_CLK;
		input                      sys_RESET;
		input                      sys_REF_REQ;
		input  [RA_MSB:CA_LSB]     sys_A;


		output                     sys_CYC_END;
    output                     sys_REF_ACK;
		output                     sys_D_VALID;
		output                     sys_INIT_DONE;
    output [SDR_A_WIDTH-1:0]   sdr_A;
		output [SDR_BA_WIDTH-1:0]  sdr_BA;
		output                     sdr_CKE;
		output                     sdr_CSn;
		output                     sdr_RASn;
		output                     sdr_CASn;
		output                     sdr_WEn;
		output                     sdr_DQM;
		inout [15:0]               sys_Data;
		inout [3:0]                sdr_DQ;

		
		wire [3:0]                 iState;    // INIT_FSM state variables
		wire [3:0]                 cState;    // CMD_FSM state variables
		wire [3:0]                 clkCnt;

		
		assign #tDLY sdr_DQM = 0;

		sdr_ctrl DUT (
		  .clk(sys_CLK),
		  .reset(sys_RESET),
		  .rd_wr(sys_R_Wn),
		  .addrs(sys_ADSn),
		  .delay_100us(sys_DLY_100US),
		  .ref_req(sys_REF_REQ),
		  .ref_ack(sys_REF_ACK),
		  .cy_end (sys_CYC_END),
		  .init_done(sys_INIT_DONE),
		  .istate(iState),
		  .cstate(cState),
		  .clk_count(clkCnt)
		);

		 sdr_signals DUT1 (
		   .clk(sys_CLK),
		   .reset(sys_RESET),
		   .sys_A(sys_A),
		   .iState(iState),
		   .cState(cState),
		   .sdr_CKE(sdr_CKE),
	     .sdr_CSn(sdr_CSn),
		   .sdr_RASn(sdr_RASn),
		   .sdr_CASn(sdr_CASn),
		   .sdr_WEn(sdr_WEn),
		   .sdr_BA(sdr_BA),
		   .sdr_A(sdr_A)
		 );

		sdr_data DUT2 (
		  .clk(sys_CLK),
		  .reset(sys_RESET),
		  .data_bus(sys_Data),
		  .data_valid(sys_D_VALID),
		  .cstate(cState),
		  .clk_count(clkCnt),
		  .sdr_DQ(sdr_DQ)
		);

endmodule

