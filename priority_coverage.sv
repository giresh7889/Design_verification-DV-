module priority_arbitration_assertion (
    input  logic arb_clk,
    input  logic arb_rst_n,
    input  logic arb_req0,
    input  logic arb_req1,
    input  logic arb_req2,
    input  logic arb_req3,
    output logic arb_gnt0,
    output logic arb_gnt1,
    output logic arb_gnt2,
    output logic arb_gnt3
);

  always @(posedge arb_clk or negedge arb_rst_n) begin
    if (!arb_rst_n) begin
      arb_gnt0 <= 0;
      arb_gnt1 <= 0;
      arb_gnt2 <= 0;
      arb_gnt3 <= 0;
    end
    else begin
      // Clear all grants every cycle
      arb_gnt0 <= 0;
      arb_gnt1 <= 0;
      arb_gnt2 <= 0;
      arb_gnt3 <= 0;

      if (arb_req1)      arb_gnt1 <= 1;
      else if (arb_req3) arb_gnt3 <= 1;
      else if (arb_req2) arb_gnt2 <= 1;
      else if (arb_req0) arb_gnt0 <= 1;
    end
  end
endmodule
//---------------------------------------------------------------------------
// test_bench_coverage
//----------------------------------------------------------------------------
module tb_priority_arbiter;

  logic arb_clk;
  logic arb_rst_n;
  logic arb_req0, arb_req1, arb_req2, arb_req3;
  logic arb_gnt0, arb_gnt1, arb_gnt2, arb_gnt3;

  // DUT
  priority_arbitration_assertion DUT (
    .arb_clk(arb_clk),
    .arb_rst_n(arb_rst_n),
    .arb_req0(arb_req0),
    .arb_req1(arb_req1),
    .arb_req2(arb_req2),
    .arb_req3(arb_req3),
    .arb_gnt0(arb_gnt0),
    .arb_gnt1(arb_gnt1),
    .arb_gnt2(arb_gnt2),
    .arb_gnt3(arb_gnt3)
  );

  initial begin
    arb_clk = 0;
    forever #5 arb_clk = ~arb_clk;
  end

  covergroup prio_cov @(posedge arb_clk);
    
    req_cp : coverpoint {arb_req3, arb_req2, arb_req1, arb_req0} {
      bins no_req   = {4'b0000};
      bins one_req  = {[4'b0001:4'b1000]};
      bins multi_req = default;
    }

    // 2. Grant coverage
    grant_cp : coverpoint {arb_gnt3,arb_gnt2,arb_gnt1,arb_gnt0} {
      bins g0 = {4'b0001};
      bins g1 = {4'b0010};
      bins g2 = {4'b0100};
      bins g3 = {4'b1000};
      bins no_gnt = {4'b0000};
    }


    req_gnt_cross : cross req_cp, grant_cp;

  endgroup

  prio_cov cg = new();

  // Random stimulus
  initial begin
    arb_rst_n = 0;
    {arb_req0,arb_req1,arb_req2,arb_req3} = 4'b0000;

    #15 arb_rst_n = 1;

    repeat(900) begin
      @(posedge arb_clk);
      arb_req0 = $urandom_range(0,1);
      arb_req1 = $urandom_range(0,1);
      arb_req2 = $urandom_range(0,1);
      arb_req3 = $urandom_range(0,1);
    end

    #50 $finish;
  end

endmodule

