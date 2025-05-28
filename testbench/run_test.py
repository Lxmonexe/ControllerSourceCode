import os
import pytest
from cocotb_test.simulator import run

os.environ["WAVES"] = "1"
os.environ["SIM"] = "questa"
os.environ["TOPLEVEL_LANG"] = "vhdl"

vhdl_src=[
          "../log_pkg.vhd", 
          "../onfi_package.vhd",
          "../latch_address.vhd",
          "../latch_command.vhd",
          "../PHY.vhd",
          "../read_data.vhd",
          "../write_data.vhd",
          "../Controller_top.vhd",
          "../true_dual_port_bram.vhd",
          "../Axi_top_slave_lite_v1_0_S00_AXI.vhd",
          "../Axi_top.vhd"
          ]

verilog_src=["../nand_model/nand_model.v",
            "../nand_model/nand_die_model.v"]

systemverilog_src=["../nand_model/nand_defines.vh",
                   "../nand_model/nand_parameters.vh"]

def test_all():
    run(
        vhdl_sources=vhdl_src,
        verilog_sources=verilog_src,
        systemverilog_sources=systemverilog_src,
        toplevel="Axi_top",            # top level HDL
        module="test_axi",        # name of cocotb test module
        vhdl_compile_args=["-2008"],
        sim_args=["-voptargs=+acc=rn","-t","1ps"],

    )
