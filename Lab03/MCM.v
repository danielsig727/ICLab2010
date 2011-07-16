//#######################################################################################//
//###                            File Name  : MCM.v                                   ###//
//###                            Module Name: MCM                                     ###//
//###                            Author     : danielsig727                            ###//
//#######################################################################################//

module MCM(
    //Input Port
    CLK, 
    RESET, 
    IN_VALID, 
    IN, 
    //Output Port
    OUT_VALID, 
    OUT,
	/*cnt_t, cnt_i, j, cnt_k, delay, q, midx, mcomp, macc, mini, minj, minacc, mincompmcomp, mincomp*/);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------

input CLK, RESET, IN_VALID;
input [7:0]  IN;
output reg OUT_VALID;
output reg [26:0]  OUT;
/*
output [3:0] cnt_t, cnt_i, j, cnt_k, delay, midx;
output [26:0] q;*/
//output [26:0] mcomp;
/*output macc;
output [3:0] mini, minj;*/
//output [26:0] /*minacc, */mincomp;

parameter IDLE = 0, READ = 1, CALC = 2, FIN = 3, OUTPUT = 4;
parameter DEFLEN = 8, STEPLEN = 5;

reg [2:0] state, nstate;
reg [7:0] m0, m1, m2, m3, m4, m5, m6, m7, m8;
reg [7:0] macc;
reg [26:0] mcomp;
reg [3:0] midx;
reg [3:0] inlen;
reg [3:0] cnt_t, cnt_i, cnt_k;
wire [3:0] j = cnt_i + cnt_t;
wire i_last = (cnt_i == DEFLEN - cnt_t - 1);
wire k_last = (cnt_k == j - 1);
reg [2:0] delay;
wire ok = (delay == STEPLEN - 1);

reg [26:0]	min01, min02, min03, min04, min05, min06, min07,
			min12, min13, min14, min15, min16, min17,
			min23, min24, min25, min26, min27,
			min34, min35, min36, min37,
			min45, min46, min47,
			min56, min57,
			min67;

reg [7:0] mini, minj;
reg [26:0] minacc, mincomp;
wire [26:0] q;
wire min_compare_and_assign;
reg [7:0] pos_i, pos_j;
wire q_smaller;

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
		if(!IN_VALID)
			nstate = CALC;
		else
			nstate = READ;
	CALC:
		if((cnt_t == DEFLEN - 1) && k_last && ok)
			nstate = FIN;
		else
			nstate = CALC;
	FIN:
		nstate = OUTPUT;
	OUTPUT:
		nstate = IDLE;
	default:
		nstate = IDLE;
	endcase
end

//////////////////
// Input
//////////////////


always @ (posedge CLK)
	if(RESET)
		inlen <= 0;
	else if(nstate == IDLE)
		inlen <= 0;
	else if(nstate == READ)
		inlen <= inlen + 1;
	else
		inlen <= inlen;

always @ (posedge CLK)
	if(RESET)
		m0 <= 0;
	else if(nstate == READ && inlen == 0)
		m0 <= IN;
	else
		m0 <= m0;

always @ (posedge CLK)
	if(RESET)
		m1 <= 0;
	else if(nstate == READ && inlen == 1)
		m1 <= IN;
	else
		m1 <= m1;

always @ (posedge CLK)
	if(RESET)
		m2 <= 0;
	else if(nstate == READ && inlen == 2)
		m2 <= IN;
	else
		m2 <= m2;

always @ (posedge CLK)
	if(RESET)
		m3 <= 0;
	else if(nstate == READ && inlen == 3)
		m3 <= IN;
	else
		m3 <= m3;

always @ (posedge CLK)
	if(RESET)
		m4 <= 0;
	else if(nstate == READ && inlen == 4)
		m4 <= IN;
	else
		m4 <= m4;

always @ (posedge CLK)
	if(RESET)
		m5 <= 0;
	else if(nstate == READ && inlen == 5)
		m5 <= IN;
	else
		m5 <= m5;

always @ (posedge CLK)
	if(RESET)
		m6 <= 0;
	else if(nstate == READ && inlen == 6)
		m6 <= IN;
	else
		m6 <= m6;

