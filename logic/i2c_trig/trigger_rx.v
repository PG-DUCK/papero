// ----------------------------------------------------------------------------------------------
// --
// --      IDE                        : ISE 14.7
// --      Component name             : trigger_rx
// --      Author and copyright       : Tianwei Bao
// --      E-mail                     : baotw@ihep.ac.cn
// --      Date                       : 2020.10-2021.03
// --      Description                : sub system recv module for DI2C trigger syncronization
// --      Version                    : v0.5
// --      Format                     : DOS/WINDOWS UTF-8 W/O BOM
// --      Change log:                : v0.1 20201202 initial version
// --                                 : v0.2 20201228 crc16-kermit integrated
// --                                 : v0.3 20201210 implementation of busy clear logic
// --                                 : v0.4 20210310 async logic elements optimazation
// --                                 : v0.5 20220831 synch trigger generation

module trigger_rx
(
  //system clk & reset
  input 	    clk,//system clock,10MHz-100MHz recommended
  input 	    reset,//high effective
  input             iBusy,//high effective

  //system interface
  input 	    busy_clear,//positive edge sensitive, must be enabled to clear "busy" to 0 when the sub-system is ready to accept a new trigger
  output reg 	    trigger,//positive edge,indicating that the trigger arrives, and the DAQ could start to catch data
  output reg [7:0]  sub_system_id,
  output reg [7:0]  trigger_type,
  output reg [31:0] trigger_serial,
  output reg 	    crc_status, //high effective,indicating that the chesksum is OK now, and the "sub_system_id","trigger_type" and "trigger_serial" are all effective and could be loaded into the DAQ package
  output reg 	    end_flag,

  // sda transceiver interface
  input 	    ro_sda,//
  output wire 	    ren_sda,
  output wire 	    de_sda,
  output wire 	    di_sda,

  // scl transceiver interface
  input 	    ro_scl,//
  output wire 	    ren_scl,
  output wire 	    de_scl,
  output wire 	    di_scl,

  // busy transceiver interface
  input 	    ro_busy,
  output wire 	    ren_busy,
  output wire 	    de_busy,
  output wire 	    di_busy //high effective,indicating that the sub-system is busy with receiving trigger package and generating the DAQ data package
);

reg [3:0] state_i2c;
parameter [3:0] st_idle                 = 4'D0;
parameter [3:0] st_sub_system_id        = 4'D1;
parameter [3:0] st_trigger_type         = 4'D2;
parameter [3:0] st_trigger_serial_step0 = 4'D3;
parameter [3:0] st_trigger_serial_step1 = 4'D4;
parameter [3:0] st_trigger_serial_step2 = 4'D5;
parameter [3:0] st_trigger_serial_step3 = 4'D6;
parameter [3:0] st_crc_step0            = 4'D7;
parameter [3:0] st_crc_step1            = 4'D8;
parameter [3:0] st_crc_check            = 4'D9;

wire scl,sda;
reg start;
reg sBusyFlag;
reg busy;
reg trigger_out_reg,trigger_out_reg2;
reg busy_clear_reg,busy_clear_reg2;
reg stop, stop_reg;
reg scl_reg,scl_reg2;
reg sda_reg,sda_reg2;
reg sda_fedge;   
reg [3:0] count_scl;
reg [7:0] data;
reg crc_reset,crc_en;
reg [15:0] crc_data,crc_recv;
wire [15:0] crc_in,crc_out;
wire crc_clk;

//transceiver interface
assign sda     = ro_sda;    //sda input
assign ren_sda = 0;         //disable receiver
assign de_sda  = 0;         //enable drive
assign di_sda  = 1'BZ;      //

assign scl     = ro_scl;    //scl input
assign ren_scl = 0;         //disable receiver
assign de_scl  = 0;         //enable driver
assign di_scl  = 1'BZ;      //


assign ren_busy = 1;        //enable receiver
assign de_busy  = 1;        //disable driver
assign di_busy  = busy;     //busy output


always@(posedge clk) begin //start detection
  if (reset==1) begin
    start <= 0;
    sBusyFlag <= 0;
  end else begin
    if ((state_i2c==st_idle) && (sBusyFlag==0) && (iBusy == 0) && (sda_fedge==1)) begin
      //idle & not busy & sda falling edge
      start <= 1;
    end else begin
      start <= 0;
    end
    
    //sBusyFlag: maintains high for the busy during the whole transaction
    if ((state_i2c==st_idle) && (iBusy == 1) && (sda_fedge==1)) begin
      sBusyFlag = 1;
    end
    if (stop_reg==1) begin
      sBusyFlag = 0;	
    end
  end
end // always@ (posedge clk)

   
always@(posedge clk) begin //stop detection
  if (reset==1) begin
    stop <= 0;
  end else begin
    if ((sda_reg2==0)&&(scl==1)&&(sda_reg==1)) begin
      //sda rising
      stop <= 1;
    end else begin
      stop <= 0;
    end
  end
end

always@(posedge clk) begin //sync register
  if (reset==1) begin
    scl_reg<=1;
    sda_reg<=1;
    scl_reg2<=1;
    sda_reg2<=1;
    sda_fedge<=0;
    trigger_out_reg<=0;
    trigger_out_reg2<=0;
    trigger<=0;
    end_flag<=0;
    stop_reg<=0;
  end else begin
    scl_reg<=scl;
    scl_reg2<=scl_reg;
    sda_reg<=sda;
    sda_reg2<=sda_reg;
    sda_fedge<=sda_reg2 & ~(sda_reg);

    trigger_out_reg<=start;
    trigger_out_reg2<=trigger_out_reg;
    trigger<=start;
    end_flag<=stop & ~sBusyFlag;
    stop_reg<= stop;
  end
