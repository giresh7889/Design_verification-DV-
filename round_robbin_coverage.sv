module rr_arbiter (

    input             arb_clk,      
    input             arb_rst_n,    
    input             arb_req0,  
    input             arb_req1,     
    input             arb_req2,     
    input             arb_req3,     
    output logic [1:0]  arb_gnt,
    output logic [1:0]  pointer
);

  always_ff @(posedge arb_clk or negedge arb_rst_n) begin
    if(!arb_rst_n) begin
      pointer <= 2'b00;   
      arb_gnt <= 2'b00;   
    end
    else begin
      case(pointer)
        2'b00: begin
          if(arb_req0)      arb_gnt <= 2'b00;
          else if(arb_req1) arb_gnt <= 2'b01;
          else if(arb_req2) arb_gnt <= 2'b10;
          else if(arb_req3) arb_gnt <= 2'b11;
          else              arb_gnt <= 2'b00; 
        end

        2'b01: begin
          if(arb_req1)      arb_gnt <= 2'b01;
          else if(arb_req2) arb_gnt <= 2'b10;
          else if(arb_req3) arb_gnt <= 2'b11;
          else if(arb_req0) arb_gnt <= 2'b00;
          else              arb_gnt <= 2'b00;
        end

        2'b10: begin
          if(arb_req2)      arb_gnt <= 2'b10;
          else if(arb_req3) arb_gnt <= 2'b11;
          else if(arb_req0) arb_gnt <= 2'b00;
          else if(arb_req1) arb_gnt <= 2'b01;
          else              arb_gnt <= 2'b00;
        end

        2'b11: begin
          if(arb_req3)      arb_gnt <= 2'b11;
          else if(arb_req0) arb_gnt <= 2'b00;
          else if(arb_req1) arb_gnt <= 2'b01;
          else if(arb_req2) arb_gnt <= 2'b10;
          else              arb_gnt <= 2'b00;
        end
      endcase

      pointer <= pointer + 1;
    end
  end

endmodule
//=---------------------------------------------------------------------------

//test_bench_for_coverage
//---------------------------------------------------------------------------


module rr_arbitration_coverage;
      logic arb_clk;
      logic arb_rst_n;
      logic arb_req0,arb_req1,arb_req2,arb_req3;
      logic [1:0] arb_gnt;
      logic [1:0] pointer;
//DUT instatation
  rr_arbiter DUT (
    .arb_clk(arb_clk),
    .arb_rst_n(arb_rst_n),
    .arb_req0(arb_req0),
    .arb_req1(arb_req1),
    .arb_req2(arb_req2),
    .arb_req3(arb_req3),
    .arb_gnt(arb_gnt),
    .pointer(pointer)
  );
initial begin
arb_clk=0;
forever #5 arb_clk=~arb_clk;
end
  covergroup rr_cover @(posedge arb_clk);
    cp_pointer:coverpoint pointer{
      bins p0={2'b00};
      bins p1={2'b01};
      bins p2={2'b10};
      bins p3={2'b11};
    }
    cp_req:coverpoint {arb_req0,arb_req1,arb_req2,arb_req3}{
      bins no_req={4'b000};
      bins one_req={[4'b0001:4'b1000]};
      bins multi_req=default;
    }
    cp_gnt:coverpoint arb_gnt {
      bins g0={2'b00};
      bins g1={2'b01};
      bins g2={2'b10};
      bins g3={2'b11};
    }
cross_cov:cross cp_pointer,cp_gnt;
  endgroup
  rr_cover cg=new();
initial begin
arb_rst_n=0;
  {arb_req0,arb_req1,arb_req2,arb_req3}=4'b000;
#15 arb_rst_n=1;
  repeat(200)begin
    @(posedge arb_clk);
    arb_req0=$urandom_range (0,1);
    arb_req1=$urandom_range (0,1);
    arb_req2=$urandom_range (0,1);
    arb_req3=$urandom_range (0,1);
  end
#50 $finish;
end
  endmodule
