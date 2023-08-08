module adder #(
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8)
(
    input signed [DATA_WIDTH-1:0] num1,
    input signed [DATA_WIDTH-1:0] num2,
    output logic signed [DATA_WIDTH-1:0] sum,
    output logic overflow,
    output logic underflow
);

    assign sum = num1 + num2;
    assign overflow = ~num1[DATA_WIDTH-1] & ~num2[DATA_WIDTH-1] & sum[DATA_WIDTH-1];
    assign underflow = num1[DATA_WIDTH-1] & num2[DATA_WIDTH-1] & ~sum[DATA_WIDTH-1];

endmodule