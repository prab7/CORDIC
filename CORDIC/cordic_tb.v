`timescale 1ns/100ps
`include "cordic.sv"

module cordic_testbench;

    reg  [15:0] Xin, Yin;
    reg  [31:0] frequency;
    wire [21:0] Xout, Yout, out_data_I, out_data_Q;
    wire  [31:0] phase_acc_out;
    reg         CLK_12MHz;

    initial begin 

        $dumpfile("./cordic.vcd");
        $dumpvars(0, cordic_testbench);

        CLK_12MHz = 1'b0;
        // Xin = 16'b0;
        // Yin = 16'd10000;
        Xin = 16'd10000;
        Yin = 16'b0;

        frequency = 32'h1555_5555; // 30 degrees at a time
        force orig.phase_acc = 0;
        #100;
        #5000;
        @(posedge CLK_12MHz);
        release orig.phase_acc;
        
        @(posedge CLK_12MHz); // 60
        @(posedge CLK_12MHz); // 90
        @(posedge CLK_12MHz); // 120
        @(posedge CLK_12MHz); // 150
        @(posedge CLK_12MHz); // 210
        @(posedge CLK_12MHz); // 240
        @(posedge CLK_12MHz); // 270
        @(posedge CLK_12MHz); // 300
        @(posedge CLK_12MHz); // 330
        @(posedge CLK_12MHz); // 360
        @(posedge CLK_12MHz); // 30

        force orig.phase_acc = 0;

        #20000 $finish;
    end

    CORDIC orig (CLK_12MHz, frequency, Xin, Yin, out_data_I, out_data_Q);

    parameter CLK12_SPEED = 40.7;

    always begin
            #CLK12_SPEED CLK_12MHz = 1'b1;
            #CLK12_SPEED CLK_12MHz = 1'b0;
    end

endmodule


