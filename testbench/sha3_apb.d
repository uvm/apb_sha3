import esdl;
import uvm;
import std.stdio;
import std.string: format;

import apb.apb_intf: apb_intf;

class apb_tb_top: Entity
{
  import Vsha3_apb_euvm;

  apb_intf!(32, 10) apbSlave;
  
  VerilatedFstD _trace;

  Signal!(ubvec!1) clk;
  Signal!(ubvec!1) rstn;

  DVsha3_apb dut;

  
  void opentrace(string fstname) {
    version (DUMPFST) {
      traceEverOn(true);
      if (_trace is null) {
        _trace = new VerilatedFstD();
        dut.trace(_trace, 99);
        _trace.open(fstname);
      }
    }
  }

  void closetrace() {
    if (_trace !is null) {
      _trace.flush();
      _trace.close();
      _trace = null;
    }
  }

  override void doConnect() {
    import std.stdio;

    apbSlave.PCLK(clk);
    apbSlave.PRESETn(rstn);

    apbSlave.PSEL(dut.PSEL);
    apbSlave.PENABLE(dut.PENABLE);
    apbSlave.PWRITE(dut.PWRITE);
    apbSlave.PREADY(dut.PREADY);
    apbSlave.PSLVERR(dut.PSLVERR);
    apbSlave.PADDR(dut.PADDR);
    apbSlave.PWDATA(dut.PWDATA);
    apbSlave.PRDATA(dut.PRDATA);
  }

  override void doBuild() {
    dut = new DVsha3_apb();
    opentrace("sha3_apb.fst");
  }
  
  override void doFinish() {
    closetrace();
  }

  Task!stimulateClk stimulateClkTask;
  Task!stimulateRst stimulateRstTask;

  void stimulateClk() {
    import std.stdio;
    clk = false;
    while (true)
      {
        clk = false;
        dut.PCLK = false;
        if (_trace !is null)
          _trace.dump(getSimTime().getVal());
        dut.eval();
        wait (10.nsec);
        clk = true;
        dut.PCLK = true;
        if (_trace !is null) {
          _trace.dump(getSimTime().getVal());
        }
        dut.eval();
        wait (10.nsec);
      }
  }

  void stimulateRst() {
    rstn = false;
    dut.PRESETn = false;
    wait (100.nsec);
    rstn = true;
    dut.PRESETn = true;
  }
  
}


class sha3_apb_tb: uvm_context
{
  apb_tb_top top;
  override void initial() {
    uvm_config_db!(apb_intf!(32, 10)).set(null, "uvm_test_top.env.agent.driver", "apb_if", top.apbSlave);
    uvm_config_db!(apb_intf!(32, 10)).set(null, "uvm_test_top.env.agent.monitor", "apb_if", top.apbSlave);
  }
}

void main(string[] args) {
  import std.stdio;
  uint random_seed;

  CommandLine cmdl = new CommandLine(args);

  if (cmdl.plusArgs("random_seed=" ~ "%d", random_seed))
    writeln("Using random_seed: ", random_seed);
  else random_seed = 1;

  auto tb = new sha3_apb_tb;
  tb.multicore(0, 1);
  tb.elaborate("tb", args);
  tb.set_seed(random_seed);
  tb.start();
  
}
