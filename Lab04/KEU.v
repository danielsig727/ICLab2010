//#######################################################################################
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  (C) Copyright Laboratory System Integration and Silican Implementation 
//  All Right Reserved.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//  2009 Spring ICLAB Course
//  Lab04     : AES Keyexpansion Unit
//  Author    : danielsig727
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//  File Name       : KEU.v
//  Module Name     : KEU
//  Release version : V1.0 (Release Date:2009-03-09)
//  Description     : Top module of Key Expansion Unit, including FSM and datapath
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//#######################################################################################

// 這次寫的很爛，僅供參考 :P
// 警告：DC會合成10分鐘左右 XD

`define WORD 32
`define BYTE 8

module KEU(
           //inputs
	   CLK,
	   RST,
	   IN_VALID,
	   MODE,
	   KEY_LENGTH,
	   SECRET_KEY,
	   //outputs
	   ROUNDKEY,
	   OUT_VALID);

input                CLK;
input                RST;
input                IN_VALID;
input                MODE;
input  [        1:0] KEY_LENGTH;
input  [`WORD*8-1:0] SECRET_KEY;
output reg [`WORD*4-1:0] ROUNDKEY;
output reg               OUT_VALID;

parameter IDLE = 0, READ = 1, CALC = 2, DEC_OUT = 3, FIN = 4,
          M_DEC = 0, M_ENC = 1;

reg [255:0] w;
reg [1:0] keylen;
reg [4:0] outlen;
reg mode;

reg [2:0] state, nstate;
reg [4:0] cnt;
reg [3:0] cnt3, cnt3acc;

always @ (posedge CLK or posedge RST)
	if(RST)
		state <= IDLE;
	else
		state <= nstate;

always @ * 
	case(state)
	IDLE:
		if(IN_VALID)
			nstate = READ;
		else
			nstate = IDLE;
	READ:
		nstate = CALC;
	CALC:
		if(cnt == outlen - 1)
			if(mode == M_DEC)
				nstate = DEC_OUT;
			else
				nstate = FIN;
		else
			nstate = CALC;
	DEC_OUT:
		if(cnt == 0)
			nstate = FIN;
		else
			nstate = DEC_OUT;
	FIN:
		nstate = IDLE;
	default:
		nstate = IDLE;
	endcase

always @ (posedge CLK)
	if(nstate == IDLE)
		cnt <= 0;
	else if(nstate == CALC)
		cnt <= cnt + 1;
	else if(nstate == DEC_OUT)
		cnt <= cnt - 1;
	else
		cnt <= cnt;

always @ (posedge CLK or posedge RST)
	if(RST)
		cnt3 <= 0;
	else if(nstate == IDLE)
		cnt3 <= 0;
	else if(nstate == CALC)
		cnt3 <= (cnt3 == 2) ? 0 : (cnt3 + 1);
	else if(nstate == DEC_OUT)
		cnt3 <= (cnt3 == 0) ? 2 : (cnt3 - 1);
	else
		cnt3 <= cnt3;

always @ (posedge CLK)
	if(nstate == IDLE)
		cnt3acc <= 0;
	else if(nstate == CALC && (cnt3 == 2 || cnt3 == 0) && cnt3acc != 7)
		cnt3acc <= cnt3acc + 1;
	else if(nstate == DEC_OUT && (cnt3 == 0 || cnt3 == 1))
		cnt3acc <= cnt3acc - 1;
	else
		cnt3acc <= cnt3acc;

always @ (posedge CLK)
	if(nstate == READ)
		case(KEY_LENGTH)
		2'b00: outlen <= 11;
		2'b01: outlen <= 13;
		2'b10: outlen <= 15;
		default: outlen <= 0;
		endcase
	else
		outlen <= outlen;

always @ (posedge CLK)
	if(nstate == READ)
		keylen <= KEY_LENGTH;
	else
		keylen <= keylen;

always @ (posedge CLK)
	if(nstate == READ)
		mode <= MODE;
	else
		mode <= mode;
//////////////////////////////////////
// HERE COMES THE DIRTY PART... Orz
//////////////////////////////////////


reg [127:0] procw; // the word in w to be replaced

