`timescale 1ns / 1ps

// Addition Module(16 bit)

//Basic B_Cell to generate Pi's && Gi's 
module b_cell(
	 input x,
	 input y,
	 output p,
	 output g
	 );
	 
	 assign p = x ^ y;
	 assign g = x & y;
endmodule

//4 bit CLA adder logic 
module cla_4bit(
     input [3 : 0] a,
	 input [3 : 0] b,
	 input c_in,
	 output [3 : 0] sum,
	 output c_out
	 );
	 
	 wire [3:0]p;
	 wire [3:0]g;
	 
	 b_cell PG1(a[0], b[0], p[0], g[0]);
	 b_cell PG2(a[1], b[1], p[1], g[1]);
	 b_cell PG3(a[2], b[2], p[2], g[2]);
	 b_cell PG4(a[3], b[3], p[3], g[3]);
	 
	 wire [3:1]c;
	 
	 assign c[1] = g[0] | (p[0] & c_in);
	 assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c_in);
	 assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c_in);
	 assign c_out = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c_in);
	 
	 assign sum[0] = p[0] ^ c_in;
	 assign sum[1] = p[1] ^ c[1];
	 assign sum[2] = p[2] ^ c[2];
	 assign sum[3] = p[3] ^ c[3];

endmodule

//Main adder by cascading 4 X (4 bit CLAs)
module cla_cascade_16(
     input [15 : 0] a,
	 input [15 : 0] b,
	 input c_in,
	 output reg [16 : 0] sum1
	 );
	 
	 wire [16:0] sum;
	 wire [4:1]c;
	 
	 cla_4bit cl0(a[3 : 0], b[3 : 0], c_in, sum[3 : 0], c[1]);
	 cla_4bit cl1(a[7 : 4], b[7 : 4], c[1], sum[7 : 4], c[2]);
	 cla_4bit cl2(a[11 : 8], b[11 : 8], c[2], sum[11 : 8], c[3]);
	 cla_4bit cl3(a[15: 12], b[15 : 12], c[3], sum[15 : 12], c[4]);
	 assign sum[16] = c[4];
	 
	 always@(*)
	 begin
	 sum1=sum;
	 end

endmodule

//%-------------------


//Booth Multiplier

module booth_multiplication(multiplicand, multiplier,prod);
  output reg signed [31:0] prod;
  input signed [15:0] multiplicand, multiplier;

  reg [1:0] store;
  integer i;
  reg lsb_bit;
  reg [15:0] comp_multiplier;

  always @(multiplicand,multiplier)
  begin
    prod = 32'd0;
    lsb_bit = 1'b0;
    comp_multiplier = -multiplier;
    
    for (i=0; i<16; i=i+1)
    begin
      store = { multiplicand[i], lsb_bit };
      case(store)
        2'd2 : prod[31:16] = prod[31:16] + comp_multiplier; 
        2'd1 : prod[31:16] = prod[31:16] + multiplier; 
      endcase
      prod = prod >> 1; 
      prod[31] = prod[30];
      lsb_bit=multiplicand[i];
      
    end
  end
  
endmodule

//%-----------------------------------


// Restoring Division Module starts here
module restoring_division(
     input [15 : 0] Dividend,
	 input [15 : 0] Divisor,
	 output reg [15 : 0] Quotient,
	 output reg [15 : 0] Remainder
	 );
	 
	 reg [15 : 0] Q, A, M;
	 integer n;
	 
	 always@(*)
		begin
			A = 0;
			Q = Dividend;
			M = Divisor;
			for(n = 16; n > 0; n = n - 1)
				begin
				
					A = {A[14 : 0], Q[15]};
					Q[15 : 1] = Q[14 : 0];
					A = A - M;
					if(A[15] == 0)			Q[0] = 1;
					else
						begin
							Q[0] = 0;
							A = A + M;
						end
				end
				
		Quotient = Q;
		Remainder = A;
				
		end
		
endmodule
// Restoring Division Module ends here


module ALU(
     input [3 : 0] S,
	 input [15 : 0] A, 
	 input [15 : 0] B,
	 output reg [31 : 0] Z
	 );
	 
	 wire [16 : 0] add;
	 wire [16 : 0] sub;
	 wire [31 : 0] mult;
	 wire [15 : 0] div, rem;
	 //Instantiating Adder
	 cla_cascade_16 cl0(A, B, 0, add);
	 
	 //Instantiating Subtractor
	 cla_cascade_16 cl1(A, -B, 0, sub);
	 
	 //Instantiating multiplier
	 booth_multiplication bm1(A, B, mult);
	 
	 //Instantiating divider
	 restoring_division rd0(A, B, div, rem);
	 
	 reg [15 : 0] X = 0;
     reg [15 : 0] Y = 0;
		
	 always@(*)
		 begin
			 X = A;
			 Y = B;
			case(S)
			     //Arithmetic Operations
				 0 : Z = {{16{add[15]}},add[15:0]};
				 1 : Z = {{16{sub[15]}},sub[15:0]}; //Sign extension: Extending 16 to 32 bits
				 2 : Z = mult;
				 3 : Z = div;
				 4 : Z = A<<1;//Left Shift
				 5 : Z = A>>1;//Right Shift
				 6 : Z[15 : 0] = {A[14 : 0], A[15]};//Rotate Left
				 7 : Z[15 : 0] = {A[0], A[15 : 1]};//Rotate Right
				 
				 //Bitwise Operations
				 8 : Z = A & B;
				 9 : Z = A | B;
				 10 : Z = A ^ B;
				 11 : Z = ~(A | B);
				 12 : Z = ~(A & B);
				 13 : Z = ~(A ^ B);
				 
				 //Comparator Operations
				 14 : Z = (A > B)?32'd1 : 32'd0;
				 15 : Z = (A < B)?32'd1 : 32'd0;
				 
				 default : Z = 0;
			 endcase
			 
		end
		
endmodule

//Testbench Module

module alu_tb;
reg [3:0]S;
reg signed [15:0] A,B;
wire signed [31:0]Z;

ALU uut(S,A,B,Z);

initial 
begin
$dumpfile("alu.vcd");
$dumpvars(0,alu_tb);
$monitor(" A=%b(%d)  | B=%b(%d)  | S=(%d)   |  Z=%b(%d)",A,A,B,B,S,Z,Z);

//Sum Testcases
A=166;
B=235;
S=0;
#10;
A=342;
B=99;
S=0;
#10;

//Subtraction testcases
A=-342;
B=3;
S=1;
#10;

A=549;
B=45;
S=1;
#10;


//Multiplication testcases
A=86;
B=97;
S=2;
#10;

A=771;
B=-44;
S=2;
#10;

//Division testcases
A=99;
B=3;
S=3;
#10;

A=725;
B=34;
S=3;
#10;

//Left shift testcases

A=755;

S=4;
#10;

//Right shift testcases

A=754;
S=5;
#10;

//Rotation Test Case(Left)
A=557;
S=6;
#10;

//Rotation Test Case(Right)
A=559;
S=7;
#10;

//Bitwise AND
A=425;
B=23;
S=8;
#10;

//Bitwise OR
A=655;
B=23;
S=9;
#10;

//Bitwise XOR
A=564;
B=23;
S=10;
#10;

//Bitwise NOR
A=353;
B=77;
S=11;
#10;

//Bitwise NAND
A=423;
B=43;
S=12;
#10;

//Bitwise XNOR
A=43245;
B=443;
S=13;
#10;

//A>B?
A=75;
B=23;
S=14;
#10;

//A==B?
A=445;
B=23;
S=15;
#10;
$finish();
end

endmodule