always @ (posedge CLK)
	if(RESET)
		m7 <= 0;
	else if(nstate == READ && inlen == 7)
		m7 <= IN;
	else
		m7 <= m7;

always @ (posedge CLK)
	if(RESET)
		m8 <= 0;
	else if(nstate == READ && inlen == 8)
		m8 <= IN;
	else
		m8 <= m8;

////////////////
// Calculation
////////////////

// Counters
//reg [3:0] cnt_t, cnt_i, cnt_k;
//wire [3:0] j = cnt_i + cnt_t;

always @ (posedge CLK)
	if(RESET)
		cnt_t <= 1;
	else if(nstate == IDLE)
		cnt_t <= 1;
	else if(nstate == CALC && i_last && k_last && ok)
		cnt_t <= cnt_t + 1;
	else
		cnt_t <= cnt_t;				


always @ (posedge CLK)
	if(RESET)
		cnt_i <= 0;
	else if(nstate == IDLE)
		cnt_i <= 0;
	else if(nstate == CALC && ok && k_last)
		if(i_last)
			cnt_i <= 0;
		else
			cnt_i <= cnt_i + 1;
	else
		cnt_i <= cnt_i;

always @ (posedge CLK)
	if(RESET)
		cnt_k <= 0;
	else if(nstate == IDLE)
		cnt_k <= 0;
	else if(nstate == CALC && ok)
		if(k_last)
			if(i_last)
				cnt_k <= 0;
			else
				cnt_k <= cnt_i + 1;
		else
			cnt_k <= cnt_k + 1;
	else
		cnt_k <= cnt_k;

//////////
// each step takes STEPLEN clock(s) to finish
/////////
always @ (posedge CLK)
	if(RESET)
		delay <= 0;
	else if(nstate == IDLE)
		delay <= 0;
	else if(nstate == CALC)
		if(delay == STEPLEN - 1)
			delay <= 0;
		else
			delay <= delay + 1;
	else
		delay <= delay;

//////////
// take care of m[i+1] * m[k+1] * m[j+1] part
/////////

always @ *
	if(delay == 0)
		midx = cnt_i;
	else if(delay == 1)
		midx = cnt_k + 1;
	else /*if(delay == 2)*/
		midx = j + 1;

always @ *
	case(midx)
	0: macc = m0;
	1: macc = m1;
	2: macc = m2;
	3: macc = m3;
	4: macc = m4;
	5: macc = m5;
	6: macc = m6;
	7: macc = m7;
	8: macc = m8;
	default: macc = 0;
	endcase

always @ (posedge CLK)
	if(RESET)
		mcomp <= 0;
	else if(delay == 0)
		mcomp <= macc;
	else if(delay == 1 || delay == 2)
		mcomp <= mcomp * macc;
	else
		mcomp <= mcomp;


///////////////
// Access min[i,j]
///////////////
/*
always @ *
	if(delay == 1)
		mini = cnt_k + 1;
	else //if(delay == 0 || delay == 4)
		mini = cnt_i;

always @ *
	if(nstate == OUTPUT)
		minj = DEFLEN - 1;
	else if(delay == 0)
		minj = cnt_k;
	else //if(delay == 1 || delay == 4)
		minj = j;
*/

always @ * begin
	mini = 0;
	if(delay == 1)
		mini[cnt_k + 1] = 1;
	else //if(delay == 0 || delay == 4)
		mini[cnt_i] = 1;
end

always @ * begin
	minj = 0;
	if(nstate == OUTPUT)
		minj[DEFLEN - 1] = 1;
	else if(delay == 0)
		minj[cnt_k] = 1;
	else //if(delay == 1 || delay == 4)
		minj[j] = 1;
