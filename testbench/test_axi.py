import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiLiteMaster, AxiLiteBus

async def clk_gen(dut,clk, period1_ns=30, period2_ns=10):  
    """ Clock generator """
    cocotb.start_soon(Clock(dut.clk, period1_ns, units="ns").start())
    cocotb.start_soon(Clock(clk, period2_ns, units="ns").start())

@cocotb.test()
async def run_test(dut):
    """ Run the testbench """
    
    clk = dut.s00_axi_aclk
    rst = dut.s00_axi_aresetn
    controller_ready = None
    await clk_gen(dut, clk)   
    axi_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s00_axi"), clk, rst,reset_active_level=False)
   

    
    
    rst.value = 0
    for _ in range(5):
        await RisingEdge(clk)
    rst.value = 1
    await RisingEdge(clk)

    await Timer(11000, units="ns")  # Wait for the controller to be ready


    # Reset the controller
    await axi_master.write(0x00008, (1).to_bytes(4, 'little'))  
    await axi_master.write(0x00004, (1).to_bytes(4, 'little'))
    
    
    
    while True:
        resp = await axi_master.read(0x00000, 4)
        data = int.from_bytes(resp.data, byteorder="little")
        if data & (1 << 0):  # Vérifie si le bit 0 est à 1
            print("reset done")
            await axi_master.write(0x00004, (0).to_bytes(4, 'little'))
            break
        await Timer(100, units="ns")  # Petite pause pour éviter de surcharger la simulation

    await Timer(5000, units="ns")

    # READ ID command
    await axi_master.write(0x00008, (2).to_bytes(4, 'little'))
    await Timer(30, units="ns")
    await axi_master.write(0x4, (1).to_bytes(4, 'little'))

    while True:
        resp = await axi_master.read(0x00000, 4)
        data = int.from_bytes(resp.data, byteorder="little")
        if (data & (1 << 0)) and (data & (1 << 1)):  # Vérifie bit 0 et bit 13
            
            await axi_master.write(0x00004, (0).to_bytes(4, 'little')) 
            print("command done")
            break
        await Timer(100, units="ns")

        
    await axi_master.write(0x30000, (10).to_bytes(4, 'little'))
    await axi_master.write(0x30000, (10).to_bytes(4, 'little'))
    await axi_master.write(0x30000, (10).to_bytes(4, 'little'))
    await axi_master.write(0x30000, (10).to_bytes(4, 'little'))
    await axi_master.write(0x30004, (160).to_bytes(4, 'little'))
    await axi_master.write(0x30000, (10).to_bytes(4, 'little'))
    await axi_master.write(0x30004, (160).to_bytes(4, 'little'))
    await axi_master.write(0x30000, (10).to_bytes(4, 'little'))
    await axi_master.write(0x30004, (160).to_bytes(4, 'little'))
    await axi_master.write(0x30008, (1212).to_bytes(4, 'little'))
    await axi_master.write(0x3000C, (54655).to_bytes(4, 'little'))
    await axi_master.write(0x30010, (515).to_bytes(4, 'little'))
    await axi_master.write(0x30014, (789).to_bytes(4, 'little'))

    await Timer(100, units="ns")

    await axi_master.read(0x30000, 4)
    await axi_master.read(0x30010, 4)
    
    

    
    await Timer(5000, units="ns")  # Wait for the controller to stop