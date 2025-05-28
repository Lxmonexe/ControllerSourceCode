import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiLiteMaster, AxiLiteBus

async def clk_gen(dut, period1_ns=30):  
    """ Clock generator """
    cocotb.start_soon(Clock(dut.clk, period1_ns, units="ns").start())
    

async def master_gen(dut):
    """ AXI Master generator """
    axi_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "S00_AXI"))
    await axi_master.reset()


@cocotb.test()
async def run_test(dut):
    """ Run the testbench """
    
    await clk_gen(dut)   
    axi_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s00_axi"))
    await axi_master.reset()  # Reset the AXI master

    await Timer(10000, units="ns")  # Wait for reset to complete

    
    await axi_master.write(0x1, 0x2)

    while True:
        controller_ready = await axi_master.read(0x0)
        if( controller_ready % 2 == 0):
            print("reset done")
            break
    
    # READ ID command
    await axi_master.write(0x2, 0x2)

    # Start the controller
    await axi_master.write(0x1, 0x1)

    while True:
        controller_ready = await axi_master.read(0x0)
        if( controller_ready & 0b1000000000001 != 0):
            print("controller ready and command done")
            break

    # Stop the controller
    await axi_master.write(0x0, 0x1)  # Stop the controller

    await Timer(100, units="ns")  # Wait for the controller to stop