end
/*
always @ *
	case(mini)
	0:
		case(minj)
		1: minacc = min01;
		2: minacc = min02;
		3: minacc = min03;
		4: minacc = min04;
		5: minacc = min05;
		6: minacc = min06;
		7: minacc = min07;
		default: minacc = 0;
		endcase
	1:
		case(minj)
		2: minacc = min12;
		3: minacc = min13;
		4: minacc = min14;
		5: minacc = min15;
		6: minacc = min16;
		7: minacc = min17;
		default: minacc = 0;
		endcase
	2:
		case(minj)
		3: minacc = min23;
		4: minacc = min24;
		5: minacc = min25;
		6: minacc = min26;
		7: minacc = min27;
		default: minacc = 0;
		endcase
	3:
		case(minj)
		4: minacc = min34;
		5: minacc = min35;
		6: minacc = min36;
		7: minacc = min37;
		default: minacc = 0;
		endcase
	4:
		case(minj)
		5: minacc = min45;
		6: minacc = min46;
		7: minacc = min47;
		default: minacc = 0;
		endcase
	5:
		case(minj)
		6: minacc = min56;
		7: minacc = min57;
		default: minacc = 0;
		endcase
	6:
		case(minj)
		7: minacc = min67;
		default: minacc = 0;
		endcase
	default: minacc = 0;
	endcase
*/

always @ * 
	if(mini[0] && minj[1])
		minacc = min01;
	else if(mini[0] && minj[2])
		minacc = min02;
	else if(mini[0] && minj[3])
		minacc = min03;
	else if(mini[0] && minj[4])
		minacc = min04;
	else if(mini[0] && minj[5])
		minacc = min05;
	else if(mini[0] && minj[6])
		minacc = min06;
	else if(mini[0] && minj[7])
		minacc = min07;
	else if(mini[1] && minj[2])
		minacc = min12;
	else if(mini[1] && minj[3])
		minacc = min13;
	else if(mini[1] && minj[4])
		minacc = min14;
	else if(mini[1] && minj[5])
		minacc = min15;
	else if(mini[1] && minj[6])
		minacc = min16;
	else if(mini[1] && minj[7])
		minacc = min17;
	else if(mini[2] && minj[3])
		minacc = min23;
	else if(mini[2] && minj[4])
		minacc = min24;
	else if(mini[2] && minj[5])
		minacc = min25;
	else if(mini[2] && minj[6])
		minacc = min26;
	else if(mini[2] && minj[7])
		minacc = min27;
	else if(mini[3] && minj[4])
		minacc = min34;
	else if(mini[3] && minj[5])
		minacc = min35;
	else if(mini[3] && minj[6])
		minacc = min36;
	else if(mini[3] && minj[7])
		minacc = min37;
	else if(mini[4] && minj[5])
		minacc = min45;
	else if(mini[4] && minj[6])
		minacc = min46;
	else if(mini[4] && minj[7])
		minacc = min47;
	else if(mini[5] && minj[6])
		minacc = min56;
	else if(mini[5] && minj[7])
		minacc = min57;
	else if(mini[6] && minj[7])
		minacc = min67;
	else 
		minacc = 0;

always @ (posedge CLK)
	if(RESET)
		mincomp <= 0;
	else if(delay == 0)
		mincomp <= minacc;
	else if(delay == 1)
		mincomp <= mincomp + minacc;
	else if(delay == 3)
		mincomp <= mincomp + mcomp;
	else
		mincomp <= mincomp;

///////////////
// save sum
///////////////
/*
always @ (posedge CLK)
	if(RESET)
		q <= 0;
	else if(delay == 3)
		q <= mincomp + mcomp;
	else 
		q <= q;
*/

assign q = mincomp; // q is implemented in mincomp

///////////////
// compare and each min
///////////////
assign min_compare_and_assign = (state == CALC) && (delay == 4) && ((q < minacc) || (minacc == 0));
assign q_smaller = (q < minacc) || (minacc == 0);
always @ * begin
	pos_i = 0;
	pos_i[cnt_i] = 1;
end
always @ * begin
	pos_j = 0;
	pos_j[j] = 1;
end
/*
char str[1000] = "\
always @ (posedge CLK)\n\
	if(RESET)\n\
		min%0d%0d <= 0;\n\
	else if(nstate == IDLE)\n\
		min%0d%0d <= 0;\n\
	else if(min_compare_and_assign && pos_i[%0d] && pos_j[%0d] && q_smaller)\n\
			min%0d%0d <= q;\n\
	else\n\
		min%0d%0d <= min%0d%0d;\n\n";
*/

