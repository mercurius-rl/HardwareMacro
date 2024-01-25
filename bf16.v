module BFAdd (
	input				en,
	output				done,

	input		[15:0]	a,
	input		[15:0]	b,
	output		[15:0]	out
);
	wire	[7:0]	w_ex_l, w_ex_s;
	wire	[6:0]	w_fr_l, w_fr_s;
	wire			w_sg_l, w_sg_s;

	wire	comp = (a[14:0] > b[14:0]);

	assign	{w_sg_l, w_ex_l, w_fr_l} = ( comp) ? a : b;
	assign	{w_sg_s, w_ex_s, w_fr_s} = (!comp) ? b : a;

	wire	[7:0]	w_fr_l1, w_fr_s1;
	assign	w_fr_l1 = {1'b1, w_fr_l};
	assign	w_fr_s1 = {1'b1, w_fr_s};

	// shift
	wire	[7:0]	w_sh, w_rem;
	wire	[7:0]	w_ex_sub = w_ex_l - w_ex_s;
	assign	{w_sh, w_rem} = (w_ex_sub >= 8'd10) ? {8'h0, w_fr_s1} : {w_fr_s1, 8'h0} >> w_ex_sub;
	
	// fract calc
	wire			w_xnor = w_sg_l ~^ w_sg_s;
	wire	[8:0]	w_fr_add = w_fr_l1 + w_sh;
	wire	[8:0]	w_fr_sub = w_fr_l1 - w_sh;
	wire	[8:0]	w_fr_res = w_xnor ? w_fr_add : w_fr_sub;

	// normalize
	function [2:0] shc;
	input [7:0] f;
	begin
		if(f[7])		shc = 3'b000;
		else if(f[6])	shc = 3'b001;
		else if(f[5])	shc = 3'b010;
		else if(f[4])	shc = 3'b011;
		else if(f[3])	shc = 3'b100;
		else if(f[2])	shc = 3'b101;
		else if(f[1])	shc = 3'b110;
		else			shc = 3'b111;
	end
	endfunction

	wire	[2:0]	w_sh_count = shc(w_fr_res[7:0]);

	wire	[6:0]	w_norm_fr = (w_xnor) ? w_fr_res >> w_fr_res[8] : w_fr_res << w_sh_count;
	wire	[7:0]	w_norm_ex = (w_xnor) ? w_ex_l + w_fr_res[8] : w_ex_l - w_sh_count;

	// round
	wire	guard, round, stiky;
	assign	{guard, round, stiky} = {w_rem[7], w_rem[6], |w_rem[5:0]};

	wire	[6:0]	w_round_fr = w_norm_fr + (guard & (round | stiky | w_norm_fr[0]));

	// exception
	function [0:0] exception;
	input	[7:0]	ex_l, ex_s;
	input	[6:0]	fr_l, fr_s;
	begin
		casex ( {ex_l,1'b0,fr_l,   ex_s,1'b0,fr_s} )
			32'h00xx_00xx: exception = 2'b01;	// zero
			32'h00xx_ff00: exception = 2'b10;	// inf
			32'h00xx_ffxx: exception = 2'b11;	// NaN
			32'h00xx_xxxx: exception = 2'b00;	// Number
			32'hFF00_00xx: exception = 2'b10;
			32'hFF00_FF00: exception = 2'b10;
			32'hFF00_FFxx: exception = 2'b11;
			32'hFF00_xxxx: exception = 2'b10;
			32'hFFxx_xxxx: exception = 2'b11;
			32'hxxxx_00xx: exception = 2'b00;
			32'hxxxx_FF00: exception = 2'b10;
			32'hxxxx_FFxx: exception = 2'b11;
			32'hxxxx_xxxx: exception = 2'b00;
			default: exception = 2'b00;
		endcase
	end
	endfunction

	wire	[1:0]	w_exc		= exception(w_ex_l, w_ex_s, w_fr_l, w_fr_s);
	wire	[7:0]	w_exc_ex	= (w_exc == 2'b00) ?	w_norm_ex
								: (w_exc == 2'b01) ?	8'h00 
								:						8'hFF;
	wire	[6:0]	w_exc_fr	= (w_exc == 2'b00) ?	w_round_fr
								: (w_exc == 2'b11) ?	7'h40 
								:						7'h00;
	wire			w_exc_sg	= w_sg_l;

	assign	out = {w_exc_sg, w_exc_ex, w_exc_fr};

endmodule

module BFSub (
	input				en,
	output				done,

	input		[15:0]	a,
	input		[15:0]	b,
	output		[15:0]	out
);
	wire	[7:0]	w_ex_l, w_ex_s;
	wire	[6:0]	w_fr_l, w_fr_s;
	wire			w_sg_l, w_sg_s;

	wire	comp = (a[14:0] > b[14:0]);
	wire	[15:0]	neg_b = {~b[15],b[14:0]};

	assign	{w_sg_l, w_ex_l, w_fr_l} = ( comp) ? a : neg_b;
	assign	{w_sg_s, w_ex_s, w_fr_s} = (!comp) ? neg_b : a;

	wire	[7:0]	w_fr_l1, w_fr_s1;
	assign	w_fr_l1 = {1'b1, w_fr_l};
	assign	w_fr_s1 = {1'b1, w_fr_s};

	// shift
	wire	[7:0]	w_sh, w_rem;
	wire	[7:0]	w_ex_sub = w_ex_l - w_ex_s;
	assign	{w_sh, w_rem} = (w_ex_sub >= 8'd10) ? {8'h0, w_fr_s1} : {w_fr_s1, 8'h0} >> w_ex_sub;
	
	// fract calc
	wire			w_xnor = w_sg_l ~^ w_sg_s;
	wire	[8:0]	w_fr_add = w_fr_l1 + w_sh;
	wire	[8:0]	w_fr_sub = w_fr_l1 - w_sh;
	wire	[8:0]	w_fr_res = w_xnor ? w_fr_add : w_fr_sub;

	// normalize
	function [2:0] shc;
	input [7:0] f;
	begin
		if(f[7])		shc = 3'b000;
		else if(f[6])	shc = 3'b001;
		else if(f[5])	shc = 3'b010;
		else if(f[4])	shc = 3'b011;
		else if(f[3])	shc = 3'b100;
		else if(f[2])	shc = 3'b101;
		else if(f[1])	shc = 3'b110;
		else			shc = 3'b111;
	end
	endfunction

	wire	[2:0]	w_sh_count = shc(w_fr_res[7:0]);

	wire	[6:0]	w_norm_fr = (w_xnor) ? w_fr_res >> w_fr_res[8] : w_fr_res << w_sh_count;
	wire	[7:0]	w_norm_ex = (w_xnor) ? w_ex_l + w_fr_res[8] : w_ex_l - w_sh_count;

	// round
	wire	guard, round, stiky;
	assign	{guard, round, stiky} = {w_rem[7], w_rem[6], |w_rem[5:0]};

	wire	[6:0]	w_round_fr = w_norm_fr + (guard & (round | stiky | w_norm_fr[0]));

	// exception
	function [0:0] exception;
	input	[7:0]	ex_l, ex_s;
	input	[6:0]	fr_l, fr_s;
	begin
		casex ( {ex_l,1'b0,fr_l,   ex_s,1'b0,fr_s} )
			32'h00xx_00xx: exception = 2'b01;	// zero
			32'h00xx_ff00: exception = 2'b10;	// inf
			32'h00xx_ffxx: exception = 2'b11;	// NaN
			32'h00xx_xxxx: exception = 2'b00;	// Number
			32'hFF00_00xx: exception = 2'b10;
			32'hFF00_FF00: exception = 2'b10;
			32'hFF00_FFxx: exception = 2'b11;
			32'hFF00_xxxx: exception = 2'b10;
			32'hFFxx_xxxx: exception = 2'b11;
			32'hxxxx_00xx: exception = 2'b00;
			32'hxxxx_FF00: exception = 2'b10;
			32'hxxxx_FFxx: exception = 2'b11;
			32'hxxxx_xxxx: exception = 2'b00;
			default: exception = 2'b00;
		endcase
	end
	endfunction

	wire	[1:0]	w_exc		= exception(w_ex_l, w_ex_s, w_fr_l, w_fr_s);
	wire	[7:0]	w_exc_ex	= (w_exc == 2'b00) ?	w_norm_ex
								: (w_exc == 2'b01) ?	8'h00 
								:						8'hFF;
	wire	[6:0]	w_exc_fr	= (w_exc == 2'b00) ?	w_round_fr
								: (w_exc == 2'b11) ?	7'h40 
								:						7'h00;
	wire			w_exc_sg	= w_sg_l;

	assign	out = {w_exc_sg, w_exc_ex, w_exc_fr};
endmodule

module BFMul (
	input				en,
	output				done,

	input		[15:0]	a,
	input		[15:0]	b,
	output		[15:0]	out
);

	// multiply
	wire			w_sg		= a[15] ^ b[15];
	wire	[15:0]	w_fr_mul	= {1'b1, a[6:0]} * {1'b1, b[6:0]};
	wire	[8:0]	w_ex_tmp	= a[14:7] + b[14:7] - 'd127 + w_fr_mul[15];

	// normalize
	wire	[10:0]	w_fr_tmp	= {w_fr_mul[15:6], (|w_fr_mul[5:0])};
	wire	[10:0]	w_norm_fr	= (w_fr_mul[15]) ? w_fr_tmp : {w_fr_tmp[9:0], 1'b0};
	
	// round
	wire	least, guard, round, stiky;
	assign	{least, guard, round, stiky} = {w_norm_fr[3], w_norm_fr[2], w_norm_fr[1], w_norm_fr[0]};
	wire	[7:0]	w_round_fr = w_norm_fr[9:3] + (guard & (least | round | stiky));

	// exception
	function [0:0] exception;
	input	[7:0]	ex_l, ex_s;
	input	[6:0]	fr_l, fr_s;
	begin
		casex ( {ex_l,1'b0,fr_l,   ex_s,1'b0,fr_s} )
			32'h00xx_00xx: exception = 2'b01;	// zero
			32'h00xx_ff00: exception = 2'b11;	// NaN
			32'h00xx_ffxx: exception = 2'b11;	// NaN
			32'h00xx_xxxx: exception = 2'b01;	// zero
			32'hFF00_00xx: exception = 2'b11;
			32'hFF00_FF00: exception = 2'b10;
			32'hFF00_FFxx: exception = 2'b11;
			32'hFF00_xxxx: exception = 2'b10;
			32'hFFxx_xxxx: exception = 2'b11;
			32'hxxxx_00xx: exception = 2'b01;
			32'hxxxx_FF00: exception = 2'b10;
			32'hxxxx_FFxx: exception = 2'b11;
			32'hxxxx_xxxx: exception = 2'b00;
			default: exception = 2'b11;
		endcase
	end
	endfunction

	wire	[1:0]	w_exc		= exception(a[14:7], a[6:0], b[14:7], b[6:0]);
	wire	[7:0]	w_exc_ex	= (w_exc == 2'b00) ?	(w_ex_tmp[8])?	8'h00	:	w_ex_tmp[7:0]
								: (w_exc == 2'b01) ?	8'h00 
								:						8'hFF;
	wire	[6:0]	w_exc_fr	= (w_exc == 2'b00) ?	(w_ex_tmp[8])?	7'h00	:	w_round_fr
								: (w_exc == 2'b11) ?	7'h40 
								:						7'h00;
	wire			w_exc_sg	= w_sg;

	assign	out = {w_exc_sg, w_exc_ex, w_exc_fr};

endmodule

module BFDiv (
	input				en,
	output				done,

	input		[15:0]	a,
	input		[15:0]	b,
	output		[15:0]	out
);
	
	// divide
	wire			w_sg		= a[15] ^ b[15];
	wire	[17:0]	w_div_fr	= ( {1'b1, a[6:0]} << 10 ) / {1'b1, b[6:0]};
	wire	[8:0]	w_ex_tmp	= a[14:7] - b[14:7] + 'd127 - !w_div_fr[10];

	// normalize
	wire	[10:0]	w_norm_fr	= (w_div_fr[9]) ? {w_div_fr[9:0], 1'b1} : {w_div_fr[8:0], 2'b11};

	// round
	wire	least, guard, round, stiky;
	assign	{least, guard, round, stiky} = {w_norm_fr[3], w_norm_fr[2], w_norm_fr[1], w_norm_fr[0]};
	wire	[7:0]	w_round_fr = w_norm_fr[9:3] + (guard & (least | round | stiky));

	// exception
	function [0:0] exception;
	input	[7:0]	ex_l, ex_s;
	input	[6:0]	fr_l, fr_s;
	begin
		casex ( {ex_l,1'b0,fr_l,   ex_s,1'b0,fr_s} )
			32'h00xx_00xx: exception = 2'b11;	// NaN
			32'h00xx_ff00: exception = 2'b01;	// zero
			32'h00xx_ffxx: exception = 2'b11;	// NaN
			32'h00xx_xxxx: exception = 2'b01;	// zero
			32'hFF00_00xx: exception = 2'b10;	// inf
			32'hFF00_FFxx: exception = 2'b11;	// NaN
			32'hFF00_xxxx: exception = 2'b10;	// inf
			32'hFFxx_xxxx: exception = 2'b11;
			32'hxxxx_0000: exception = 2'b10;
			32'hxxxx_FF00: exception = 2'b01;
			32'hxxxx_FFxx: exception = 2'b11;
			32'hxxxx_xxxx: exception = 2'b00;
			default: exception = 2'b11;
		endcase
	end
	endfunction

	wire	[1:0]	w_exc		= exception(a[14:7], a[6:0], b[14:7], b[6:0]);
	wire	[7:0]	w_exc_ex	= (w_exc == 2'b00) ?	(w_ex_tmp[8])?	8'h00	:	w_ex_tmp[7:0]
								: (w_exc == 2'b01) ?	8'h00 
								:						8'hFF;
	wire	[6:0]	w_exc_fr	= (w_exc == 2'b00) ?	(w_ex_tmp[8])?	7'h00	:	w_round_fr
								: (w_exc == 2'b11) ?	7'h40 
								:						7'h00;
	wire			w_exc_sg	= w_sg;

	assign	out = {w_exc_sg, w_exc_ex, w_exc_fr};
endmodule