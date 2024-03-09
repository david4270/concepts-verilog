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

module alu(
    input [7:0] a,b, //input operands
    input [2:0] alu_op, //operation to be performed
    output reg [15:0] result, //result of the operation
    output reg zero //zero flag
    );

    wire addout;

    adder add8(
        .a(a),
        .b(b),
        .cin(1'b0),
        .sum(result[7:0]),
        .cout(result[8])
    );

    always_comb begin
        case(alu_op)
            3'b000: result = {7'b0, result[8:0]}; //add
            3'b001: result = (16'b0) | (a - b); //sub
            3'b010: result = (16'b0) | (a * b); //mul
            3'b011: result = (16'b0) | (a / b); //div
            3'b100: result = (16'b0) | (a & b); //and
            3'b101: result = (16'b0) | (a | b); //or
            3'b110: result = (16'b0) | (a ^ b); //xor
            3'b111: result = (16'b0) | (a); //pass through  
        endcase
    end

    always@(posedge result) begin
        if(result == 0) begin
            zero = 1;
        end
        else begin
            zero = 0;
        end
    end

endmodule

module alu_tb;
    // Parameters
    parameter num_tests = 50;

    //inputs
    reg [7:0] a, b;
    reg [2:0] alu_op;

    //outputs
    wire [15:0] result;
    wire zero;

    //internal wires
    reg [15:0] expected_result = 16'b0;
    int passed = 0;

    // Instantiate DUT
    alu dut(
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );

    //testbench
    initial begin
        $display("Starting ALU testbench");
        
        //run tests
        for(int i = 0; i < num_tests; i = i + 1) begin
            //generate random inputs
            a = $random;
            b = $random;
            alu_op = $random;
            
            //delay
            #10;

            //print inputs
            $display("Test %d: a = %d, b = %d, alu_op = %d", i, a, b, alu_op);

            //print results
            $display("Result = %d, Zero Flag = %d", result, zero);

            //perform operation based on opcode
            case(alu_op)
                3'b000: begin
                    $display("Expected result = %d + %d = %d", a, b, a + b);
                    expected_result = a + b;
                end
                3'b001: begin
                    $display("Expected result = %d - %d = %d", a, b, a - b);
                    expected_result = a - b;
                end
                3'b010: begin
                    $display("Expected result = %d * %d = %d", a, b, a * b);
                    expected_result = a * b;
                end
                3'b011: begin
                    $display("Expected result = %d / %d = %d", a, b, a / b);
                    expected_result = a / b;
                end
                3'b100: begin
                    $display("Expected result = %d & %d = %d", a, b, a & b);
                    expected_result = a & b;
                end
                3'b101: begin
                    $display("Expected result = %d | %d = %d", a, b, a | b);
                    expected_result = a | b;
                end
                3'b110: begin
                    $display("Expected result = %d ^ %d = %d", a, b, a ^ b);
                    expected_result = a ^ b;
                end
                3'b111: begin
                    $display("Expected result = %d", a);
                    expected_result = a;
                end
                default: begin
                    $display("Invalid opcode");
                    expected_result = 16'b0;
                end

                
            endcase

            //check if result is as expected
            if(result == expected_result & zero == 16'b0) begin
                $display("Test %d passed", i);
                passed++;
            end
            else begin
                $display("Test %d failed", i);
            end
        end

        //end testbench
        $display("ALU testbench finished, passed %d out of %d tests", passed, num_tests);
        //$finish;
    end


endmodule