reg [31:0] tmpw_src;
reg [31:0] tmpw_rot;
reg [4:0] cntc; // correction for cnt to be used with rcon
wire [31:0] tmpw_sub;
wire [31:0] rcon;
wire [31:0] tmpw_rcon;
reg [31:0] tmpw_fin;


reg [31:0] tmpw1_src;
wire [31:0] tmpw1;
reg [31:0] tmpw2_src;
wire [31:0] tmpw2;
reg [31:0] tmpw3_src;
wire [31:0] tmpw3;

reg [255:0] neww;

// decoder, for furture simplicity
/*
reg [2:0] key_mode;
always @ * begin
	key_mode = 0;
	key_mode[keylen] = 1;
end
*/

wire reverse_en = (mode == M_DEC) && (nstate == DEC_OUT); // reverse mode flag

//reg [127:0] procw; // the word in w to be replaced
always @ *
	case(keylen)
	0:
		procw = w[255:128];
	1:
		case(cnt3)
		0: procw = w[255:128];
		1: procw = {w[127:64], w[255:192]};
		2: procw = w[191:64];
		default: procw = 0;
		endcase
	default: //2
		if(~cnt[0]) // i == 8n
			procw = w[255:128];
		else
			procw = w[127:0];
	endcase

// the word that requires s-box
//reg [31:0] tmpw_src;
always @ *
	case(keylen)
	0:
		tmpw_src = (~reverse_en) ? procw[31:0] : tmpw3;
	1:
		case(cnt3)
		0: tmpw_src = w[95:64];
		1: tmpw_src = (~reverse_en) ? tmpw1 : procw[95:64];
		default: tmpw_src = w[223:192]; //2
		endcase
	default: //2
		if(~cnt[0]) // i == 8n
			tmpw_src = w[31:0];
		else
			tmpw_src = w[159:128];
	endcase

//reg [31:0] tmpw_rot;
always @ *
	case(keylen)
	0:
		tmpw_rot = {tmpw_src[23:0], tmpw_src[31:24]};
	1:
		tmpw_rot = {tmpw_src[23:0], tmpw_src[31:24]};
	default: //2
		if(~cnt[0]) // i == 8n
			tmpw_rot = {tmpw_src[23:0], tmpw_src[31:24]};
		else
			tmpw_rot = tmpw_src;
	endcase

//wire [31:0] tmpw_sub;
Sbox sb3(tmpw_rot[31:24], tmpw_sub[31:24]);
Sbox sb2(tmpw_rot[23:16], tmpw_sub[23:16]);
Sbox sb1(tmpw_rot[15:8], tmpw_sub[15:8]);
Sbox sb0(tmpw_rot[7:0], tmpw_sub[7:0]);
//reg [4:0] cntc; // correction for cnt to be used with rcon
always @ *
	case(keylen)
	0:
		cntc = (state == DEC_OUT) ? (cnt - 1) : cnt;
	1:
		cntc = cnt3acc;
	default: //2
		cntc = (~reverse_en) ? (cnt >> 1) : ((cnt - 1) >> 1);
	endcase


assign rcon = (cntc <= 7) ? ({{16'h0100 << cntc}, {16'h0}}) : ((cntc == 8) ? 32'h1b000000 : 32'h36000000);
assign tmpw_rcon = tmpw_sub ^ rcon;
//reg [31:0] tmpw_fin;
always @ *
	case(keylen)
	0:
		tmpw_fin = tmpw_rcon ^ procw[127:96];
	1:
		case(cnt3)
		0: tmpw_fin = tmpw_rcon ^ procw[127:96];
		1: tmpw_fin = tmpw_rcon ^ procw[63:32];
		2: tmpw_fin = tmpw_src ^ procw[127:96];
		default: tmpw_fin = 0;
		endcase
	default: //2
		if(~cnt[0]) // i == 8n
			tmpw_fin = tmpw_rcon ^ procw[127:96];
		else
			tmpw_fin = tmpw_sub ^ procw[127:96];
	endcase


