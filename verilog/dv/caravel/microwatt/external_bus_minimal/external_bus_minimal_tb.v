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


module external_bus_tb (
	input clk,

	input [7:0] ext_bus_in,
	input ext_bus_pty_in,

	output [7:0] ext_bus_out,
	output ext_bus_pty_out
);
	localparam [7:0] CMD_READ = 8'h2;
	localparam [7:0] CMD_WRITE = 8'h3;
	localparam [7:0] CMD_READ_ACK = 8'h82;
	localparam [7:0] CMD_WRITE_ACK = 8'h83;

	localparam [3:0] ADDR_BYTES = 4;
	localparam [3:0] DATA_BYTES = 8;

	localparam [3:0] READ_DELAY_CYCLES = 8;

	localparam [3:0] RECV_STATE_IDLE = 0;
	localparam [3:0] RECV_STATE_WRITE_ADDR = 1;
	localparam [3:0] RECV_STATE_WRITE_DATA = 2;
	localparam [3:0] RECV_STATE_WRITE_SEL = 3;
	localparam [3:0] RECV_STATE_READ_ADDR = 4;
	localparam [3:0] RECV_STATE_READ_DELAY = 5;
	reg [3:0] recv_state;

	reg [31:0] recv_addr;
	reg [63:0] recv_data;
	reg [7:0] recv_sel;
	reg [3:0] recv_count;
	reg [127:0] tx_data;

	reg [7:0] bus_out;

	assign ext_bus_out = bus_out;
	assign ext_bus_pty_out = ~^bus_out;

	initial begin
		bus_out <= 8'h0;
		recv_state <= 0;
		recv_addr <= 0;
		recv_sel <= 0;
		recv_data <= 0;
		recv_count <= 0;
		tx_data <= 0;
	end

	// receive on positive edge
	always @(posedge clk) begin
		if (ext_bus_pty_in != ~^ext_bus_in) begin
			$display("Bad parity on bus");
			$fatal;
		end

		case (recv_state)
			RECV_STATE_IDLE: begin
				//$display("Idle state");

				if (ext_bus_in == CMD_WRITE) begin
					$display("Got write command");
					recv_state <= RECV_STATE_WRITE_ADDR;
					recv_addr <= 0;
					recv_sel <= 0;
					recv_data <= 0;
					recv_count <= ADDR_BYTES;
				end
				if (ext_bus_in == CMD_READ) begin
					$display("Got read command");
					recv_state <= RECV_STATE_READ_ADDR;
					recv_addr <= 0;
					recv_sel <= 0;
					recv_data <= 0;
					recv_count <= ADDR_BYTES;
				end
			end

			RECV_STATE_WRITE_ADDR: begin
				$display("RECV_STATE_WRITE_ADDR state");

				recv_addr <= { ext_bus_in, recv_addr[23:8] };
				$display("A: %02x", ext_bus_in);
				if (recv_count == 1) begin
					recv_state <= RECV_STATE_WRITE_SEL;
				end else begin
					recv_count <= recv_count - 1;
				end
			end

			RECV_STATE_WRITE_SEL: begin
				$display("RECV_STATE_WRITE_SEL state");

				$display("S: %02x", ext_bus_in);
				recv_sel <= ext_bus_in;
				recv_state <= RECV_STATE_WRITE_DATA;
				recv_count <= DATA_BYTES;
			end

			RECV_STATE_WRITE_DATA: begin
				$display("RECV_STATE_WRITE_DATA state");

				recv_data <= { ext_bus_in, recv_addr[23:8] };
				$display("D: %02x", ext_bus_in);
				if (recv_count == 1) begin
					tx_data <= CMD_WRITE_ACK;
					recv_state <= RECV_STATE_IDLE;
				end else begin
					recv_count <= recv_count - 1;
				end
			end

			RECV_STATE_READ_ADDR: begin
				$display("RECV_STATE_READ_ADDR state");

				recv_addr <= { ext_bus_in, recv_addr[23:8] };
				$display("A: %02x", ext_bus_in);
				if (recv_count == 1) begin
					recv_count <= READ_DELAY_CYCLES;
					recv_state <= RECV_STATE_READ_DELAY;
				end else begin
					recv_count <= recv_count - 1;
				end
			end

			RECV_STATE_READ_DELAY: begin
				$display("RECV_STATE_READ_DELAY state");
				if (recv_count == 1) begin
					tx_data <= { 64'h0102030405060708, CMD_READ_ACK};
					recv_state <= RECV_STATE_IDLE;
				end else begin
					recv_count <= recv_count - 1;
				end
			end

			default: begin
				$display("BAD state");
				$fatal;
			end
		endcase
	end

	// transmit on negative edge
	always @(negedge clk) begin
		if (|tx_data) begin
			$display("T: %02x", tx_data[7:0]);
			bus_out <= tx_data[7:0];
			tx_data <= tx_data[127:8];
		end else begin
			bus_out <= 8'h0;
		end
	end
endmodule

module external_bus_minimal_tb;
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
	wire [3:0] checkbits;
	wire user_flash_csb;
	wire user_flash_clk;
	inout user_flash_io0;
	inout user_flash_io1;
	wire ext_bus_clk;
	wire [7:0] ext_bus_in;
	wire ext_bus_pty_in;
	wire [7:0] ext_bus_out;
	wire ext_bus_pty_out;

	assign user_flash_csb = mprj_io[8];
	assign user_flash_clk = mprj_io[9];
	assign user_flash_io0 = mprj_io[10];
	assign mprj_io[11] = user_flash_io1;

	assign checkbits = mprj_io[17:16];

	assign ext_bus_clk = mprj_io[18];
	assign ext_bus_out[7:0] = mprj_io[26:19];
	assign ext_bus_pty_out = mprj_io[27];
	assign mprj_io[35:28] = ext_bus_in[7:0];
	assign mprj_io[36] = ext_bus_pty_in;

	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;

	// 50 MHz clock
	always #10 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("external_bus_minimal.vcd");
		$dumpvars(0, external_bus_minimal_tb);

		$display("Microwatt external bus minimal test");

		repeat (1000000) begin
			@(posedge clock);
		end

		$display("Timeout, test failed");
		$fatal;
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
		wait(checkbits == 2'h1);
		$display("Management engine started");

		wait(checkbits == 2'h2);
		$display("Microwatt alive!");

		// Wait for Microwatt to respond with success
		wait(checkbits == 2'h3);
		$display("Success!");
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
		.io2(),			// not used
		.io3()			// not used
	);

	external_bus_tb external_bus_tb (
		.clk(ext_bus_clk),
		.ext_bus_in(ext_bus_out),
		.ext_bus_pty_in(ext_bus_pty_out),
		.ext_bus_out(ext_bus_in),
		.ext_bus_pty_out(ext_bus_pty_in)
	);
endmodule
`default_nettype wire
