module CC(
    //Input Port
    CLK, 
    RESET, 
    IN_VALID, 
    MODE, 
    IN_A, 
    IN_B,
    //Output Port
    OUT_VALID, 
    OUT);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------

input  CLK, RESET, IN_VALID, MODE;
input  signed[7:0] IN_A, IN_B;
output reg OUT_VALID;
output reg signed[18:0] OUT;

parameter IDLE = 0, READ = 1, CALC = 2, FIN = 3, OUTPUT = 4;

reg [2:0] state, nstate;
reg mode;
reg [3:0] inlen;
reg [4:0] outlen;
reg [4:0] outcnt;

reg signed[7:0] a0, a1, a2, a3, a4, a5, a6, a7, a8;
reg signed[7:0] b0, b1, b2, b3, b4, b5, b6, b7, b8;
reg signed[18:0] out00, out01, out02, out03, out04, out05, out06, out07, out08, out09, out10, out11, out12, out13, out14;
reg [3:0] cnti, cntj;

reg signed[7:0] acomp, bcomp;
wire signed[15:0] mult = acomp * bcomp;
reg [5:0] pos;
reg signed[18:0] ncmp;
reg [14:0] oassign;

always @ (posedge CLK)
	if(RESET)
		state <= IDLE;
	else
		state <= nstate;

always @ * begin
	case(state)
		IDLE: 
			if(IN_VALID)
				nstate = READ;
			else
				nstate = IDLE;
		READ:
			if(IN_VALID)
				nstate = READ;
			else 
				nstate = CALC;
		CALC:
			if((cnti == inlen-1) && (cnti == cntj))
				nstate = FIN;
			else
				nstate = CALC;
		FIN:
			nstate = OUTPUT;
		OUTPUT:
			if(outcnt == outlen)
				nstate = IDLE;
			else
				nstate = OUTPUT;
		default:
			nstate = IDLE;
	endcase
end

//////////////////////////
// Input part
/////////////////////////

always @ (posedge CLK)
	if(RESET)
		mode <= 0;
	else if(state == IDLE && IN_VALID)
		mode <= MODE;
	else
		mode <= mode;

always @ (posedge CLK)
	if(RESET)
		inlen <= 0;
	else if(nstate == IDLE)
		inlen <= 0;
	else if(IN_VALID)
		inlen <= inlen + 1;
	else
		inlen <= inlen;

always @ (posedge CLK)
	if(RESET)
		outlen <= 0;
	else if(state == READ && ~IN_VALID)
		outlen <= mode ? inlen : 2*inlen - 1;
	else 
		outlen <= outlen;

//////////////////////////
// Calculation part
/////////////////////////

always @ (posedge CLK)
	if(RESET)
		cnti <= 0;
	else if(state == CALC && cntj == inlen-1)
		cnti <= cnti + 1;
	else if(state == CALC)
		cnti <= cnti;
	else
		cnti <= 0;

always @ (posedge CLK)
	if(RESET)
		cntj <= 0;
	else if(state == CALC && cntj != inlen-1)
		cntj <= cntj + 1;
	else
		cntj <= 0;

always @ * begin
	case(cnti)
		0: acomp = a0;
		1: acomp = a1;
		2: acomp = a2;
		3: acomp = a3;
		4: acomp = a4;
		5: acomp = a5;
		6: acomp = a6;
		7: acomp = a7;
		8: acomp = a8;
		default : acomp = 0;
	endcase
end

always @ * begin
	case(cntj)
		0: bcomp = b0;
		1: bcomp = b1;
		2: bcomp = b2;
		3: bcomp = b3;
		4: bcomp = b4;
		5: bcomp = b5;
		6: bcomp = b6;
		7: bcomp = b7;
		8: bcomp = b8;
		default : bcomp = 0;
	endcase
end

always @ * begin
	pos = cnti + cntj;
	if(pos >= outlen)
		pos = pos - outlen;
end

always @ * begin
	case(pos)
		0: ncmp = out00;
		1: ncmp = out01;
		2: ncmp = out02;
		3: ncmp = out03;
		4: ncmp = out04;
		5: ncmp = out05;
		6: ncmp = out06;
		7: ncmp = out07;
		8: ncmp = out08;
		9: ncmp = out09;
		10: ncmp = out10;
		11: ncmp = out11;
		12: ncmp = out12;
		13: ncmp = out13;
		14: ncmp = out14;
		default: ncmp = 0;
	endcase
	ncmp = ncmp + mult;
end

always @ * begin
	oassign = 0;
	if(state == CALC)
		oassign[pos] = 1;
end

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out00 <= 0;
	else if(oassign[0])
		out00 <= ncmp;
	else
		out00 <= out00;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out01 <= 0;
	else if(oassign[1])
		out01 <= ncmp;
	else
		out01 <= out01;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out02 <= 0;
	else if(oassign[2])
		out02 <= ncmp;
	else
		out02 <= out02;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out03 <= 0;
	else if(oassign[3])
		out03 <= ncmp;
	else
		out03 <= out03;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out04 <= 0;
	else if(oassign[4])
		out04 <= ncmp;
	else
		out04 <= out04;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out05 <= 0;
	else if(oassign[5])
		out05 <= ncmp;
	else
		out05 <= out05;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out06 <= 0;
	else if(oassign[6])
		out06 <= ncmp;
	else
		out06 <= out06;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out07 <= 0;
	else if(oassign[7])
		out07 <= ncmp;
	else
		out07 <= out07;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out08 <= 0;
	else if(oassign[8])
		out08 <= ncmp;
	else
		out08 <= out08;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out09 <= 0;
	else if(oassign[9])
		out09 <= ncmp;
	else
		out09 <= out09;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out10 <= 0;
	else if(oassign[10])
		out10 <= ncmp;
	else
		out10 <= out10;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out11 <= 0;
	else if(oassign[11])
		out11 <= ncmp;
	else
		out11 <= out11;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out12 <= 0;
	else if(oassign[12])
		out12 <= ncmp;
	else
		out12 <= out12;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out13 <= 0;
	else if(oassign[13])
		out13 <= ncmp;
	else
		out13 <= out13;

