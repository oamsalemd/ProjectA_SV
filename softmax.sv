/*

Compile:
vcs +libext+.sv -sv -y .. ../softmax.sv -debug_access+all -sverilog -timescale=1ns/1ps -kdb -lca

1. Upon "enable" signal, calculate the softmax of the input vector.
2. "enable" must remain asserted until "data_ready" pulses.
3. First phase:
    -> Calculate the exponential of each element in the input vector.
    -> Calculate the sum of the exponential values.
   Second phase:
    -> Divide each exponential value by the sum.
4. Then, 4. Then, "data_ready" pulses when the output vector is ready.

*/

module softmax #(
    parameter VEC_SIZE = 107,
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8
    ) (
    input clk,
    input rst_n,
    input enable,
    input signed [DATA_WIDTH-1:0] vec_in [VEC_SIZE],
    output logic data_ready,
    output reg signed [DATA_WIDTH-1:0] vec_out [VEC_SIZE]
    );

    logic enable_d;

    // going through the input vector and calculating exp(vec_in[i]):
    logic [$clog2(VEC_SIZE):0] exp_idx;
    logic signed [DATA_WIDTH-1:0] exp_out;
    logic exp_enable;
    logic exp_data_ready;

    // diving each exp(vec_in[i]) by the sum:
    logic [$clog2(VEC_SIZE):0] div_idx;
    logic signed [DATA_WIDTH-1:0] div_result;
    logic div_data_ready;

    // summarizing the exp(vec_in[i]) values:
    logic signed [DATA_WIDTH-1:0] adder_result;
    logic signed [DATA_WIDTH-1:0] exp_sum;

    exp #(DATA_WIDTH, FIXED_PNT) exp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(exp_enable),
        .num(vec_in[exp_idx]),
        .exp_num(exp_out),
        .data_ready(exp_data_ready)
    );

    div #(DATA_WIDTH, FIXED_PNT) div_inst (
        .num1(vec_out[div_idx]),
        .num2(exp_sum),
        .result(div_result)
    );

    adder #(DATA_WIDTH, FIXED_PNT) adder_inst (
        .num1(exp_sum),
        .num2(exp_out),
        .sum(adder_result),
        .overflow(),
        .underflow()
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) exp_sum <= {DATA_WIDTH{1'b0}};
        else if (enable & exp_data_ready) exp_sum <= adder_result;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) vec_out <= '{default:0};
        // exp of vec_in per element:
        else if (enable & exp_data_ready) vec_out[exp_idx] <= exp_out;
        // division of final result:
        else if (enable & div_data_ready) vec_out[div_idx] <= div_result;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) exp_idx <= 1'b0;
        else if (enable & exp_data_ready & exp_idx < VEC_SIZE) exp_idx <= exp_idx + 1'b1;
        else if (enable_d & ~enable) exp_idx <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) exp_enable <= 1'b0;
        else if (enable & exp_data_ready) exp_enable <= 1'b0;
        else if (enable & exp_idx < VEC_SIZE) exp_enable <= 1'b1;
        else if (enable_d & ~enable) exp_enable <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) div_idx <= 0;
        else if (enable & div_data_ready & div_idx < VEC_SIZE & exp_idx == VEC_SIZE) div_idx <= div_idx + 1'b1;
        else if (enable_d & ~enable) div_idx <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) div_data_ready <= 1'b0;
        else if (enable & div_idx == VEC_SIZE & exp_idx == VEC_SIZE) div_data_ready <= 1'b0;
        else if (enable & div_idx < VEC_SIZE & exp_idx == VEC_SIZE) div_data_ready <= 1'b1;
        else if (enable_d & ~enable) div_data_ready <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) enable_d <= 1'b0;
        else enable_d <= enable;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) data_ready <= 1'b0;
        else if (enable & div_data_ready & div_idx == VEC_SIZE) data_ready <= 1'b1;
        else if (enable_d & ~enable) data_ready <= 1'b0;
    end

endmodule