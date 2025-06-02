import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiLiteMaster, AxiLiteBus

async def clk_gen(dut, period1_ns=30):  
    """ Clock generator """
    cocotb.start_soon(Clock(dut.clk, period1_ns, units="ns").start())
    

@cocotb.test()
async def run_test(dut):
    """ Run the testbench """
    
    await clk_gen(dut)   
    axi_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s00_axi"), dut.clk, dut.rst)
   

    await Timer(10010, units="ns")  # Wait for power up to complete

    # Reset the controller
    await axi_master.write(0x2, b'1')  
    print("reset command sent")

    await axi_master.write(0x1, b'1')
    print("start reset command")
    
    while True:
        controller_ready = await axi_master.read(0x0,b'32')
        if( controller_ready % 2 == 0):
            print("reset done")
            break
    
    await axi_master.write(0x1, b'0')

    # READ ID command
    await axi_master.write(0x2, b'2')

    # Start the controller
    await axi_master.write(0x1, b'1')

    while True:
        controller_ready = await axi_master.read(0x0,b'32')
        if( controller_ready & 0b1000000000001 != 0):
            print("controller ready and command done")
            break

    # Stop the controller
    await axi_master.write(0x1, b'0') 

    await Timer(100, units="ns")  # Wait for the controller to stop