import esdl;
import uvm;

import apb.apb_seq_item: apb_seq_item;
import sha3_apb_sequencer: sha3_apb_sequencer;
import sha3_seq_item: sha3_seq_item;

class sha3_apb_sequence(int DW, int AW): uvm_sequence!(apb_seq_item!(DW, AW))
{
  enum BW = DW/8;

  mixin uvm_object_utils;
  sha3_apb_sequencer!(DW, AW) sequencer;
  sha3_seq_item sha3_item;

  this(string name = "sha3_apb_sequence") {
    super(name);
  }

  override void body() {
    sequencer.sha3_get_port.get(sha3_item);
    auto data = sha3_item.phrase;
    auto size = sha3_item.out_size;
    bool last_block = false;
    uint rate = (1600-2*size)/8; // 144, 136, 104, 72
    uint num_frames = cast(uint) (((data.length + rate))/(rate));
    for (size_t k=0; k!=num_frames; ++k) {
      ubyte [200] arr_block;
      for (size_t i=0; i!=rate; ++i) {
        if (k*rate + i < data.length) {
          arr_block[i] = data[rate*k+i];
        }
        else if (k*rate + i == data.length) {
          arr_block[i] = 0x06;
          last_block = true;
        }
        else {
          arr_block[i] = 0x00;
        }
        if (i==(rate-1) && last_block == true) {
          arr_block[i] |= 0x80;
        }
      }

      for (size_t i=0; i != (k==0 ? 50 : rate/4); ++i) {
        uint word = 0;
        for (size_t j=0; j!=4; ++j) {
          word += (cast(uint) arr_block[i*4+j]) << ((j) * 8);
        }
        auto data_req = REQ.type_id.create("req");
        data_req.data = word;
        data_req.addr = toubvec!AW(0x200+4*i);
        data_req.strb = toubvec!BW(0xF);
        data_req.is_write = true;
      
        start_item(data_req);
        finish_item(data_req);
      }
      if (k == 0) {
        init_pulse();//data_req.data = 0x00000001;
      }
      else {
        next_pulse();//data_req.data = 0x00000002;
      }
    }
    read_hash(rate);
  }

  void init_pulse() {
    auto data_req = REQ.type_id.create("init_pulse_start");
    data_req.data = 0x00000001;
    data_req.addr = 0x20;
    data_req.strb = toubvec!BW(0xF);
    data_req.is_write = true;

    start_item(data_req);
    finish_item(data_req);

    data_req = REQ.type_id.create("init_pulse_end");
    data_req.data = 0x00000000;
    data_req.addr = 0x20;
    data_req.strb = toubvec!BW(0xF);
    data_req.is_write = true;

    start_item(data_req);
    finish_item(data_req);
  }

  void  next_pulse() {
    auto data_req = REQ.type_id.create("next_pulse_start");
    data_req.data = 0x00000002;
    data_req.addr = 0x20;
    data_req.strb = toubvec!BW(0xF);
    data_req.is_write = true;

    start_item(data_req);
    finish_item(data_req);

    data_req = REQ.type_id.create("next_pulse_end");
    data_req.data = 0x00000000;
    data_req.addr = 0x20;
    data_req.strb = toubvec!BW(0xF);
    data_req.is_write = true;

    start_item(data_req);
    finish_item(data_req);
  }

  void read_hash(int rate) {
    auto out_size = (1600 - rate*8)/2;
    int  num_reads = out_size/32;
    for (uint i=0; i!= num_reads; i++) {
      auto data_req = REQ.type_id.create("read_hash");
      data_req.addr = toubvec!AW(0x300+4*i);
      data_req.strb = toubvec!BW(0xF);
      data_req.is_write = false;
    
      start_item(data_req);
      finish_item(data_req);
    }
  }
}

