import esdl;
import uvm;

import sha3_scoreboard: sha3_scoreboard;
import sha3_monitor: sha3_monitor;
import apb.apb_agent: apb_agent;
import apb.apb_sequencer: apb_sequencer;
import sha3_agent: sha3_agent;
import sha3_apb_sequencer: sha3_apb_sequencer;

class sha3_env(int DW, int AW): uvm_env
{
  mixin uvm_component_utils;
  @UVM_BUILD {
    apb_agent!(DW, AW) agent;
    sha3_agent phrase_agent;
    sha3_scoreboard!(DW, AW) scoreboard;
    sha3_monitor!(DW, AW) monitor;
  }

  override void build_phase(uvm_phase phase) {
    set_type_override_by_type(apb_sequencer!(DW, AW).get_type(),
                              sha3_apb_sequencer!(DW, AW).get_type());
  }

  this(string name , uvm_component parent) {
    super(name, parent);
  }

  override void connect_phase(uvm_phase phase) {
    super.connect_phase(phase);
    monitor.sha3_port.connect(scoreboard.sha3_analysis);
    agent.monitor.egress.connect(monitor.apb_analysis);
    auto sha3_squencer = cast (sha3_apb_sequencer!(DW, AW)) agent.sequencer;
    assert (sha3_squencer !is null);
    sha3_squencer.sha3_get_port.connect(phrase_agent.sequencer.seq_item_export);
  }
}
      
