module sdr_data(
                 clk,
                 reset,
                 data_bus,    // bidirectional data port from system to sdram controller
                 data_valid,
                 cstate,
                 clk_count,  
                 sdr_DQ       // bidirectional data from controller to sdram model 
                );

    `include "sdr_para.v"



    input  		clk;
    input  		reset;
    input [3:0] cstate;
    input [3:0] clk_count;
    output            data_valid;
    inout  [15:0]     data_bus;
    inout   [3:0]     sdr_DQ;


    reg [15:0]  regSdrDQ;
    reg         enable_sysD;
    reg [15:0]  regSysD;
	reg [3:0]   regSysDX;
	reg         enableSdrDQ;


    wire         stateWRITEA;

	wire [3:0]   cnt0_dq ;
	wire [3:0]   cnt1_dq ;
	wire [3:0]   cnt2_dq ;
	wire [3:0]   cnt3_dq ;


	

	assign #tDLY data_valid = enable_sysD;

	
	//  Read Cycle Data Path
	//
	assign #tDLY data_bus = (enable_sysD) ? regSdrDQ : 16'hzzzz;

	assign cnt0_dq = (cstate == c_rdata) && (clk_count == 0) ? sdr_DQ : regSdrDQ[3:0];
	assign cnt1_dq = (cstate == c_rdata) && (clk_count == 1) ? sdr_DQ : regSdrDQ[7:4];
	assign cnt2_dq = (cstate == c_rdata) && (clk_count == 2) ? sdr_DQ : regSdrDQ[11:8];
	assign cnt3_dq = (cstate == c_rdata) && (clk_count == 3) ? sdr_DQ : regSdrDQ[15:12];

	always @(posedge clk or posedge reset)
	   if (reset)
	      regSdrDQ <= #tDLY 16'h0000;
	   else
	      regSdrDQ <= #tDLY {cnt3_dq,cnt2_dq,cnt1_dq,cnt0_dq};


	always @(posedge clk or posedge reset)
	  if (reset)
	          enable_sysD <= #tDLY 0;
	  else if ((cstate == c_rdata) && (clk_count == NUM_CLK_READ - 1))
	          enable_sysD <= #tDLY 1;
	  else    enable_sysD <= #tDLY 0;

	
	//  Write Cycle Data Path
	//
	assign #tDLY sdr_DQ = (enableSdrDQ) ? regSysDX : 4'bzzzz;

	always @(posedge clk or posedge reset)
	  if (reset)
	          regSysDX <= #tDLY 16'h0000;
	  else if (cstate == c_WRITEA)
	          regSysDX <= #tDLY regSysD[3:0];
	  else if ((cstate == c_wdata) && (clk_count == 1))
	          regSysDX <= #tDLY regSysD[7:4];
	  else if ((cstate == c_wdata) && (clk_count == 2))
	          regSysDX <= #tDLY regSysD[11:8];
	  else    regSysDX <= #tDLY regSysD[15:12];

	assign #tDLY stateWRITEA = (cstate == c_WRITEA) ? 1'b1 : 1'b0;

	always @(posedge clk or posedge reset)
	  if  (reset)
	          enableSdrDQ <= #tDLY 0;
	  else if (cstate == c_WRITEA)
	          enableSdrDQ <= #tDLY 1;
	  else if ((cstate == c_wdata) && (clk_count == NUM_CLK_WRITE))
	          enableSdrDQ <= #tDLY 0;

	always @(posedge clk or posedge reset)
	  if (reset)
	          regSysD <= #tDLY 16'h0000;
	  else    regSysD <= #tDLY data_bus;


	endmodule
