
 	
parameter tDLY = 2; // 2ns delay for simulation purpose


parameter Programmed_Length = 1'b0;
parameter Single_Access     = 1'b1;

// Operation Mode
parameter Standard          = 2'b00; 

// CAS Latency
parameter Latency_2         = 3'b010;
parameter Latency_3         = 3'b011;

// Burst Type
parameter Sequential        = 1'b0;
parameter Interleaved       = 1'b1;

// Burst Length
parameter Length_1          = 3'b000;
parameter Length_2          = 3'b001;
parameter Length_4          = 3'b010;
parameter Length_8          = 3'b011;



// register mode setting

parameter Write_Burst_Mode =    Programmed_Length;
                                
parameter Operation_Mode   =    Standard;

parameter CAS_Latency      =    Latency_3;

parameter Burst_Type       =    Sequential;
                               

parameter Burst_Length     =    Length_4;
                                

// Bus width setting

// Row    : RA_MSB <--> RA_LSB  = 13
// Bank   :                    BA_MSB <--> BA_LSB =2
// Column :                                       CA_MSB <--> CA_LSB = 9
//

parameter RA_MSB = 22;
parameter RA_LSB = 11;

parameter BA_MSB = 10;
parameter BA_LSB =  9;

parameter CA_MSB =  8;
parameter CA_LSB =  0;

parameter SDR_BA_WIDTH =  2; // BA0,BA1
parameter SDR_A_WIDTH  = 12; 


// SDRAM AC timing spec  in nanoseconds

parameter tCK  = 20;
parameter tMRD = 2*tCK;
parameter tRP  = 15;      //precharge
parameter tRFC = 66;      //refresh cycle
parameter tRCD = 15;      // row to col delay
parameter tWR  = tCK + 7;   //Write recovery time
parameter tDAL = tWR + tRP;  //data in  to activation


// Converts timing specifications from nanoseconds to clock cycles.

parameter NUM_CLK_tMRD = tMRD/tCK;
parameter NUM_CLK_tRP  =  tRP/tCK;
parameter NUM_CLK_tRFC = tRFC/tCK;
parameter NUM_CLK_tRCD = tRCD/tCK;
parameter NUM_CLK_tDAL = tDAL/tCK;

parameter NUM_CLK_WAIT = 0; 
parameter NUM_CLK_CL    = 3;
parameter NUM_CLK_READ  = 4;
parameter NUM_CLK_WRITE = 4;



// INIT_FSM state 


parameter i_NOP   = 4'b0000;
parameter i_PRE   = 4'b0001;
parameter i_tRP   = 4'b0010;
parameter i_AR1   = 4'b0011;
parameter i_tRFC1 = 4'b0100;
parameter i_AR2   = 4'b0101;
parameter i_tRFC2 = 4'b0110;
parameter i_MRS   = 4'b0111;  // mode reg set
parameter i_tMRD  = 4'b1000;  //timing for mrs
parameter i_ready = 4'b1001;  


// CMD_FSM  for controller logic


parameter c_idle   = 4'b0000;
parameter c_tRCD   = 4'b0001;
parameter c_cl     = 4'b0010;
parameter c_rdata  = 4'b0011;
parameter c_wdata  = 4'b0100;
parameter c_tRFC   = 4'b0101;
parameter c_tDAL   = 4'b0110;
parameter c_ACTIVE = 4'b1000;
parameter c_READA  = 4'b1001;
parameter c_WRITEA = 4'b1010;
parameter c_AR     = 4'b1011;

 
//sdram commands

parameter INHIBIT            = 4'b1111;  //nop the bus in inactive
parameter NOP                = 4'b0111;  // nop in current state
parameter ACTIVE             = 4'b0011;  //open a row in specific bank
parameter READ               = 4'b0101;
parameter WRITE              = 4'b0100;
parameter BURST_TERMINATE    = 4'b0110;
parameter PRECHARGE          = 4'b0010;  //close a row in a specfic bank
parameter AUTO_REFRESH       = 4'b0001;
parameter LOAD_MODE_REGISTER = 4'b0000;