always @ (posedge CLK)
	if(RESET || state == IDLE)
		out14 <= 0;
	else if(oassign[14])
		out14 <= ncmp;
	else
		out14 <= out14;



//////////////////////////
// Output part
/////////////////////////

always @ (posedge CLK)
	if(RESET)
		OUT_VALID <= 0;
	else if(nstate == OUTPUT)
		OUT_VALID <= 1'b1;
	else
		OUT_VALID <= 0;

always @ (posedge CLK)
	if(RESET)
		outcnt <= 0;
	else if(nstate == OUTPUT)
		outcnt <= outcnt + 1;
	else
		outcnt <= 0;

always @ (posedge CLK)
	if(RESET)
		OUT <= 0;
	else if(nstate == OUTPUT) begin
		case(outcnt)
			0: OUT <= out00;
			1: OUT <= out01;
			2: OUT <= out02;
			3: OUT <= out03;
			4: OUT <= out04;
			5: OUT <= out05;
			6: OUT <= out06;
			7: OUT <= out07;
			8: OUT <= out08;
			9: OUT <= out09;
			10: OUT <= out10;
			11: OUT <= out11;
			12: OUT <= out12;
			13: OUT <= out13;
			14: OUT <= out14;
			default : OUT <= 0;
		endcase
	end else
		OUT <= 0;



//////////////////////////
// Data input part... very boring! Orz
/////////////////////////
always @ (posedge CLK)
	if(RESET)
		a0 <= 0;
	else if(nstate == READ && inlen == 0)
		a0 <= IN_A;
	else
		a0 <= a0;

always @ (posedge CLK)
	if(RESET)
		a1 <= 0;
	else if(nstate == READ && inlen == 1)
		a1 <= IN_A;
	else
		a1 <= a1;

always @ (posedge CLK)
	if(RESET)
		a2 <= 0;
	else if(nstate == READ && inlen == 2)
		a2 <= IN_A;
	else
		a2 <= a2;

always @ (posedge CLK)
	if(RESET)
		a3 <= 0;
	else if(nstate == READ && inlen == 3)
		a3 <= IN_A;
	else
		a3 <= a3;

always @ (posedge CLK)
	if(RESET)
		a4 <= 0;
	else if(nstate == READ && inlen == 4)
		a4 <= IN_A;
	else
		a4 <= a4;

always @ (posedge CLK)
	if(RESET)
		a5 <= 0;
	else if(nstate == READ && inlen == 5)
		a5 <= IN_A;
	else
		a5 <= a5;

always @ (posedge CLK)
	if(RESET)
		a6 <= 0;
	else if(nstate == READ && inlen == 6)
		a6 <= IN_A;
	else
		a6 <= a6;

always @ (posedge CLK)
	if(RESET)
		a7 <= 0;
	else if(nstate == READ && inlen == 7)
		a7 <= IN_A;
	else
		a7 <= a7;

always @ (posedge CLK)
	if(RESET)
		a8 <= 0;
	else if(nstate == READ && inlen == 8)
		a8 <= IN_A;
	else
		a8 <= a8;

always @ (posedge CLK)
	if(RESET)
		b0 <= 0;
	else if(nstate == READ && inlen == 0)
		b0 <= IN_B;
	else
		b0 <= b0;

always @ (posedge CLK)
	if(RESET)
		b1 <= 0;
	else if(nstate == READ && inlen == 1)
		b1 <= IN_B;
	else
		b1 <= b1;

always @ (posedge CLK)
	if(RESET)
		b2 <= 0;
	else if(nstate == READ && inlen == 2)
		b2 <= IN_B;
	else
		b2 <= b2;

always @ (posedge CLK)
	if(RESET)
		b3 <= 0;
	else if(nstate == READ && inlen == 3)
		b3 <= IN_B;
	else
		b3 <= b3;

always @ (posedge CLK)
	if(RESET)
		b4 <= 0;
	else if(nstate == READ && inlen == 4)
		b4 <= IN_B;
	else
		b4 <= b4;

always @ (posedge CLK)
	if(RESET)
		b5 <= 0;
	else if(nstate == READ && inlen == 5)
		b5 <= IN_B;
	else
		b5 <= b5;

always @ (posedge CLK)
	if(RESET)
		b6 <= 0;
	else if(nstate == READ && inlen == 6)
		b6 <= IN_B;
	else
		b6 <= b6;

always @ (posedge CLK) 
	if(RESET)
		b7 <= 0;
	else if(nstate == READ && inlen == 7)
		b7 <= IN_B;
	else
		b7 <= b7;

always @ (posedge CLK) 
	if(RESET)
		b8 <= 0;
	else if(nstate == READ && inlen == 8)
		b8 <= IN_B;
	else
		b8 <= b8;

		
endmodule
