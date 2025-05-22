// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// HMAC Core implementation

module pcr_core import prim_sha2_pkg::*; (
  input clk_i,
  input rst_ni,

  input [1023:0]      secret_key_i, // {word0, word1, ..., word7}
  input               hmac_en_i,
  input digest_mode_e digest_size_i,
  input key_length_e  key_length_i,

  input        reg_hash_start_i,
  input        reg_hash_stop_i,
  input        reg_hash_continue_i,
  input        reg_hash_process_i,
  output logic hash_done_o,
  output logic sha_hash_start_o,
  output logic sha_hash_continue_o,
  output logic sha_hash_process_o,
  input        sha_hash_done_i,

  // fifo
  output logic        sha_rvalid_o,
  output sha_fifo32_t sha_rdata_o,
  input               sha_rready_i,

  input               fifo_rvalid_i,
  input  sha_fifo32_t fifo_rdata_i,
  output logic        fifo_rready_o,

  // fifo control (select and fifo write data)
  output logic       fifo_wsel_o,      // 0: from reg, 1: from digest
  output logic       fifo_wvalid_o,
  // 0: digest[0][upper], 1:digest[0][lower] .. 14: digest[7][upper], 15: digest[7][lower]
  output logic [3:0] fifo_wdata_sel_o,
  input              fifo_wready_i,

  input  [63:0] message_length_i,
  output [63:0] sha_message_length_o,

  output logic idle_o,

  // Add PCR-related ports here
  input        [4:0]      pcr_select_i,
  input                   pcr_extend_en_i,
  input                   pcr_event_en_i,
  input                   pcr_hash_done_i,
  input  logic [255:0]    digest_i,
  input                   pcr_read_en_i,
  output logic [255:0]    pcr_read_data_o,
  input                   pcr_reset_en_i,
  input  [7:0]            locality_i,       // Locality for access control
  output logic            pcr_updating_o

);

  localparam int NumPcr = 24;

  // PCR storage
  logic [NumPcr-1:0][255:0] pcr_storage;

  // PCR attributes structure
  typedef struct packed {
    logic       state_save;
    logic [4:0] reset_locality;
    logic [4:0] extend_locality;
  } pcr_attr_t;

  // Array of PCR attributes
  pcr_attr_t pcr_attributes [NumPcr];

  // PCR attributes initialization
  generate
    for (genvar i = 0; i < 16; i++) begin : gen_pcr_attributes
      assign pcr_attributes[i].state_save = 1'b1;
      assign pcr_attributes[i].reset_locality = 5'h0;
      assign pcr_attributes[i].extend_locality = 5'h1f;
    end
    // Special cases for PCRs 16-23
    assign pcr_attributes[16] = '{state_save: 1'b0, reset_locality: 5'h0f, extend_locality: 5'h1f};
    assign pcr_attributes[17] = '{state_save: 1'b0, reset_locality: 5'h10, extend_locality: 5'h1c};
    assign pcr_attributes[18] = '{state_save: 1'b0, reset_locality: 5'h10, extend_locality: 5'h1c};
    assign pcr_attributes[19] = '{state_save: 1'b0, reset_locality: 5'h10, extend_locality: 5'h0c};
    assign pcr_attributes[20] = '{state_save: 1'b0, reset_locality: 5'h14, extend_locality: 5'h0e};
    assign pcr_attributes[21] = '{state_save: 1'b0, reset_locality: 5'h14, extend_locality: 5'h04};
    assign pcr_attributes[22] = '{state_save: 1'b0, reset_locality: 5'h14, extend_locality: 5'h04};
    assign pcr_attributes[23] = '{state_save: 1'b0, reset_locality: 5'h0f, extend_locality: 5'h1f};
  endgenerate

  // Helper function to check reset locality
  function automatic logic check_reset_locality(logic [4:0] pcr_index, logic [7:0] locality);
    return |(pcr_attributes[pcr_index].reset_locality & locality[4:0]);
  endfunction

  // Helper function to check extend locality
  function automatic logic check_extend_locality(logic [4:0] pcr_index, logic [7:0] locality);
    return |(pcr_attributes[pcr_index].extend_locality & locality[4:0]);
  endfunction

  // Internal update counter
  logic [31:0] update_counter;

  logic start_transfer;
  logic trigger;
  logic trigger_d1;
  logic pcr_hash_done;
  logic [255:0] digest_storage; // Add storage for digest
  logic sha_hash_done;


  // 初始化 PCR 存储器为随机数
  initial begin
    for (int i = 0; i < NumPcr; i++) begin
      logic [255:0] random_value;
      for (int j = 0; j < 8; j++) begin
        random_value[31 + j * 32 -: 32] = $urandom();
      end
      pcr_storage[i] = random_value;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // Reset PCRs based on reset locality
      for (int i = 0; i < NumPcr; i++) begin
        if (check_reset_locality(i[4:0], locality_i)) begin
          pcr_storage[i] <= '0;
        end
      end
      update_counter <= '0;
      trigger_d1 <= '0;
      trigger <= '0;
      pcr_updating_o <= '0;

    end else if (pcr_reset_en_i) begin
      // PCR reset logic
      if (check_reset_locality(pcr_select_i[4:0], locality_i)) begin
        pcr_storage[pcr_select_i] <= '0;
        update_counter <= update_counter + 1;
      end
    end else if (pcr_extend_en_i) begin
      // PCR extend logic
      if (check_extend_locality(pcr_select_i[4:0], locality_i)) begin
        pcr_updating_o <= '1;
        trigger_d1 <= trigger;
        trigger <= '1;
        start_transfer <= trigger && !trigger_d1;
        pcr_hash_done <= pcr_hash_done_i;
        if (pcr_hash_done) begin
          // Update PCR with new hash value
          pcr_storage[pcr_select_i] <= digest_i;
          update_counter <= update_counter + 1;
          pcr_updating_o <= '0;
        end
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // Reset the digest storage
      digest_storage <= 256'b0;
      sha_hash_done <= 1'b0;
    end else if (sha_hash_done_i) begin // Check if SHA hash is done
      sha_hash_done <= sha_hash_done_i;
    end else if (sha_hash_done) begin
      digest_storage <= digest_i; // Store mid-digest
      $display("Digest Storage: %h", digest_storage);
      sha_hash_done <= 1'b0;
    end
  end

  // 计数器，用于追踪前8个32位字
  logic [3:0] word_counter;

  // 计数器逻辑
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      word_counter <= '0;
    end else if (fifo_rvalid_i && fifo_rready_o) begin
      // 如果是PCR扩展模式，同时打印PCR值
      if (pcr_extend_en_i) begin
        if (word_counter < 4'd8 || (pcr_event_en_i && word_counter > 4'd7)) begin
          word_counter <= word_counter + 1'b1;
          $display("word_counter: %0d, sha_rdata_reg: %h", "pcr_storage[%0d] = %h",word_counter, sha_rdata_reg,pcr_select_i, pcr_storage[pcr_select_i]);
        end
      end else begin
        word_counter <= '0;
      end
    end
  end

  // PCR read logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pcr_read_data_o <= '0;
    end else if (pcr_read_en_i) begin
      pcr_read_data_o <= pcr_storage[pcr_select_i];
    end
  end

  localparam int unsigned BlockSizeSHA256     = 512;
  localparam int unsigned BlockSizeSHA512     = 1024;

  localparam int unsigned BlockSizeBitsSHA256 = $clog2(BlockSizeSHA256);
  localparam int unsigned BlockSizeBitsSHA512 = $clog2(BlockSizeSHA512);

  localparam int unsigned HashWordBitsSHA256  = $clog2($bits(sha_word32_t));

  localparam bit [63:0] BlockSizeSHA256in64  = 64'(BlockSizeSHA256);
  localparam bit [63:0] BlockSizeSHA512in64  = 64'(BlockSizeSHA512);

  logic hash_start;    // generated from internal state machine
  logic hash_continue; // generated from internal state machine
  logic hash_process;  // generated from internal state machine to trigger hash
  logic hmac_hash_done;

  logic [BlockSizeSHA256-1:0] i_pad_256;
  logic [BlockSizeSHA512-1:0] i_pad_512;
  logic [BlockSizeSHA256-1:0] o_pad_256;
  logic [BlockSizeSHA512-1:0] o_pad_512;

  logic [63:0] txcount, txcount_d; // works for both digest lengths

  logic [BlockSizeBitsSHA512-HashWordBitsSHA256-1:0] pad_index_512;
  logic [BlockSizeBitsSHA256-HashWordBitsSHA256-1:0] pad_index_256;
  logic clr_txcount, load_txcount, inc_txcount;

  logic hmac_sha_rvalid;

  logic idle_d, idle_q;
  logic reg_hash_stop_d, reg_hash_stop_q;

  typedef enum logic [1:0] {
    SelIPad,
    SelOPad,
    SelFifo
  } sel_rdata_t;

  sel_rdata_t sel_rdata;

  typedef enum logic {
    SelIPadMsg,
    SelOPadMsg
  } sel_msglen_t;

  sel_msglen_t sel_msglen;

  typedef enum logic {
    Inner,  // Update when state goes to StIPad
    Outer   // Update when state enters StOPad
  } round_t ;

  logic update_round ;
  round_t round_q, round_d;

  typedef enum logic [2:0] {
    StIdle,
    StIPad,
    StMsg,              // Actual Msg, and Digest both
    StPushToMsgFifo,    // Digest --> Msg Fifo
    StWaitResp,         // Hash done( by checking processed_length? or hash_done)
    StOPad,
    StDone              // hmac_done
  } st_e ;

  st_e st_q, st_d;

  logic clr_fifo_wdata_sel;
  logic txcnt_eq_blksz;

  logic reg_hash_process_flag;

  assign sha_hash_start_o    = (hmac_en_i) ? hash_start    : reg_hash_start_i;
  assign sha_hash_continue_o = (hmac_en_i) ? hash_continue : reg_hash_continue_i;

  assign sha_hash_process_o  = (hmac_en_i) ? reg_hash_process_i | hash_process : reg_hash_process_i;
  assign hash_done_o         = (hmac_en_i) ? hmac_hash_done                    : sha_hash_done_i;

  assign pad_index_512 = txcount[BlockSizeBitsSHA512-1:HashWordBitsSHA256];
  assign pad_index_256 = txcount[BlockSizeBitsSHA256-1:HashWordBitsSHA256];

  // adjust inner and outer padding depending on key length and block size
  always_comb begin : adjust_key_pad_length
    // set defaults
    i_pad_256 = '{default: '0};
    i_pad_512 = '{default: '0};
    o_pad_256 = '{default: '0};
    o_pad_512 = '{default: '0};

    unique case (key_length_i)
      Key_128: begin
        i_pad_256 = {secret_key_i[1023:896],
                    {(BlockSizeSHA256-128){1'b0}}} ^ {(BlockSizeSHA256/8){8'h36}};
        i_pad_512 = {secret_key_i[1023:896],
                    {(BlockSizeSHA512-128){1'b0}}} ^ {(BlockSizeSHA512/8){8'h36}};
        o_pad_256 = {secret_key_i[1023:896],
                    {(BlockSizeSHA256-128){1'b0}}} ^ {(BlockSizeSHA256/8){8'h5c}};
        o_pad_512 = {secret_key_i[1023:896],
                    {(BlockSizeSHA512-128){1'b0}}} ^ {(BlockSizeSHA512/8){8'h5c}};
      end
      Key_256: begin
        i_pad_256 = {secret_key_i[1023:768],
                    {(BlockSizeSHA256-256){1'b0}}} ^ {(BlockSizeSHA256/8){8'h36}};
        i_pad_512 = {secret_key_i[1023:768],
                    {(BlockSizeSHA512-256){1'b0}}} ^ {(BlockSizeSHA512/8){8'h36}};
        o_pad_256 = {secret_key_i[1023:768],
                    {(BlockSizeSHA256-256){1'b0}}} ^ {(BlockSizeSHA256/8){8'h5c}};
        o_pad_512 = {secret_key_i[1023:768],
                    {(BlockSizeSHA512-256){1'b0}}} ^ {(BlockSizeSHA512/8){8'h5c}};
      end
      Key_384: begin
        i_pad_256 = {secret_key_i[1023:640],
                    {(BlockSizeSHA256-384){1'b0}}} ^ {(BlockSizeSHA256/8){8'h36}};
        i_pad_512 = {secret_key_i[1023:640],
                    {(BlockSizeSHA512-384){1'b0}}} ^ {(BlockSizeSHA512/8){8'h36}};
        o_pad_256 = {secret_key_i[1023:640],
                    {(BlockSizeSHA256-384){1'b0}}} ^ {(BlockSizeSHA256/8){8'h5c}};
        o_pad_512 = {secret_key_i[1023:640],
                    {(BlockSizeSHA512-384){1'b0}}} ^ {(BlockSizeSHA512/8){8'h5c}};
      end
      Key_512: begin
        i_pad_256 = secret_key_i[1023:512] ^ {(BlockSizeSHA256/8){8'h36}};
        i_pad_512 = {secret_key_i[1023:512],
                    {(BlockSizeSHA512-512){1'b0}}} ^ {(BlockSizeSHA512/8){8'h36}};
        o_pad_256 = secret_key_i[1023:512] ^ {(BlockSizeSHA256/8){8'h5c}};
        o_pad_512 = {secret_key_i[1023:512],
                    {(BlockSizeSHA512-512){1'b0}}} ^ {(BlockSizeSHA512/8){8'h5c}};
      end
      Key_1024: begin // not allowed to be configured for SHA-2 256
        // zero out for SHA-2 256
        i_pad_256 = '{default: '0};
        i_pad_512 = secret_key_i[1023:0]   ^ {(BlockSizeSHA512/8){8'h36}};
        // zero out for SHA-2 256
        o_pad_256 = '{default: '0};
        o_pad_512 = secret_key_i[1023:0]   ^ {(BlockSizeSHA512/8){8'h5c}};
      end
      default: begin
      end
    endcase
  end

  logic [31:0] sha_rdata_reg;
  logic pcr_data_valid;
  logic digest_data_valid;

  assign pcr_data_valid = pcr_extend_en_i &&
                         (word_counter < 4'd8) &&
                         fifo_rvalid_i;

  assign digest_data_valid = pcr_extend_en_i && pcr_event_en_i &&
                            (word_counter > 4'd7) && fifo_rvalid_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sha_rdata_reg <= '0;
    end else if (pcr_extend_en_i && (word_counter < 4'd8)) begin
      sha_rdata_reg <= pcr_storage[pcr_select_i][255-word_counter*32 -: 32];
    end else if (pcr_event_en_i && (word_counter > 4'd7)) begin
      sha_rdata_reg <= digest_storage[511-word_counter*32 -: 32];
    end
  end

  assign fifo_rready_o = (hmac_en_i) ? (st_q == StMsg) & sha_rready_i : sha_rready_i ;
  // sha_rvalid is controlled by State Machine below.
  assign sha_rvalid_o  = (!hmac_en_i) ? fifo_rvalid_i : hmac_sha_rvalid ;
  assign sha_rdata_o =
    (pcr_data_valid || digest_data_valid) ? '{data: sha_rdata_reg, mask: '1} :
    (!hmac_en_i)    ? fifo_rdata_i :
    (sel_rdata == SelIPad && digest_size_i == SHA2_256)
                  ? '{data: i_pad_256[(BlockSizeSHA256-1)-32*pad_index_256-:32], mask: '1} :
    (sel_rdata == SelIPad && ((digest_size_i == SHA2_384) || (digest_size_i == SHA2_512)))
                  ? '{data: i_pad_512[(BlockSizeSHA512-1)-32*pad_index_512-:32], mask: '1} :
    (sel_rdata == SelOPad && digest_size_i == SHA2_256)
                  ? '{data: o_pad_256[(BlockSizeSHA256-1)-32*pad_index_256-:32], mask: '1} :
    (sel_rdata == SelOPad && ((digest_size_i == SHA2_384) || (digest_size_i == SHA2_512)))
                  ? '{data: o_pad_512[(BlockSizeSHA512-1)-32*pad_index_512-:32], mask: '1} :
    (sel_rdata == SelFifo) ? fifo_rdata_i :
                  '{default: '0};

  logic [63:0] sha_msg_len;

  always_comb begin: assign_sha_message_length
    sha_msg_len = '0;
    if (!hmac_en_i) begin
      sha_msg_len = message_length_i;
    // HASH = (o_pad || HASH_INTERMEDIATE (i_pad || msg))
    // message length for HASH_INTERMEDIATE = block size (i_pad) + message length
    end else if (sel_msglen == SelIPadMsg) begin
      if (digest_size_i == SHA2_256) begin
        sha_msg_len = message_length_i + BlockSizeSHA256in64;
      end else if ((digest_size_i == SHA2_384) || (digest_size_i == SHA2_512)) begin
        sha_msg_len = message_length_i + BlockSizeSHA512in64;
      end
    end else if (sel_msglen == SelOPadMsg) begin
    // message length for HASH = block size (o_pad) + HASH_INTERMEDIATE digest length
      if (digest_size_i == SHA2_256) begin
        sha_msg_len = BlockSizeSHA256in64 + 64'd256;
      end else if (digest_size_i == SHA2_384) begin
        sha_msg_len = BlockSizeSHA512in64 + 64'd384;
      end else if (digest_size_i == SHA2_512) begin
        sha_msg_len = BlockSizeSHA512in64 + 64'd512;
      end
    end else
      sha_msg_len = '0;
  end

  assign sha_message_length_o = sha_msg_len;

  always_comb begin
    txcnt_eq_blksz = '0;

    unique case (digest_size_i)
      SHA2_256: txcnt_eq_blksz = (txcount[BlockSizeBitsSHA256-1:0] == '0) && (txcount != '0);
      SHA2_384: txcnt_eq_blksz = (txcount[BlockSizeBitsSHA512-1:0] == '0) && (txcount != '0);
      SHA2_512: txcnt_eq_blksz = (txcount[BlockSizeBitsSHA512-1:0] == '0) && (txcount != '0);
      default;
    endcase
  end

  assign inc_txcount = sha_rready_i && sha_rvalid_o;

  // txcount
  //    Looks like txcount can be removed entirely here in hmac_core
  //    In the first round (InnerPaddedKey), it can just watch process and hash_done
  //    In the second round, it only needs count 256 bits for hash digest to trigger
  //    hash_process to SHA2
  always_comb begin
    txcount_d = txcount;
    if (clr_txcount) begin
      txcount_d = '0;
    end else if (load_txcount) begin
      // When loading, add block size to the message length because the SW-visible message length
      // does not include the block containing the key xor'ed with the inner pad.
      unique case (digest_size_i)
        SHA2_256: txcount_d = message_length_i + BlockSizeSHA256in64;
        SHA2_384: txcount_d = message_length_i + BlockSizeSHA512in64;
        SHA2_512: txcount_d = message_length_i + BlockSizeSHA512in64;
        default : txcount_d = message_length_i + '0;
      endcase
    end else if (inc_txcount) begin
      txcount_d[63:5] = txcount[63:5] + 1'b1; // increment by 32 (data word size)
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) txcount <= '0;
    else         txcount <= txcount_d;
  end

  // reg_hash_process_i trigger logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      reg_hash_process_flag <= 1'b0;
    end else if (reg_hash_process_i) begin
      reg_hash_process_flag <= 1'b1;
    end else if (hmac_hash_done || reg_hash_start_i || reg_hash_continue_i) begin
      reg_hash_process_flag <= 1'b0;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      round_q <= Inner;
    end else if (update_round) begin
      round_q <= round_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      fifo_wdata_sel_o <= 3'h 0;
    end else if (clr_fifo_wdata_sel) begin
      fifo_wdata_sel_o <= 3'h 0;
    end else if (fifo_wsel_o && fifo_wvalid_o) begin
      fifo_wdata_sel_o <= fifo_wdata_sel_o + 1'b1; // increment by 1
    end
  end

  assign sel_msglen = (round_q == Inner) ? SelIPadMsg : SelOPadMsg ;

  always_ff @(posedge clk_i or negedge rst_ni) begin : state_ff
    if (!rst_ni) st_q <= StIdle;
    else         st_q <= st_d;
  end

  always_comb begin : next_state
    hmac_hash_done     = 1'b0;
    hmac_sha_rvalid    = 1'b0;
    clr_txcount        = 1'b0;
    load_txcount       = 1'b0;
    update_round       = 1'b0;
    round_d            = Inner;
    fifo_wsel_o        = 1'b0;   // from register
    fifo_wvalid_o      = 1'b0;
    clr_fifo_wdata_sel = 1'b1;
    sel_rdata          = SelFifo;
    hash_start         = 1'b0;
    hash_continue      = 1'b0;
    hash_process       = 1'b0;
    st_d               = st_q;

    unique case (st_q)
      StIdle: begin
        // reset round to Inner
        // we always switch context into inner round since outer round computes once over
        // single block at the end (outer key pad + inner hash)
        update_round = 1'b1;
        round_d      = Inner;
        if (hmac_en_i && reg_hash_start_i) begin
          st_d = StIPad; // start at StIPad if told to start

          clr_txcount  = 1'b1;
          hash_start   = 1'b1;
        end else if (hmac_en_i && reg_hash_continue_i) begin
          st_d = StMsg; // skip StIPad if told to continue - assumed it finished StIPad

          load_txcount  = 1'b1;
          hash_continue = 1'b1;
        end else begin
          st_d = StIdle;
        end
      end

      StIPad: begin
        sel_rdata = SelIPad;

        if (txcnt_eq_blksz) begin
          st_d = StMsg;

          hmac_sha_rvalid = 1'b0; // block new read request
        end else begin
          st_d = StIPad;

          hmac_sha_rvalid = 1'b1;
        end
      end

      StMsg: begin
        sel_rdata   = SelFifo;
        fifo_wsel_o = (round_q == Outer);

        if ( (((round_q == Inner) && reg_hash_process_flag) || (round_q == Outer))
            && (txcount >= sha_message_length_o)) begin
          st_d    = StWaitResp;

          hmac_sha_rvalid = 1'b0; // block reading words from MSG FIFO
          hash_process    = (round_q == Outer);
        end else if (txcnt_eq_blksz && (txcount >= sha_message_length_o)
                     && reg_hash_stop_q && (round_q == Inner)) begin
          // wait till all MSG words are pushed out from FIFO (txcount reaches msg length)
          // before transitioning to StWaitResp to wait on sha_hash_done_i and disabling
          // reading from MSG FIFO
          st_d =  StWaitResp;

          hmac_sha_rvalid = 1'b0;
        end else begin
          st_d            = StMsg;
          hmac_sha_rvalid = fifo_rvalid_i;
        end
      end

      StWaitResp: begin
        hmac_sha_rvalid = 1'b0;

        if (sha_hash_done_i) begin
          if (round_q == Outer) begin
            st_d = StDone;
          end else begin // round_q == Inner
            if (reg_hash_stop_q) begin
              st_d = StDone;
            end else begin
              st_d = StPushToMsgFifo;
            end
          end
        end else begin
          st_d = StWaitResp;
        end
      end

      StPushToMsgFifo: begin
        hmac_sha_rvalid    = 1'b0;
        fifo_wsel_o        = 1'b1;
        fifo_wvalid_o      = 1'b1;
        clr_fifo_wdata_sel = 1'b0;

        if (fifo_wready_i && (((fifo_wdata_sel_o == 4'd7) && (digest_size_i == SHA2_256)) ||
                             ((fifo_wdata_sel_o == 4'd15) && (digest_size_i == SHA2_512)) ||
                             ((fifo_wdata_sel_o == 4'd11) && (digest_size_i == SHA2_384)))) begin

          st_d = StOPad;

          clr_txcount  = 1'b1;
          update_round = 1'b1;
          round_d      = Outer;
          hash_start   = 1'b1;
        end else begin
          st_d = StPushToMsgFifo;

        end
      end

      StOPad: begin
        sel_rdata   = SelOPad;
        fifo_wsel_o = 1'b1; // Remained HMAC select to indicate HMAC is in second stage

        if (txcnt_eq_blksz) begin
          st_d = StMsg;

          hmac_sha_rvalid = 1'b0; // block new read request
        end else begin
          st_d = StOPad;

          hmac_sha_rvalid = 1'b1;
        end
      end

      StDone: begin
        // raise interrupt (hash_done)
        st_d = StIdle;

        hmac_hash_done = 1'b1;
      end

      default: begin
        st_d = StIdle;
      end

    endcase
  end

  // raise reg_hash_stop_d flag at reg_hash_stop_i and keep it until sha_hash_done_i is asserted
  // to indicate the hashing operation on current block has completed
  assign reg_hash_stop_d = (reg_hash_stop_i == 1'b1)                            ? 1'b1 :
                           (sha_hash_done_i == 1'b1 && reg_hash_stop_q == 1'b1) ? 1'b0 :
                                                                                  reg_hash_stop_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      reg_hash_stop_q <= 1'b0;
    end else begin
      reg_hash_stop_q <= reg_hash_stop_d;
    end
  end

  // Idle status signaling: This module ..
  assign idle_d =
      // .. is not idle when told to start or continue
      (reg_hash_start_i || reg_hash_continue_i) ? 1'b0 :
      // .. is idle when the FSM is in the Idle state
      (st_q == StIdle) ? 1'b1 :
      // .. is idle when it has processed a complete block of a message and is told to stop in any
      // FSM state
      (txcnt_eq_blksz && reg_hash_stop_d) ? 1'b1 :
      // .. and keeps the current idle state in all other cases.
      idle_q;

  assign idle_o = idle_d;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      idle_q <= 1'b1;
    end else begin
      idle_q <= idle_d;
    end
  end
endmodule
