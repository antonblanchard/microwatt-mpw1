`default_nettype none
/*
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *  Copyright (C) 2018  Tim Edwards <tim@efabless.com>
 *  Copyright (C) 2020  Anton Blanchard <anton@linux.ibm.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`timescale 1 ns / 1 ps

`include "caravel_netlists.v"
`include "spiflash.v"
`include "tbuart_modified.v"

module memory_test;
	reg clock;
	reg RSTB;
	reg CSB;
	reg power1, power2;

	wire gpio;
	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;
	wire [37:0] mprj_io;
	wire [1:0] checkbits;
	wire uart_tx;
	wire user_flash_csb;
	wire user_flash_clk;
	inout user_flash_io0;
	inout user_flash_io1;
	inout user_flash_io2;
	inout user_flash_io3;

	assign user_flash_csb = mprj_io[8];
	assign user_flash_clk = mprj_io[9];

	// Without output enables, how can we hook up bidirectional pins?
	assign user_flash_io0 = mprj_io[10];
	assign mprj_io[11] = user_flash_io1;
	assign user_flash_io2 = mprj_io[12];
	assign user_flash_io3 = mprj_io[13];

	assign checkbits = mprj_io[17:16];

	assign uart_tx = mprj_io[6];
	assign mprj_io[5] = 1'b1;

	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;

	// 50 MHz clock
	always #10 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("memory_test.vcd");
		$dumpvars(0, memory_test);

		$display("Microwatt memory test");

		repeat (500000) @(posedge clock);
		$display("Timeout");
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#1000;
		RSTB <= 1'b1;		// Release reset
		#170000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
	end

	always @(checkbits) begin
                wait(checkbits == 2'h1);
                $display("Management engine started");

                wait(checkbits == 2'h2);
                $display("Microwatt alive!");

		wait(checkbits != 2'h2);

		if(checkbits == 2'h0) begin
			$display("Fail");
			$finish;
		end

		if(checkbits == 2'h3) begin
			$display("Success");
			$finish;
		end

		$display("Unknown Failure %x", checkbits);
		$finish;
	end

	wire VDD3V3;
	wire VDD1V8;
	wire VSS;

	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("mgmt_engine.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

	spiflash #(
		.FILENAME("microwatt.hex")
	) spiflash_microwatt (
		.csb(user_flash_csb),
		.clk(user_flash_clk),
		.io0(user_flash_io0),
		.io1(user_flash_io1),
		.io2(user_flash_io2),
		.io3(user_flash_io3)
	);

	tbuart_modified #(
		.baud_rate(115200)
	) tbuart (
		.ser_rx(uart_tx)
	);

endmodule
`default_nettype wire
