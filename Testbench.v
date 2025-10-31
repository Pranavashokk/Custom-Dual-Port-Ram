`timescale 1ns / 1ps

module true_dual_port_bram_tb;

    parameter DWIDTH        = 8;
    parameter DEPTH         = 256;
    parameter ADDR_W        = 8;
    parameter WRITE_FIRST   = 1;

    reg clk;
    reg clk_en;
    reg singleportmode;

    reg port_en_0, wr_en_0;
    reg [ADDR_W-1:0] addr_in_0;
    reg [DWIDTH-1:0] data_in_0;

    reg port_en_1, wr_en_1;
    reg [ADDR_W-1:0] addr_in_1;
    reg [DWIDTH-1:0] data_in_1;

    wire [DWIDTH-1:0] data_out_0_async;
    wire [DWIDTH-1:0] data_out_1_async;
    wire collision_flag_async;

    wire [DWIDTH-1:0] data_out_0_sync;
    wire [DWIDTH-1:0] data_out_1_sync;
    wire collision_flag_sync;

    true_dual_port_bram #(
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .ADDR_W(ADDR_W),
        .READ_SYNC(0),
        .WRITE_FIRST(WRITE_FIRST)
    ) dut_async (
        .clk(clk), .clk_en(clk_en),
        .port_en_0(port_en_0), .wr_en_0(wr_en_0), .addr_in_0(addr_in_0), .data_in_0(data_in_0), .data_out_0(data_out_0_async),
        .port_en_1(port_en_1), .wr_en_1(wr_en_1), .addr_in_1(addr_in_1), .data_in_1(data_in_1), .data_out_1(data_out_1_async),
        .singleportmode(singleportmode),
        .collision_flag(collision_flag_async)
    );
    
    true_dual_port_bram #(
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .ADDR_W(ADDR_W),
        .READ_SYNC(1),
        .WRITE_FIRST(WRITE_FIRST)
    ) dut_sync (
        .clk(clk), .clk_en(clk_en),
        .port_en_0(port_en_0), .wr_en_0(wr_en_0), .addr_in_0(addr_in_0), .data_in_0(data_in_0), .data_out_0(data_out_0_sync),
        .port_en_1(port_en_1), .wr_en_1(wr_en_1), .addr_in_1(addr_in_1), .data_in_1(data_in_1), .data_out_1(data_out_1_sync),
        .singleportmode(singleportmode),
        .collision_flag(collision_flag_sync)
    );

    parameter CLK_PERIOD = 10;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    task initialize;
        begin
            port_en_0 = 0; wr_en_0 = 0;
            addr_in_0 = 0; data_in_0 = 0;
            port_en_1 = 0; wr_en_1 = 0;
            addr_in_1 = 0; data_in_1 = 0;
            clk_en = 0;
            singleportmode = 0;
        end
    endtask

    initial begin
        initialize;
        #10;
        clk_en = 1;

        port_en_0 = 1; wr_en_0 = 1; addr_in_0 = 8'h10; data_in_0 = 8'hD0;
        @(posedge clk);
        port_en_0 = 0; wr_en_0 = 0;
        @(posedge clk);

        port_en_0 = 1; wr_en_0 = 0; addr_in_0 = 8'h10;
        port_en_1 = 1; wr_en_1 = 0; addr_in_1 = 8'h10;
        @(posedge clk);
        port_en_0 = 0; port_en_1 = 0;
        @(posedge clk);

        port_en_0 = 1; wr_en_0 = 1; addr_in_0 = 8'h10; data_in_0 = 8'hF1;
        port_en_1 = 1; wr_en_1 = 0; addr_in_1 = 8'h10;
        @(posedge clk);
        port_en_0 = 0; wr_en_0 = 0;
        port_en_1 = 1; wr_en_1 = 0; addr_in_1 = 8'h10;
        @(posedge clk);
        port_en_1 = 0;
        @(posedge clk);

        port_en_0 = 1; wr_en_0 = 1; addr_in_0 = 8'h20; data_in_0 = 8'hA5;
        port_en_1 = 1; wr_en_1 = 1; addr_in_1 = 8'h20; data_in_1 = 8'h5A;
        @(posedge clk);
        port_en_0 = 0; wr_en_0 = 0;
        port_en_1 = 0; wr_en_1 = 0;
        @(posedge clk);

        $finish;
    end

endmodule
