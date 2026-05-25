module dma_read_fsm (clk,rst,trigger,src_add,length,read_done,ARADDR,ARVALID,ARREADY,RDATA,RVALID,RREADY,fifo_din,fifo_we,fifo_full);
    input clk,rst,trigger;
    input [31:0] src_add;
    input [4:0] length;
    output reg read_done;
    output reg [31:0] ARADDR;
    output reg ARVALID;
    input ARREADY;
    input [31:0] RDATA;
    input RVALID;
    output wire RREADY; 
    output reg [31:0] fifo_din;
    output reg fifo_we;
    input fifo_full;

    //state
    localparam IDLE = 2'b00;
    localparam AR_ADDR= 2'b01;
    localparam R_DATA=2'b10;
    localparam DONE_STATE=2'b11;

    reg [1:0] state;

    //data depth reg
    reg [31:0] current_address;
    reg [4:0] bytes_remaining;
    reg [1:0] current_offset;
    reg [31:0] pack_reg;
    reg [2:0] pack_count;
    //comb sig for next_state
    reg [31:0] next_pack_reg;
    reg [2:0] next_pack_count;
    reg [31:0] extracted_data;
    reg [2:0] bytes_from_bus;
    reg [2:0] valid_bytes_in_word;

    assign RREADY=(state==R_DATA) && !fifo_full;
    //byte extraction (big endian)
    always @(*) begin
        next_pack_reg=pack_reg;
        next_pack_count=pack_count;
        fifo_we=1'b0;
        fifo_din=32'b0;
        //how many valid bytes are in the current word
        valid_bytes_in_word=4-current_offset;
        
        if(bytes_remaining<valid_bytes_in_word) begin
            bytes_from_bus=bytes_remaining;
        end
        else begin
            bytes_from_bus=valid_bytes_in_word;
        end
        
        //shift the incoming rdata
        case(current_offset)
            2'b00: extracted_data=RDATA;
            2'b01: extracted_data= {RDATA[23:0],8'b0};
            2'b10: extracted_data= {RDATA [15:0],16'b0};
            2'b11: extracted_data ={RDATA [7:0], 24'b0};
        endcase

        //packing engine
        if(state==R_DATA && RVALID && RREADY) begin
            if(pack_count==0) begin
                if(bytes_from_bus>=4) begin
                    fifo_din=extracted_data;
                    fifo_we=1'b1;
                    next_pack_count=0;
                    next_pack_reg=32'b0;
                end else begin
                    next_pack_reg=extracted_data;
                    next_pack_count=bytes_from_bus;
                end
            end
            else if(pack_count==1) begin
                if((pack_count+bytes_from_bus)>=4) begin
                    fifo_din={pack_reg[31:24],extracted_data[31:8]};
                    fifo_we=1'b1;
                    next_pack_count=bytes_from_bus-3;
                    next_pack_reg={extracted_data[7:0],24'b0};
                end else begin
                    if(bytes_from_bus==1) next_pack_reg={pack_reg[31:24],extracted_data[31:24],16'b0};
                    if(bytes_from_bus==2) next_pack_reg={pack_reg[31:24],extracted_data[31:16],8'b0};
                    next_pack_count=pack_count+bytes_from_bus;
                end
            end
            else if(pack_count==2) begin
                if((pack_count+bytes_from_bus)>=4) begin
                    fifo_din={pack_reg[31:16],extracted_data[31:16]};
                    fifo_we=1'b1;
                    next_pack_count=bytes_from_bus-2;
                    next_pack_reg={extracted_data[15:0],16'b0};
                end else begin
                    if(bytes_from_bus==1) next_pack_reg={pack_reg[31:16],extracted_data[31:24],8'b0};
                    next_pack_count=pack_count+bytes_from_bus;
                end
            end
            else if(pack_count==3) begin
                if((pack_count+bytes_from_bus)>=4) begin
                    fifo_din={pack_reg[31:8],extracted_data[31:24]};
                    fifo_we=1'b1;
                    next_pack_count=bytes_from_bus-1;
                    next_pack_reg={extracted_data[23:0],8'b0};
                end
            end
        end
    end

    //seq logic
    always @(posedge clk) begin
        if(rst) begin
            state<=IDLE;
            current_address<=32'b0;
            bytes_remaining<=5'b0;
            current_offset<=2'b0;
            pack_reg<=32'b0;
            pack_count<=3'b0;
            ARADDR<=32'b0;
            ARVALID<=1'b0;
            read_done<=1'b0;
        end else begin
            read_done<=1'b0;
            case(state)
            IDLE: begin
                if(trigger) begin
                    current_address<={src_add[31:2],2'b00};
                    current_offset<=src_add[1:0];
                    bytes_remaining<=length;
                    pack_reg<=32'b0;
                    pack_count<=3'b0;
                    ARADDR<={src_add[31:2],2'b00};
                    ARVALID<=1'b1;
                    state<=AR_ADDR;
                end
            end
            AR_ADDR: begin
                if(ARREADY &&  ARVALID) begin
                    ARVALID<=1'b0;
                    state<=R_DATA;
                end
            end
            R_DATA: begin
                if(RVALID && RREADY) begin
                    pack_reg<=next_pack_reg;
                    pack_count<=next_pack_count;

                    current_address<=current_address+4;
                    current_offset<=2'b00;

                    if(bytes_remaining<=bytes_from_bus) begin
                        bytes_remaining<=5'b0;
                        state<=DONE_STATE;
                    end else begin
                        bytes_remaining<=bytes_remaining-bytes_from_bus;
                        ARADDR<=current_address+4;
                        ARVALID<=1'b1;
                        state<=AR_ADDR;
                    end
                end
            end
            DONE_STATE: begin
                read_done<=1'b1;
                state<=IDLE;
            end
            endcase
        end
    end
endmodule
