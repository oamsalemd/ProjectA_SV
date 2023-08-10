/*

Compile:
vcs +libext+.sv -sv -y .. ../softmax.sv -debug_access+all -sverilog -timescale=1ns/1ps -kdb -lca

1. Upon "enable" signal, calculate the softmax of the input vector.
2. "enable" must remain asserted until "data_ready" pulses.
3. First cycle:
    -> Calculate the exponential of each element in the input vector.
   Second cycle:
    -> Calculate the sum of the exponential values.
        // TODO: Break down the sum into sub-chains.
   Third cycle:
    -> Divide each exponential value by the sum.
4. Then, 4. Then, "data_ready" pulses when the output vector is ready.

*/

module softmax #(
    parameter VEC_SIZE = 1,
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8
    ) (
    input clk,
    input rst_n,
    input enable,
    input signed [DATA_WIDTH-1:0] vec_in [VEC_SIZE],
    output logic data_valid,
    output logic signed [DATA_WIDTH-1:0] vec_out [VEC_SIZE]
    );

    logic enable_d, enable_dd, enable_ddd, enable_dddd;

    // Combo for exp vec:
    logic signed [DATA_WIDTH-1:0] vec_in_exp [VEC_SIZE];
    generate
        for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin: softmax_comb_exp
            assign vec_in_exp[i] = enable ? $exp(vec_in[i]) : '{default:0};
        end
    endgenerate

    // Synchronous for exp vec:
    logic signed [DATA_WIDTH-1:0] vec_in_exp_reg [VEC_SIZE];
    generate
        for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin: softmax_sync_exp
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) vec_in_exp_reg[i] <= '{default:0};
                else if (enable_d) vec_in_exp_reg[i] <= vec_in_exp[i];
            end
        end
    endgenerate


    // Combo for adders:
    logic [DATA_WIDTH-1:0] adders_chain_result [VEC_SIZE];

    generate
        assign adders_chain_result[0] = vec_in_exp_reg[0];
        for (genvar t = 1; t < VEC_SIZE; t = t + 1) begin: softmax_comb_adders
            adder #(DATA_WIDTH, FIXED_PNT) adder_inst (
                .num1(adders_chain_result[t-1]),
                .num2(vec_in_exp_reg[t]),
                .sum(adders_chain_result[t]),
                .overflow(),
                .underflow()
            );
        end
    endgenerate

    // Synchronous for adders:
    logic signed [DATA_WIDTH+$clog2(VEC_SIZE)-1:0] vec_in_exp_sum;
    always_ff @(posedge clk or negedge rst_n) begin: softmax_sync_adders
        if (!rst_n) vec_in_exp_sum <= '{default:0};
        else if (enable_dd) vec_in_exp_sum <= adders_chain_result[VEC_SIZE-1];
    end

    // Combo for division:
    logic signed [DATA_WIDTH-1:0] vec_div [VEC_SIZE];
    generate
        for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin: softmax_comb_div
            div #(DATA_WIDTH, FIXED_PNT) div_inst (
                .num1(vec_in_exp_reg[i]),
                .num2(vec_in_exp_sum),
                .result(vec_div[i])
            );
        end
    endgenerate

    // Synchronous for division:
    generate
        for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin: softmax_sync_div
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) vec_out[i] <= '{default:0};
                else if (enable_ddd) vec_out[i] <= vec_div[i];
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) enable_d <= 1'b0;
        else enable_d <= enable;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) enable_dd <= 1'b0;
        else enable_dd <= enable_d;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) enable_ddd <= 1'b0;
        else enable_ddd <= enable_dd;
    end

    assign data_valid = enable_ddd & ~enable_dddd;

endmodule