// xor-er 1
//reg [31:0] tmpw1_src;
always @ *
	if(reverse_en)
		tmpw1_src = procw[127:96];
	else
		case(keylen)
		0:
			tmpw1_src = tmpw_fin;
		1:
			case(cnt3)
			0: tmpw1_src = tmpw_fin;
			1: tmpw1_src = tmpw2;
			default: tmpw1_src = tmpw_fin; //2
			endcase
		default: //2
			tmpw1_src = tmpw_fin;
		endcase

assign tmpw1 = tmpw1_src  ^ procw[95:64];

// xor-er 2
//reg [31:0] tmpw2_src;
always @ *
	if(reverse_en && !(keylen == 1 && cnt3 == 1))
		tmpw2_src = procw[95:64];
	else
		case(keylen)
		0:
			tmpw2_src = tmpw1;
		1:
			case(cnt3)
			0: tmpw2_src = tmpw1;
			1: tmpw2_src = w[159:128];
			default: tmpw2_src = tmpw1; //2
			endcase		
		default: //2
			tmpw2_src = tmpw1;
		endcase

assign tmpw2 = (keylen == 1 && cnt3 == 1) ? (tmpw2_src ^ procw[127:96]) : (tmpw2_src  ^ procw[63:32]);

// xor-er 3
//reg [31:0] tmpw3_src;
always @ *
	if(reverse_en)
		tmpw3_src = procw[63:32];
	else
		case(keylen)
		0:
			tmpw3_src = tmpw2;
		1:
			case(cnt3)
			0: tmpw3_src = tmpw2;
			1: tmpw3_src = tmpw_fin;
			default: tmpw3_src = tmpw2; //2
			endcase			
		default: //2
			tmpw3_src = tmpw2;
		endcase

assign tmpw3 = tmpw3_src  ^ procw[31:0];

