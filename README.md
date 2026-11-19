# IHP SG13G2 AXI4 / AXI-Lite DMA Controller

[[https://github.com/NiranjankumarKatragadda/ihp-sg13g2-axi4-dma/actions/workflows/ci.yml/badge.svg]](https://github.com/NiranjankumarKatragadda/ihp-sg13g2-axi4-dma/actions/workflows/ci.yml)
[[https://img.shields.io/badge/PDK-IHP%20SG13G2%20130nm-darkblue]](https://github.com/IHP-GmbH/IHP-Open-PDK)
[[https://img.shields.io/badge/Flow-LibreLane%20v3-green]](https://github.com/librelane/librelane)
[[https://img.shields.io/badge/License-Apache%202.0-blue.svg]](LICENSE)

Synthesizable 32-bit DMA engine with an AXI4-Lite CSR slave and an AXI4 master issuing multi-beat INCR bursts (up to 16 beats). Hardened on **IHP SG13G2 (130nm BiCMOS)** via LibreLane and verified with `cocotbext-axi` (Verilator 5.020) plus pad-level RTL & Gate-Level CI (Icarus Verilog).

## Architecture
- `src/axi4_dma.v`: AXI4-Lite CSR slave, AXI4 master read/write FSM, and `irq` output.
- `src/chip_core.sv`: Padframe wrapper with an on-chip 16 x 32-bit scratchpad AXI slave for standalone RTL and gate-level sign-off.

## Register map (AXI4-Lite)

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | `CTRL` | `[0]` `go` (write `1` to launch transfer) |
| `0x04` | `STATUS` | `[0]` `done`, `[1]` `busy` (`st != IDLE`) |
| `0x08` | `SRC` | 32-bit source byte address |
| `0x0C` | `DST` | 32-bit destination byte address |
| `0x10` | `WORDS` | `[15:0]` transfer length in 32-bit words |

## Behavior and limits
- **Burst type & max length:** INCR bursts only (`AWLEN`/`ARLEN` up to `15`, 16 beats max per burst), 32-bit word-aligned.
- **Multi-burst splitting:** Transfers longer than 16 words split automatically into sequential chunks of up to 16 beats (`20` words executes as `16 + 4`).
- **Completion:** `done` and `irq` assert after the final `BVALID & BREADY` handshake completes.

## Physical design configuration & CI status

| Metric | Value |
| --- | --- |
| Technology | IHP SG13G2 (130nm BiCMOS) |
| Flow | LibreLane v3 (`Chip` flow, `librelane-nodrc` in CI) |
| Clock target | 50 MHz (`CLOCK_PERIOD: 20` ns) |
| Die / core area | `1600 x 1600 um^2` / `870 x 870 um^2` (`10%` target density) |
| CI status | RTL sim + LibreLane PnR + GDS upload + GL sim PASS ([run 44108818810](https://github.com/NiranjankumarKatragadda/ihp-sg13g2-axi4-dma/actions/runs/44108818810)) |

## Verification

| Testbench | What it checks | Simulator |
| --- | --- | --- |
| `cocotb/test_axi_dma.py` | `TESTS=2 PASS=2` (0.05s): 4-beat and 20-word (`16 + 4` beat) INCR bursts via `AxiLiteMaster` + `AxiRam` | Verilator 5.020 |
| `cocotb/chip_top_tb.py` | Full-chip pad-level RTL and post-PnR gate-level netlist checks | Icarus Verilog |

## Reproduce

    git clone https://github.com/NiranjankumarKatragadda/ihp-sg13g2-axi4-dma.git
    cd ihp-sg13g2-axi4-dma
    make -f cocotb/Makefile.dma
    nix develop --command make sim && nix develop --command make librelane-nodrc && nix develop --command make sim-gl

## Need something similar?
NK Verif Labs offers verification and RTL-to-GDSII services. Email **nkveriflabs@gmail.com**.

## License
Apache-2.0. See [LICENSE](LICENSE).
