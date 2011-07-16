//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2010 Spring
//   Lab02      : PID
//   Author     : Ju-Hung Hsiao (ju0909@si2lab.org)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PID.v
//   Module Name : PID
//   Release version : V1.0 (Release Date: 2010-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

// by danielsig727, 2011 summer
module PID(//input
           MODE, 
           IN_A, 
           IN_B, 
           IN_C, 
           IN_D, 
           IN_X1, 
           IN_X2, 
           //output
           OUT);//, x12, x22, sqdiff, quadiff);
           
input  MODE;
input  signed[4:0] IN_A, IN_B, IN_C, IN_D;
input  signed[4:0] IN_X1, IN_X2;
output signed[31:0] OUT;//, x12, x22, sqdiff, quadiff;
/*
wire signed[31:0] x1l, x2l;
assign x1l = {{27{IN_X1[4]}}, IN_X1};
assign x2l = {{27{IN_X2[4]}}, IN_X2};
*/
wire signed[5:0] diff = IN_X2-IN_X1;

wire signed[11:0] x12, x22;
assign x12 = IN_X1 * IN_X1;
assign x22 = IN_X2 * IN_X2;

wire signed[12:0] sqdiff = x22-x12;

wire signed[25:0] quadiff = (sqdiff) * (x12+x22);

				
wire signed[31:0] out01 = IN_A*quadiff<< 4;
wire signed[31:0] tout01 = out01>>>2;//{{3{out01[27]}}, out01[26:0], 2'b00}; //((IN_A*quadiff<<4)>>>2)

wire signed[31:0] out02 = IN_C*sqdiff<<4;
wire signed[31:0] tout02 = out02>>>1;//{{2{out02[27]}}, out02[26:0], 3'b000}; //((IN_C*sqdiff<<4)>>>1)

wire signed[31:0] ans0 = (tout01 + tout02 + (IN_D*diff<<4));
wire signed[31:0] ans1 = ((3*IN_A) * x12 + (IN_B<<<1) * IN_X1 + IN_C)<<4;

wire signed[31:0] OUT = MODE ? ans1 : ans0;
/*					
wire signed[31:0] OUT = (MODE == 0) ? (tout01 + tout02 + (IN_D*diff<<4)) :
                           ((3*IN_A) * x12 + (IN_B<<<1) * x1l + IN_C)<<4;
*/
/*
wire signed[31:0] OUT = (MODE == 0) ? (((IN_A*quadiff<<4)>>>2) + ((IN_C*sqdiff<<4)>>>1) + (IN_D*diff<<4)) :
                           ((3*IN_A) * x12 + (IN_B<<<1) * x1l + IN_C)<<4;
*/						   
//wire signed[31:0] t = OUT[31:4];
//wire signed[31:0] t2 = ;
						   
endmodule


