// module multiplierDivisionUnsigned #(
//     parameter int BIT_WIDTH = 16  // Q4.12 cho i_dataA, Q0.16 cho i_dataB và o_data
// ) (
//     input  logic                    i_valid,
//     input  logic signed [BIT_WIDTH-1:0]   i_dataA,  // Q4.12, signed
//     input  logic [BIT_WIDTH-1:0]   i_dataB,  // Q0.16, unsigned
//     output logic signed [BIT_WIDTH-1:0]   o_data,   // Q0.16, unsigned
//     output logic                   o_valid
// );

//     logic [2*BIT_WIDTH-1:0] prod;    // Q4.28, 32-bit unsigned
//     logic signed [BIT_WIDTH-1:0]   result;  // Q0.16 trước clip
//     logic [BIT_WIDTH-1:0]   i_dataA_unsigned;  // Q4.12, unsigned (sau kiểm tra)

//     always_comb begin : multip
    
//         // Kiểm tra i_dataA không âm
//         if (i_dataA < 0) begin
//             i_dataA_unsigned = 0;  // Nếu âm, đặt về 0 (vì e^x không âm)
//         end else begin
//             i_dataA_unsigned = i_dataA[BIT_WIDTH-1:0];  // Coi như unsigned
//         end

//         if (i_valid) begin
//             prod = i_dataA_unsigned * i_dataB;  // Q4.12 * Q0.16 = Q4.28, unsigned
//             result = prod[27:12] + (prod[11] ? 1 : 0);  // Q4.28 -> Q0.16, làm tròn
//             // Saturation cho Q0.16 (unsigned)
//             if (result > 16'hFFFF) begin
//                 o_data = 16'hFFFF;
//             end else begin
//                 o_data = result;
//             end
//             o_valid = i_valid;
// //         end else begin
// //             o_data = o_data;
// //             o_valid = o_valid;
//         end
//     end
// endmodule







module multiplierDivisionUnsigned #(
    parameter int BIT_WIDTH = 16  // Q4.12 cho i_dataA, Q0.16 cho i_dataB và o_data
) (
    input  logic                        i_valid,
    input  logic signed [BIT_WIDTH-1:0] i_dataA,  // Q4.12, signed
    input  logic        [BIT_WIDTH-1:0] i_dataB,  // Q0.16, unsigned
    output logic        [BIT_WIDTH-1:0] o_data,   // Q0.16, unsigned
    output logic                        o_valid
);

  (* use_dsp = "yes" *)    logic [2*BIT_WIDTH-1:0] prod;   // Q4.28, 32-bit unsigned
    logic [BIT_WIDTH-1:0]   result; // Q0.16

    always_comb begin
        // default
        o_data  = '0;
        o_valid = 1'b0;

        if (i_valid) begin
            // chặn giá trị âm
            logic [BIT_WIDTH-1:0] i_dataA_unsigned;
            if (i_dataA < 0) begin
                i_dataA_unsigned = '0;
            end
            else begin 
                i_dataA_unsigned = $unsigned(i_dataA);
            end

            // multiply
            prod   = i_dataA_unsigned * i_dataB;      // Q4.12 * Q0.16 = Q4.28
//            result = prod[27:12] + (prod[11] ? 1 : 0); // round
//result = prod[27:12] + 16'(prod[11] ? 1 : 0);
        result = $unsigned(prod[27:12]) + $unsigned(prod[11] ? 1 : 0);

            // saturation
            if (result > 16'hFFFF) begin 
                o_data = 16'hFFFF;
            end
            else begin
                o_data = result;
            end

            o_valid = i_valid;
        end
    end
endmodule
