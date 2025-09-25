import esdl;
import uvm;

import apb.apb_sequencer: apb_sequencer;
import sha3_seq_item: sha3_seq_item;

class sha3_apb_sequencer(int DW, int AW):
  apb_sequencer!(DW, AW)
{
  mixin uvm_component_utils;

  @UVM_BUILD {
    uvm_seq_item_pull_port!sha3_seq_item sha3_get_port;
  }

  this(string name, uvm_component parent=null) {
    super(name, parent);
  }
}
