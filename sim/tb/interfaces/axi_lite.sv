`timescale 1ns / 1ps

interface axil (input clk);
    logic        awvalid;
    logic [31:0] awaddr;
    logic        awready;
    logic        wvalid;
    logic [31:0] wdata;
    logic        wready;
    logic        bvalid;
    logic  [1:0] bresp;
    logic        bready;
    logic        arvalid;
    logic [31:0] araddr;
    logic        arready;
    logic        rvalid;
    logic [31:0] rdata;
    logic  [1:0] rresp;
    logic        rready;

    modport master (
        input awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp,
        output awvalid, awaddr, wvalid, wdata, bready, arvalid, araddr, rready
    );

    modport slave (
        input awvalid, awaddr, wvalid, wdata, bready, arvalid, araddr, rready,
        output awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp
    );

    task reset();
        awvalid <= 1'b0;
        awaddr  <=   '0;
        awready <= 1'b0;
        wvalid  <= 1'b0;
        wdata   <=   '0;
        wready  <= 1'b0;
        bvalid  <= 1'b0;
        bresp   <=   '0;
        bready  <= 1'b1;
        arvalid <= 1'b0;
        araddr  <=   '0;
        arready <= 1'b0;
        rvalid  <= 1'b0;
        rdata   <=   '0;
        rresp   <=   '0;
        rready  <= 1'b0;
    endtask

    task read_register;
        input  logic [31:0] address;
        output logic [31:0] data;
        @(negedge clk);

        // Send address
        araddr  <= address;
        arvalid <= 1'b1;
        wait(arready == 1'b1);
        @(negedge clk);
        @(negedge clk);
        arvalid <= 1'b0;

        // Get data
        rready  <= 1'b1;
        wait(rvalid == 1'b1);
        @(negedge clk);
        data    <= rdata;
        @(negedge clk);
        rready  <= 1'b0;
    endtask

    task write_register;
        input logic [31:0] address;
        input logic [31:0] data;
        @(negedge clk);
        fork
            begin
                // Send address
                awaddr  <= address;
                awvalid <= 1'b1;
                wait(awready == 1'b1);
                @(negedge clk);
                @(negedge clk);
                awvalid <= 1'b0;
            end
            begin
                // Send data
                wvalid  <= 1'b1;
                wdata   <= data;
                wait(wready == 1'b1);
                @(negedge clk);
                @(negedge clk);
                wvalid  <= 1'b0;
            end
        join
    endtask
endinterface