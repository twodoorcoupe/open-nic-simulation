package open_nic_file_tools;
    parameter int W_DATA = 512;
    parameter int W_KEEP = W_DATA / 8;

    // Names of the axi files read and written by the testbench
    parameter string AXIS_DMA_IN  = "axi_in_dma";
    parameter string AXIS_DMA_OUT = "axi_out_dma";
    parameter string AXIS_PHY_IN  = "axi_in_phy";
    parameter string AXIS_PHY_OUT = "axi_out_phy";
    parameter string AXIL_IN      = "axi_in_registers";
    parameter string AXIL_OUT     = "axi_out_registers";

    // Special characters in the axi files
    parameter string HEX_CHARACTERS = "0123456789abcdefABCDEF-";
    parameter string TIME_COMMANDS = "@+*";
    parameter string AXIS_COMMANDS = {"?!", TIME_COMMANDS};
    parameter string AXIL_COMMANDS = {"!", TIME_COMMANDS};

    `include "make_delay.svh"
    `include "string_utils.svh"
    `include "file_reader.svh"
    `include "file_writer.svh"
    `include "file_registers.svh"
endpackage