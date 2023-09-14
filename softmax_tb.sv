module softmax_tb;

logic clk;
logic rst_in;
logic enable;
logic enable_in;
assign #1 enable_in = enable;
logic signed [15:0] vec_in [3];
logic signed [15:0] vec_in_in [3];
assign #1 vec_in_in = vec_in;
logic data_ready;
logic signed [15:0] vec_out [3];

softmax #(
    VEC_SIZE = 3,
    DATA_WIDTH = 16,
    FIXED_PNT = 8)
i_softmax (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable_in),
    .vec_in(vec_in_in),
    .data_ready(data_ready),
    .vec_out(vec_out))

always begin
    #10 clk = ~clk;
end

initial begin
    clk = 0;
    rst_n = 1;
    enable = 0;
    num = 0;
    repeat(2) @(posedge clk);
    rst_n = 0;
    repeat(4) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
    enable = 1;
    vec_in[0] = 16'b0000010000000000;
    vec_in[1] = 16'b0000011000000000;
    vec_in[2] = 16'b0000010100000000;
    @(posedge data_ready);
    enable = 0;
    $display("vec_out[0] = %d", vec_out[0]);
    $display("vec_out[1] = %d", vec_out[1]);
    $display("vec_out[2] = %d", vec_out[2]);
    @(posedge clk);
    $stop;
end

endmodule