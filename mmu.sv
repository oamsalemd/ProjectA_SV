/*

1. Upon "enable", the MMU will start to multiply the input matrices and accumulate the result in the output matrix.
2. "enable" must remain asserted until "data_ready" pulses.
3. First cycle:
    -> All multiplications occur simultaneously.
   Second cycle:
    -> All adders are chained together to accumulate the result.
4. Then, "data_ready" pulses when the output matrix is ready.

*/

module mmu #(
    parameter NUM_ROWS_A = 1,
    parameter NUM_COLS_A = 1, // NUM_ROWS_B
    parameter NUM_COLS_B = 1,
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8
) (
    input clk,
    input rst_n,
    input enable, // level signal
    input signed [DATA_WIDTH-1:0] mat_in1 [NUM_ROWS_A][NUM_COLS_A],
    input signed [DATA_WIDTH-1:0] mat_in2 [NUM_COLS_A][NUM_COLS_B],
    input signed [DATA_WIDTH-1:0] mat_in_accum [NUM_ROWS_A][NUM_COLS_B],
    output logic data_ready,
    output logic signed [DATA_WIDTH-1:0] mat_out [NUM_ROWS_A][NUM_COLS_B]
);

    logic [DATA_WIDTH-1:0] mat_mul_temp [NUM_ROWS_A][NUM_COLS_B][NUM_COLS_A];
    logic enable_d;
    logic enable_dd;

    generate
        for (genvar i = 0; i < NUM_ROWS_A; i = i + 1) begin: row_a
            for (genvar j = 0; j < NUM_COLS_B; j = j +1) begin: col_b
                for (genvar k = 0; k < NUM_COLS_A; k = k + 1) begin: col_a
                    logic signed [DATA_WIDTH-1:0] mat_in1_gated [NUM_ROWS_A][NUM_COLS_A];
                    assert mat_in1_gated[i][k] = enable ? mat_in1[i][k] : 'h0;

                    logic signed [DATA_WIDTH-1:0] mat_in2_gated [NUM_COLS_A][NUM_COLS_B];
                    assert mat_in2_gated[k][j] = enable ? mat_in2[k][j] : 'h0;

                    mult #(DATA_WIDTH, FIXED_PNT) mult_inst (
                        .num1(mat_in1_gated[i][k]),
                        .num2(mat_in2_gated[k][j]),
                        .product(mat_mul_temp[i][j][k])
                        .overflow(),
                        .underflow()
                    );
                end
            end
        end
    endgenerate

    always_ff (posedge clk or negedge rst_n) begin
        generate
            for (genvar r = 0; r < NUM_ROWS_A; r = r + 1) begin: out_rows
                for (genvar s = 0; s < NUM_COLS_B; s = s + 1) begin: out_cols
                    logic [DATA_WIDTH-1:0] adders_chain_result [NUM_COLS_A];
                    for (genvar t = 1; t < NUM_COLS_A; t = t + 1) begin: out_cols
                        adder #(DATA_WIDTH, FIXED_PNT) adder_inst (
                            .num1(adders_chain_result[t-1]),
                            .num2(mat_mul_temp[r][s][t]),
                            .sum(adders_chain_result[t]),
                            .overflow(),
                            .underflow()
                        );
                        end

                    if (~rst_n) mat_out[r][s] <= 'h0;
                    else if (enable_d) begin
                        logic [DATA_WIDTH-1:0] first_adder_result;
                        adder #(DATA_WIDTH, FIXED_PNT) adder_inst (
                            .num1(mat_in_accum[r][s]),
                            .num2(mat_mul_temp[r][s][0]),
                            .sum(first_adder_result),
                            .overflow(),
                            .underflow()
                        );

                        assign adders_chain_result[0] = first_adder_result;

                        mat_out[r][s] <= adders_chain_result[NUM_COLS_A-1]
                    end
                end
            end
        endgenerate
    end

    always_ff (posedge clk or negedge rst_n) begin
        if (~rst_n) enable_d <= 0;
        else enable_d <= enable;
    end

    always_ff (posedge clk or negedge rst_n) begin
        if (~rst_n) enable_dd <= 0;
        else enable_dd <= enable_d;
    end

    assign data_ready = enable_d & ~enable_dd;

endmodule