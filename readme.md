# ONFI Controller Project

## Introduction

This project implements an ONFI-compliant NAND Flash controller with an AXI4-Lite interface, written in VHDL. It includes a cocotb-based Python testbench for simulation and verification. The design supports command, address, data latching, and features a dual-port BRAM for data buffering.

---

## Repository Structure

```
ControllerSourceCode/
├── log_pkg.vhd
├── onfi_package.vhd
├── latch_address.vhd
├── latch_command.vhd
├── read_data.vhd
├── write_data.vhd
├── PHY.vhd
├── Controller_top.vhd
├── true_dual_port_bram.vhd
├── Axi_top_slave_lite_v1_0_S00_AXI.vhd
├── axi_top.vhd
├── testbench/
│   └── test_axi.py
│   └── run_test.py
├── nand_model/
│   └── nand_model.v
│   └── nand_die_model.v
│   └── nand_defines.vh
│   └── nand_parameters.vh
```

---

## HDL Components

- **Controller_top.vhd**: Main ONFI controller FSM and glue logic.
- **axi_top.vhd**: Top-level entity, connects AXI interface and controller.
- **Axi_top_slave_lite_v1_0_S00_AXI.vhd**: AXI4-Lite slave implementation.
- **PHY.vhd**: Physical interface to NAND flash.
- **true_dual_port_bram.vhd**: Dual-port BRAM for data buffering.
- **latch_command.vhd, latch_address.vhd, write_data.vhd, read_data.vhd**: FSMs for ONFI command, address, write, and read operations.
- **log_pkg.vhd, onfi_package.vhd**: Utility and type packages.

---

## Testbench & Simulation

- **testbench/test_axi.py**: Python cocotb testbench for AXI and controller verification.
- **testbench/run_test.py**: Simulation runner using cocotb-test.

### Example Testbench Flow

- Resets the controller and AXI interface.
- Sends ONFI commands via AXI.
- Writes and reads data to/from BRAM.
- Checks controller status and prints results.

---

## Build & Simulation Instructions

### Prerequisites

- QuestaSim/ModelSim or Vivado (for VHDL simulation)
- Python 3.8+
- cocotb and cocotb-test (Python packages)

### Steps

1. **Install Python dependencies**  
   ```sh
   pip install cocotb cocotb-test cocotbext-axi
   ```

2. **Run the testbench**  
   ```sh
   pytest -o log cli=True testbench/run_test.py
   ```

3. **View simulation results**  
   - Output is printed to the terminal.
   - Check for `reset done` and `command done` messages.

---

## Configuration & Customization

- **AXI parameters**: Data width, address width can be adjusted in VHDL sources.
- **Timing parameters**: Modify clock periods in `test_axi.py` and VHDL files.
- **BRAM size**: Change in `true_dual_port_bram.vhd`.

---

## Usage Examples

### Write Data to BRAM

```python
for i in range(2300):
    await axi_master.write(0x30000 + i * 4, i.to_bytes(4, 'little'))
```

### Send ONFI Command

```python
await axi_master.write(0x00008, (2).to_bytes(4, 'little'))  # Example command
await axi_master.write(0x00004, (1).to_bytes(4, 'little'))  # Start command
```

---

---

## References

- [ONFI Specification](https://www.onfi.org/)
- [AXI4-Lite Protocol](https://developer.arm.com/documentation/ihi0022/latest/)
- [NAND-Avalon](https://github.com/nbstrong/nand_avalon/tree/master)
