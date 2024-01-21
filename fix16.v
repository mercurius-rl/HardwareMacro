module FixAdd (
	input				en,
	output				done,

	input		[15:0]	a,
	input		[15:0]	b,
	output		[15:0]	out
);
	assign	out = $signed(a) + $signed(b);
	assign	done = en;
endmodule

module FixSub (
	input				en,
	output				done,

	input		[15:0]	a,
	input		[15:0]	b,
	output		[15:0]	out
);
	assign	out = $signed(a) - $signed(b);
	assign	done = en;
endmodule

module FixMul (
	input				en,
	output				done,

	input		[15:0]	a,
	input		[15:0]	b,
	output		[15:0]	out
);
	wire	[15:0]	pp00 = (b[00]) ? a : 32'h0;
	wire	[15:0]	pp01 = (b[01]) ? a : 32'h0;
	wire	[15:0]	pp02 = (b[02]) ? a : 32'h0;
	wire	[15:0]	pp03 = (b[03]) ? a : 32'h0;
	wire	[15:0]	pp04 = (b[04]) ? a : 32'h0;
	wire	[15:0]	pp05 = (b[05]) ? a : 32'h0;
	wire	[15:0]	pp06 = (b[06]) ? a : 32'h0;
	wire	[15:0]	pp07 = (b[07]) ? a : 32'h0;
	wire	[15:0]	pp08 = (b[08]) ? a : 32'h0;
	wire	[15:0]	pp09 = (b[09]) ? a : 32'h0;
	wire	[15:0]	pp10 = (b[10]) ? a : 32'h0;
	wire	[15:0]	pp11 = (b[11]) ? a : 32'h0;
	wire	[15:0]	pp12 = (b[12]) ? a : 32'h0;
	wire	[15:0]	pp13 = (b[13]) ? a : 32'h0;
	wire	[15:0]	pp14 = (b[14]) ? a : 32'h0;
	wire	[15:0]	pp15 = (b[15]) ? a : 32'h0;

	wire	[31:0]	temp	= ( {~pp00[15], pp00[14:0]} <<  0 )
							+ ( {~pp01[15], pp01[14:0]} <<  1 )
							+ ( {~pp02[15], pp02[14:0]} <<  2 )
							+ ( {~pp03[15], pp03[14:0]} <<  3 )
							+ ( {~pp04[15], pp04[14:0]} <<  4 )
							+ ( {~pp05[15], pp05[14:0]} <<  5 )
							+ ( {~pp06[15], pp06[14:0]} <<  6 )
							+ ( {~pp07[15], pp07[14:0]} <<  7 )
							+ ( {~pp08[15], pp08[14:0]} <<  8 )
							+ ( {~pp09[15], pp09[14:0]} <<  9 )
							+ ( {~pp10[15], pp10[14:0]} << 10 )
							+ ( {~pp11[15], pp11[14:0]} << 11 )
							+ ( {~pp12[15], pp12[14:0]} << 12 )
							+ ( {~pp13[15], pp13[14:0]} << 13 )
							+ ( {~pp14[15], pp14[14:0]} << 14 )
							+ ( { pp15[15],~pp15[14:0]} << 15 )
							+ 32'h80010000;

	wire	overflow = temp[31:22] > 0;
	assign	out =	(temp[31]) ? // negative number
						(overflow) ? 16'h8000 : {1'b1, temp[22:8]} 
					:			 // positive number
						(overflow) ? 16'h7FFF : {1'b0, temp[22:8]} ;

	assign	done = en;
endmodule

module FixDiv (
	input				clk,
	input				rst,

	input				en,
	output				done,

	input		[15:0]	a,
	input		[15:0]	b,
	output		[15:0]	out
);
	reg		[29:0]	dividend;
	reg		[14:0]	divider;
	reg		[4:0]	c;

	reg				a_sign, b_sign;

	reg		[15:0]	q;

	wire	[16:0]	sub = {1'b0, dividend[29:14]} - {2'b0, divider};

	always @(posedge clk) begin
		if (rst) begin
			c			<=	5'h0;

			dividend	<=	32'h0;
			q			<=	15'h0;
		end else begin
			if (c != 0) begin
				if ( c == 17 ) begin
					if (!en) begin
						c			<=	0;
					end
				end else if ( c == 16 )begin
					q			<=	(a_sign ^ b_sign) ? ~q + 1'b1 : q;
					if (!en) begin
						c			<=	0;
					end else begin
						c			<=	c + 1'b1;
					end
				end else begin
					q			<=	(q << 1) + !sub[16];
					if (!sub[16]) begin // divisible
						dividend	<=	{sub[15:0], dividend[13:0], 1'b0};
					end else begin
						dividend	<=	{dividend[29:0], 1'b0};
					end
					c			<=	c + 1'b1;
				end
			end	else if (en) begin
				divider	<=	(b[15]) ? ~b + 1 : b;
				dividend<=	(a[15]) ? {16'h0, ~a + 16'b1} : a;
				b_sign	<=	b[15];
				a_sign	<=	a[15];
				q		<=	0;
				c		<=	1; 
			end
		end
	end

	assign	out = q;
	assign	done = (c >= 16);
endmodule