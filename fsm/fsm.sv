`timescale 1ns/1ns

// detects sequence 10101

module fsm(input a, clk, output reg out);
    //states
    reg[2:0] currState = 3'b000, prevState = 3'b000;
    parameter S0 = 3'b000, S1 = 3'b001, S2 = 3'b010, S3 = 3'b011, S4 = 3'b100, S5 = 3'b101;

    always@(posedge clk) begin
        
        case(currState)
            S0: if (a) currState = S1; else currState = S0;
            S1: if (a) currState = S1; else currState = S2;
            S2: if (a) currState = S3; else currState = S0;
            S3: if (a) currState = S1; else currState = S4;
            S4: if (a) currState = S5; else currState = S0;
            S5: if (a) currState = S1; else currState = S4;
            default: currState = S0;
        endcase

        if(prevState == S4 && currState == S5) begin
            out = 1;
        end
        else begin
            out = 0;
        end

        prevState <= currState;
    end

endmodule



module tb_fsm;
    //inputs
    reg a;
    reg clk = 0;

    //outputs
    wire out;

    //internal values
    reg expected_out = 0;
    int passed = 0;
    parameter num_tests = 30;
    parameter CLK_PERIOD = 5;
    reg [4:0] pastFive = 5'b0;

    //generate clk with 10ns period
    always #CLK_PERIOD clk = ~clk;

    // Instantiate DUT
    fsm dut(
        .a(a),
        .clk(clk),
        .out(out)
    );

    //testbench
    initial begin

        for(int i = 0; i < num_tests; i++) begin
            
            $display("Starting test %0d", i);
            
            for(int i = 0; i < 10; i++) begin
                a = $random % 2;
                #10;
                pastFive = {pastFive[3:0], a};
                if(pastFive == 5'b10101 && out != 1) begin
                    $display("Test %d failed", i);
                    continue;
                end
                if(pastFive != 5'b10101 && out == 1) begin
                    $display("Test %d failed", i);
                    continue;
                end
            end 

            
            passed++;
            $display("Finished test %0d, Cleaning output", i);       
            a = 0;
            #30;
        end

        $display("Passed %0d out of %0d tests", passed, num_tests);
    end
    
endmodule