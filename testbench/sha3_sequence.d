import esdl;
import uvm;

import sha3_seq_item: sha3_seq_item;
import sha3_sequencer: sha3_sequencer;
import sha3_seq_item: sha3_seq_item, output_size_enum;

class sha3_sequence: uvm_sequence!sha3_seq_item
{
  mixin uvm_object_utils;
  sha3_sequencer sequencer;
  output_size_enum out_size;
  string phrase;

  void set_phrase(string ph) {
    phrase = ph;
  }

  void set_outputsize(output_size_enum os) {
    out_size = os;
  }
  
  this(string name = "sha3_sequence") {
    super(name);
    req = REQ.type_id.create("req");
  }

  override void body() {
    for (size_t i=0; i!=1; ++i) {
      req.randomize();
      uvm_info("PRINTREQUEST", ":\n" ~ req.sprint(), UVM_DEBUG);
      req.is_write = true;
      REQ tr = cast(REQ) req.clone;
      start_item(tr);
      finish_item(tr);
    }
  }
}

