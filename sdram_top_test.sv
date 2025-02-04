
`include "sdr_top.v"

module sdr_tb;

wire sys_R_Wn;      // read/write#
wire sys_ADSn;      // address strobe
wire sys_DLY_100US; // sdr power and clock stable for 100 us
wire sys_CLK;       // sdr clock
wire sys_RESET;     // reset signal
wire sys_REF_REQ;   // sdr auto-refresh request
wire sys_REF_ACK;   // sdr auto-refresh acknowledge
wire [23:1] sys_A;  // address bus
wire [15:0] sys_D;  // data bus
wire sys_D_VALID;   // data valid
wire sys_CYC_END;   // end of current cycle
wire sys_INIT_DONE; // initialization completed, ready for normal operation

wire [3:0] sdr_DQ;  // sdr data
wire [11:0] sdr_A;  // sdr address
wire [1:0] sdr_BA;  // sdr bank address
wire sdr_CKE;       // sdr clock enable
wire sdr_CSn;       // sdr chip select
wire sdr_RASn;      // sdr row address
wire sdr_CASn;      // sdr column select
wire sdr_WEn;       // sdr write enable
wire sdr_DQM;       // sdr write data mask

//---------------------------------------------------------------------
// modules

sdr_top UUT(
  .sys_R_Wn(sys_R_Wn),      // read/write#
  .sys_ADSn(sys_ADSn),      // address strobe
  .sys_DLY_100US(sys_DLY_100US), // sdr power and clock stable for 100 us
  .sys_CLK(sys_CLK),       // sdr clock
  .sys_RESET(sys_RESET),     // reset signal
  .sys_REF_REQ(sys_REF_REQ),   // sdr auto-refresh request
  .sys_REF_ACK(sys_REF_ACK),   // sdr auto-refresh acknowledge
  .sys_A(sys_A),         // address bus
  .sys_Data(sys_D),         // data bus
  .sys_D_VALID(sys_D_VALID),   // data valid
  .sys_CYC_END(sys_CYC_END),   // end of current cycle
  .sys_INIT_DONE(sys_INIT_DONE), // initialization completed, ready for normal operation

  .sdr_DQ(sdr_DQ),        // sdr data
  .sdr_A(sdr_A),         // sdr address
  .sdr_BA(sdr_BA),        // sdr bank address
  .sdr_CKE(sdr_CKE),       // sdr clock enable
  .sdr_CSn(sdr_CSn),       // sdr chip select
  .sdr_RASn(sdr_RASn),      // sdr row address
  .sdr_CASn(sdr_CASn),      // sdr column select
  .sdr_WEn(sdr_WEn),       // sdr write enable
  .sdr_DQM(sdr_DQM)        // sdr write data mask
);

system STIMULUS(
  .sys_CLK(sys_CLK),
  .sys_RESET(sys_RESET),
  .sys_A(sys_A),
  .sys_ADSn(sys_ADSn),
  .sys_R_Wn(sys_R_Wn),
  .sys_D(sys_D),
  .sys_DLY_100US(sys_DLY_100US),
  .sys_REF_REQ(sys_REF_REQ),
  .sys_CYC_END(sys_CYC_END),
  .sys_INIT_DONE(sys_INIT_DONE)
);


sdr SDR_SDRAM(
  sdr_DQ,
  sdr_A,
  sdr_BA,
  sys_CLK,
  sdr_CKE,
  sdr_CSn,
  sdr_RASn,
  sdr_CASn,
  sdr_WEn,
  sdr_DQM
);

endmodule

module sdr (
  sdr_DQ,        // sdr data
  sdr_A,         // sdr address
  sdr_BA,        // sdr bank address
  sdr_CK,        // sdr clock
  sdr_CKE,       // sdr clock enable
  sdr_CSn,       // sdr chip select
  sdr_RASn,      // sdr row address
  sdr_CASn,      // sdr column select
  sdr_WEn,       // sdr write enable
  sdr_DQM        // sdr write data mask
);


parameter Num_Meg    =  8; 
parameter Data_Width =  4;
parameter Num_Bank   =  4; 

parameter tAC = 5.4;
parameter tOH = 2.7;

parameter SDR_A_WIDTH  =  12;
parameter SDR_BA_WIDTH =  2; 

parameter MEG = 21'h100000;
parameter MEM_SIZE = Num_Meg * MEG * Num_Bank;
parameter ROW_WIDTH = 12;
parameter COL_WIDTH = (Data_Width ==  4) ? 11 :
                      (Data_Width ==  8) ? 10 :
                      (Data_Width == 16) ?  9 : 0;



input [SDR_A_WIDTH-1:0]  sdr_A;
input [SDR_BA_WIDTH-1:0] sdr_BA;
input                    sdr_CK;
input                    sdr_CKE;
input                    sdr_CSn;
input                    sdr_RASn;
input                    sdr_CASn;
input                    sdr_WEn;
input                    sdr_DQM;
inout [Data_Width-1:0]   sdr_DQ;



reg [Data_Width-1:0] Memory [*];    // for sdram storage
reg [Data_Width-1:0] Memory_read [*];   // for verification of data stored

reg [2:0]              casLatency;
reg [2:0]              burstLength;

reg [SDR_BA_WIDTH-1:0] bank;
reg [ROW_WIDTH-1:0]    row;
reg [COL_WIDTH-1:0]    column;

reg [3:0] counter;   

reg [Data_Width-1:0]   dataOut;
reg enableSdrDQ;

reg write;
reg latency;
reg read;
reg [15:0]read_count;
reg [15:0]write_count;



// code
//
initial begin
  casLatency = 0;
  burstLength = 0;
  bank = 0;
  row = 0;
  column = 0;
  counter = 0;
  dataOut = 0; //stores read operations
  enableSdrDQ = 0;
  write = 0;
  latency = 0;
  read = 0;
  read_count = 0;
  write_count = 0;
end

assign sdr_DQ =
         (Data_Width ==  4) ? (enableSdrDQ ? dataOut :  4'hz) :
         (Data_Width ==  8) ? (enableSdrDQ ? dataOut :  8'hzz) :
         (Data_Width == 16) ? (enableSdrDQ ? dataOut : 16'hzzzz) : 0;

always @(posedge sdr_CK)
  case ({sdr_CSn,sdr_RASn,sdr_CASn,sdr_WEn})
    4'b0000: begin
               $display($time,"ns : Load Mode Register 0x%h",sdr_A);
               casLatency = sdr_A[6:4];
               burstLength = (sdr_A[2:0] == 3'b000) ? 1 :
                             (sdr_A[2:0] == 3'b001) ? 2 :
                             (sdr_A[2:0] == 3'b010) ? 4 :
                             (sdr_A[2:0] == 3'b011) ? 8 : 0;
               $display($time,
                     "ns : mode: CAS Latency=0x%h, Burst Length=0x%h",
                     casLatency, burstLength);
             end
    4'b0001: $display($time,"ns : Auto Refresh Command");
    4'b0010:  begin
                 $display($time,"ns : Precharge Command");
               // bank_active[sdr_BA] = 0;
            end
    4'b0011: begin
                $display($time,"ns : Activate Command");
               if (bank == sdr_BA && row != sdr_A) begin
                 $display($time,"ns : Row change detected. Issuing Precharge Command.");
                 
               end
               $display($time,"ns : Activate Command");

               row = sdr_A;
             end
    4'b0100: begin
               $display($time,"ns : Write Command");
               column = (Data_Width ==  4) ? {sdr_A[11],sdr_A[9:0]} :
                        (Data_Width ==  8) ? {sdr_A[9:0]} :
                        (Data_Width == 16) ? {sdr_A[8:0]} : 0;
               bank = sdr_BA;
               write = 1;
               counter = burstLength;
               Memory[{row,column,bank}] = sdr_DQ;
               $display($time,
                     "ns :write: Bank=0x%h, Row=0x%h, Column=0x%h, Data=0x%h",
                     bank, row, column, sdr_DQ);
        write_count = write_count +1;
             end
    4'b0101: begin
               $display($time,"ns : Read Command");
               column = (Data_Width ==  4) ? {sdr_A[11],sdr_A[9:0]} :
                        (Data_Width ==  8) ? {sdr_A[9:0]} :
                        (Data_Width == 16) ? {sdr_A[8:0]} : 0;
               bank = sdr_BA;
               counter = {1'b0,casLatency} - 1;
               latency = 1;
             end
    4'b0110: $display($time,"ns : Burst Terminate");
    4'b0111: begin
//               $display($time,"ns : Nop Command");
               if ((write == 1) && (counter != 0))
                 begin
                   counter = counter - 1;
                   if (counter == 0) write = 0;
                   else
                     begin
                       column = column + 1;
                       Memory[{row,column,bank}] = sdr_DQ;
             write_count = write_count +1;
                       $display($time,
                         "ns :write: Bank=0x%h, Row=0x%h, Column=0x%h, Data=0x%h",
                         bank, row, column, sdr_DQ);
                     end
                 end
               else if ((read == 1) && (counter != 0))
                 begin
                   counter = counter - 1;
                   if (counter == 0)
                     begin
                       read = 0;
                       enableSdrDQ = #tOH 0;
                     end
                   else
                     begin
                       column = column + 1;
                       dataOut = #tAC Memory[{row,column,bank}];
             read_count = read_count +1;
             Memory_read[{row,column,bank}] = dataOut;
                       $display($time,
                         "ns : read: Bank=0x%h, Row=0x%h, Column=0x%h, Data=0x%h",
                         bank, row, column, dataOut);
             
                     end
                 end
               else if ((latency == 1) && (counter != 0))
                 begin
                   counter = counter - 1;
                   if (counter == 0)
                     begin
                       latency = 0;
                       read = 1;
                       counter = burstLength;
                       dataOut = #tAC Memory[{row,column,bank}];
             read_count = read_count +1;
             Memory_read[{row,column,bank}] = dataOut;
                       enableSdrDQ = 1;
                       $display($time,
                         "ns : read: Bank=0x%h, Row=0x%h, Column=0x%h, Data=0x%h",
                         bank, row, column, dataOut);
                     end
                 end
             end
  endcase

reg flag;
integer i;
always @(posedge sdr_CK)
begin
flag=1;

if ((read_count == write_count) && (write_count != 0))
  begin
   $display("the read count : %d",read_count);
 $display("the write count : %d",write_count);

  for (i = 0; i < Memory.size();i = i+1)
    begin
      if(Memory.exists(i))
      begin
        
      $display("Memory_read %0h ",Memory_read[i]);
      $display("Memory %0h ",Memory[i]);
    if (Memory[i] == Memory_read[i])
    begin 
      flag=1 & flag;
    end
    // else if(read_count == write_count) begin
      // flag=1;
    // end
    else
    begin
      flag=0 & flag;
    end
    end
  end
    $display("------------------------------------------------------------");
  if (flag)
    $display("----------------------TEST PASS-----------------------------");
  else
    $display("----------------------TEST FAIL-----------------------------");
    
    $display("------------------------------------------------------------");
    
    
  $stop;
  end
end 
endmodule





module system(
  sys_CLK,
  sys_RESET,
  sys_A,
  sys_ADSn,
  sys_R_Wn,
  sys_D,
  sys_DLY_100US,
  sys_REF_REQ,
  sys_CYC_END,
  sys_INIT_DONE
);



`include "sdr_para.v"
//---------------------------------------------------------------------
// outputs & registers
//
output        sys_CLK;
output        sys_RESET;
output [23:1] sys_A;
output        sys_ADSn;
output        sys_R_Wn;
output [15:0] sys_D;
output        sys_DLY_100US;
output        sys_REF_REQ;