always @ (posedge CLK)
	if(RESET)
		min01 <= 0;
	else if(nstate == IDLE)
		min01 <= 0;
	else if(min_compare_and_assign && pos_i[0] && pos_j[1] && q_smaller)
		min01 <= q;
	else
		min01 <= min01;

always @ (posedge CLK)
	if(RESET)
		min02 <= 0;
	else if(nstate == IDLE)
		min02 <= 0;
	else if(min_compare_and_assign && pos_i[0] && pos_j[2] && q_smaller)
		min02 <= q;
	else
		min02 <= min02;

always @ (posedge CLK)
	if(RESET)
		min03 <= 0;
	else if(nstate == IDLE)
		min03 <= 0;
	else if(min_compare_and_assign && pos_i[0] && pos_j[3] && q_smaller)
		min03 <= q;
	else
		min03 <= min03;

always @ (posedge CLK)
	if(RESET)
		min04 <= 0;
	else if(nstate == IDLE)
		min04 <= 0;
	else if(min_compare_and_assign && pos_i[0] && pos_j[4] && q_smaller)
		min04 <= q;
	else
		min04 <= min04;

always @ (posedge CLK)
	if(RESET)
		min05 <= 0;
	else if(nstate == IDLE)
		min05 <= 0;
	else if(min_compare_and_assign && pos_i[0] && pos_j[5] && q_smaller)
		min05 <= q;
	else
		min05 <= min05;

always @ (posedge CLK)
	if(RESET)
		min06 <= 0;
	else if(nstate == IDLE)
		min06 <= 0;
	else if(min_compare_and_assign && pos_i[0] && pos_j[6] && q_smaller)
		min06 <= q;
	else
		min06 <= min06;

always @ (posedge CLK)
	if(RESET)
		min07 <= 0;
	else if(nstate == IDLE)
		min07 <= 0;
	else if(min_compare_and_assign && pos_i[0] && pos_j[7] && q_smaller)
		min07 <= q;
	else
		min07 <= min07;

always @ (posedge CLK)
	if(RESET)
		min12 <= 0;
	else if(nstate == IDLE)
		min12 <= 0;
	else if(min_compare_and_assign && pos_i[1] && pos_j[2] && q_smaller)
		min12 <= q;
	else
		min12 <= min12;

always @ (posedge CLK)
	if(RESET)
		min13 <= 0;
	else if(nstate == IDLE)
		min13 <= 0;
	else if(min_compare_and_assign && pos_i[1] && pos_j[3] && q_smaller)
		min13 <= q;
	else
		min13 <= min13;

always @ (posedge CLK)
	if(RESET)
		min14 <= 0;
	else if(nstate == IDLE)
		min14 <= 0;
	else if(min_compare_and_assign && pos_i[1] && pos_j[4] && q_smaller)
		min14 <= q;
	else
		min14 <= min14;

always @ (posedge CLK)
	if(RESET)
		min15 <= 0;
	else if(nstate == IDLE)
		min15 <= 0;
	else if(min_compare_and_assign && pos_i[1] && pos_j[5] && q_smaller)
		min15 <= q;
	else
		min15 <= min15;

always @ (posedge CLK)
	if(RESET)
		min16 <= 0;
	else if(nstate == IDLE)
		min16 <= 0;
	else if(min_compare_and_assign && pos_i[1] && pos_j[6] && q_smaller)
		min16 <= q;
	else
		min16 <= min16;

always @ (posedge CLK)
	if(RESET)
		min17 <= 0;
	else if(nstate == IDLE)
		min17 <= 0;
	else if(min_compare_and_assign && pos_i[1] && pos_j[7] && q_smaller)
		min17 <= q;
	else
		min17 <= min17;

always @ (posedge CLK)
	if(RESET)
		min23 <= 0;
	else if(nstate == IDLE)
		min23 <= 0;
	else if(min_compare_and_assign && pos_i[2] && pos_j[3] && q_smaller)
		min23 <= q;
	else
		min23 <= min23;

always @ (posedge CLK)
	if(RESET)
		min24 <= 0;
	else if(nstate == IDLE)
		min24 <= 0;
	else if(min_compare_and_assign && pos_i[2] && pos_j[4] && q_smaller)
		min24 <= q;
	else
		min24 <= min24;

