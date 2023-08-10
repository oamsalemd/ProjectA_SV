/*

Compile:
vcs +libext+.sv -sv -y .. ../mmu_long.sv -debug_access+all -sverilog -timescale=1ns/1ps -kdb -lca

1. Upon "enable", the MMU will start to multiply the input matrices and accumulate the result in the output matrix.
2. "enable" must remain asserted until "data_ready" pulses.
   Once "data_ready" pulses, the output matrix is ready and "enable" MUST be deasserted.
3. Each cycle, the MMU multiplies a single cell of mat_in1 with a single cell of mat_in2 and adds the result to the corresponding cell of mat_in_accum.
4. Then, "data_ready" pulses when the output matrix is ready.

*/

module mmu_long #(
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

    logic [$clog2(NUM_ROWS_A):0] counter_row_a;
    logic [$clog2(NUM_COLS_A):0] counter_col_a; // counter_row_b
    logic [$clog2(NUM_COLS_B):0] counter_col_b;

    logic enable_d;

    logic [DATA_WIDTH-1:0] gated_num1;
    logic [DATA_WIDTH-1:0] gated_num2;
    logic [DATA_WIDTH-1:0] cell_mult_output;
    logic [DATA_WIDTH-1:0] cell_accum_output;

    logic done_row_a;
    assign done_row_a = (counter_row_a == NUM_ROWS_A-1);
    logic done_col_a;
    assign done_col_a = (counter_col_a == NUM_COLS_A-1);
    logic done_col_b;
    assign done_col_b = (counter_col_b == NUM_COLS_B-1);

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) counter_col_a <= {NUM_COLS_A{1'b0}};
        else if (enable_d) counter_col_a <= done_col_a ? {NUM_COLS_A{1'b0}} : counter_col_a + 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) counter_row_a <= {NUM_ROWS_A{1'b0}};
        else if (enable_d && done_col_a) counter_row_a <= done_row_a ? {NUM_ROWS_A{1'b0}} : counter_row_a + 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) counter_col_b <= {NUM_COLS_B{1'b0}};
        else if (enable_d && done_row_a) counter_col_b <= done_col_b ? {NUM_COLS_B{1'b0}} : counter_col_b + 1'b1;
    end

    assign gated_num1 = enable ? mat_in1[counter_row_a][counter_col_a] : {DATA_WIDTH{1'b0}};
    assign gated_num2 = enable ? mat_in2[counter_col_a][counter_col_b] : {DATA_WIDTH{1'b0}};

    mult #(DATA_WIDTH, FIXED_PNT) mult_cell (
        .num1(gated_num1),
        .num2(gated_num2),
        .product(cell_mult_output),
        .overflow(),
        .underflow()
    );

    adder #(DATA_WIDTH, FIXED_PNT) adder_cell (
        .num1(cell_mult_output),
        .num2(mat_out[counter_row_a][counter_col_b]),
        .sum(cell_accum_output),
        .overflow(),
        .underflow()
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) mat_out <= '{default:1'b0};
        else if (enable_d) mat_out[counter_row_a][counter_col_b] <= cell_accum_output;
        else if (enable & ~enable_d) mat_out <= mat_in_accum;
    end

    assign data_ready = enable & done_col_b & done_row_a;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) enable_d <= 1'b0;
        else enable_d <= enable;
    end

endmodule