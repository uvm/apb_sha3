import esdl;
import uvm;

import sha3_seq_item: sha3_seq_item;

class sha3_sequencer:  uvm_sequencer!sha3_seq_item
{
  mixin uvm_component_utils;

  this(string name, uvm_component parent=null) {
    super(name, parent);
  }
}

