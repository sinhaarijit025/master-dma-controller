`timescale 1ns / 1ps

module tb_master_dma_ex2;

    reg clk;
    reg reset;
    
    // Control Interface
    reg         trigger;
    reg  [4:0]  length;
    reg  [31:0] source_address;
    reg  [31:0] destination_address;
    wire        done;
    
    // AXI-Lite Read Channels
    wire [31:0] ARADDR;
    wire        ARVALID;
    reg         ARREADY;
    reg  [31:0] RDATA;
    reg         RVALID;
    wire        RREADY;
    
    // AXI-Lite Write Channels
    wire [31:0] AWADDR;
    wire        AWVALID;
    reg         AWREADY;
    wire [31:0] WDATA;
    wire        WVALID;
    reg         WREADY;
    reg         BVALID;
    wire        BREADY;

    dma dut (
        .clk(clk), 
        .rst(reset),
        .trigger(trigger), 
        .length(length),
        .src_add(source_address), 
        .dest_add(destination_address),
        .done(done),
        .ARADDR(ARADDR), .ARVALID(ARVALID), .ARREADY(ARREADY),
        .RDATA(RDATA), .RVALID(RVALID), .RREADY(RREADY),
        .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
        .WDATA(WDATA), .WVALID(WVALID), .WREADY(WREADY),
        .BVALID(BVALID), .BREADY(BREADY)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("wave_final.vcd");   // Saves to a different file
        $dumpvars(0, tb_master_dma_ex2);
    end

    always @(posedge clk) begin
        if (reset) begin
            ARREADY <= 1'b1; 
            RVALID  <= 1'b0;
            RDATA   <= 32'b0;
        end else begin
            if (ARVALID && ARREADY) begin
                ARREADY <= 1'b0; 
                RVALID  <= 1'b1; 
                
                // Example 2 Memory Map
                case (ARADDR)
                    32'h1010: RDATA <= 32'hDEADBEEF;
                    32'h1014: RDATA <= 32'h11223344;
                    32'h1018: RDATA <= 32'h55667788;
                    default:  RDATA <= 32'h00000000;
                endcase
            end 
            else if (RVALID && RREADY) begin
                RVALID  <= 1'b0; 
                ARREADY <= 1'b1; 
            end
        end
    end

    reg aw_accepted, w_accepted;

    always @(posedge clk) begin
        if (reset) begin
            AWREADY     <= 1'b1;
            WREADY      <= 1'b1;
            BVALID      <= 1'b0;
            aw_accepted <= 1'b0;
            w_accepted  <= 1'b0;
        end else begin
            if (AWVALID && AWREADY) aw_accepted <= 1'b1;
            if (WVALID && WREADY)   begin
                w_accepted <= 1'b1;
                $display("--------------------------------------------------");
                $display("[%0t ns] SLAVE MEMORY WRITE LOG:", $time);
                $display("         Address: 0x%h", AWADDR);
                $display("         Data:    0x%h", WDATA);
                $display("--------------------------------------------------");
            end

            AWREADY <= (AWVALID && AWREADY) ? 1'b0 : AWREADY;
            WREADY  <= (WVALID && WREADY)   ? 1'b0 : WREADY;

            if (aw_accepted && w_accepted && !BVALID) begin
                BVALID <= 1'b1;
            end 
            else if (BVALID && BREADY) begin
                BVALID      <= 1'b0;
                aw_accepted <= 1'b0;
                w_accepted  <= 1'b0;
                AWREADY     <= 1'b1; 
                WREADY      <= 1'b1;
            end
        end
    end

    initial begin
        reset = 1;
        trigger = 0;
        source_address = 0;
        destination_address = 0;
        length = 0;

        #20 reset = 0;
        #20;

        $display("STARTING DMA TRANSFER: EXAMPLE 2");
        $display("Source: 0x1011 (Offset 1) | Dest: 0x3000 | Len: 9 Bytes");
        
        // Example 2 parameters
        source_address      = 32'h1011; 
        destination_address = 32'h3000;
        length              = 5'd9;
        
        trigger = 1;
        #10 trigger = 0;

        wait(done);
        
        $display("DMA TRANSFER COMPLETE (DONE SIGNAL ASSERTED)");
        
        #50 $finish;
    end

endmodule
