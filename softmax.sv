/*



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

    logic signed [DATA_WIDTH-1:0] vec_in_exp [VEC_SIZE];
    generate
        for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin: softmax
            assign vec_in_exp[i] = enable ? $exp(vec_in[i]) : 'h0;
        end
    endgenerate

    logic signed [DATA_WIDTH+$clog2(VEC_SIZE)-1:0] vec_in_exp_sum;
    generate
        logic [DATA_WIDTH-1:0] adders_chain_result [VEC_SIZE];

        assign adders_chain_result[0] = vec_in_exp[0];
        for (genvar t = 1; t < VEC_SIZE; t = t + 1) begin: vec_adders_chain
            adder #(DATA_WIDTH, FIXED_PNT) adder_inst (
                .num1(adders_chain_result[t-1]),
                .num2(vec_in_exp[t]),
                .sum(adders_chain_result[t]),
                .overflow(),
                .underflow()
            );
        end
        assign vec_in_exp_sum = adders_chain_result[VEC_SIZE-1];
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) begin
            for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin
                vec_out[i] <= 'h0;
            end
        end else if (enable) begin
            for (genvar i = 0; i < VEC_SIZE; i = i + 1) begin
                vec_out[i] <= enable ? vec_in_exp[i] / vec_in_exp_sum : 'h0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin: softmax
        if (!rst_n) enable_d <= 1'b0;
        else enable_d <= enable;
        end
    end

    assign data_valid = enable & ~enable_d;