input         sys_CYC_END;
input         sys_INIT_DONE;

wire           sys_CLK;
reg           sys_CLK_int;
reg           sys_CLK_en;
reg           sys_RESET;
reg [23:1]    sys_A;
reg           sys_ADSn;
reg           sys_R_Wn;
reg [15:0]    sys_D;
reg           sys_DLY_100US;
reg           sys_REF_REQ;

wire          sys_CYC_END;

//---------------------------------------------------------------------
// parameters -- change to whatever you like
//
parameter clock_time = 100;
parameter reset_time = 1000;

parameter sys_CLK_period = tCK;

//---------------------------------------------------------------------
// tasks
//
task write;
    input [23:1] addr;
    input [15:0] data;
  begin
    sys_A = addr;
    sys_ADSn = 0;  //addrs strobe setting to 0 when new mem is
    sys_R_Wn = 0;
    #sys_CLK_period;
    sys_ADSn = 1;
    sys_D = data;
    #(sys_CLK_period * (NUM_CLK_WRITE + NUM_CLK_WAIT + 4));
    sys_D = 16'hzzzz;
    sys_R_Wn = 1;
    sys_A = 24'hzzzzzz;
  end
endtask

task read;
    input [23:1] addr;
  begin
    sys_A = addr;
    sys_ADSn = 0;
    sys_R_Wn = 1;
    #sys_CLK_period;
    sys_ADSn = 1;
    #(sys_CLK_period * (NUM_CLK_CL + NUM_CLK_READ + 3));
    sys_R_Wn = 1;
    sys_A = 24'hzzzzzz;
  end
