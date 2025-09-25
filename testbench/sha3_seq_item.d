import esdl;
import uvm;

enum output_size_enum {SHA3_224=224, SHA3_256=256,
                       SHA3_384=384, SHA3_512=512}

enum access_e: bool {READ, WRITE}

class sha3_seq_item: uvm_sequence_item
{
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
  }

  @UVM_DEFAULT {
    bool is_write;
    @rand ubyte[] phrase;
    @rand output_size_enum out_size;
  }
  constraint! q{
    phrase.length <= 1024;
    foreach (c; phrase) {
      c < 80;
      c > 10;
    }
  } phrase_length;
}

