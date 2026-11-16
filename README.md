# IHP SG13G2 AXI4 / AXI-Lite DMA Controller

[[https://github.com/NiranjankumarKatragadda/ihp-sg13g2-axi4-dma/actions/workflows/ci.yml/badge.svg]](https://github.com/NiranjankumarKatragadda/ihp-sg13g2-axi4-dma/actions/workflows/ci.yml)
[[https://img.shields.io/badge/PDK-IHP%20SG13G2%20130nm-darkblue]](https://github.com/IHP-GmbH/IHP-Open-PDK)
[[https://img.shields.io/badge/Flow-LibreLane-green]](https://github.com/librelane/librelane)

Synthesizable 32-bit AXI4-Lite CSR + AXI4 Master DMA engine hardened on **IHP SG13G2 (130nm BiCMOS)** via LibreLane, verified with **Cocotb + cocotbext-axi** (Verilator 5.020) and full RTL/Gate-Level CI (Icarus Verilog).

## Architecture
- `src/axi4_dma.v`: AXI4-Lite CSR slave (`0x00` CTRL, `0x04` STATUS, `0x08` SRC, `0x0C` DST, `0x10` WORDS) + AXI4 master read/write FSM + `irq`.
- `src/chip_core.sv`: Padframe wrapper with an on-chip 16×32-bit scratchpad AXI slave for standalone RTL & gate-level sign-off.
- `cocotb/test_axi_dma.py`: `cocotbext-axi` (`AxiLiteMaster` + `AxiRam`) DMA copy test on Verilator 5.020.
- `cocotb/chip_top_tb.py`: Full-chip pad-level RTL & Gate-Level Cocotb testbench.