end

always@(posedge clk) begin //data receiver
  if(reset==1) begin
    count_scl<=0;
    data<=0;
  end else begin
    if(stop==1) begin
      count_scl<=0;
    end else begin
      if((scl_reg==1)&&(scl_reg2==0)) begin
        if(count_scl==4'D9) begin
          data[7:0]<={data[6:0],sda_reg};
          count_scl<=1;
        end else if(count_scl==4'D8) begin
          data[7:0]<=0;
          count_scl<=count_scl+4'D1;
        end else if(count_scl<4'D9) begin
          data[7:0]<={data[6:0],sda_reg};
          count_scl<=count_scl+4'D1;
        end
      end 
    end //stop
  end //reset
end //posedge

always@(posedge clk) begin //busy controller
  if(reset==1) begin
    busy_clear_reg<=0;
    busy_clear_reg2<=0;
    busy<=0;
  end else begin
    busy_clear_reg<=busy_clear;
    busy_clear_reg2<=busy_clear_reg;
    if(trigger_out_reg==1) begin
      busy<=1;
    end else begin
      if((stop==1)) begin
        busy<=0;
      end
    end
  end
end

always@(posedge clk) begin // DI2C package decoder
  if(reset==1) begin
    state_i2c<=st_idle;
    crc_data<=0;
    crc_recv<=0;
    crc_reset<=1;
    crc_en<=0;
    crc_status<=0;
    sub_system_id<=0;
    trigger_type<=0;
    trigger_serial<=0;
  end else begin
    case(state_i2c)
      st_idle:
        begin
          crc_reset<=1;
          crc_en<=0;
          crc_status<=0;
          if (sda_fedge==1) begin
            state_i2c<=st_sub_system_id;
          end else begin
            state_i2c<=st_idle;
          end
        end
    
      st_sub_system_id:
        begin
          crc_reset<=0;
          if((count_scl==4'D8)&&(scl_reg==1)&&(scl_reg2==0)) begin
            state_i2c<=st_trigger_type;
            sub_system_id[7:0]<=data[7:0];
          end else begin
            state_i2c<=st_sub_system_id;
          end
        end
      
      st_trigger_type:
        begin
          if((count_scl==4'D8)&&(scl_reg==1)&&(scl_reg2==0)) begin
            state_i2c<=st_trigger_serial_step0;
            trigger_type[7:0]<=data[7:0];
          end else begin
            state_i2c<=st_trigger_type;
          end
        end
      
      st_trigger_serial_step0:
        begin
          if((count_scl==4'D8)&&(scl_reg==1)&&(scl_reg2==0)) begin
            state_i2c<=st_trigger_serial_step1;
            trigger_serial[31:24]<=data[7:0];
            crc_data[15:0]<={sub_system_id[7:0],trigger_type[7:0]};
            crc_en<=1;
          end else begin
            state_i2c<=st_trigger_serial_step0;
          end
        end
      
      st_trigger_serial_step1:
        begin
          crc_en<=0;
          if((count_scl==4'D8)&&(scl_reg==1)&&(scl_reg2==0)) begin
            state_i2c<=st_trigger_serial_step2;
            trigger_serial[23:16]<=data[7:0];
          end else begin
            state_i2c<=st_trigger_serial_step1;
          end
        end
      
      st_trigger_serial_step2:
        begin
          if((count_scl==4'D8)&&(scl_reg==1)&&(scl_reg2==0)) begin
            state_i2c<=st_trigger_serial_step3;
            trigger_serial[15:8]<=data[7:0];
            crc_data[15:0]<=trigger_serial[31:16];
            crc_en<=1;
          end else begin
            state_i2c<=st_trigger_serial_step2;
          end
        end
      
      st_trigger_serial_step3:
        begin
          crc_en<=0;
          if((count_scl==4'D8)&&(scl_reg==1)&&(scl_reg2==0)) begin
            state_i2c<=st_crc_step0;
            trigger_serial[7:0]<=data[7:0];
          end else begin
            state_i2c<=st_trigger_serial_step3;
          end
        end
      
      st_crc_step0:
        begin
          if((count_scl==4'D8)&&(scl_reg==1)&&(scl_reg2==0)) begin
            state_i2c<=st_crc_step1;
            crc_recv[15:8]<=data[7:0];
            crc_data[15:0]<=trigger_serial[15:0];
            crc_en<=1;
          end else begin
            state_i2c<=st_crc_step0;
          end
        end
      
      st_crc_step1:
        begin
          crc_en<=0;
          if((count_scl==4'D8)&&(scl_reg==1)&&(scl_reg2==0)) begin
            state_i2c<=st_crc_check;
            crc_recv[7:0]<=data[7:0];
          end else begin
            state_i2c<=st_crc_step1;
          end
        end
      
      st_crc_check:
        begin
          if (stop==1) begin
            state_i2c<=st_idle;
          end else begin
            state_i2c<=st_crc_check;
          end

          if(crc_recv[15:0]==crc_out[15:0]) begin
            crc_status<=1;
          end else begin
            crc_status<=0;
          end
        end
    endcase
  end
end

assign crc_in={crc_data[8],crc_data[9],crc_data[10],crc_data[11],crc_data[12],crc_data[13],crc_data[14],crc_data[15],crc_data[0],crc_data[1],crc_data[2],crc_data[3],crc_data[4],crc_data[5],crc_data[6],crc_data[7]};
assign crc_clk=(~clk); //FIXME monnezza

crc16_generator inst_crc16_generator //crc16-kermit check
(
  .clock(crc_clk),
  .reset(crc_reset),
  .data_in_en(crc_en),
  .data_in(crc_in),
  .crc_out(crc_out)
);


endmodule
