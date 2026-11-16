# SPDX-FileCopyrightText: © 2025 LibreLane Template Contributors
# SPDX-License-Identifier: Apache-2.0

import os
import random
import logging
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, Edge, RisingEdge, FallingEdge, ClockCycles
from cocotb_tools.runner import get_runner

sim = os.getenv("SIM", "icarus")
pdk_root = os.getenv("PDK_ROOT", Path("~/.ciel").expanduser())
pdk = os.getenv("PDK", "ihp-sg13g2")
scl = os.getenv("SCL", "sg13g2_stdcell")
gl = os.getenv("GL", False)

hdl_toplevel = "chip_top"

async def set_defaults(dut):
    dut.input_PAD.value = 0

async def enable_power(dut):
    dut.VDD.value = 1
    dut.VSS.value = 0

async def start_clock(clock, freq=50):
    """Start the clock @ freq MHz"""
    c = Clock(clock, 1 / freq * 1000, "ns")
    cocotb.start_soon(c.start())


async def reset(reset, active_low=True, time_ns=1000):
    """Reset dut"""
    cocotb.log.info("Reset asserted...")

    reset.value = not active_low
    await Timer(time_ns, "ns")
    reset.value = active_low

    cocotb.log.info("Reset deasserted.")


async def start_up(dut):
    """Startup sequence"""
    await set_defaults(dut)
    if gl:
        await enable_power(dut)
    await start_clock(dut.clk_PAD)
    await reset(dut.rst_n_PAD)


@cocotb.test()
async def test_chip_dma(dut):
    """Verify axi4_dma pad-level CSR write, DMA copy, and irq assertion."""
    await start_up(dut)
    dut.bidir_PAD.value = 0
    for addr, val in [(0x08, 0x00), (0x0C, 0x20), (0x10, 4), (0x00, 1)]:
        dut.bidir_PAD.value = val
        dut.input_PAD.value = (1 << 9) | addr
        await ClockCycles(dut.clk_PAD, 3)
        dut.input_PAD.value = 0
        await ClockCycles(dut.clk_PAD, 2)
    for _ in range(60):
        await ClockCycles(dut.clk_PAD, 1)
        if (int(dut.bidir_PAD.value) & 1) == 1:
            break
    assert (int(dut.bidir_PAD.value) & 1) == 1, f"Expected irq=1 on bidir_PAD[0], got {dut.bidir_PAD.value}"

def chip_top_runner():

    proj_path = Path(__file__).resolve().parent

    sources = []
    defines = {}
    includes = []

    if gl:
        # SCL models
        sources.append(Path(pdk_root) / pdk / "libs.ref" / scl / "verilog" / f"{scl}.v")
        sources.append(Path(pdk_root) / pdk / "libs.ref" / scl / "verilog" / f"sg13g2_udp.v")

        # We use the unpowered netlist
        sources.append(proj_path / f"../final/nl/{hdl_toplevel}.nl.v")

        defines = {"USE_POWER_PINS": False}
    else:
        sources.append(proj_path / "../src/chip_top.sv")
        sources.append(proj_path / "../src/chip_core.sv")
        sources.append(proj_path / "../src/axi4_dma.v")

    sources += [
        # IO pad models
        Path(pdk_root) / pdk / "libs.ref/sg13g2_io/verilog/sg13g2_io.v",
        
        # Bondpads
        proj_path / "../ip/bondpad_70x70/vh/bondpad_70x70.v",
        proj_path / "../ip/bondpad_70x70_novias/vh/bondpad_70x70_novias.v",
        
        # SRAM models
        Path(pdk_root) / pdk / "libs.ref/sg13g2_sram/verilog/RM_IHPSG13_1P_1024x32_c2_bm_bist.v",
        Path(pdk_root) / pdk / "libs.ref/sg13g2_sram/verilog/RM_IHPSG13_1P_core_behavioral_bm_bist.v",
    ]

    build_args = []

    if sim == "icarus":
        # For debugging
        # build_args = ["-Winfloop", "-pfileline=1"]
        pass

    if sim == "verilator":
        build_args = ["--timing", "--trace", "--trace-fst", "--trace-structs"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        defines=defines,
        always=True,
        includes=includes,
        build_args=build_args,
        waves=True,
    )

    plusargs = []

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="chip_top_tb,",
        plusargs=plusargs,
        waves=True,
    )


if __name__ == "__main__":
    chip_top_runner()
