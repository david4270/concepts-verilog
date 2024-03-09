`timescale 1ns/1ns

module fullAdder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);

    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule

module mul(input [7:0]a, b, output wire [15:0]out);
    //assign out = (16'b0) | (a * b);

    
    // partial products
    wire [15:0] pp[9];
    assign pp[0] = '0;

    // carry
    wire [16:0] carry[9];
    assign carry[0] = '0;

    // final row carry
    wire [16:8] carry_final;
    assign carry_final[8] = '0;

    // generate partial products
    genvar i,j;
    generate
        //for each row
        for(i = 0; i < 8; i++) begin: row
            // carry forward partial products
            for(j = 0; j < i; j++) begin: pp_pass
                assign pp[i+1][j] = pp[i][j];
            end
            // full adder -> input: sum of previous partial products + partial product + carry, output: new sum of partial product & carry
            for(j = i; j < i+8; j++) begin: column
                fullAdder fa_mul(
                    .a(pp[i][j]),
                    .b(a[j-i] & b[i] | 0),
                    .cin(carry[i][j] | 0),
                    .sum(pp[i+1][j]),
                    .cout(carry[i+1][j+1])
                );
            end
            // carry zeroes of partial products which are not calculated yet
            for(j = i+8; j < 16; j++) begin: pp_highbit_pass
                assign pp[i+1][j] = pp[i][j];
            end            
        end
        // add the fast adder in the last row
        for(i = 8; i < 16; i++) begin: fast_adder
            fullAdder fastadder(
                .a(pp[8][i]),
                .b(carry[8][i]),
                .cin(carry_final[i]),
                .sum(out[i]),
                .cout(carry_final[i+1])
            );
        end        

    endgenerate

    assign out[7:0] = pp[8][7:0];


endmodule

module mul_tb;

    //parameters
    parameter num_tests = 10;

    //inputs
    reg [7:0] a, b;

    //outputs
    wire [15:0] out;
    
    //passed tests
    int passed = 0;
    int i = 0;
    int expectedOut = 0;

    // instantiate DUT
    mul dut (
        .a(a),
        .b(b),
        .out(out)
    );

    // testbench
    initial begin
        $display("Running mul testbench");
        //run multiple tests
        repeat(num_tests) begin
            a = $random;
            b = $random;
            $display("a = %0d, b = %0d", a, b);
            #20;
            $display("Module output = %0d", out);
            expectedOut = a*b;
            $display("Expected output = a*b = %0d", expectedOut);
            if(out == a*b) begin
                $display("Test %0d passed", i);
                passed = passed + 1;
            end
            else begin
                $display("Test %0d failed", i);
            end
            i++;
        end
        $display("Passed %0d out of %0d tests", passed, num_tests);
        //$finish;
    end
endmodule