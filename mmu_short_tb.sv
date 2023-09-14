module mmu_short_tb;

logic clk;
logic rst_n;
logic enable;
logic enable_in;
assign #1 enable_in = enable;
logic signed [15:0] mat_in1 [2][2];
logic signed [15:0] mat_in1_in [2][2];
assign #1 mat_in1_in[0][0] = mat_in1[0][0];
assign #1 mat_in1_in[0][1] = mat_in1[0][1];
assign #1 mat_in1_in[1][0] = mat_in1[1][0];
assign #1 mat_in1_in[1][1] = mat_in1[1][1];
logic signed [15:0] mat_in2 [2][2];
logic signed [15:0] mat_in2_in [2][2];
assign #1 mat_in2_in[0][0] = mat_in2[0][0];
assign #1 mat_in2_in[0][1] = mat_in2[0][1];
assign #1 mat_in2_in[1][0] = mat_in2[1][0];
assign #1 mat_in2_in[1][1] = mat_in2[1][1];
logic signed [15:0] mat_in_accum [2][2];
logic signed [15:0] mat_out [2][2];
logic data_ready;

mmu_short #(
    .NUM_ROWS_A(2),
    .NUM_COLS_A(2),
    .NUM_COLS_B(2),
    .DATA_WIDTH(16),
    .FIXED_PNT(8))
i_mmu_short (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable_in),
    .mat_in1(mat_in1_in),
    .mat_in2(mat_in2_in),
    .mat_in_accum(mat_in_accum),
    .mat_out(mat_out),
    .data_ready(data_ready)
);

always begin
    #10 clk = ~clk;
end

initial begin
    clk = 0;
    rst_n = 1;
    enable = 0;
    mat_in1 = '{default:'0};
    mat_in2 = '{default:'0};
    mat_in_accum = '{default:'0};
    repeat(2) @(posedge clk);
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
    enable = 1;
    mat_in1[0][0] = 16'd1 << 8;
    mat_in1[0][1] = 16'd2 << 8;
    mat_in1[1][0] = 16'd3 << 8;
    mat_in1[1][1] = 16'd3 << 7;
    mat_in2[0][0] = 16'd4 << 8;
    mat_in2[0][1] = 16'd3 << 8;
    mat_in2[1][0] = 16'd2 << 8;
    mat_in2[1][1] = 16'd5 << 7;
    mat_in_accum[0][0] = 16'd1 << 8;
    mat_in_accum[0][1] = 16'd1 << 8;
    mat_in_accum[1][0] = 16'd1 << 8;
    mat_in_accum[1][1] = 16'd1 << 8;
    @(posedge data_ready);
    enable = 0;
    $display("mat_out[0][0] = %d", mat_out[0][0]);
    $display("mat_out[0][1] = %d", mat_out[0][1]);
    $display("mat_out[1][0] = %d", mat_out[1][0]);
    $display("mat_out[1][1] = %d", mat_out[1][1]);
    repeat(4) @(posedge clk);
    $stop;
end

endmodule