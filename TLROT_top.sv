
// `include "/nfs/home/zhangdongrong/thinclient_drives/xs-env/XiangShan/src/
// main/resources/TLROT/lowrisc_dv_rot_top_verilator_sim_0.1.f"
import tlul_pkg::*;

module TLROT_top (
    input clk_i,
    input rst_ni,
    output logic ROMInitEn,
    input scan_mode,
    
    output         a_ready,
    input          a_valid,
    input  [2:0]   a_bits_opcode,
    input  [2:0]   a_bits_param,
    input  [1:0]   a_bits_size,
    input  [7:0]   a_bits_source,
    input  [31:0]  a_bits_address,
    input  [3:0]   a_bits_mask,
    input  [31:0]  a_bits_data,
    input         d_ready,
    output          d_valid,
    output [2:0]   d_bits_opcode,
    output [2:0]   d_bits_param,
    output [1:0]   d_bits_size,
    output [7:0]   d_bits_source,
    output         d_bits_sink,
    output [31:0]  d_bits_data,
    output         d_bits_denied,

    output logic [17:0] intr_rot_o
);

tlul_pkg::tl_h2d_t tl_i;
tlul_pkg::tl_h2d_t tl_i_user;
tlul_pkg::tl_d2h_t tl_o;

localparam bit EnableDataIntgGen = 1;

// tlul_pkg::tl_h2d_t64 rom_ctrl_rom_tl_req;
// tlul_pkg::tl_d2h_t64 rom_ctrl_rom_tl_rsp;

rom_ctrl_pkg::pwrmgr_data_t       rom_ctrl_pwrmgr_data;

logic clk_edn_i;
logic rst_edn_ni;
logic rst_shadowed_ni;

// entropy src
entropy_src_pkg::entropy_src_rng_req_t       es_rng_req_o;
entropy_src_pkg::entropy_src_rng_rsp_t       es_rng_rsp_i;
logic       es_rng_fips_o;

logic intr_hmac_hmac_done_o;
logic intr_hmac_fifo_empty_o;
logic intr_hmac_hmac_err_o;
logic intr_kmac_kmac_done_o;
logic intr_kmac_fifo_empty_o;
logic intr_kmac_kmac_err_o;
logic intr_keymgr_op_done_o;
logic intr_csrng_cs_cmd_req_done_o;
logic intr_csrng_cs_entropy_req_o;
logic intr_csrng_cs_hw_inst_exc_o;
logic intr_csrng_cs_fatal_err_o;
logic intr_entropy_src_es_entropy_valid_o;
logic intr_entropy_src_es_health_test_failed_o;
logic intr_entropy_src_es_observe_fifo_ready_o;
logic intr_entropy_src_es_fatal_err_o;
logic intr_edn0_edn_cmd_req_done_o;
logic intr_edn0_edn_fatal_err_o;
logic intr_otbn_done;

assign intr_rot_o = {
    intr_otbn_done,
    intr_edn0_edn_fatal_err_o,
    intr_edn0_edn_cmd_req_done_o,
    intr_entropy_src_es_fatal_err_o,
    intr_entropy_src_es_observe_fifo_ready_o,
    intr_entropy_src_es_health_test_failed_o,
    intr_entropy_src_es_entropy_valid_o,
    intr_csrng_cs_fatal_err_o,
    intr_csrng_cs_hw_inst_exc_o,
    intr_csrng_cs_entropy_req_o,
    intr_csrng_cs_cmd_req_done_o,
    intr_keymgr_op_done_o,
    intr_kmac_kmac_err_o,
    intr_kmac_fifo_empty_o,
    intr_kmac_kmac_done_o,
    intr_hmac_hmac_err_o,
    intr_hmac_fifo_empty_o,
    intr_hmac_hmac_done_o
};

assign tl_i.a_valid = a_valid;
assign tl_i.a_opcode = a_valid ? tl_a_op_e'(a_bits_opcode) : tl_a_op_e'(0);  
assign tl_i.a_param = a_valid ? a_bits_param : 0;
assign tl_i.a_size = a_valid ? a_bits_size : 0;
assign tl_i.a_source = a_valid ? a_bits_source : 0;
assign tl_i.a_address = a_valid ? a_bits_address : 0;
assign tl_i.a_mask = a_valid ? a_bits_mask : 0;
assign tl_i.a_data = a_valid ? a_bits_data : 0;

