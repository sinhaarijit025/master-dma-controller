module dma(clk,rst,trigger,length,src_add,dest_add,done,ARADDR,ARVALID,ARREADY,RDATA,RVALID,RREADY,AWADDR,AWVALID,AWREADY,WDATA,WVALID,WREADY,BVALID,BREADY);
    input clk,rst;
    //control
    input trigger;
    input [4:0] length;
    input [31:0] src_add;
    input [31:0] dest_add;
    output done;

    //axi address channel
    output [31:0] ARADDR;
    output ARVALID;
    input ARREADY; // FIXED: Was AWREADY

    //axi read data
    input [31:0] RDATA;
    input RVALID;
    output RREADY;

    //axi write address
    output [31:0] AWADDR;
    output AWVALID;
    input AWREADY;

    //axi write data
    output [31:0] WDATA;
    output WVALID;
    input WREADY;

    //axi write response 
    input BVALID;
    output BREADY;

    wire [31:0] fifo_din;
    wire fifo_we;
    wire fifo_full;
    wire [31:0] fifo_dout;
    wire fifo_re;
    wire fifo_empty;

    wire read_done;
    wire write_done;

    assign done = write_done;

    //dma read fsm
    dma_read_fsm u1(
        .clk(clk), .rst(rst), .trigger(trigger), .src_add(src_add), .length(length), .read_done(read_done),
        .ARADDR(ARADDR), .ARVALID(ARVALID), .ARREADY(ARREADY),
        .RDATA(RDATA), .RVALID(RVALID), .RREADY(RREADY),
        .fifo_din(fifo_din), .fifo_we(fifo_we), .fifo_full(fifo_full)
    );

    //synchronous fifo 16 depth,32 bits
    fifo #(.data_width(32), .addr_width(4)) u_fifo(
        .clk(clk), .rst(rst),
        .din(fifo_din), .wr_en(fifo_we), .full(fifo_full),
        .dout(fifo_dout), .rd_en(fifo_re), .empty(fifo_empty)
    );

    //dma write fsm
    dma_write_fsm u3(
        .clk(clk), .rst(rst), .trigger(trigger), .dest_add(dest_add), .length(length), .write_done(write_done),
        .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
        .WDATA(WDATA), .WVALID(WVALID), .WREADY(WREADY),
        .BVALID(BVALID), .BREADY(BREADY),
        .fifo_dout(fifo_dout), .fifo_re(fifo_re), .fifo_empty(fifo_empty)
    );
endmodule

