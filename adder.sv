module adder #(
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8,
    parameter IS_REDUCE = 0)
(
    input signed [DATA_WIDTH-1:0] num1,
    input signed [DATA_WIDTH-1:0] num2,
    output logic signed [DATA_WIDTH-1:0] sum,
    output logic overflow,
    output logic underflow
);
    generate if (IS_REDUCE) begin: MINUS
            assign sum = num1 - num2;
        end else begin: ADD
            assign sum = num1 + num2;
        end
    endgenerate

    assign overflow = ~num1[DATA_WIDTH-1] & ~num2[DATA_WIDTH-1] & sum[DATA_WIDTH-1];
    assign underflow = num1[DATA_WIDTH-1] & num2[DATA_WIDTH-1] & ~sum[DATA_WIDTH-1];

endmodule