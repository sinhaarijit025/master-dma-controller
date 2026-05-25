module dma_write_fsm(
    clk,rst,trigger,dest_add,length,write_done,
    AWADDR,AWVALID,AWREADY,WDATA,WVALID,WREADY,
    BVALID,BREADY, // Added missing ports
    fifo_dout,fifo_re,fifo_empty
);
    input clk,rst,trigger;
    input [31:0] dest_add;
    input [4:0] length;
    output reg write_done;
    
    output reg [31:0] AWADDR;
    output reg AWVALID;
    input AWREADY;
    
    output reg [31:0] WDATA;
    output reg WVALID;
    input WREADY;
    
    input BVALID;       // Added missing declaration
    output reg BREADY;  // Added missing declaration
    
    input [31:0] fifo_dout;
    output reg fifo_re;
    input fifo_empty;

    localparam IDLE=3'b000;
    localparam WAIT_FIFO=3'b001;
    localparam WRITE_TX=3'b010;
    localparam WRITE_RESPONSE=3'b011;
    localparam DONE_STATE=3'b100;

    reg [2:0] state;
    reg [31:0] current_address;
    reg [2:0] total_words_to_write;
    reg [2:0] words_written;

    always @(posedge clk) begin
        if(rst) begin
            state<=IDLE;
            write_done<=1'b0; // FIXED: Changed = to <=
            AWADDR<=32'b0;
            AWVALID<=1'b0;
            WDATA<=32'b0;
            WVALID<=1'b0;
            BREADY<=1'b0;
            fifo_re<=1'b0;
            current_address<=32'b0;
            total_words_to_write<=3'b0;
            words_written<=3'b0;
        end else  begin
            write_done<=1'b0;
            fifo_re<=1'b0;
            case(state)
                IDLE: begin
                    if(trigger) begin
                        current_address<=dest_add;
                        words_written<=3'b0;
                        total_words_to_write<=length[4:2];
                        if(length[4:2]==0) begin
                            state<=DONE_STATE;
                        end else begin
                            state<=WAIT_FIFO;
                        end
                    end
                end
                WAIT_FIFO: begin
                    if(!fifo_empty) begin
                        fifo_re<=1'b1;
                        AWADDR<=current_address;
                        WDATA<=fifo_dout;
                        AWVALID<=1'b1;
                        WVALID<=1'b1;
                        BREADY<=1'b1;
                        state<=WRITE_TX;
                    end
                end
                WRITE_TX: begin
                    if(AWVALID && AWREADY)  begin
                        AWVALID<=1'b0;
                    end
                    if(WVALID && WREADY) begin
                        WVALID<=1'b0;
                    end
                    if(!AWVALID && !WVALID) begin
                        state<=WRITE_RESPONSE;
                    end
                end
                WRITE_RESPONSE: begin
                    if(BVALID && BREADY) begin
                        BREADY<=1'b0;
                        current_address<=current_address+4;
                        words_written<=words_written+1;

                        if((words_written+1)==total_words_to_write) begin
                            state<=DONE_STATE;
                        end else begin
                            state<=WAIT_FIFO;
                        end
                    end
                end
                DONE_STATE: begin
                    write_done<=1'b1;
                    state<=IDLE;
                end
                default: state<=IDLE;
            endcase
        end
    end
endmodule