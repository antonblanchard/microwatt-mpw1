`default_nettype none
/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
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

/* tbuart --- mimic an external UART display, operating at 9600 baud	*/
/* and accepting ASCII characters for display.				*/

/* To do:  Match a known UART 3.3V 16x2 LCD display.  However, it	*/
/* should be possible on a testing system to interface to the UART	*/
/* pins on a Raspberry Pi, also running at 3.3V.			*/

module tbuart_modified # (
	parameter baud_rate = 115200
) (
	input  ser_rx
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
					$write("%c", recv_pattern);
					$fflush();
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
