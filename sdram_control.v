 // sdr sdram controller

 module sdr_ctrl
                (
                clk,
                reset,
                rd_wr,
                addrs,
                delay_100us,
                ref_req,     //refresh req
                ref_ack,
                cy_end,
                init_done,
                istate,     //initialization fsm
                cstate,     //command fsm
                clk_count
                );

   `include "sdr_para.v"


  input        		clk;
	input        		reset;
	input        		rd_wr;
	input        		addrs;
	input        		delay_100us;
	input        		ref_req;
  output  reg     cy_end;
	output  reg         ref_ack;
	output  reg         init_done;
	output  reg [3:0]   istate;
	output  reg [3:0]   cstate;
	output  reg [3:0]   clk_count;

    
    reg     syncResetclk; // timing is met then the clock is reset


  `define endOf_tRP          clk_count == NUM_CLK_tRP
	`define endOf_tRFC         clk_count == NUM_CLK_tRFC
	`define endOf_tMRD         clk_count == NUM_CLK_tMRD
	`define endOf_tRCD         clk_count == NUM_CLK_tRCD
	`define endOf_Cas_Latency  clk_count == NUM_CLK_CL
	`define endOf_Read_Burst   clk_count == NUM_CLK_READ - 1
	`define endOf_Write_Burst  clk_count == NUM_CLK_WRITE
	`define endOf_tDAL         clk_count == NUM_CLK_WAIT


	always @(posedge clk or posedge reset)
  		if (reset) begin
     		istate <= #tDLY i_NOP;
  		end else
    		case (istate)
		      i_NOP:   // wait for 100 us delay by checking sys_DLY_100US
		               if (delay_100us) istate <= #tDLY i_PRE;
		      i_PRE:   // precharge all
		               istate <= #tDLY (NUM_CLK_tRP == 0) ? i_AR1 : i_tRP;
		      i_tRP:   // wait until tRP satisfied
		               if (`endOf_tRP) istate <= #tDLY i_AR1;
		      i_AR1:   // auto referesh
		               istate <= #tDLY (NUM_CLK_tRFC == 0) ? i_AR2 : i_tRFC1;
		      i_tRFC1: // wait until tRFC satisfied
		               if (`endOf_tRFC) istate <= #tDLY i_AR2;
		      i_AR2:   // auto referesh
		               istate <= #tDLY (NUM_CLK_tRFC == 0) ? i_MRS : i_tRFC2;
		      i_tRFC2: // wait until tRFC satisfied
		               if (`endOf_tRFC) istate <= #tDLY i_MRS;
		      i_MRS:   // load mode register
		               istate <= #tDLY (NUM_CLK_tMRD == 0) ? i_ready : i_tMRD;
		      i_tMRD:  // wait until tMRD satisfied
		               if (`endOf_tMRD) istate <= #tDLY i_ready;
		      i_ready: // stay at this state for normal operation
		               istate <= #tDLY i_ready;
		      default:
		               istate <= #tDLY i_NOP;
		    endcase


//INIT_DONE generation

always @(posedge clk or posedge reset)
  if (reset) begin
     init_done <= #tDLY 0;
  end else
    case (istate)
      i_ready: init_done <= #tDLY 1;
      default: init_done <= #tDLY 0;
    endcase


    // CMD_FSM state machine

always @(posedge clk or posedge reset)
  if (reset) begin
     cstate <= #tDLY c_idle;
  end else
    case (cstate)
      c_idle:   // wait until refresh request or addr strobe asserted
                if (ref_req && init_done) cstate <= #tDLY c_AR;
                else if (!addrs && init_done) cstate <= #tDLY c_ACTIVE;
      c_ACTIVE: // assert row/bank addr
                if (NUM_CLK_tRCD == 0)
                   cstate <= #tDLY (rd_wr) ? c_READA : c_WRITEA;
                else cstate <= #tDLY c_tRCD;
      c_tRCD:   // wait until tRCD satisfied
                if (`endOf_tRCD)
                   cstate <= #tDLY (rd_wr) ? c_READA : c_WRITEA;
      c_READA:  // assert col/bank addr for read with auto-precharge
                cstate <= #tDLY c_cl;
      c_cl:     // CASn latency
                if (`endOf_Cas_Latency) cstate <= #tDLY c_rdata;
      c_rdata:  // read cycle data phase
                if (`endOf_Read_Burst) cstate <= #tDLY c_idle;
      c_WRITEA: // assert col/bank addr for write with auto-precharge
                cstate <= #tDLY c_wdata;
      c_wdata:  // write cycle data phase
                if (`endOf_Write_Burst) cstate <= #tDLY c_tDAL;
      c_tDAL:   // wait until (tWR + tRP) satisfied before issuing next
                // SDRAM ACTIVE command
                if (`endOf_tDAL) cstate <= #tDLY c_idle;
      c_AR:     // auto-refresh
                cstate <= #tDLY (NUM_CLK_tRFC == 0) ? c_idle : c_tRFC;
      c_tRFC:   // wait until tRFC satisfied
                if (`endOf_tRFC) cstate <= #tDLY c_idle;
      default:
                cstate <= #tDLY c_idle;
    endcase


//refresh acknowledgement

always @(posedge clk or posedge reset)
  if (reset) begin
     ref_ack <= #tDLY 0;
  end else
    case (cstate)
      c_idle:
         if (ref_req && init_done) ref_ack <= #tDLY 1;
         else ref_ack <= #tDLY 0;
      c_AR:
         if (NUM_CLK_tRFC == 0) ref_ack <= #tDLY 0;
         else ref_ack <= #tDLY 1;
      default:
         ref_ack <= #tDLY 0;
    endcase



always @(posedge clk or posedge reset)
  if (reset) begin
     cy_end <= #tDLY 1;
  end else
    case (cstate)
      c_idle:
         if (ref_req && init_done) cy_end <= #tDLY 1;
         else if (!addrs && init_done) cy_end <= #tDLY 0;
         else cy_end <= #tDLY 1;
      c_ACTIVE,
      c_tRCD,
      c_READA,
      c_cl,
      c_WRITEA,
      c_wdata:
         cy_end <= #tDLY 0;
      c_rdata:
        cy_end <= #tDLY (`endOf_Read_Burst) ? 1 : 0;
      c_tDAL:
         cy_end <= #tDLY (`endOf_tDAL) ? 1 : 0;
      default:
         cy_end <= #tDLY 1;
    endcase

