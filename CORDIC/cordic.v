

//// CORDIC implementation in Verilog ////


`define K 32'h26dd3b6a  // Π(n=infinity) cos(alpha_n) --> 0.6072529350088814

module CORDIC #(
    parameter IN_WIDTH = 16,
    parameter EXTRA_BITS = 6
) (
    input clk,                          // Master Clock 
    // input rst,                       // Master asynchronous reset
    input  wire signed  [31:0] angle,   // phase_step 
    input  wire signed  [IN_WIDTH -1: 0]          x_init, y_init, 
    output wire signed  [(IN_WIDTH + EXTRA_BITS) -1: 0] cos, sin
    //output reg [31:0] phase_acc
);

    localparam WI = IN_WIDTH;
    localparam WXY = IN_WIDTH + EXTRA_BITS; // 22-bit data regs
    localparam STG = WXY;

    // arctan(2^-idx) = alpha_idx
    //reg [31:0] arctan_2n [0:30];
    wire [31:0] arctan_2n [0:30];

    // MSB 2'b00 (0,PI/2)
    // MSB 2'b01 (PI/2, PI)
    // MSB 2'b10 (PI, 3*PI/2)
    // MSB 2'b11 (3*PI/2, 2*PI)

    //                     32'b01000000000000000000000000000000  // upper 2 bits  = 2'b01 = 90 degree
    assign arctan_2n[00] = 32'b00100000000000000000000000000000; // alpha_0 = pi/4 rads
    assign arctan_2n[01] = 32'b00010010111001000000010100011101; // alpha_1 = 26.565 degrees
    assign arctan_2n[02] = 32'b00001001111110110011100001011011; // alpha_2 = 14.036 degrees
    assign arctan_2n[03] = 32'b00000101000100010001000111010100; 
    assign arctan_2n[04] = 32'b00000010100010110000110101000011;
    assign arctan_2n[05] = 32'b00000001010001011101011111100001;
    assign arctan_2n[06] = 32'b00000000101000101111011000011110;
    assign arctan_2n[07] = 32'b00000000010100010111110001010101;
    assign arctan_2n[08] = 32'b00000000001010001011111001010011;
    assign arctan_2n[09] = 32'b00000000000101000101111100101110;
    assign arctan_2n[10] = 32'b00000000000010100010111110011000;
    assign arctan_2n[11] = 32'b00000000000001010001011111001100;
    assign arctan_2n[12] = 32'b00000000000000101000101111100110;
    assign arctan_2n[13] = 32'b00000000000000010100010111110011;
    assign arctan_2n[14] = 32'b00000000000000001010001011111001;
    assign arctan_2n[15] = 32'b00000000000000000101000101111101;
    assign arctan_2n[16] = 32'b00000000000000000010100010111110;
    assign arctan_2n[17] = 32'b00000000000000000001010001011111;
    assign arctan_2n[18] = 32'b00000000000000000000101000101111;
    assign arctan_2n[19] = 32'b00000000000000000000010100011000;
    assign arctan_2n[20] = 32'b00000000000000000000001010001100;
    assign arctan_2n[21] = 32'b00000000000000000000000101000110;
    assign arctan_2n[22] = 32'b00000000000000000000000010100011;
    assign arctan_2n[23] = 32'b00000000000000000000000001010001;
    assign arctan_2n[24] = 32'b00000000000000000000000000101000;
    assign arctan_2n[25] = 32'b00000000000000000000000000010100;
    assign arctan_2n[26] = 32'b00000000000000000000000000001010;
    assign arctan_2n[27] = 32'b00000000000000000000000000000101;
    assign arctan_2n[28] = 32'b00000000000000000000000000000010;
    assign arctan_2n[29] = 32'b00000000000000000000000000000001; // arctan(2^-29)
    assign arctan_2n[30] = 32'b00000000000000000000000000000000;

    // initial begin
    //     $readmemb("arctan_table.txt", arctan_2n);
    //     $display("Arctan values loaded:");
        
    //     for (integer i = 0; i < 31; i = i + 1) begin
    //         $display("arctan_2n[%0d] = %b", i, arctan_2n[i]);
    //     end
    // end

    reg signed [WXY:0] _x [0:STG-1];
    reg signed [WXY:0] _y [0:STG-1];
    reg signed  [31:0] _z [0:STG-1];

    reg         [31:0] phase_acc; // phase accumulator

    wire [1:0] quadrant = phase_acc[31:30];
    wire signed [WI -1:0] NXin;
    wire signed [WI -1:0] NYin;

    assign NXin = -x_init;
    assign NYin = -y_init;
 
    always @(posedge clk) begin
        // make sure the rotation angle is in the -pi/2 to pi/2 range
        case(quadrant)
            2'b00,
            2'b11: begin // no changes needed for these quadrants
                _x[0] <= {x_init[WI -1], x_init} << (EXTRA_BITS -1);
                _y[0] <= {y_init[WI -1], y_init} << (EXTRA_BITS -1);
                _z[0] <= phase_acc;
            end
    
            2'b01: begin
                _x[0] <= {  NYin[WI -1], NYin}   << (EXTRA_BITS -1);
                _y[0] <= {x_init[WI -1], x_init} << (EXTRA_BITS -1);
                _z[0] <= {2'b00,phase_acc[29:0]}; // subtract pi/2 for angle in this quadrant
            end
    
            2'b10: begin
                _x[0] <= {y_init[WI -1], y_init} << (EXTRA_BITS -1);
                _y[0] <= {  NXin[WI -1], NXin}   << (EXTRA_BITS -1);
                _z[0] <= {2'b11,phase_acc[29:0]}; // add pi/2 to angles in this quadrant
            end
        endcase

        // advanced NCO
        phase_acc <= phase_acc + angle; // phase_step
    end

    genvar i;
    
    generate
    for (i=0; i< (STG -1); i = i+1) 
    
    begin: XYZ
        wire                   z_sgn;
        wire signed  [WXY -1 :0] x_shr, y_shr; 
    
        assign x_shr = _x[i] >>> i; // signed shift right
        assign y_shr = _y[i] >>> i;
    
        //the sign of the current rotation angle
        assign z_sgn = _z[i][31]; // z_sgn = 1 if _z[i] < 0
    
        always @(posedge clk) begin
           // add/subtract shifted data
           _x[i+1] <= z_sgn ? _x[i] + y_shr         : _x[i] - y_shr;
           _y[i+1] <= z_sgn ? _y[i] - x_shr         : _y[i] + x_shr;
           _z[i+1] <= z_sgn ? _z[i] + arctan_2n[i]  : _z[i] - arctan_2n[i];
        end
    end
    endgenerate

    assign sin = _y[IN_WIDTH -1];
    assign cos = _x[IN_WIDTH -1];

endmodule