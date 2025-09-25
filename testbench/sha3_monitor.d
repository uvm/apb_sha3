import esdl;
import uvm;

import std.format: format;
import sha3_seq_item: sha3_seq_item;
import sha3_seq_item: sha3_seq_item, output_size_enum;
import apb.apb_seq_item: apb_seq_item;

class sha3_monitor(int DW, int AW): uvm_monitor
{
  sha3_seq_item sha3_item;
  
  @UVM_BUILD {
    uvm_analysis_imp!(write) apb_analysis;
    uvm_analysis_port!sha3_seq_item sha3_port;
  }

  mixin uvm_component_utils;

  this(string name, uvm_component parent) {
    super(name,parent);
  }

  union {
    uint[50] word_block;
    ubyte[200] byte_block;
  }

  ubyte[] out_buffer;

  ubyte[] sha3_buffer;

  ubyte[] sha3_str;
  
  uint sha3_rate;               // The byte rate of the SHA3

  apb_seq_item!(DW, AW) last_data_item;

  enum sha3_state: byte {INIT_BLOCK, NEXT_BLOCK, OUT_BLOCK}

  sha3_state state;
  
  void process_transactions() {
    import std.stdio;
    uint out_size = sha3_rate * 8;
    uint blk_size = (1600 - 2*out_size)/8;
    if (out_size != output_size_enum.SHA3_224 &&
        out_size != output_size_enum.SHA3_256 &&
        out_size != output_size_enum.SHA3_384 &&
        out_size != output_size_enum.SHA3_512) {
      uvm_error("SHA3_ILLEGAL_SIZE",
                format("ILLEGAL output size %x",
                       out_size));
    }
    output_size_enum sha3_size = cast(output_size_enum) (out_size);

    for (size_t i=0; i != sha3_buffer.length/200; ++i) {
      sha3_str ~= sha3_buffer[i*200..i*200+blk_size];
      for (size_t j=i*200+blk_size; j!=(i+1)*200; ++j) {
        if (sha3_buffer[j] != 0) {
          uvm_error("SHA3_ILLEGAL_CAPACITY_BYTE",
                    format("ILLEGAL non-zero byte in capacity region %x at position %d",
                           sha3_buffer[j], j));
        }
      }
    }

    if (sha3_str[$-1] == 0x86) {
      sha3_str.length -= 1;
    }
    else if (sha3_str[$-1] == 0x80) {
      uint i = 2;
      while (sha3_str[$-i] == 0x00) i += 1;
      if (sha3_str[$-i] != 0x06) {
        uvm_error("SHA3_ILLEGAL_PAD_START",
                  format("ILLEGAL Pas Start %x",
                         sha3_str[$-i]));
      }
      sha3_str.length -= i;
    }
    else {
      uvm_error("SHA3_ILLEGAL_LAST_BYTE",
                format("ILLEGAL Last Byte in Input %x",
                       sha3_str[$-1]));
    }
    // send transactions to scoreboard
    sha3_seq_item sha3_in_trans =
      sha3_seq_item.type_id.create("SHA3 MONITORED INPUT");
    sha3_in_trans.phrase = sha3_str;
    sha3_in_trans.out_size = sha3_size;
    sha3_in_trans.is_write = true;
    sha3_port.write(sha3_in_trans);
    
    sha3_seq_item sha3_out_trans =
      sha3_seq_item.type_id.create("SHA3 MONITORED OUTPUT");
    sha3_out_trans.phrase = out_buffer;
    sha3_out_trans.out_size = sha3_size;
    sha3_out_trans.is_write = false;
    sha3_port.write(sha3_out_trans);
    
    sha3_str.length = 0;
    out_buffer.length = 0;
    sha3_buffer.length = 0;
  }

  void write(apb_seq_item!(DW, AW) item) {
    if (item.is_write is true) { // writes on registers
      if (state is sha3_state.OUT_BLOCK) { // we have just started writing next transaction
        state = sha3_state.INIT_BLOCK;
      }
      if (! (item.addr == 0x20 || (item.addr >= 0x200 && item.addr < 0x200 + 200))) {
        uvm_error("APB_ILLEGAL_ADDR",
                  format("ILLEGAL address (%x) for APB WRITE transaction",
                         item.addr));
      }

      if (item.addr >= 0x200) { // register data writes
        if (last_data_item is null) last_data_item = item;
        else if (item.data != 0 && item.addr >= last_data_item.addr) {
          last_data_item = item;
        }
        
        word_block[(item.addr - 0x200)/4] = item.data;
      }

      if (item.addr == 0x20) {  // for detecting init and next
        switch (item.data) {
        case 0x00000001:
          assert (state is sha3_state.INIT_BLOCK);
          state = sha3_state.NEXT_BLOCK;
          sha3_buffer ~= byte_block;
          break;
        case 0x00000002:
          sha3_buffer ~= byte_block;
          break;
        case 0x00000000:
          break;
        default:
          uvm_error("APB_ILLEGAL_DATA",
                    format("ILLEGAL data value (%x) observed on addr (%x)",
                           item.data, item.addr));
          break;
        }
      }
    }
    else {                      // READ in register
      if (last_data_item !is null) {
        // must have 0x80 or 0x86 at the MSB of the last_data_item's data field
        ubyte last_msb = cast(ubyte) last_data_item.data[24..32];
        if (last_msb != 0x80 && last_msb != 0x86)
          uvm_error("SHA3 DATA FRAME",
                    format("Expected last non-zero byte of the SHA3 frame to be either 0x80 or 0x86" ~
                           " got 0x%0x", last_msb));
        sha3_rate = ((0x200 + 200) - (last_data_item.addr + 4))/2;
        uvm_info("SHA3 RATE", format("Sha3 Rate is: %s", sha3_rate), UVM_DEBUG);
        last_data_item = null;
      }
      state = sha3_state.OUT_BLOCK;
      if (! (item.addr >= 0x300 && item.addr < 0x300 + 16*4)) {
        uvm_error("APB_ILLEGAL_ADDR",
                  format("ILLEGAL address (%x) for APB READ transaction",
                         item.addr));
      }
      auto addr_offset = item.addr - 0x300;

      if (addr_offset != out_buffer.length) {
        uvm_error("APB_ILLEGAL_ADDR",
                  format("Not in sequence address (%x) for APB READ transaction",
                         item.addr));
      }

      uint read_data = item.data;
      ubyte* read_ptr = cast (ubyte*) &read_data;
      for (size_t i=0; i!=4; ++i) {
        out_buffer ~= read_ptr[i];
      }
      if (out_buffer.length == sha3_rate) process_transactions();
      if (out_buffer.length > sha3_rate)
        uvm_error("APB_ILLEGAL_ADDR",
                  format("Read transaction has overshot the SHA3 Rate (%x) for APB READ transaction",
                         item.addr));
    }
  }
}

