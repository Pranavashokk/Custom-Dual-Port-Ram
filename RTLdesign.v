module true_dual_port_bram #(
    parameter DWIDTH      = 8,
    parameter DEPTH       = 256,
    parameter ADDR_W      = $clog2(DEPTH),
    parameter READ_SYNC   = 1,
    parameter WRITE_FIRST = 1      
)(
    input                         clk,
    input                         clk_en,
    input                         port_en_0,
    input                         wr_en_0,
    input      [ADDR_W-1:0]       addr_in_0,
    input      [DWIDTH-1:0]       data_in_0,
    output reg [DWIDTH-1:0]       data_out_0,
    input                         port_en_1,
    input                         wr_en_1,
    input      [ADDR_W-1:0]       addr_in_1,
    input      [DWIDTH-1:0]       data_in_1,
    output reg [DWIDTH-1:0]       data_out_1,
    input                         singleportmode,
    output reg                    collision_flag
);

    (* ram_style = "block" *) reg [DWIDTH-1:0] ram [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            ram[i] = {DWIDTH{1'b0}};
    end

    always @(posedge clk) begin
        if (clk_en)
            collision_flag <= (port_en_0 && port_en_1 && wr_en_0 && wr_en_1 && (addr_in_0 == addr_in_1));
    end

    generate
        if (READ_SYNC) begin : SYNC_READ
            always @(posedge clk) begin
                if (clk_en) begin
                    if (singleportmode) begin
                        if (port_en_0) begin
                            if (wr_en_0) begin
                                if (addr_in_0 <= 8'h0F)
                                    ram[addr_in_0] <= data_in_0;
                                if (WRITE_FIRST == 1)
                                    data_out_0 <= data_in_0;
                                else
                                    data_out_0 <= ram[addr_in_0];
                            end else begin
                                data_out_0 <= ram[addr_in_0];
                            end
                        end else begin
                            data_out_0 <= {DWIDTH{1'b0}};
                        end
                        data_out_1 <= {DWIDTH{1'b0}};
                    end else begin
                        if (port_en_0 && port_en_1 && wr_en_0 && wr_en_1) begin
                            if (addr_in_0 == addr_in_1) begin
                                ram[addr_in_0] <= data_in_0;
                                if (WRITE_FIRST == 1) begin
                                    data_out_0 <= data_in_0;
                                    data_out_1 <= data_in_0;
                                end else begin
                                    data_out_0 <= ram[addr_in_0];
                                    data_out_1 <= ram[addr_in_0];
                                end
                            end else begin
                                ram[addr_in_0] <= data_in_0;
                                ram[addr_in_1] <= data_in_1;
                                if (WRITE_FIRST == 1) begin
                                    data_out_0 <= data_in_0;
                                    data_out_1 <= data_in_1;
                                end else begin
                                    data_out_0 <= ram[addr_in_0];
                                    data_out_1 <= ram[addr_in_1];
                                end
                            end
                        end else if (port_en_0 && wr_en_0 && port_en_1 && !wr_en_1) begin
                            ram[addr_in_0] <= data_in_0;
                            if (WRITE_FIRST == 1)
                                data_out_0 <= data_in_0;
                            else
                                data_out_0 <= ram[addr_in_0];
                            data_out_1 <= ram[addr_in_1];
                        end else if (port_en_0 && !wr_en_0 && port_en_1 && wr_en_1) begin
                            ram[addr_in_1] <= data_in_1;
                            if (WRITE_FIRST == 1)
                                data_out_1 <= data_in_1;
                            else
                                data_out_1 <= ram[addr_in_1];
                            data_out_0 <= ram[addr_in_0];
                        end else if (port_en_0 && port_en_1 && !wr_en_0 && !wr_en_1) begin
                            data_out_0 <= ram[addr_in_0];
                            data_out_1 <= ram[addr_in_1];
                        end else begin
                            if (port_en_0) begin
                                if (wr_en_0)
                                    ram[addr_in_0] <= data_in_0;
                                if (WRITE_FIRST == 1 && wr_en_0)
                                    data_out_0 <= data_in_0;
                                else
                                    data_out_0 <= ram[addr_in_0];
                            end else begin
                                data_out_0 <= {DWIDTH{1'b0}};
                            end
                            if (port_en_1) begin
                                if (wr_en_1)
                                    ram[addr_in_1] <= data_in_1;
                                if (WRITE_FIRST == 1 && wr_en_1)
                                    data_out_1 <= data_in_1;
                                else
                                    data_out_1 <= ram[addr_in_1];
                            end else begin
                                data_out_1 <= {DWIDTH{1'b0}};
                            end
                        end
                    end
                end
            end
        end else begin : ASYNC_READ
            always @(posedge clk) begin
                if (clk_en) begin
                    if (port_en_0 && wr_en_0)
                        ram[addr_in_0] <= data_in_0;
                    if (port_en_1 && wr_en_1)
                        ram[addr_in_1] <= data_in_1;
                end
            end
            always @* begin
                if (port_en_0)
                    data_out_0 = ram[addr_in_0];
                else
                    data_out_0 = {DWIDTH{1'b0}};
                if (port_en_1)
                    data_out_1 = ram[addr_in_1];
                else
                    data_out_1 = {DWIDTH{1'b0}};
            end
        end
    endgenerate

endmodule
