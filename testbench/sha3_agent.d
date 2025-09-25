import esdl;
import uvm;
import sha3_sequencer: sha3_sequencer;

class sha3_agent: uvm_agent
{
  mixin uvm_component_utils;

  @UVM_BUILD sha3_sequencer  sequencer;

  this(string name, uvm_component parent) {
    super(name, parent);
  }
}