endtask

//---------------------------------------------------------------------
// code
//
initial begin
    sys_R_Wn    <= #1 1'b1;
    sys_ADSn    <= #1 1'b1;
    sys_DLY_100US   <= #1 1'b0;
    sys_REF_REQ <= #1 1'b0;
    sys_CLK_int <= #1 1'b0;
    sys_RESET   <= #1 1'b1;
    sys_A       <= #1 24'hFFFFFF;
    sys_D       <= #1 16'hzzzz;
    sys_CLK_en  <= #1 1'b0;
    #clock_time;
    sys_CLK_en  <= #1 1'b1;
    #reset_time;
    @(posedge sys_CLK);
    $display($time,"ns : Coming Out Of Reset");
    sys_RESET    <= #1 1'b0;
    #100001;
    sys_DLY_100US    <= #1 1'b1;
    @(posedge sys_INIT_DONE);
    #500;
    @(negedge sys_CLK);
      write(23'h000000, 16'h1234);
    //   write(23'h000200, 16'h5678);
       write(23'h000400, 16'h9ABC);
    // write(23'h000600, 16'hDEF0);
   
      //write(23'h000000, 16'h1567);
      write(23'h000001, 16'h5674);
      write(23'h100001, 16'h1111);
    // write(23'h001300, 16'h5678);
     
   
      read(23'h000000);
      // read(23'h000200);
       read(23'h000400);
      // read(23'h000600);
       read(23'h000001);
       read(23'h100001);
      //  read(23'h001300);
      
    
//    $stop;
end

always
    #(sys_CLK_period/2) sys_CLK_int <= ~sys_CLK_int;

assign sys_CLK = sys_CLK_en & sys_CLK_int;

endmodule

