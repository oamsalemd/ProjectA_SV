/*

Compile:
vcs +libext+.sv -sv -y .. ../relu.sv -debug_access+all -sverilog -timescale=1ns/1ps -kdb -lca

*/

module relu #(
    parameter VEC_SIZE = 1,
    parameter DATA_WIDTH = 16,
    parameter FIXED_PNT = 8)
(
    input signed [DATA_WIDTH-1:0] vec_in [VEC_SIZE],
    output logic signed [DATA_WIDTH-1:0] vec_out [VEC_SIZE]
    );

    generate for (genvar i = 0; i < VEC_SIZE; i++) begin : relu
        assign vec_out[i] = (vec_in[i] > 0) ? vec_in[i] : '{default:0};
        end
    endgenerate

endmodule