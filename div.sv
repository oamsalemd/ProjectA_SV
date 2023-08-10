module div #(
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8)
(
    input signed [DATA_WIDTH-1:0] num1,
    input signed [DATA_WIDTH-1:0] num2,
    output logic signed [DATA_WIDTH-1:0] result
);

    assign result = num1 / num2;

endmodule