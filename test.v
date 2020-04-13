`timescale 1ns / 1ps
/*I2C功能模块仿真
时钟选取20MHz
*/
module test;

	// Inputs
	reg CLK;
	reg RSTn;
	reg [1:0] Start_Sig;
	reg [7:0] Addr_Sig;
	reg [7:0] WrData;

	// Outputs
	wire [7:0] RdData;
	wire Done_Sig;
	wire SCL;
	wire [4:0] SQ_i;

	// Bidirs
	wire SDA;
   reg treg_SDA;
	assign SDA = treg_SDA;
	
	// Instantiate the Unit Under Test (UUT)
	iic_func_module uut (
		.CLK(CLK), 
		.RSTn(RSTn), 
		.Start_Sig(Start_Sig), 
		.Addr_Sig(Addr_Sig), 
		.WrData(WrData), 
		.RdData(RdData), 
		.Done_Sig(Done_Sig), 
		.SCL(SCL), 
		.SDA(SDA), 
		.SQ_i(SQ_i)
	);

/***************************/
  initial
    begin
      RSTn = 0; #10 RSTn = 1;
      CLK = 1; forever #25 CLK = ~CLK;
    end
/******************************/
      reg [3:0]i;
always @ ( posedge CLK or negedge RSTn )
   if( !RSTn )
     begin
       i <= 4'd0;
       Start_Sig <= 2'd0;
       Addr_Sig <= 8'd0;
       WrData <= 8'd0;
     end
   else
       case( i )
		   0:
           if( Done_Sig ) 
			     begin 
				    Start_Sig <= 2'd0; i <= i + 1'b1; 
			     end
           else 
			     begin 
				  Start_Sig <= 2'b01; Addr_Sig <= 8'b10101010; WrData <= 8'b10101010; 
				  end
		   1:
           if( Done_Sig ) 
			     begin 
				    Start_Sig <= 2'd0; i <= i + 1'b1; 
				  end
           else 
			     begin 
				    Start_Sig <= 2'b10; Addr_Sig <= 8'b10101010; 
				  end
         2:
               i <= i;
        endcase
always @ ( posedge CLK or negedge RSTn )
  if( !RSTn )
    treg_SDA <= 1'b1;
  else if( Start_Sig[0] )
    case( SQ_i )
      15: treg_SDA = 1'b0;//即时结果
      default treg_SDA = 1'b1;
    endcase
  else if( Start_Sig[1] )
    case(SQ_i)
      17: 
		  treg_SDA = 1'b0;
      19,20,21,22,23,24,25,26:
        treg_SDA = WrData[26-SQ_i];
      default treg_SDA = 1'b1;
    endcase	
	
		
		
		
		
		
endmodule

