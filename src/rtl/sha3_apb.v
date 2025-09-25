module sha3_apb
  (
   PCLK,
   PRESETn,

   // Memory mapped read/write slave interface
   PSEL,
   PADDR,
   PENABLE,
   PWRITE,
   PWDATA,
   PRDATA,
   PREADY,
   PSLVERR
   );

   input         PCLK;
   input         PRESETn;

   // Memory mapped read/write slave interface
   input         PSEL;
   input         PENABLE;
   input         PWRITE;
   input [9:0]   PADDR;
   input [31:0]  PWDATA;
   output [31:0] PRDATA;
   output        PREADY;
   output        PSLVERR;

   wire [31:0]   PRDATA;
   reg           PREADY;


   reg           state_read;
   
   wire          PSEL;
   wire          WE;
   wire          reg_status_valid;

   wire          PSLVERR = 1'b0;

   assign WE = PWRITE && PENABLE;
   // assign PREADY = reg_status_valid;

   always @(posedge PCLK) begin
      if (PRESETn == 1'b0) PREADY <= 1'b0;
      else begin
         if (PWRITE == 1'b1) begin
            PREADY <= reg_status_valid;
         end
         else begin
            PREADY <= reg_status_valid && PSEL && PENABLE;
         end
      end
   end

   
   sha3_wrapper sha3_wr (.clk             (PCLK),
                         .rst_n            (PRESETn),
                         .cs               (PSEL),
                         .we               (WE),
                         .address          (PADDR/4),
                         .write_data       (PWDATA),
                         .read_data        (PRDATA),
                         .reg_status_valid (reg_status_valid)
                         );
endmodule // sha3_apb

