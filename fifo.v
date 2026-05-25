module fifo  #(parameter data_width = 32,parameter addr_width=4)(clk,rst,din,wr_en,full,dout,rd_en,empty);
    input clk,rst;
    input [data_width-1:0] din;
    input wr_en;
    output full;
    output [data_width-1:0] dout;
    input rd_en;
    output empty;

    localparam FIFO_DEPTH=(1<<addr_width);
    reg [data_width-1:0] mem [0:FIFO_DEPTH-1];

    reg [addr_width-1:0] wr_ptr;
    reg [addr_width-1:0] rd_ptr;

    reg [addr_width:0] count;
    assign full=(count==FIFO_DEPTH);
    assign empty= (count==0);
    assign dout=mem[rd_ptr];

    always @(posedge clk) begin
        if(rst) begin
            wr_ptr<=0;
            rd_ptr<=0;
            count<=0;
        end
        else begin
            case({wr_en && !full,rd_en && !empty})
                2'b10: begin
                    mem[wr_ptr]<=din;
                    wr_ptr<=wr_ptr+1;
                    count<=count+1;
                end
                2'b01: begin
                    rd_ptr<=rd_ptr+1;
                    count<=count-1;
                end
                2'b11: begin
                    mem[wr_ptr]<=din;
                    wr_ptr<=wr_ptr+1;
                    rd_ptr<=rd_ptr+1;
                end
                2'b00: begin
                    //no
                end
            endcase
        end
    end
endmodule