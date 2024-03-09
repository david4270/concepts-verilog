`timescale 1ns/1ns

module fullAdder(input a,b,cin, output sum, cout);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

module adder (input [7:0] a, b,
    input cin,
    output wire [7:0] sum,
    output cout
    );
    //assign {cout, sum} = a + b + cin;

    //instantiate 8 full adders

    wire [7:0] carry;

    //https://circuitcove.com/design-examples-adders/
    fullAdder fa[7:0] (
        .a(a),
        .b(b),
        .cin({carry[6:0],cin}),
        .sum(sum),
        .cout(carry)
    );

    assign cout = carry[7];

endmodule

module adder_tb;

    //parameters
    parameter num_tests = 10;

    //inputs
    reg [7:0] a, b;
    reg cin;

    //outputs
    wire [7:0] sum;
    wire cout;
    
    //passed tests
    int passed = 0;

    // instantiate DUT
    adder dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    // testbench
    initial begin
        $display("Running adder testbench");
        //run multiple tests
        for(int i=0; i < num_tests; i++) begin
            //generate random inputs
            a = $random;
            b = $random;
            cin = $random;
            
            // delay to let signals propagate
            #5;
            
            // display input values
            $display("Test %0d: a=%0d, b=%0d, cin=%0d", i, a, b, cin);

            // display expected result
            $display("Expected: sum=%0d, cout=%0d", a+b+cin, (a+b+cin)>255);

            //display actual result
            $display("Actual: sum=%0d, cout=%0d", sum, cout);

            //compare results
            if(sum != a+b+cin || cout != (a+b+cin)>255) begin
                $error("Test %0d failed", i);
            end
            else begin
                $display("Test %0d passed", i);
                passed++;
            end
        end

        //Display completion message
        $display("adder testbench finished, %0d/%0d tests passed", passed, num_tests);

        //stop simulation
        //$finish;

    end

endmodule
