// sdram controller which generate signals req to interface with sdram

`define sdr_COMMAND  {sdr_CSn, sdr_RASn, sdr_CASn, sdr_WEn}

module sdr_signals (

				  clk,
				  reset,
				  sys_A,
				  iState,
				  cState,
				  sdr_CKE,    // sdr clock enable
				  sdr_CSn,    // sdr chip select
				  sdr_RASn,   // sdr row address
				  sdr_CASn,   // sdr column select
				  sdr_WEn,    // sdr write enable
				  sdr_BA,     // sdr bank address
				  sdr_A       // sdr address
				);

`include "sdr_para.v"


input                     	  clk;
input                     	  reset;
input [RA_MSB:CA_LSB]     	  sys_A;
input [3:0]               	  iState;
input [3:0]               	  cState;
output  reg                   sdr_CKE;
output  reg                   sdr_CSn;
output  reg                   sdr_RASn;
output  reg                   sdr_CASn;
output  reg                   sdr_WEn;
output reg [SDR_BA_WIDTH-1:0] sdr_BA;
output reg [SDR_A_WIDTH-1:0]  sdr_A;


// SDR SDRAM Control Singals

always @(posedge clk or posedge reset)
  if (reset) begin
    `sdr_COMMAND <= #tDLY INHIBIT;
    sdr_CKE <= #tDLY 1'b0;
    sdr_BA  <= #tDLY {SDR_BA_WIDTH{1'b1}};
    sdr_A   <= #tDLY {SDR_A_WIDTH{1'b1}};
  end else
    case (iState)
      i_tRP,
      i_tRFC1,
      i_tRFC2,
      i_tMRD,
      i_NOP: begin
               `sdr_COMMAND <= #tDLY NOP;
               sdr_CKE <= #tDLY 1'b1;
               sdr_BA  <= #tDLY {SDR_BA_WIDTH{1'b1}};
               sdr_A   <= #tDLY {SDR_A_WIDTH{1'b1}};
             end
      i_PRE: begin
               `sdr_COMMAND <= #tDLY PRECHARGE;
               sdr_CKE <= #tDLY 1'b1;
               sdr_BA  <= #tDLY {SDR_BA_WIDTH{1'b1}};
               sdr_A   <= #tDLY {SDR_A_WIDTH{1'b1}};
             end
      i_AR1,
      i_AR2: begin
               `sdr_COMMAND <= #tDLY AUTO_REFRESH;
               sdr_CKE <= #tDLY 1'b1;
               sdr_BA  <= #tDLY {SDR_BA_WIDTH{1'b1}};
               sdr_A   <= #tDLY {SDR_A_WIDTH{1'b1}};
             end
      i_MRS: begin
               `sdr_COMMAND <= #tDLY LOAD_MODE_REGISTER;
               sdr_CKE <= #tDLY 1'b1;
               sdr_BA  <= #tDLY {SDR_BA_WIDTH{1'b0}};
               sdr_A   <= #tDLY {
                            2'b00,
                            Write_Burst_Mode,
                            Operation_Mode,
                            CAS_Latency,
                            Burst_Type,
                            Burst_Length
                          };
             end
      i_ready:
             case (cState)
               c_idle,
               c_tRCD,
               c_tRFC,
               c_cl,
               c_rdata,
               c_wdata:  begin
                           `sdr_COMMAND <= #tDLY NOP;
                           sdr_CKE <= #tDLY 1'b1;
                           sdr_BA  <= #tDLY {SDR_BA_WIDTH{1'b1}};
                           sdr_A   <= #tDLY {SDR_A_WIDTH{1'b1}};
                         end
               c_ACTIVE: begin
                           `sdr_COMMAND <= #tDLY ACTIVE;
                           sdr_CKE <= #tDLY 1'b1;
                           sdr_BA  <= #tDLY sys_A[BA_MSB:BA_LSB];//bank
                           sdr_A   <= #tDLY sys_A[RA_MSB:RA_LSB];//row
                         end
               c_READA:  begin
                           `sdr_COMMAND <= #tDLY READ;
                           sdr_CKE <= #tDLY 1'b1;
                           sdr_BA  <= #tDLY sys_A[BA_MSB:BA_LSB];//bank
                           sdr_A   <= #tDLY {
                                        sys_A[CA_MSB],//column
                                        1'b1, //enable auto precharge
                                        sys_A[CA_MSB-1:CA_LSB],//column
                                        2'b00 //2 '0'(burst length 4)
                                      };
                           end
               c_WRITEA: begin
                           `sdr_COMMAND <= #tDLY WRITE;
                           sdr_CKE <= #tDLY 1'b1;
                           sdr_BA  <= #tDLY sys_A[BA_MSB:BA_LSB];//bank
                           sdr_A   <= #tDLY {
                                        sys_A[CA_MSB],//column
                                        1'b1, //enable auto precharge
                                        sys_A[CA_MSB-1:CA_LSB],//column
                                        2'b00 
                                      };
                         end
               c_AR:     begin
                           `sdr_COMMAND <= #tDLY AUTO_REFRESH;
                           sdr_CKE <= #tDLY 1'b1;
                           sdr_BA  <= #tDLY {SDR_BA_WIDTH{1c'b1}};
                           sdr_A   <= #tDLY {SDR_A_WIDTH{1'b1}};
                         end
               default:  begin
                           `sdr_COMMAND <= #tDLY NOP;
                           sdr_CKE <= #tDLY 1'b1;
                           sdr_BA  <= #tDLY {SDR_BA_WIDTH{1'b1}};
                           sdr_A   <= #tDLY {SDR_A_WIDTH{1'b1}};
                         end
             endcase
      default:
             begin
               `sdr_COMMAND <= #tDLY NOP;
               sdr_CKE <= #tDLY 1'b1;
               sdr_BA  <= #tDLY {SDR_BA_WIDTH{1'b1}};
               sdr_A   <= #tDLY {SDR_A_WIDTH{1'b1}};
             end
    endcase

endmodule
