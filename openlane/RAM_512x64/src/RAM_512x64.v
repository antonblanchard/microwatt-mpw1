module RAM_512x64 (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif
    input           CLK,
    input   [7:0]   WE,
    input           EN,
    input   [63:0]  Di,
    output  [63:0]  Do,
    input   [8:0]   A
);
   
    DFFRAM #(.COLS(2)) LBANK (
            `ifdef USE_POWER_PINS
                .VPWR(vccd1),
                .VGND(vssd1),
            `endif
                .CLK(CLK),
                .WE(WE[3:0]),
                .EN(EN),
                .Di(Di[31:0]),
                .Do(Do[31:0]),
                .A(A[8:0])
            );

    DFFRAM #(.COLS(2)) HBANK (
            `ifdef USE_POWER_PINS
                .VPWR(vccd1),
                .VGND(vssd1),
            `endif
                .CLK(CLK),
                .WE(WE[7:4]),
                .EN(EN),
                .Di(Di[63:32]),
                .Do(Do[63:32]),
                .A(A[8:0])
            );

endmodule        
