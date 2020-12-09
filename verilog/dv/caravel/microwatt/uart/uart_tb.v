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

module tbuart_expect_seven # (
	parameter baud_rate = 115200
) (
	input ser_rx
);
	reg [3:0] recv_state;
	reg [2:0] recv_divcnt;
	reg [7:0] recv_pattern;

	reg clk;

	initial begin
		clk <= 1'b0;
		recv_state <= 0;
		recv_divcnt <= 0;
		recv_pattern <= 0;
	end

	// Our simulation is in nanosecond steps and we want 5 clocks per bit,
	// ie 10 clock transitions
	always #(1000000000/baud_rate/10) clk <= (clk === 1'b0);

	always @(posedge clk) begin
		recv_divcnt <= recv_divcnt + 1;
		case (recv_state)
			0: begin
				if (!ser_rx)
					recv_state <= 1;
				recv_divcnt <= 0;
			end
			1: begin
				if (2*recv_divcnt > 3'd3) begin
					recv_state <= 2;
					recv_divcnt <= 0;
				end
			end
			10: begin
				if (recv_divcnt > 3'd3) begin
					recv_state <= 0;
					$display("Got %c from Microwatt", recv_pattern);
					// Expecting 7 back
					if (recv_pattern == 55) begin
						$finish;
					end else begin
						$fatal;
					end
				end
			end
			default: begin
				if (recv_divcnt > 3'd3) begin
					recv_pattern <= {ser_rx, recv_pattern[7:1]};
					recv_state <= recv_state + 1;
					recv_divcnt <= 0;
				end
			end
		endcase
	end
endmodule

module uart_tb;
	reg clock;
	reg RSTB;
	reg CSB;
	reg power1, power2;
	reg uart_rx;

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

	assign user_flash_csb = mprj_io[8];
	assign user_flash_clk = mprj_io[9];
	assign user_flash_io0 = mprj_io[10];
	assign mprj_io[11] = user_flash_io1;

	assign checkbits = mprj_io[17:16];
	assign uart_tx = mprj_io[6];
	assign mprj_io[5] = uart_rx;

	// 50 MHz clock
	always #10 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("uart.vcd");
		$dumpvars(0, uart_tb);

		$display("Microwatt UART rx -> tx test");

		repeat (150) begin
			repeat (10000) @(posedge clock);
			// Diagnostic. . . interrupts output pattern.
		end
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

	initial begin
		uart_rx <= 1'b1;

		wait(checkbits == 2'h1);
		$display("Management engine started");

		wait(checkbits == 2'h2);
		$display("Microwatt alive!");

		// 115200 = 8680 ns per bit
		$display("Writing 7 to Microwatt uart");
		uart_rx <= 1'b0;
		#8680
		uart_rx <= 1'b1;
		#8680
		uart_rx <= 1'b1;
		#8680
		uart_rx <= 1'b1;
		#8680
		uart_rx <= 1'b0;
		#8680
		uart_rx <= 1'b1;
		#8680
		uart_rx <= 1'b1;
		#8680
		uart_rx <= 1'b0;
		#8680
		uart_rx <= 1'b0;
		#8680
		$display("Done. Waiting for Microwatt to send 7 back");
		uart_rx <= 1'b1;
	end

	wire VDD3V3;
	wire VDD1V8;
	wire VSS;

	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;

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
		.io2(),			// not used
		.io3()			// not used
	);

	tbuart_expect_seven #(
		.baud_rate(115200)
	) tbuart (
		.ser_rx(uart_tx)
	);

endmodule
`default_nettype wire
