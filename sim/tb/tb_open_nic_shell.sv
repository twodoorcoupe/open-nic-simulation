`timescale 1ns / 1ps

import open_nic_file_tools::*;

module tb_open_nic_shell ();
    parameter int    MIN_PKT_LEN     = 64;
    parameter int    MAX_PKT_LEN     = 1518;
    parameter int    NUM_PHYS_FUNC   = 1;
    parameter int    NUM_QUEUE       = 512;
    parameter int    NUM_QDMA        = 1;
    parameter int    NUM_CMAC_PORT   = 1;
    parameter string SIM_LOCATION    = "";

    logic rstn;
    logic rst_done;
    logic axil_aclk;
    logic axis_aclk;
    logic axis_aclk_cmac;
    event start;

    axil axil (axil_aclk);
    FileRegisters registers;

    open_nic_shell  #(
        .MIN_PKT_LEN        (MIN_PKT_LEN),
        .MAX_PKT_LEN        (MAX_PKT_LEN),
        .NUM_PHYS_FUNC      (NUM_PHYS_FUNC),
        .NUM_QUEUE          (NUM_QUEUE),
        .NUM_QDMA           (NUM_QDMA),
        .NUM_CMAC_PORT      (NUM_CMAC_PORT)
    ) open_nic_shell (
        .s_axil_sim_awvalid (axil.awvalid),
        .s_axil_sim_awaddr  (axil.awaddr),
        .s_axil_sim_awready (axil.awready),
        .s_axil_sim_wvalid  (axil.wvalid),
        .s_axil_sim_wdata   (axil.wdata),
        .s_axil_sim_wready  (axil.wready),
        .s_axil_sim_bvalid  (axil.bvalid),
        .s_axil_sim_bresp   (axil.bresp),
        .s_axil_sim_bready  (axil.bready),
        .s_axil_sim_arvalid (axil.arvalid),
        .s_axil_sim_araddr  (axil.araddr),
        .s_axil_sim_arready (axil.arready),
        .s_axil_sim_rvalid  (axil.rvalid),
        .s_axil_sim_rdata   (axil.rdata),
        .s_axil_sim_rresp   (axil.rresp),
        .s_axil_sim_rready  (axil.rready),
        .powerup_rstn       (rstn)
    );

    // Assign parameters and axi stream clock depending on box being tested
    assign axil_aclk =   open_nic_shell.axil_aclk;
    assign rst_done  = & open_nic_shell.shell_rst_done;
`ifdef __250mhz__
    localparam W_USER = 48;
    localparam W_SPLIT = W_USER / 3;
    localparam N_HOST_INTERFACES = NUM_QDMA * NUM_PHYS_FUNC;
    localparam N_CARD_INTERFACES = NUM_CMAC_PORT;
    assign axis_aclk = open_nic_shell.axis_aclk;
`elsif __322mhz__
    localparam W_USER = 1;
    localparam N_HOST_INTERFACES = NUM_CMAC_PORT;
    localparam N_CARD_INTERFACES = NUM_CMAC_PORT;
    assign axis_aclk = open_nic_shell.cmac_clk[0];
`elsif __full__
    localparam W_USER = 52;
    localparam W_USER_CMAC = 1;
    localparam N_HOST_INTERFACES = NUM_QDMA * NUM_PHYS_FUNC;
    localparam N_CARD_INTERFACES = NUM_CMAC_PORT;
    assign axis_aclk      = open_nic_shell.axis_aclk;
    assign axis_aclk_cmac = open_nic_shell.cmac_clk[0];
`endif

    // Create interfaces and file readers and writers on the host side (QDMA side)
    axis       #(W_DATA, W_USER) dma_send       [N_HOST_INTERFACES] (axis_aclk);
    axis       #(W_DATA, W_USER) dma_receive    [N_HOST_INTERFACES] (axis_aclk);
    FileReader #(W_DATA, W_USER) dma_in_reader  [N_HOST_INTERFACES];
    FileWriter #(W_DATA, W_USER) dma_out_writer [N_HOST_INTERFACES];

    // Create interfaces and file readers and writers on the card side (CMAC side)
`ifdef __full__
    axis       #(W_DATA, W_USER_CMAC) phy_send       [N_CARD_INTERFACES] (axis_aclk_cmac);
    axis       #(W_DATA, W_USER_CMAC) phy_receive    [N_CARD_INTERFACES] (axis_aclk_cmac);
    FileReader #(W_DATA, W_USER_CMAC) phy_in_reader  [N_CARD_INTERFACES];
    FileWriter #(W_DATA, W_USER_CMAC) phy_out_writer [N_CARD_INTERFACES];
