import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiBus, AxiRam, AxiLiteBus, AxiLiteMaster

@cocotb.test()
async def test_axi4_dma_copy(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    await Timer(40, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    axil = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.clk, dut.rst_n, reset_active_level=False)
    ram = AxiRam(AxiBus.from_prefix(dut, "m_axi"), dut.clk, dut.rst_n, reset_active_level=False, size=2**16)
    payload = b"\xDE\xAD\xBE\xEF\xCA\xFE\xBA\xBE\x12\x34\x56\x78\xAA\x55\x00\xFF"
    ram.write(0x0100, payload)
    await axil.write_dword(0x08, 0x0100)
    await axil.write_dword(0x0C, 0x0200)
    await axil.write_dword(0x10, 4)
    await axil.write_dword(0x00, 1)
    for _ in range(100):
        await RisingEdge(dut.clk)
        if int(dut.irq.value) == 1: break
    assert int(dut.irq.value) == 1, "DMA did not complete"
    assert ram.read(0x0200, 16) == payload, "DMA data mismatch!"
    dut._log.info("PASS: AXI4 DMA copied 16 bytes cleanly via cocotbext-axi!")
