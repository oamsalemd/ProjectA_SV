module exp_tb;

logic clk;
logic rst_in;
logic enable;
logic enable_in;
assign #1 enable_in = enable;
logic signed [15:0] num;
logic signed [15:0] num_in;
assign #1 num_in = num;
logic signed [15:0] exp_num;
logic data_ready;

exp #(
    .DATA_WIDTH(16),
    .FIXED_PNT(8))
i_exp (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable_in),
    .num(num_in),
    .exp_num(exp_num),
    .data_ready(data_ready)
    );


always #10 clk = ~clk;

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
    num = 16'b0000010000000000; // num = 4.0
    enable = 1;
    @(posedge data_ready);
    enable = 0;
    $display("exp(4.0) = %f", exp_num);
    @(posedge clk);
    $stop;
end

endmodule