always @ (posedge CLK)
	if(RESET)
		min25 <= 0;
	else if(nstate == IDLE)
		min25 <= 0;
	else if(min_compare_and_assign && pos_i[2] && pos_j[5] && q_smaller)
		min25 <= q;
	else
		min25 <= min25;

always @ (posedge CLK)
	if(RESET)
		min26 <= 0;
	else if(nstate == IDLE)
		min26 <= 0;
	else if(min_compare_and_assign && pos_i[2] && pos_j[6] && q_smaller)
		min26 <= q;
	else
		min26 <= min26;

always @ (posedge CLK)
	if(RESET)
		min27 <= 0;
	else if(nstate == IDLE)
		min27 <= 0;
	else if(min_compare_and_assign && pos_i[2] && pos_j[7] && q_smaller)
		min27 <= q;
	else
		min27 <= min27;

always @ (posedge CLK)
	if(RESET)
		min34 <= 0;
	else if(nstate == IDLE)
		min34 <= 0;
	else if(min_compare_and_assign && pos_i[3] && pos_j[4] && q_smaller)
		min34 <= q;
	else
		min34 <= min34;

always @ (posedge CLK)
	if(RESET)
		min35 <= 0;
	else if(nstate == IDLE)
		min35 <= 0;
	else if(min_compare_and_assign && pos_i[3] && pos_j[5] && q_smaller)
		min35 <= q;
	else
		min35 <= min35;

always @ (posedge CLK)
	if(RESET)
		min36 <= 0;
	else if(nstate == IDLE)
		min36 <= 0;
	else if(min_compare_and_assign && pos_i[3] && pos_j[6] && q_smaller)
		min36 <= q;
	else
		min36 <= min36;

always @ (posedge CLK)
	if(RESET)
		min37 <= 0;
	else if(nstate == IDLE)
		min37 <= 0;
	else if(min_compare_and_assign && pos_i[3] && pos_j[7] && q_smaller)
		min37 <= q;
	else
		min37 <= min37;

always @ (posedge CLK)
	if(RESET)
		min45 <= 0;
	else if(nstate == IDLE)
		min45 <= 0;
	else if(min_compare_and_assign && pos_i[4] && pos_j[5] && q_smaller)
		min45 <= q;
	else
		min45 <= min45;

always @ (posedge CLK)
	if(RESET)
		min46 <= 0;
	else if(nstate == IDLE)
		min46 <= 0;
	else if(min_compare_and_assign && pos_i[4] && pos_j[6] && q_smaller)
		min46 <= q;
	else
		min46 <= min46;

always @ (posedge CLK)
	if(RESET)
		min47 <= 0;
	else if(nstate == IDLE)
		min47 <= 0;
	else if(min_compare_and_assign && pos_i[4] && pos_j[7] && q_smaller)
		min47 <= q;
	else
		min47 <= min47;

always @ (posedge CLK)
	if(RESET)
		min56 <= 0;
	else if(nstate == IDLE)
		min56 <= 0;
	else if(min_compare_and_assign && pos_i[5] && pos_j[6] && q_smaller)
		min56 <= q;
	else
		min56 <= min56;

always @ (posedge CLK)
	if(RESET)
		min57 <= 0;
	else if(nstate == IDLE)
		min57 <= 0;
	else if(min_compare_and_assign && pos_i[5] && pos_j[7] && q_smaller)
		min57 <= q;
	else
		min57 <= min57;

always @ (posedge CLK)
	if(RESET)
		min67 <= 0;
	else if(nstate == IDLE)
		min67 <= 0;
	else if(min_compare_and_assign && pos_i[6] && pos_j[7] && q_smaller)
		min67 <= q;
	else
		min67 <= min67;



///////////////
// Output
///////////////

always @ (posedge CLK)
	if(RESET)
		OUT_VALID <= 0;
	else if(nstate == OUTPUT) 
		OUT_VALID <= 1;
	else
		OUT_VALID <= 0;

always @ (posedge CLK)
	if(RESET)
		OUT <= 0;
	else if(nstate == OUTPUT)
		OUT <= minacc;
	else 
		OUT <= 0;



endmodule
