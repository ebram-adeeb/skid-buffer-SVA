module skid_buf #(
    parameter WIDTH = 32 
) (
    input  logic clk,
    input  logic rstn,
    //upstream 
    input  logic                  i_valid,
    output logic                  i_ready,
    input  logic [WIDTH-1:0] i_data,
    //downstream
    output logic                  o_valid,
    input  logic                  o_ready,
    output logic [WIDTH-1:0] o_data
);
    logic stall,skid,load_out;
    logic valid_q,ready_q;
    logic [WIDTH-1:0] skid_data,data_q;

    //internal control signals
    assign stall     = i_valid && !o_ready && o_valid; 
    assign skid      = !i_ready;
    assign load_out  = o_ready || !o_valid; 
    always_ff @(posedge clk or negedge rstn) begin : skid_part
        if(!rstn) begin
            ready_q      <= 1'b1;
            skid_data    <= '0; //could be removed later for efficient PPA
        end else begin
            if (!skid && stall) begin
                ready_q   <= 1'b0;
                skid_data <= i_data;
            end else if (skid && o_ready) begin
                ready_q <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk or negedge rstn) begin : out_rgs
        if(!rstn) begin
            valid_q <= 1'b0;
            data_q  <= '0; //could be removed later for efficient PPA
        end else if(load_out) begin
            valid_q <= skid || i_valid;
            data_q  <= (skid)? skid_data:i_data;
        end
    end

    assign i_ready = ready_q;
    assign o_valid = valid_q;
    assign o_data  = data_q;
endmodule
