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

module mul #(parameter N)(input [N-1:0]a, b, output logic [2*N-1:0] out);

    // partial products
    wire [2*N-1:0] pp[N+1];
    assign pp[0] = '0;

    // carry
    wire [2*N:0] carry[N+1];
    assign carry[0] = '0;

    // final row carry
    wire [2*N:N] carry_final;
    assign carry_final[N] = '0;

    // generate partial products
    genvar i,j;
    generate
        for(i=0; i < N; i++) begin: row
            for(j=0; j < i; j++) begin: pp_pass
                assign pp[i+1][j] = pp[i][j];
            end
            for(j=i; j < i+N; j++) begin: column
                fullAdder fa_mul(
                    .a(pp[i][j]),
                    .b(a[j-i] & b[i] | 0),
                    .cin(carry[i][j] | 0),
                    .sum(pp[i+1][j]),
                    .cout(carry[i+1][j+1])
                );
            end
            for(j=i+N; j < 2*N; j++) begin: pp_highbit_pass
                assign pp[i+1][j] = pp[i][j];
            end
        end
        for(i=N; i < 2*N; i++) begin: fast_adder
            fullAdder fastadder(
                .a(pp[N][i] |0),
                .b(carry[N][i] |0),
                .cin(carry_final[i] |0),
                .sum(out[i]),
                .cout(carry_final[i+1])
            );
        end
        
    endgenerate

    assign out[N-1:0] = pp[N][N-1:0];

endmodule


// Multiplier of IEEE-754 32-bit representation

module mul_fp(
    input [31:0] a, b,
    output logic [31:0] c,
    output logic [4:0] state // zero, nan, inf, overflow, underflow
);
    //FP32 -> 1 sign bit, 8 exponent bits, 23 fraction bits
    // sign bit -> 0 if positive, 1 if negative
    // exponent bits -> 8 bits, 2^(exp-127)
    // fraction bits -> 23 bits, 1+(fraction), 2^-1, 2^-2, 2^-3, ... 2^-23
    // if all fraction bits are 0, then the number is 0

    wire sign = a[31] ^ b[31];

    wire [7:0] exp = a[30:23] + b[30:23] - 127;

    logic [47:0] frac;

    //need to revise this part
    mul #(.N(24)) mulFrac(
        .a({1'b1,a[22:0]}), .b({1'b1,b[22:0]}),
        .out(frac)
    );

    //25 bits of multiplied mantissa -> first two bits are integer bits
    logic [24:0] newFrac;
    assign newFrac = frac[47:23];

    //if the first bit of newFrac is 1, then the number is greater than 1
    always_comb begin
        /*
        //zero
        if((exp == 0 && newFrac == 0) || a == 0 || b == 0) begin
            c = 32'b0;
            state = 5'b10000; //zero
        end
        //nan
        else if((exp == 8'b11111111 && newFrac != 0) || (a[30:23] == 8'b11111111 && a[22:0] != 23'b0) || (b[30:23] == 8'b11111111 && b[22:0] != 23'b0)) begin
            c = {1'b0,8'b11111111,23'b0};
            state = 5'b01000; //nan
        end
        //inf
        else if(exp == 8'b11111111 && newFrac == 0) begin
            c = {1'b0,8'b11111111,23'b0};
            state = 5'b00100; //inf
        end
        //underflow
        else if(exp < 8'b01111111) begin
            c = 32'b0;
            state = 5'b00010; //underflow
        end
        //overflow
        else if(exp > 8'b11111111) begin
            c = {sign,8'b11111111,23'b0};
            state = 5'b00001; //overflow
        end
        */
        // if rounded value > 1
        if(newFrac[24]) begin
            c = {sign | 1'b0, exp+1, newFrac[23:1]};
            state = 5'b00000; //normal
        end
        // if rounded value < 1
        else begin
            c = {sign | 1'b0, exp, newFrac[22:0]};
            state = 5'b00000; //normal
        end
    end

endmodule

module tb_mul_fp;
    
    //parameters
    parameter num_tests = 50;

    //inputs
    reg [31:0] a, b;

    //outputs
    wire [31:0] c;
    wire [4:0] state;

    //passed tests
    int passed = 0;
    int i = 0;
    shortreal expectedOut = 0;
    shortreal abs;
    shortreal absExpected;
    shortreal epsilon = 0.00001;

    // instantiate DUT
    mul_fp dut (
        .a(a),
        .b(b),
        .c(c),
        .state(state)
    );

    // testbench
    initial begin
        $display("Running mul_fp testbench");

        //run multiple tests
        repeat(num_tests) begin
            a = $random;
            b = $random;
            expectedOut = $bitstoshortreal(a)*$bitstoshortreal(b);
            $display("a = %g, b = %g", $bitstoshortreal(a), $bitstoshortreal(b));
            $display("Expected output = a*b = %g", expectedOut);
            #10;
            $display("Module output = %g", $bitstoshortreal(c));

            abs = ($bitstoshortreal(c) - expectedOut) > 0 ? ($bitstoshortreal(c) - expectedOut) : -(($bitstoshortreal(c) - expectedOut));
            absExpected = expectedOut > 0 ? expectedOut : -expectedOut;
            
            if(abs <= epsilon * absExpected) begin
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