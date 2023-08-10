/*

Compile:
vcs +libext+.sv -sv -y .. ../mat_transpose.sv -debug_access+all -sverilog -timescale=1ns/1ps -kdb -lca

*/

module mat_transpose #(
    parameter NUM_ROWS = 64,
    parameter NUM_COLS = 96,
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8)
(
    input signed [DATA_WIDTH-1:0] mat_in [NUM_ROWS][NUM_COLS],
    output logic signed [DATA_WIDTH-1:0] mat_out [NUM_COLS][NUM_ROWS]
    );

    generate
        for (genvar i = 0; i < NUM_ROWS; i++) begin : ROWS
            for (genvar j = 0; j < NUM_COLS; j++) begin : COLS
                assign mat_out[j][i] = mat_in[i][j];
            end
        end
    endgenerate

endmodule