/*

1. Upon "enable" signal, the module begins to calculate the Taylor series.
-> The module detects which bin the input number is in.
-> The module calculates the base of the bin (exp^(bin.start)).
-> The module calculates the Taylor series for the input number (num - bin.start).
-> The module accumulates and divides each element of the Taylor series by the factorial of the element's order.

2. The module multiplies the intermediate result by the base of the bin.

3. The module outputs the result and pulses "data_ready".
-> It is then expected that "enable" will be de-asserted.

*/

module exp #(
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8)
(
    input clk,
    input rst_n,
    input enable,
    input signed [DATA_WIDTH-1:0] num,
    output reg signed [DATA_WIDTH-1:0] exp_num,
    output reg data_ready
);

    /* Constants */
    localparam NUM_OF_BINS = 7;
    logic signed [DATA_WIDTH-1:0] BIN_START [NUM_OF_BINS];
    logic signed [DATA_WIDTH-1:0] BIN_START_EXP [NUM_OF_BINS];
    localparam TAYLOR_ORDER = 15;
    logic [DATA_WIDTH-1:0] FACT_ARR [TAYLOR_ORDER];

    generate
        for (genvar i = 0; i < TAYLOR_ORDER; i++) begin: FACT_ARR_gen
            logic [$clog2(TAYLOR_ORDER):0] j;
            logic [DATA_WIDTH-1:0] fact;

            assign j = (i == 0) ? 1 : FACT_ARR[i-1];
            assign FACT_ARR[i] = (i == 0) ? 1 : j * i;
        end
    endgenerate

    // vector of bin[i].start:
    generate
        for (genvar i = 0; i < NUM_OF_BINS; i++) begin
            if (i < NUM_OF_BINS / 2) // negative bins
                assign BIN_START[i] = -((2 ** (DATA_WIDTH-FIXED_PNT-1)) * i) / NUM_OF_BINS;
            else // positive bins
                assign BIN_START[i] = ((2 ** (DATA_WIDTH-FIXED_PNT-1)) * i) / NUM_OF_BINS;
        end
    endgenerate

    // vector of exp^(bin[i].start):
    // TODO: check that line in TB!
    generate
        for (genvar i = 0; i < NUM_OF_BINS; i++) begin
            assign BIN_START_EXP[i] = $exp(BIN_START[i]);
        end
    endgenerate

    /* Signals */
    logic [$clog2(NUM_OF_BINS):0] bin_sel;
    logic vec_ones_bin_sel [NUM_OF_BINS];

    logic [DATA_WIDTH-1:0] base_bin_start_exp;

    logic [$clog2(TAYLOR_ORDER):0] taylor_counter;
    logic taylor_counter_done;

    logic [DATA_WIDTH-1:0] mult_result;
    logic [DATA_WIDTH-1:0] mult_result_reg;

    logic [DATA_WIDTH-1:0] adder_result;
    logic [DATA_WIDTH-1:0] adder_bin_result;

    logic [DATA_WIDTH-1:0] div_result;

    logic enable_d;

    initial $display ("BIN_START[1] is %d", BIN_START[1]);

    /* Code */
    generate
        for (genvar i = 0; i < NUM_OF_BINS - 1; i = i + 1) begin: bin_select_gen
            assign vec_ones_bin_sel[i] = enable ? ((num >= BIN_START[i]) && (num < BIN_START[i+1])) : 1'b0;
        end
    endgenerate

    always_comb begin
        bin_sel = '0;
        for (int i = 0; i < NUM_OF_BINS; i++)
            if (vec_ones_bin_sel[i])
                bin_sel = i;
    end

    // detect which bin is the input number in:
    assign base_bin_start_exp = BIN_START_EXP[bin_sel];


    logic [DATA_WIDTH-1:0] num1;
    logic [DATA_WIDTH-1:0] num2;
    assign num1 = taylor_counter_done ? base_bin_start_exp : num - BIN_START[bin_sel];
    assign num2 = taylor_counter_done ? exp_num : mult_result_reg;

    // mult instance:
    mult #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIXED_PNT(FIXED_PNT))
    mult_inst (
        .num1(num1),
        .num2(num2),
        .product(mult_result),
        .overflow(),
        .underflow()
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) mult_result_reg <= {{DATA_WIDTH-FIXED_PNT-1{1'b0}},1'b1,{FIXED_PNT{1'b0}}};
        else if (enable & ~enable_d) mult_result_reg <= num - BIN_START[bin_sel];
        else if (enable && ~taylor_counter_done) mult_result_reg <= mult_result;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) taylor_counter <= '0;
        else if (taylor_counter_done) taylor_counter <= '0;
        else if (enable) taylor_counter <= taylor_counter + 1'b1;
    end

    div #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIXED_PNT(FIXED_PNT))
    div_inst (
        .num1(mult_result_reg),
        .num2(FACT_ARR[taylor_counter] << FIXED_PNT),
        .result(div_result)
    );

    adder #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIXED_PNT(FIXED_PNT))
    adder_inst (
        .num1(div_result),
        .num2(exp_num),
        .sum(adder_result),
        .overflow(),
        .underflow()
    );

    adder #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIXED_PNT(FIXED_PNT))
    adder_bin_inst (
        .num1((1'b1 << FIXED_PNT) - BIN_START[bin_sel]),
        .num2(num),
        .sum(adder_bin_result),
        .overflow(),
        .underflow()
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) exp_num <= '0;
        else if (enable & ~enable_d) exp_num <= adder_bin_result;
        else if (enable_d && ~taylor_counter_done) exp_num <= adder_result;

        // last cycle is to multiply result in base_bin_start_exp:
        else if (enable && taylor_counter_done) exp_num <= mult_result;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) enable_d <= '0;
        else if (enable) enable_d <= enable;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) taylor_counter_done <= 1'b0;
        else if (enable & ~enable_d) taylor_counter_done <= 1'b0;
        else if (taylor_counter == TAYLOR_ORDER) taylor_counter_done <= 1'b1;
        else if (enable_d & ~enable) taylor_counter_done <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) data_ready <= 1'b0;
        else if (enable && taylor_counter_done) data_ready <= 1'b1;
    end

endmodule