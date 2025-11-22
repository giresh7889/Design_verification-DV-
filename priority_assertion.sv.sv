module priority_arbitration_assertion(
    input logic arb_clk,
    input logic arb_rst_n,
    input logic arb_req0,
    input logic arb_req1,
    input logic arb_req2,
    input logic arb_req3,
    output logic arb_gnt0,
    output logic arb_gnt1,
    output logic arb_gnt2,
    output logic arb_gnt3);
  always@(posedge arb_clk or negedge arb_rst_n)
    if(!arb_rst_n)begin
       arb_gnt0<=0;
       arb_gnt1<=0;
       arb_gnt2<=0;
       arb_gnt3<=0;
  end
else begin
  if(arb_req1)      arb_gnt1 <=  1;
  else if(arb_req3) arb_gnt3 <=  1;
  else if(arb_req2) arb_gnt2 <=  1;
  else if(arb_req0) arb_gnt0  <=  1;
    end
    endmodule
    //--------------------------------------------------------------------------------------------------------------------
    //
// simple test_bench_for_assertion
//-----------------------------------------------------------------------------------------------------------------------------
module tb_priority_arbiter;

  logic arb_clk;
  logic arb_rst_n;
  logic arb_req0, arb_req1, arb_req2, arb_req3;
  logic arb_gnt0, arb_gnt1, arb_gnt2, arb_gnt3;

  
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


  initial begin
    arb_rst_n = 0;
    {arb_req0,arb_req1,arb_req2,arb_req3} = 4'b0000;

    #15 arb_rst_n = 1;

    #10@(posedge arb_clk) arb_req1 = 1;    
    #20@(posedge arb_clk) arb_req3 = 1;
    #20 @(posedge arb_clk)arb_req2 = 1;
    #20@(posedge arb_clk)  arb_req0 = 1;

    #40@(posedge arb_clk) arb_req1 = 0;
    #20@(posedge arb_clk) arb_req3 = 0;
    #20@(posedge arb_clk) arb_req2 = 0;
    #20@(posedge arb_clk) arb_req0 = 0;

    #50 $finish;
  end

  // ----------------------------------------------------------
  // Monitor
  // ----------------------------------------------------------
  always @(posedge arb_clk) begin
    $monitor("T=%0t | Req0=%b,Req1=%b,Req2=%b,Req3=%b | Gnt0=%b,Gnt1=%b,Gnt2=%b,Gnt3=%b",
             $time,
             arb_req0,arb_req1,arb_req2,arb_req3,
             arb_gnt0,arb_gnt1,arb_gnt2,arb_gnt3);
  end

  // ----------------------------------------------------------
  // Assertions
  // ----------------------------------------------------------

  // 1. One-hot grant check
  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        $onehot0({arb_gnt3,arb_gnt2,arb_gnt1,arb_gnt0}))
    else $error("Grant is not one-hot!");

  // 2. If grant is given, corresponding request must be high
  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        arb_gnt0 |-> arb_req0);

  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        arb_gnt1 |-> arb_req1);

  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        arb_gnt2 |-> arb_req2);

  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        arb_gnt3 |-> arb_req3);

  // ----------------------------------------------------------
  // 3. Priority order check (1 → 3 → 2 → 0)
  // ----------------------------------------------------------

  // If req1 is high → MUST grant1 (highest priority)
  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        arb_req1 |-> arb_gnt1)
    else $error("Priority violation: req1 not granted first");

  // If req1 is LOW and req3 is HIGH → grant3
  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        (!arb_req1 && arb_req3) |-> arb_gnt3)
    else $error("Priority violation: req3 should win");

  // If req1, req3 are LOW and req2 HIGH → grant2
  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        (!arb_req1 && !arb_req3 && arb_req2) |-> arb_gnt2)
    else $error("Priority violation: req2 should win");

  // req0 wins only if all others LOW
  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        (!arb_req1 && !arb_req3 && !arb_req2 && arb_req0) |-> arb_gnt0)
    else $error("Priority violation: req0 should win last");

  // 4.no of cycles request will wait
  assert property (@(posedge arb_clk) disable iff(!arb_rst_n)
        arb_req1 |-> ##[0:1] arb_gnt1);

endmodule

    
    