`else
    axis       #(W_DATA, W_USER) phy_send       [N_CARD_INTERFACES] (axis_aclk);
    axis       #(W_DATA, W_USER) phy_receive    [N_CARD_INTERFACES] (axis_aclk);
    FileReader #(W_DATA, W_USER) phy_in_reader  [N_CARD_INTERFACES];
    FileWriter #(W_DATA, W_USER) phy_out_writer [N_CARD_INTERFACES];
`endif

    genvar i;

    // Assign the interfaces on the host side (QDMA side)
    generate
        for (i = 0; i < N_HOST_INTERFACES; i++) begin

        `ifdef __250mhz__
            // Assign the host to card signals
            assign open_nic_shell.box_250mhz_inst.s_axis_qdma_h2c_tvalid[i]                      = dma_send[i].tvalid;
            assign open_nic_shell.box_250mhz_inst.s_axis_qdma_h2c_tdata[W_DATA*i+:W_DATA]        = dma_send[i].tdata;
            assign open_nic_shell.box_250mhz_inst.s_axis_qdma_h2c_tkeep[W_KEEP*i+:W_KEEP]        = dma_send[i].tkeep;
            assign open_nic_shell.box_250mhz_inst.s_axis_qdma_h2c_tlast[i]                       = dma_send[i].tlast;
            assign open_nic_shell.box_250mhz_inst.s_axis_qdma_h2c_tuser_size[W_SPLIT*i+:W_SPLIT] = dma_send[i].tuser[2*W_SPLIT+:W_SPLIT];
            assign open_nic_shell.box_250mhz_inst.s_axis_qdma_h2c_tuser_src[W_SPLIT*i+:W_SPLIT]  = dma_send[i].tuser[W_SPLIT+:W_SPLIT];
            assign open_nic_shell.box_250mhz_inst.s_axis_qdma_h2c_tuser_dst[W_SPLIT*i+:W_SPLIT]  = dma_send[i].tuser[0+:W_SPLIT];
            assign dma_send[i].tready = open_nic_shell.box_250mhz_inst.s_axis_qdma_h2c_tready[i];

            // Assign the card to host signals
            assign dma_receive[i].tvalid                    = open_nic_shell.box_250mhz_inst.m_axis_qdma_c2h_tvalid[i];
            assign dma_receive[i].tdata                     = open_nic_shell.box_250mhz_inst.m_axis_qdma_c2h_tdata[W_DATA*i+:W_DATA];
            assign dma_receive[i].tkeep                     = open_nic_shell.box_250mhz_inst.m_axis_qdma_c2h_tkeep[W_KEEP*i+:W_KEEP];
            assign dma_receive[i].tlast                     = open_nic_shell.box_250mhz_inst.m_axis_qdma_c2h_tlast[i];
            assign dma_receive[i].tuser[2*W_SPLIT+:W_SPLIT] = open_nic_shell.box_250mhz_inst.m_axis_qdma_c2h_tuser_size[W_SPLIT*i+:W_SPLIT];
            assign dma_receive[i].tuser[W_SPLIT+:W_SPLIT]   = open_nic_shell.box_250mhz_inst.m_axis_qdma_c2h_tuser_src[W_SPLIT*i+:W_SPLIT];
            assign dma_receive[i].tuser[0+:W_SPLIT]         = ~rstn ? '0 : open_nic_shell.box_250mhz_inst.m_axis_qdma_c2h_tuser_dst[W_SPLIT*i+:W_SPLIT];
            assign open_nic_shell.box_250mhz_inst.m_axis_qdma_c2h_tready[i] = dma_receive[i].tready;

        `elsif __322mhz__
            // Assign the host to card signals
            assign open_nic_shell.box_322mhz_inst.s_axis_adap_tx_322mhz_tvalid[i]               = dma_send[i].tvalid;
            assign open_nic_shell.box_322mhz_inst.s_axis_adap_tx_322mhz_tdata[W_DATA*i+:W_DATA] = dma_send[i].tdata;
            assign open_nic_shell.box_322mhz_inst.s_axis_adap_tx_322mhz_tkeep[W_KEEP*i+:W_KEEP] = dma_send[i].tkeep;
            assign open_nic_shell.box_322mhz_inst.s_axis_adap_tx_322mhz_tlast[i]                = dma_send[i].tlast;
            assign open_nic_shell.box_322mhz_inst.s_axis_adap_tx_322mhz_tuser_err[i]            = dma_send[i].tuser[0];
            assign dma_send[i].tready = open_nic_shell.box_322mhz_inst.s_axis_adap_tx_322mhz_tready[i];

            // Assign the card to host signals
            assign dma_receive[i].tvalid   = open_nic_shell.box_322mhz_inst.m_axis_adap_rx_322mhz_tvalid[i];
            assign dma_receive[i].tdata    = open_nic_shell.box_322mhz_inst.m_axis_adap_rx_322mhz_tdata[W_DATA*i+:W_DATA];
            assign dma_receive[i].tkeep    = open_nic_shell.box_322mhz_inst.m_axis_adap_rx_322mhz_tkeep[W_KEEP*i+:W_KEEP];
            assign dma_receive[i].tlast    = open_nic_shell.box_322mhz_inst.m_axis_adap_rx_322mhz_tlast[i];
            assign dma_receive[i].tuser[0] = open_nic_shell.box_322mhz_inst.m_axis_adap_rx_322mhz_tuser_err[i];

        `elsif __full__
            // Assign the host to card signals
            assign open_nic_shell.s_axis_qdma_h2c_sim_tvalid[i]               = dma_send[i].tvalid;
            assign open_nic_shell.s_axis_qdma_h2c_sim_tdata[W_DATA*i+:W_DATA] = dma_send[i].tdata;
            assign open_nic_shell.s_axis_qdma_h2c_sim_tcrc                    = '0;
            assign open_nic_shell.s_axis_qdma_h2c_sim_tlast[i]                = dma_send[i].tlast;
            assign open_nic_shell.s_axis_qdma_h2c_sim_tuser_qid[11*i+:11]     = dma_send[i].tuser[51-32-:11];
            assign open_nic_shell.s_axis_qdma_h2c_sim_tuser_port_id           = '0;
            assign open_nic_shell.s_axis_qdma_h2c_sim_tuser_err               = '0;
            assign open_nic_shell.s_axis_qdma_h2c_sim_tuser_mdata[32*i+:32]   = dma_send[i].tuser[51-:32]; // Packet size in bytes in the lower 16 bits
            assign open_nic_shell.s_axis_qdma_h2c_sim_tuser_mty[6*i+:6]       = dma_send[i].tuser[51-32-11-:6]; // Number of invalid bytes in the last beat
            assign open_nic_shell.s_axis_qdma_h2c_sim_tuser_zero_byte         = '0;
            assign dma_send[i].tready = open_nic_shell.s_axis_qdma_h2c_sim_tready[i];

            // Assign the card to host signals
            assign dma_receive[i].tvalid               = open_nic_shell.m_axis_qdma_c2h_sim_tvalid[i];
            assign dma_receive[i].tkeep                = '1;
            assign dma_receive[i].tdata                = open_nic_shell.m_axis_qdma_c2h_sim_tdata[W_DATA*i+:W_DATA];
            assign dma_receive[i].tlast                = open_nic_shell.m_axis_qdma_c2h_sim_tlast[i];
            assign dma_receive[i].tuser[51-32-:11]     = open_nic_shell.m_axis_qdma_c2h_sim_ctrl_qid[11*i+:11];
            assign dma_receive[i].tuser[51-:32]        = '0;
            assign dma_receive[i].tuser[51-32-11-:6]   = open_nic_shell.m_axis_qdma_c2h_sim_mty[6*i+:6];
            assign open_nic_shell.m_axis_qdma_c2h_sim_tready[i] = dma_receive[i].tready;
        `endif

            initial begin
                string in_location, out_location;
                in_location  = $sformatf("%s/%s%1d.txt", SIM_LOCATION, AXIS_DMA_IN, i);
                out_location = $sformatf("%s/%s%1d.txt", SIM_LOCATION, AXIS_DMA_OUT, i);
                dma_in_reader[i]  = new (in_location, dma_send[i]);
                dma_out_writer[i] = new (out_location, dma_receive[i]);

                // Reset the interfaces
                dma_send[i].reset();
                dma_receive[i].reset();

                // Wait for the shell to reset
                @(start);
                fork
                    dma_in_reader[i].start();
                    dma_out_writer[i].start();
                join_none
            end
        end
    endgenerate

    // Assign the interfaces on the card side (CMAC side)
    generate
        for (i = 0; i < N_CARD_INTERFACES; i++) begin

        `ifdef __250mhz__
            // Assign the card to host interface
            assign open_nic_shell.box_250mhz_inst.s_axis_adap_rx_250mhz_tvalid[i]                      = phy_send[i].tvalid;
            assign open_nic_shell.box_250mhz_inst.s_axis_adap_rx_250mhz_tdata[W_DATA*i+:W_DATA]        = phy_send[i].tdata;
            assign open_nic_shell.box_250mhz_inst.s_axis_adap_rx_250mhz_tkeep[W_KEEP*i+:W_KEEP]        = phy_send[i].tkeep;
            assign open_nic_shell.box_250mhz_inst.s_axis_adap_rx_250mhz_tlast[i]                       = phy_send[i].tlast;
            assign open_nic_shell.box_250mhz_inst.s_axis_adap_rx_250mhz_tuser_size[W_SPLIT*i+:W_SPLIT] = phy_send[i].tuser[2*W_SPLIT+:W_SPLIT];
            assign open_nic_shell.box_250mhz_inst.s_axis_adap_rx_250mhz_tuser_src[W_SPLIT*i+:W_SPLIT]  = phy_send[i].tuser[W_SPLIT+:W_SPLIT];
            assign open_nic_shell.box_250mhz_inst.s_axis_adap_rx_250mhz_tuser_dst[W_SPLIT*i+:W_SPLIT]  = phy_send[i].tuser[0+:W_SPLIT];
            assign phy_send[i].tready = open_nic_shell.box_250mhz_inst.s_axis_adap_rx_250mhz_tready[i];

            // Assign the host to card interface
            assign phy_receive[i].tvalid                    = open_nic_shell.box_250mhz_inst.m_axis_adap_tx_250mhz_tvalid[i];
            assign phy_receive[i].tdata                     = open_nic_shell.box_250mhz_inst.m_axis_adap_tx_250mhz_tdata[W_DATA*i+:W_DATA];
            assign phy_receive[i].tkeep                     = open_nic_shell.box_250mhz_inst.m_axis_adap_tx_250mhz_tkeep[W_KEEP*i+:W_KEEP];
            assign phy_receive[i].tlast                     = open_nic_shell.box_250mhz_inst.m_axis_adap_tx_250mhz_tlast[i];
            assign phy_receive[i].tuser[2*W_SPLIT+:W_SPLIT] = open_nic_shell.box_250mhz_inst.m_axis_adap_tx_250mhz_tuser_size[W_SPLIT*i+:W_SPLIT];
            assign phy_receive[i].tuser[W_SPLIT+:W_SPLIT]   = open_nic_shell.box_250mhz_inst.m_axis_adap_tx_250mhz_tuser_src[W_SPLIT*i+:W_SPLIT];
            assign phy_receive[i].tuser[0+:W_SPLIT]         = ~rstn ? '0 : open_nic_shell.box_250mhz_inst.m_axis_adap_tx_250mhz_tuser_dst[W_SPLIT*i+:W_SPLIT];
            assign open_nic_shell.box_250mhz_inst.m_axis_adap_tx_250mhz_tready[i] = phy_receive[i].tready;

        `elsif __322mhz__
            // Assign the card to host interface
            assign open_nic_shell.box_322mhz_inst.s_axis_cmac_rx_tvalid[i]               = phy_send[i].tvalid;
            assign open_nic_shell.box_322mhz_inst.s_axis_cmac_rx_tdata[W_DATA*i+:W_DATA] = phy_send[i].tdata;
            assign open_nic_shell.box_322mhz_inst.s_axis_cmac_rx_tkeep[W_KEEP*i+:W_KEEP] = phy_send[i].tkeep;
            assign open_nic_shell.box_322mhz_inst.s_axis_cmac_rx_tlast[i]                = phy_send[i].tlast;
            assign open_nic_shell.box_322mhz_inst.s_axis_cmac_rx_tuser_err[i]            = phy_send[i].tuser[0];
            assign phy_send[i].tready = rstn;

            // Assign the host to card interface
            assign phy_receive[i].tvalid   = open_nic_shell.box_322mhz_inst.m_axis_cmac_tx_tvalid[i];
            assign phy_receive[i].tdata    = open_nic_shell.box_322mhz_inst.m_axis_cmac_tx_tdata[W_DATA*i+:W_DATA];
            assign phy_receive[i].tkeep    = open_nic_shell.box_322mhz_inst.m_axis_cmac_tx_tkeep[W_KEEP*i+:W_KEEP];
            assign phy_receive[i].tlast    = open_nic_shell.box_322mhz_inst.m_axis_cmac_tx_tlast[i];
            assign phy_receive[i].tuser[0] = open_nic_shell.box_322mhz_inst.m_axis_cmac_tx_tuser_err[i];
            assign open_nic_shell.box_322mhz_inst.m_axis_cmac_tx_tready[i] = phy_receive[i].tready;
        `elsif __full__
            // Assign the card to host interface
            assign open_nic_shell.s_axis_cmac_rx_sim_tvalid[i]               = phy_send[i].tvalid;
            assign open_nic_shell.s_axis_cmac_rx_sim_tdata[W_DATA*i+:W_DATA] = phy_send[i].tdata;
            assign open_nic_shell.s_axis_cmac_rx_sim_tkeep[W_KEEP*i+:W_KEEP] = phy_send[i].tkeep;
            assign open_nic_shell.s_axis_cmac_rx_sim_tlast[i]                = phy_send[i].tlast;
            assign open_nic_shell.s_axis_cmac_rx_sim_tuser_err[i]            = phy_send[i].tuser[0];
            assign phy_send[0].tready = rstn;

            // Assign the host to card interface
            assign phy_receive[i].tvalid   = open_nic_shell.m_axis_cmac_tx_sim_tvalid[i];
            assign phy_receive[i].tdata    = open_nic_shell.m_axis_cmac_tx_sim_tdata[W_DATA*i+:W_DATA];
            assign phy_receive[i].tkeep    = open_nic_shell.m_axis_cmac_tx_sim_tkeep[W_KEEP*i+:W_KEEP];
            assign phy_receive[i].tlast    = open_nic_shell.m_axis_cmac_tx_sim_tlast[i];
            assign phy_receive[i].tuser[0] = open_nic_shell.m_axis_cmac_tx_sim_tuser_err[i];
            assign open_nic_shell.m_axis_cmac_tx_sim_tready = phy_receive[i].tready;
        `endif

            initial begin
                string in_location, out_location;
                in_location  = $sformatf("%s/%s%1d.txt", SIM_LOCATION, AXIS_PHY_IN, i);
                out_location = $sformatf("%s/%s%1d.txt", SIM_LOCATION, AXIS_PHY_OUT, i);
                phy_in_reader[i]  = new (in_location, phy_send[i]);
                phy_out_writer[i] = new (out_location, phy_receive[i]);

                // Reset the interfaces
                phy_send[i].reset();
                phy_receive[i].reset();

                // Wait for the shell to reset
                @(start);
                fork
                    phy_in_reader[i].start();
                    phy_out_writer[i].start();
                join_none
            end
        end
    endgenerate

    task wait_for_readers;
        forever begin
            repeat(100) @(negedge axis_aclk);
            // If any of the readrs has not finished, try again in a while
            foreach (phy_in_reader[i])
                if (!phy_in_reader[i].get_finished())
                    continue;
            foreach (dma_in_reader[i])
                if (!dma_in_reader[i].get_finished())
                    continue;

            // Wait some time then signal the writers to stop
            repeat(100) @(negedge axis_aclk);
            FileWriter#()::finish();
            return;
        end
    endtask

    initial begin
        string location_in, location_out;
        location_in  = $sformatf("%s/%s.txt", SIM_LOCATION, AXIL_IN);
        location_out = $sformatf("%s/%s.txt", SIM_LOCATION, AXIL_OUT);
        registers = new(location_in, location_out, axil);
        axil.reset();

        // Reset the shell
        rstn  =  1'b0;
        @(posedge rst_done);
        rstn <=  1'b1;
        repeat(100) @(negedge axis_aclk);

        // Assign the number of queues
        axil.write_register(32'h0000_1000, NUM_QUEUE);
        repeat(100) @(negedge axis_aclk);
        -> start;

        fork
            // Start the register file reader/writer
            registers.start();

            // Wait until all files are read then stop
            wait_for_readers();
        join

        repeat(100) @(negedge axis_aclk);
        $stop;
    end
endmodule