/*

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

    logic enable_d, enable_dd, enable_ddd;

    // Combo for exp vec:
    logic signed [DATA_WIDTH-1:0] vec_in_exp [VEC_SIZE];
    generate
        for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin: softmax
            assign vec_in_exp[i] = enable ? $exp(vec_in[i]) : 'h0;
        end
    endgenerate

    // Synchronous for exp vec:
    logic signed [DATA_WIDTH-1:0] vec_in_exp_reg [VEC_SIZE];
    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) begin
            for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin
                vec_in_exp_reg[i] <= 'h0;
            end
        end else if (enable_d) begin
            for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin
                vec_in_exp_reg[i] <= vec_in_exp[i];
            end
        end
    end

    // Combo for adders:
    logic [DATA_WIDTH-1:0] adders_chain_result [VEC_SIZE];

    generate
        assign adders_chain_result[0] = vec_in_exp_reg[0];
        for (genvar t = 1; t < VEC_SIZE; t = t + 1) begin: vec_adders_chain
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
    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) vec_in_exp_sum <= 'h0;
        else if (enable_dd) vec_in_exp_sum <= adders_chain_result[VEC_SIZE-1];
    end

    // Combo for division:
    logic signed [DATA_WIDTH-1:0] vec_div [VEC_SIZE];
    generate
        for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin: softmax
            assign vec_div[i] = vec_in_exp_reg[i] / vec_in_exp_sum;
        end
    endgenerate

    // Synchronous for division:
    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) begin
            for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin
                vec_out[i] <= 'h0;
            end
        end else if (enable_ddd) begin
            for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin
                vec_out[i] <= vec_div[i];
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) enable_d <= 1'b0;
        else enable_d <= enable;
    end

    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) enable_dd <= 1'b0;
        else enable_dd <= enable_d;
    end

    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) enable_ddd <= 1'b0;
        else enable_ddd <= enable_dd;
    end

    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) data_valid <= 1'b0;
        else enable_dddd <= enable_ddd;
    end

    assign data_valid = enable_ddd & ~enable_dddd;