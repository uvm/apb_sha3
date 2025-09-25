import esdl;
import uvm;

import sha3_env: sha3_env;
import sha3_sequence: sha3_sequence;
import sha3_apb_sequence: sha3_apb_sequence;
import sha3_apb_sequencer: sha3_apb_sequencer;

class random_test_parameterized(int DW, int AW): uvm_test
{
  mixin uvm_component_utils;

  this(string name, uvm_component parent) {
    super(name, parent);
  }

  @UVM_BUILD {
    sha3_env!(DW, AW) env;
  }

  // override void build_phase(uvm_phase phase) {
  //   super.build_phase(phase);
  //   env = new sha3_env!(DW, AW)("env", this);
  // }

  override void run_phase(uvm_phase  phase) {
    sha3_sequence sha3_seq;
    sha3_apb_sequence!(DW, AW) wr_seq;
    phase.raise_objection(this, "apb_test");
    phase.get_objection.set_drain_time(this, 1.usec);
    sha3_seq = sha3_sequence.type_id.create("sha3_seq");
    for (size_t i=0; i != 100; ++i) {
      fork ({
          sha3_seq.sequencer = env.phrase_agent.sequencer;
          sha3_seq.randomize();
          sha3_seq.start(env.phrase_agent.sequencer);
        },
        {
          wr_seq = sha3_apb_sequence!(DW, AW).type_id.create("wr_seq");
          wr_seq.sequencer = cast (sha3_apb_sequencer!(DW, AW)) env.agent.sequencer;
          assert(wr_seq.sequencer !is null);
          // wr_seq.randomize();
          wr_seq.start(env.agent.sequencer);
        }).join();
    }
    phase.drop_objection(this, "apb_test");
  }
}


alias random_test = random_test_parameterized!(32, 10);