// Clock Counter
//
always @(posedge clk)
  if (syncResetclk) clk_count <= #tDLY 0;
  else clk_count <= #tDLY clk_count + 1;

//
// syncResetClkCNT generation
//
always @(istate or cstate or clk_count)
  case (istate)
    i_PRE:
         syncResetclk <= #tDLY (NUM_CLK_tRP == 0) ? 1 : 0;
    i_AR1,
    i_AR2:
         syncResetclk <= #tDLY (NUM_CLK_tRFC == 0) ? 1 : 0;
    i_NOP:
         syncResetclk <= #tDLY 1;
    i_tRP:
         syncResetclk <= #tDLY (`endOf_tRP) ? 1 : 0;
    i_tMRD:
         syncResetclk <= #tDLY (`endOf_tMRD) ? 1 : 0;
    i_tRFC1,
    i_tRFC2:
         syncResetclk <= #tDLY (`endOf_tRFC) ? 1 : 0;
    i_ready:
         case (cstate)
           c_ACTIVE:
                syncResetclk <= #tDLY (NUM_CLK_tRCD == 0) ? 1 : 0;
           c_idle:
                syncResetclk <= #tDLY 1;
           c_tRCD:
                syncResetclk <= #tDLY (`endOf_tRCD) ? 1 : 0;
           c_tRFC:
                syncResetclk <= #tDLY (`endOf_tRFC) ? 1 : 0;
           c_cl:
                syncResetclk <= #tDLY (`endOf_Cas_Latency) ? 1 : 0;
           c_rdata:
                syncResetclk <= #tDLY (clk_count == NUM_CLK_READ) ? 1 : 0;
           c_wdata:
                syncResetclk <= #tDLY (`endOf_Write_Burst) ? 1 : 0;
           default:
                syncResetclk <= #tDLY 0;
         endcase
    default:
         syncResetclk <= #tDLY 0;
  endcase

endmodule : sdr_ctrl