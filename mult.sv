module mult #(
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8)
(
    input signed [DATA_WIDTH-1:0] num1,
    input signed [DATA_WIDTH-1:0] num2,
    output logic signed [DATA_WIDTH-1:0] product,
    output logic overflow,
    output logic underflow
);

    logic [2*DATA_WIDTH-1:0] temp_prod;
    assign temp_prod = num1 * num2;
    assign product = temp_prod[DATA_WIDTH+FIXED_PNT-1:FIXED_PNT];
    assign overflow = ~num1[DATA_WIDTH-1] & ~num2[DATA_WIDTH-1] & temp_prod[2*DATA_WIDTH-1];
    assign underflow = num1[DATA_WIDTH-1] & num2[DATA_WIDTH-1] & ~temp_prod[2*DATA_WIDTH-1];

endmodule