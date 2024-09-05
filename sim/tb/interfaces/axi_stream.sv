`timescale 1ns / 1ps

interface axis #(parameter w_data = 512, parameter w_user = 0) (input logic clk);
    localparam int w_keep = w_data / 8;

    logic              tvalid;
    logic [w_data-1:0] tdata;
    logic [w_keep-1:0] tkeep;
    logic              tlast;
    logic [w_user-1:0] tuser;
    logic              tready;

    modport master (
        input tready,
        output tvalid, tdata, tkeep, tlast, tuser
    );

    modport slave (
        input tvalid, tdata, tkeep, tlast, tuser,
        output tready
    );

    task reset;
        tvalid <= 1'b0;
        tdata  <=  'b0;
        tkeep  <=  'b0;
        tlast  <= 1'b0;
        tuser  <=  'b0;
        tready <= 1'b0;
    endtask

    task send_beat;
        input logic [w_data-1:0] data;
        input logic [w_keep-1:0] keep;
        input logic              last;
        tvalid <= 1'b1;
        tdata  <= data;
        tkeep  <= keep;
        tlast  <= last;
        if (!tready) @(posedge tready);
    endtask

    task send_user;
        input logic [w_user-1:0] user;
        tuser <= user;
    endtask
endinterface