assign tl_i.a_user = a_valid ?  tlul_pkg::TL_A_USER_DEFAULT : 0;
// assign tl_o.d_user = tlul_pkg:TL_D_USER_DEFAULT;

tlul_cmd_intg_gen #(.EnableDataIntgGen (EnableDataIntgGen)) u_cmd_intg_gen (
    .tl_i(tl_i),
    .tl_o(tl_i_user)
  );

always_comb begin
  tl_i_user.a_user.instr_type = ((tl_i.a_opcode == PutFullData)
                        | (tl_i.a_opcode == PutPartialData) ) ? prim_mubi_pkg::MuBi4False : prim_mubi_pkg::MuBi4True;
end

assign a_ready = tl_o.a_ready;

assign d_valid = tl_o.d_valid;
assign d_bits_opcode = tl_o.d_opcode;
assign d_bits_param = tl_o.d_param;
assign d_bits_size = tl_o.d_size;  
assign d_bits_source = tl_o.d_source;
assign d_bits_sink  = tl_o.d_sink;
assign d_bits_data = tl_o.d_data;
assign d_bits_denied = tl_o.d_error;

assign tl_i.d_ready = d_ready;


assign ROMInitEn = (rom_ctrl_pwrmgr_data==8'h66)? 1'd1 : 1'd0;

//rst_ni reverse reset!
rot_top u_rot_top (
    .clk_i(clk_i),
    .rst_ni(~rst_ni),
    .rst_shadowed_ni(~rst_ni),
    .clk_edn_i(clk_i),
    .rst_edn_ni(~rst_ni),
    .scan_mode(scan_mode),

    .tl_i(tl_i_user),
    .tl_o(tl_o),

    .rom_ctrl_pwrmgr_data(rom_ctrl_pwrmgr_data),
    // .rom_ctrl_rom_tl_req(rom_ctrl_rom_tl_req),
    // .rom_ctrl_rom_tl_rsp(rom_ctrl_rom_tl_rsp),

    .es_rng_req_o(es_rng_req_o),
    .es_rng_rsp_i(es_rng_rsp_i),
    .es_rng_fips_o(es_rng_fips_o),

    .intr_hmac_hmac_done_o(intr_hmac_hmac_done_o),
    .intr_hmac_fifo_empty_o(intr_hmac_fifo_empty_o),  
    .intr_hmac_hmac_err_o(intr_hmac_hmac_err_o),
    .intr_kmac_kmac_done_o(intr_kmac_kmac_done_o),
    .intr_kmac_fifo_empty_o(intr_kmac_fifo_empty_o),
    .intr_kmac_kmac_err_o(intr_kmac_kmac_err_o),
    .intr_keymgr_op_done_o(intr_keymgr_op_done_o),
    .intr_csrng_cs_cmd_req_done_o(intr_csrng_cs_cmd_req_done_o),
    .intr_csrng_cs_entropy_req_o(intr_csrng_cs_entropy_req_o),  
    .intr_csrng_cs_hw_inst_exc_o(intr_csrng_cs_hw_inst_exc_o),
    .intr_csrng_cs_fatal_err_o(intr_csrng_cs_fatal_err_o),
    .intr_entropy_src_es_entropy_valid_o(intr_entropy_src_es_entropy_valid_o),
    .intr_entropy_src_es_health_test_failed_o(intr_entropy_src_es_health_test_failed_o),  
    .intr_entropy_src_es_observe_fifo_ready_o(intr_entropy_src_es_observe_fifo_ready_o),
    .intr_entropy_src_es_fatal_err_o(intr_entropy_src_es_fatal_err_o),
    .intr_edn0_edn_cmd_req_done_o(intr_edn0_edn_cmd_req_done_o),
    .intr_edn0_edn_fatal_err_o(intr_edn0_edn_fatal_err_o),
    .intr_otbn_done(intr_otbn_done)
);

localparam int unsigned EntropyStreams = 4;
rng #(
  .EntropyStreams ( EntropyStreams )
) u_rng (
  .clk_i ( clk_i ),
  .rst_ni ( ~rst_ni ),
  .clk_ast_rng_i ( clk_i ),
  .rst_ast_rng_ni (  ~rst_ni ),
  .rng_en_i ( es_rng_req_o.rng_enable ),
  .rng_fips_i ( es_rng_fips_o ),
  .scan_mode_i ( scan_mode ),
  .rng_b_o ( es_rng_rsp_i.rng_b  ),
  .rng_val_o ( es_rng_rsp_i.rng_valid )
);
    
endmodule