// new value of w
//reg [255:0] neww;
always @ *
	case(keylen)
	0:
		neww = {tmpw_fin, tmpw1, tmpw2, tmpw3, 128'b0};
	1:
		if(state == CALC && cnt == 11)
			neww = {w[255:192], tmpw_fin, tmpw1, w[127:64], 64'b0};
		else
			case(cnt3)
			0: neww = {tmpw_fin, tmpw1, tmpw2, tmpw3, w[127:64], 64'b0};
			1: neww = {tmpw_fin, tmpw3, w[191:128], tmpw2, tmpw1, 64'b0};
			default: neww = {w[255:192], tmpw_fin, tmpw1, tmpw2, tmpw3, 64'b0}; //2
			endcase	
	default: //2
		if(state == CALC && mode == M_DEC && cnt == 13)
			neww = w;  // hold w right before decode mode
		else if(~cnt[0]) // i == 8n
			neww = {tmpw_fin, tmpw1, tmpw2, tmpw3, w[127:0]};
		else
			neww = {w[255:128], tmpw_fin, tmpw1, tmpw2, tmpw3};
	endcase

///////////////////////////////////////////

always @ (posedge CLK)
	if(nstate == READ)
		w <= SECRET_KEY;
	else
		w <= neww;

always @ (posedge CLK)
	if(nstate == IDLE)
		OUT_VALID <= 0;
	else if(state == FIN)
		OUT_VALID <= 0;
	else if(mode == M_ENC && state == READ)
		OUT_VALID <= 1;
	else if(state == CALC && nstate == DEC_OUT)
		OUT_VALID <= 1;
	else
		OUT_VALID <= OUT_VALID;
		
//(mode == M_ENC ? (|cnt) : (state == DEC_OUT)) || (state == FIN);

//reg [255:0] ROUNDKEY = 0;

always @ (posedge CLK or posedge RST)
	if(RST)
		ROUNDKEY <= 0;
	else
		ROUNDKEY <= procw;


endmodule


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//  Module Name     : KEU
//  Release version : V1.0 (Release Date:2009-03-09)
//  Description     : Sbox used in key generation process, any 8-bit input is substitute
//                    to a 8-bit output
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
module Sbox(sub_in, sub_out);

input  [`BYTE-1:0] sub_in;
output [`BYTE-1:0] sub_out;
reg    [`BYTE-1:0] sub_out;

always@* begin
    case(sub_in)
    8'h00: sub_out = 8'h63;
    8'h01: sub_out = 8'h7C;
    8'h02: sub_out = 8'h77;
    8'h03: sub_out = 8'h7B;
    8'h04: sub_out = 8'hF2;
    8'h05: sub_out = 8'h6B;
    8'h06: sub_out = 8'h6F;
    8'h07: sub_out = 8'hC5;
    8'h08: sub_out = 8'h30;
    8'h09: sub_out = 8'h01;
    8'h0A: sub_out = 8'h67;
    8'h0B: sub_out = 8'h2B;
    8'h0C: sub_out = 8'hFE;
    8'h0D: sub_out = 8'hD7;
    8'h0E: sub_out = 8'hAB;
    8'h0F: sub_out = 8'h76;
    8'h10: sub_out = 8'hCA;
    8'h11: sub_out = 8'h82;
    8'h12: sub_out = 8'hC9;
    8'h13: sub_out = 8'h7D;
    8'h14: sub_out = 8'hFA;
    8'h15: sub_out = 8'h59;
    8'h16: sub_out = 8'h47;
    8'h17: sub_out = 8'hF0;
    8'h18: sub_out = 8'hAD;
    8'h19: sub_out = 8'hD4;
    8'h1A: sub_out = 8'hA2;
    8'h1B: sub_out = 8'hAF;
    8'h1C: sub_out = 8'h9C;
    8'h1D: sub_out = 8'hA4;
    8'h1E: sub_out = 8'h72;
    8'h1F: sub_out = 8'hC0;
    8'h20: sub_out = 8'hB7;
    8'h21: sub_out = 8'hFD;
    8'h22: sub_out = 8'h93;
    8'h23: sub_out = 8'h26;
    8'h24: sub_out = 8'h36;
    8'h25: sub_out = 8'h3F;
    8'h26: sub_out = 8'hF7;
    8'h27: sub_out = 8'hCC;
    8'h28: sub_out = 8'h34;
    8'h29: sub_out = 8'hA5;
    8'h2A: sub_out = 8'hE5;
    8'h2B: sub_out = 8'hF1;
    8'h2C: sub_out = 8'h71;
    8'h2D: sub_out = 8'hD8;
    8'h2E: sub_out = 8'h31;
    8'h2F: sub_out = 8'h15;
    8'h30: sub_out = 8'h04;
    8'h31: sub_out = 8'hC7;
    8'h32: sub_out = 8'h23;
    8'h33: sub_out = 8'hC3;
    8'h34: sub_out = 8'h18;
    8'h35: sub_out = 8'h96;
    8'h36: sub_out = 8'h05;
    8'h37: sub_out = 8'h9A;
    8'h38: sub_out = 8'h07;
    8'h39: sub_out = 8'h12;
    8'h3A: sub_out = 8'h80;
    8'h3B: sub_out = 8'hE2;
    8'h3C: sub_out = 8'hEB;
    8'h3D: sub_out = 8'h27;
    8'h3E: sub_out = 8'hB2;
    8'h3F: sub_out = 8'h75;
    8'h40: sub_out = 8'h09;
    8'h41: sub_out = 8'h83;
    8'h42: sub_out = 8'h2C;
    8'h43: sub_out = 8'h1A;
    8'h44: sub_out = 8'h1B;
    8'h45: sub_out = 8'h6E;
    8'h46: sub_out = 8'h5A;
    8'h47: sub_out = 8'hA0;
    8'h48: sub_out = 8'h52;
    8'h49: sub_out = 8'h3B;
    8'h4A: sub_out = 8'hD6;
    8'h4B: sub_out = 8'hB3;
    8'h4C: sub_out = 8'h29;
    8'h4D: sub_out = 8'hE3;
    8'h4E: sub_out = 8'h2F;
    8'h4F: sub_out = 8'h84;
    8'h50: sub_out = 8'h53;
    8'h51: sub_out = 8'hD1;
    8'h52: sub_out = 8'h00;
    8'h53: sub_out = 8'hED;
    8'h54: sub_out = 8'h20;
    8'h55: sub_out = 8'hFC;
    8'h56: sub_out = 8'hB1;
    8'h57: sub_out = 8'h5B;
    8'h58: sub_out = 8'h6A;
    8'h59: sub_out = 8'hCB;
    8'h5A: sub_out = 8'hBE;
    8'h5B: sub_out = 8'h39;
    8'h5C: sub_out = 8'h4A;
    8'h5D: sub_out = 8'h4C;
    8'h5E: sub_out = 8'h58;
    8'h5F: sub_out = 8'hCF;
    8'h60: sub_out = 8'hD0;
    8'h61: sub_out = 8'hEF;
    8'h62: sub_out = 8'hAA;
    8'h63: sub_out = 8'hFB;
    8'h64: sub_out = 8'h43;
    8'h65: sub_out = 8'h4D;
    8'h66: sub_out = 8'h33;
    8'h67: sub_out = 8'h85;
    8'h68: sub_out = 8'h45;
    8'h69: sub_out = 8'hF9;
    8'h6A: sub_out = 8'h02;
    8'h6B: sub_out = 8'h7F;
    8'h6C: sub_out = 8'h50;
    8'h6D: sub_out = 8'h3C;
    8'h6E: sub_out = 8'h9F;
    8'h6F: sub_out = 8'hA8;
    8'h70: sub_out = 8'h51;
    8'h71: sub_out = 8'hA3;
    8'h72: sub_out = 8'h40;
    8'h73: sub_out = 8'h8F;
    8'h74: sub_out = 8'h92;
    8'h75: sub_out = 8'h9D;
    8'h76: sub_out = 8'h38;
    8'h77: sub_out = 8'hF5;
    8'h78: sub_out = 8'hBC;
    8'h79: sub_out = 8'hB6;
    8'h7A: sub_out = 8'hDA;
    8'h7B: sub_out = 8'h21;
    8'h7C: sub_out = 8'h10;
    8'h7D: sub_out = 8'hFF;
    8'h7E: sub_out = 8'hF3;
    8'h7F: sub_out = 8'hD2;
    8'h80: sub_out = 8'hCD;
    8'h81: sub_out = 8'h0C;
    8'h82: sub_out = 8'h13;
    8'h83: sub_out = 8'hEC;
    8'h84: sub_out = 8'h5F;
    8'h85: sub_out = 8'h97;
    8'h86: sub_out = 8'h44;
    8'h87: sub_out = 8'h17;
    8'h88: sub_out = 8'hC4;
    8'h89: sub_out = 8'hA7;
    8'h8A: sub_out = 8'h7E;
    8'h8B: sub_out = 8'h3D;
    8'h8C: sub_out = 8'h64;
    8'h8D: sub_out = 8'h5D;
    8'h8E: sub_out = 8'h19;
    8'h8F: sub_out = 8'h73;
    8'h90: sub_out = 8'h60;
    8'h91: sub_out = 8'h81;
    8'h92: sub_out = 8'h4F;
    8'h93: sub_out = 8'hDC;
    8'h94: sub_out = 8'h22;
    8'h95: sub_out = 8'h2A;
    8'h96: sub_out = 8'h90;
    8'h97: sub_out = 8'h88;
    8'h98: sub_out = 8'h46;
    8'h99: sub_out = 8'hEE;
    8'h9A: sub_out = 8'hB8;
    8'h9B: sub_out = 8'h14;
    8'h9C: sub_out = 8'hDE;
    8'h9D: sub_out = 8'h5E;
    8'h9E: sub_out = 8'h0B;
    8'h9F: sub_out = 8'hDB;
    8'hA0: sub_out = 8'hE0;
    8'hA1: sub_out = 8'h32;
    8'hA2: sub_out = 8'h3A;
    8'hA3: sub_out = 8'h0A;
    8'hA4: sub_out = 8'h49;
    8'hA5: sub_out = 8'h06;
    8'hA6: sub_out = 8'h24;
    8'hA7: sub_out = 8'h5C;
    8'hA8: sub_out = 8'hC2;
    8'hA9: sub_out = 8'hD3;
    8'hAA: sub_out = 8'hAC;
    8'hAB: sub_out = 8'h62;
    8'hAC: sub_out = 8'h91;
    8'hAD: sub_out = 8'h95;
    8'hAE: sub_out = 8'hE4;
    8'hAF: sub_out = 8'h79;
    8'hB0: sub_out = 8'hE7;
    8'hB1: sub_out = 8'hC8;
    8'hB2: sub_out = 8'h37;
    8'hB3: sub_out = 8'h6D;
    8'hB4: sub_out = 8'h8D;
    8'hB5: sub_out = 8'hD5;
    8'hB6: sub_out = 8'h4E;
    8'hB7: sub_out = 8'hA9;
    8'hB8: sub_out = 8'h6C;
    8'hB9: sub_out = 8'h56;
    8'hBA: sub_out = 8'hF4;
    8'hBB: sub_out = 8'hEA;
    8'hBC: sub_out = 8'h65;
    8'hBD: sub_out = 8'h7A;
    8'hBE: sub_out = 8'hAE;
    8'hBF: sub_out = 8'h08;
    8'hC0: sub_out = 8'hBA;
    8'hC1: sub_out = 8'h78;
    8'hC2: sub_out = 8'h25;
    8'hC3: sub_out = 8'h2E;
    8'hC4: sub_out = 8'h1C;
    8'hC5: sub_out = 8'hA6;
    8'hC6: sub_out = 8'hB4;
    8'hC7: sub_out = 8'hC6;
    8'hC8: sub_out = 8'hE8;
    8'hC9: sub_out = 8'hDD;
    8'hCA: sub_out = 8'h74;
    8'hCB: sub_out = 8'h1F;
    8'hCC: sub_out = 8'h4B;
    8'hCD: sub_out = 8'hBD;
    8'hCE: sub_out = 8'h8B;
    8'hCF: sub_out = 8'h8A;
    8'hD0: sub_out = 8'h70;
    8'hD1: sub_out = 8'h3E;
    8'hD2: sub_out = 8'hB5;
    8'hD3: sub_out = 8'h66;
    8'hD4: sub_out = 8'h48;
    8'hD5: sub_out = 8'h03;
    8'hD6: sub_out = 8'hF6;
    8'hD7: sub_out = 8'h0E;
    8'hD8: sub_out = 8'h61;
    8'hD9: sub_out = 8'h35;
    8'hDA: sub_out = 8'h57;
    8'hDB: sub_out = 8'hB9;
    8'hDC: sub_out = 8'h86;
    8'hDD: sub_out = 8'hC1;
    8'hDE: sub_out = 8'h1D;
    8'hDF: sub_out = 8'h9E;
    8'hE0: sub_out = 8'hE1;
    8'hE1: sub_out = 8'hF8;
    8'hE2: sub_out = 8'h98;
    8'hE3: sub_out = 8'h11;
    8'hE4: sub_out = 8'h69;
    8'hE5: sub_out = 8'hD9;
    8'hE6: sub_out = 8'h8E;
    8'hE7: sub_out = 8'h94;
    8'hE8: sub_out = 8'h9B;
    8'hE9: sub_out = 8'h1E;
    8'hEA: sub_out = 8'h87;
    8'hEB: sub_out = 8'hE9;
    8'hEC: sub_out = 8'hCE;
    8'hED: sub_out = 8'h55;
    8'hEE: sub_out = 8'h28;
    8'hEF: sub_out = 8'hDF;
    8'hF0: sub_out = 8'h8C;
    8'hF1: sub_out = 8'hA1;
    8'hF2: sub_out = 8'h89;
    8'hF3: sub_out = 8'h0D;
    8'hF4: sub_out = 8'hBF;
    8'hF5: sub_out = 8'hE6;
    8'hF6: sub_out = 8'h42;
    8'hF7: sub_out = 8'h68;
    8'hF8: sub_out = 8'h41;
    8'hF9: sub_out = 8'h99;
    8'hFA: sub_out = 8'h2D;
    8'hFB: sub_out = 8'h0F;
    8'hFC: sub_out = 8'hB0;
    8'hFD: sub_out = 8'h54;
    8'hFE: sub_out = 8'hBB;
    8'hFF: sub_out = 8'h16;
    endcase
end 

endmodule

