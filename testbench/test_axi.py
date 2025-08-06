import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiLiteMaster, AxiLiteBus

async def clk_gen(dut,clk, period1_ns=10, period2_ns=8):  
    """ Clock generator """
    cocotb.start_soon(Clock(dut.clk_controller_i, period1_ns, units="ns").start())
    cocotb.start_soon(Clock(clk, period2_ns, units="ns").start())

@cocotb.test()
async def run_test(dut):
    """ Run the testbench """
    
    clk = dut.s00_axi_aclk
    rst = dut.s00_axi_aresetn
    dut.dbg_btn_i.value = 0
    controller_ready = None
    await clk_gen(dut, clk)   
    axi_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s00_axi"), clk, rst,reset_active_level=False)
   
    
    
    
    rst.value = 0
    for _ in range(5):
        await RisingEdge(clk)
    rst.value = 1
    await RisingEdge(clk)

    await Timer(12000, units="ns")  # Wait for the controller to be ready
    
    dut.dbg_btn_i.value = 1
    

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
        await Timer(1000, units="ns")  # Petite pause pour éviter de surcharger la simulation

    

    # READ ID command

    await axi_master.write(0x0000c, (32).to_bytes(4, 'little'))
    await Timer(300, units="ns")
    await axi_master.write(0x00008, (2).to_bytes(4, 'little'))
    await Timer(300, units="ns")
    await axi_master.write(0x00004, (1).to_bytes(4, 'little'))

    while True:
        resp = await axi_master.read(0x00000, 4)
        data = int.from_bytes(resp.data, byteorder="little")
        if (data & (1 << 0)) and (data & (1 << 1)):  # Vérifie bit 0 et bit 1
            
            await axi_master.write(0x00004, (0).to_bytes(4, 'little')) 
            print("command done")
            break
        await Timer(1000, units="ns")

    for i in range(2300):
        await axi_master.write(0x30000 + i * 4, (151520258).to_bytes(4, 'little'))

    await axi_master.write(0x0000c, (67108864).to_bytes(4, 'little'))
    await Timer(300, units="ns")
    await axi_master.write(0x00008, (32800).to_bytes(4, 'little'))
    await Timer(300, units="ns")
    await axi_master.write(0x00004, (1).to_bytes(4, 'little'))

    while True:
        resp = await axi_master.read(0x00000, 4)
        data = int.from_bytes(resp.data, byteorder="little")
        if (data & (1 << 0)) and (data & (1 << 1)):  # Vérifie bit 0 et bit 1
            
            await axi_master.write(0x00004, (0).to_bytes(4, 'little')) 
            print("command done")
            break
        await Timer(1000, units="ns")

    await Timer(300, units="ns")
    await axi_master.write(0x00008, (33808).to_bytes(4, 'little'))
    await Timer(300, units="ns")
    await axi_master.write(0x00004, (1).to_bytes(4, 'little'))

    while True:
        resp = await axi_master.read(0x00000, 4)
        data = int.from_bytes(resp.data, byteorder="little")
        if (data & (1 << 0)) and (data & (1 << 1)):  # Vérifie bit 0 et bit 1
            
            await axi_master.write(0x00004, (0).to_bytes(4, 'little')) 
            print("command done")
            break
        await Timer(1000, units="ns")

    await Timer(5000, units="ns")  # Wait for the controller to stop