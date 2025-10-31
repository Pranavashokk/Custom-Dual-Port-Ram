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
        $display("----------------------------------------------------------------");
        $display("Starting True Dual-Port BRAM Comparison Testbench");
        $display("----------------------------------------------------------------");

        initialize;
        #10;
        clk_en = 1;

        $display("T1: Initial Write (0xD0 -> 0x10) for setup.");
        port_en_0 = 1; wr_en_0 = 1; addr_in_0 = 8'h10; data_in_0 = 8'hD0;
        @(posedge clk);
        port_en_0 = 0; wr_en_0 = 0;
        @(posedge clk);

        $display("T2: Read Comparison (0x10 should contain 0xD0)");
        port_en_0 = 1; wr_en_0 = 0; addr_in_0 = 8'h10;
        port_en_1 = 1; wr_en_1 = 0; addr_in_1 = 8'h10;
        # (CLK_PERIOD / 2);
        if (data_out_0_async == 8'hD0) $display("    PASS: Async Port 0 reads 0x%h instantly.", data_out_0_async);
        else $display("    ERROR: Async Port 0 reads 0x%h (Expected 0xD0).", data_out_0_async);
        if (data_out_0_sync == 8'h00) $display("    PASS: Sync Port 0 still reads 0x%h (Previous cycle output).", data_out_0_sync);
        else $display("    ERROR: Sync Port 0 reads 0x%h too early (Expected 0x00).", data_out_0_sync);
        @(posedge clk);
        # (CLK_PERIOD / 2);
        if (data_out_0_async == 8'hD0) $display("    PASS: Async Port 0 reads 0x%h.", data_out_0_async);
        if (data_out_0_sync == 8'hD0) $display("    PASS: Sync Port 0 reads 0x%h (One-cycle delay confirmed).", data_out_0_sync);
        else $display("    ERROR: Sync Port 0 failed to read 0x%h (Expected 0xD0).", data_out_0_sync);
        port_en_0 = 0; port_en_1 = 0;
        @(posedge clk);

        $display("T3: Write-Read Conflict Comparison (Port 0 W, Port 1 R, Same Address)");
        port_en_0 = 1; wr_en_0 = 1; addr_in_0 = 8'h10; data_in_0 = 8'hF1;
        port_en_1 = 1; wr_en_1 = 0; addr_in_1 = 8'h10;
        # (CLK_PERIOD / 2);
        if (data_out_1_async == 8'hD0) $display("    PASS: Async Port 1 reads OLD data 0x%h mid-cycle.", data_out_1_async);
        else $display("    ERROR: Async Port 1 reads 0x%h (Expected OLD 0xD0).", data_out_1_async);
        if (data_out_1_sync == 8'hD0) $display("    PASS: Sync Port 1 reads PREVIOUS data 0x%h mid-cycle.", data_out_1_sync);
        else $display("    ERROR: Sync Port 1 reads 0x%h (Expected PREVIOUS 0xD0).", data_out_1_sync);
        @(posedge clk);
        port_en_0 = 0; wr_en_0 = 0;
        port_en_1 = 1; wr_en_1 = 0; addr_in_1 = 8'h10;
        # (CLK_PERIOD / 2);
        if (data_out_1_async == 8'hF1) $display("    PASS: Async Port 1 instantly updates to NEW data 0x%h.", data_out_1_async);
        else $display("    ERROR: Async Port 1 reads 0x%h (Expected NEW 0xF1).", data_out_1_async);
        if (data_out_1_sync == 8'hF1) $display("    PASS: Sync Port 1 updates to NEW data 0x%h (After one cycle delay).", data_out_1_sync);
        else $display("    ERROR: Sync Port 1 reads 0x%h (Expected NEW 0xF1).", data_out_1_sync);
        port_en_1 = 0;
        @(posedge clk);

        $display("T4: Write-Write Collision Test (0x20, 0xA5 vs 0x5A)");
        port_en_0 = 1; wr_en_0 = 1; addr_in_0 = 8'h20; data_in_0 = 8'hA5;
        port_en_1 = 1; wr_en_1 = 1; addr_in_1 = 8'h20; data_in_1 = 8'h5A;
        @(posedge clk);
        if (collision_flag_async) $display("    PASS: Async Collision flag asserted.");
        else $display("    ERROR: Async Collision flag NOT asserted.");
        if (collision_flag_sync) $display("    PASS: Sync Collision flag asserted.");
        else $display("    ERROR: Sync Collision flag NOT asserted.");
        port_en_0 = 0; wr_en_0 = 0;
        port_en_1 = 0; wr_en_1 = 0;
        @(posedge clk);

        $display("----------------------------------------------------------------");
        $display("Testbench finished.");
        $finish;
    end

endmodule
