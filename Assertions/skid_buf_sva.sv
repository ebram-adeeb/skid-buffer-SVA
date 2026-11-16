//note: needs to be updated later, don't rely on internal signals + coverage + ref model  
module skid_buf_sva #(
    parameter DATA_WIDTH = 32 
) (
    input logic clk,
    input logic rstn,
    input logic i_valid,
    input logic i_ready,
    input logic [DATA_WIDTH-1:0] i_data,
    input logic o_valid,
    input logic o_ready,
    input logic [DATA_WIDTH-1:0] o_data,
    input logic skid,
    input logic stall,
    input logic [DATA_WIDTH-1:0] skid_data,
    input logic load_out
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rstn);
    
    // -------------------------------------------------------------------------
    // 1. RESET CHECKS
    // -------------------------------------------------------------------------
    assert_async_reset: assert property (
        disable iff (rstn) // Overwrite default disable
        !rstn |-> (!o_valid && !skid)
    );

    // -------------------------------------------------------------------------
    // 2. CONTROL LOGIC VERIFICATION
    // -------------------------------------------------------------------------
    assert_ready_exact: assert property (
        i_ready == !skid
    );

    assert_stall_logic: assert property (
        stall == (i_valid && !o_ready && o_valid)
    );

    assert_load_out_logic: assert property (
        load_out == (o_ready || !o_valid)
    );

    assert_o_valid_update: assert property (
        load_out |=> o_valid == $past(skid || i_valid)
    );

    assert_skid_state_update: assert property (
        !i_ready && o_ready |=> !skid
    );

    // -------------------------------------------------------------------------
    // 3. COMPLETE DATA INTEGRITY & STABILITY
    // -------------------------------------------------------------------------
    assert_out_data_capture_direct: assert property (
        load_out && !skid |=> o_data == $past(i_data)
    );

    assert_out_data_capture_skid: assert property (
        load_out && !i_ready |=> o_data == $past(skid_data)
    );

    assert_skid_data_capture: assert property (
        stall && !skid |=> skid_data == $past(i_data)
    );

    assert_skid_data_stable: assert property (
        !i_ready && !o_ready |=> $stable(skid_data)
    );

    assert_out_data_stable: assert property (
        o_valid && !o_ready |=> o_valid && $stable(o_data)
    );

    // -------------------------------------------------------------------------
    // 4. LIVENESS & ENVIRONMENT ASSUMPTIONS
    // -------------------------------------------------------------------------
    // Upstream Protocol Compliance
    assume_in_stable: assume property (
        i_valid && !i_ready |=> i_valid && $stable(i_data)
    );

    // Downstream Progress Assumption
    assume_downstream_handshake: assume property (
        o_valid |-> s_eventually(o_ready)
    );

    // Forward Progress Verification
    assert_upstream_handshake: assert property (
        i_valid |-> s_eventually(i_ready)
    );

    assert_liveness: assert property (
        i_valid && i_ready |-> s_eventually(o_valid)
    );

endmodule

bind skid_buf skid_buf_sva #(.DATA_WIDTH(DATA_WIDTH)) bind_inst (.*);
