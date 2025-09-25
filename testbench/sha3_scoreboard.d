import esdl;
import uvm;

import sha3_seq_item: sha3_seq_item;

extern(C) void* sha3(const void* str, size_t strlen, void* md, int mdlen);

class sha3_scoreboard(int DW, int AW): uvm_scoreboard
{
  import std.format: format;
  
  mixin uvm_component_utils;

  sha3_seq_item write_seq;

  this(string name, uvm_component parent = null) {
    synchronized(this) {
      super(name, parent);
    }
  }

  uvm_phase run_ph;
  override void run_phase(uvm_phase phase) {
    run_ph = phase;
  }
  
  @UVM_BUILD {
    uvm_analysis_imp!(write) sha3_analysis;
  }
  
  ubyte[] expected;
  
  void write(sha3_seq_item item) {
    if (item.is_write) {       // req
      uvm_info("WRITE", item.sprint, UVM_DEBUG);
      write_seq = item;
      run_ph.raise_objection(this);
    }
    else {
      uvm_info("READ", item.sprint, UVM_DEBUG);
      expected.length = item.out_size/8;
      sha3(write_seq.phrase.ptr,
           cast(uint) write_seq.phrase.length, expected.ptr, cast(uint) expected.length);
      if (expected == item.phrase) {
        uvm_info("MATCHED", format("\n[%(%02X, %)]: expected \n[%(%02X, %)]: actual",
                                   expected, item.phrase), UVM_MEDIUM);
      }
      else {
        uvm_error("MISMATCHED", format("\n[%(%02X, %)]: expected \n[%(%02X, %)]: actual",
                                   expected, item.phrase));
      }
      run_ph.drop_objection(this);
    }
  }

}
