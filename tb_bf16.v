module tb_bf16;
	integer fd, fda, fds, fdm, fdd; // file descriptor

	reg [15:0]	a, b;
	wire[15:0]	out_add, out_sub, out_mul, out_div;

	integer		rtn=0;

	initial begin
		fd = $fopen("verification_dataset_bf16/value_soruce.txt","r");
		fda = $fopen("verification_dataset_bf16/value_add_h.txt","w");
		fds = $fopen("verification_dataset_bf16/value_sub_h.txt","w");
		fdm = $fopen("verification_dataset_bf16/value_mul_h.txt","w");
		fdd = $fopen("verification_dataset_bf16/value_div_h.txt","w");
		if(fd===0) $finish;
		//num = $fscanf(fd,"a=%d,b=%d",a,b);

		while($feof(fd)===0) begin
			rtn = $fscanf(fd,"%b",a);
			rtn = $fscanf(fd,"%b",b);
			#10;
			$fwrite(fda,"%b\n",out_add);
			$fwrite(fds,"%b\n",out_sub);
			$fwrite(fdm,"%b\n",out_mul);
			$fwrite(fdd,"%b\n",out_div);
		end
		$fclose(fd);
		$fclose(fda);
		$fclose(fds);
		$fclose(fdm);
		$fclose(fdd);
	end

	BFAdd BFAdd(
		.a(a),
		.b(b),
		.out(out_add)
	);

	BFSub BFSub(
		.a(a),
		.b(b),
		.out(out_sub)
	);

	BFMul BFMul(
		.a(a),
		.b(b),
		.out(out_mul)
	);

	BFDiv BFDiv(
		.a(a),
		.b(b),
		.out(out_div)
	);

	initial begin
		$dumpfile("wave.vcd");
		$dumpvars(0, tb_bf16);
	end
endmodule