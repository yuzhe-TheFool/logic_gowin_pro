# FoLogic HDL

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-red.svg)](https://www.gnu.org/licenses/gpl-3.0)

**FoLogic** is an open-source 16-channel 200MHz logic analyzer based on
**FPGA + USB 2.0 PHY (CY7C68013A)** architecture.

This repository contains the **FPGA HDL source code** for the FoLogic logic analyzer,
implemented on **Gowin GW2A-18 FPGA** (LogiPi G1 core board) with DDR3 SDRAM support.

## Project Structure

```
logic/
├── src/                          # HDL source files
│   ├── logic_top.v               # Top-level module
│   ├── sample_clock_gen.v        # Sample clock generation with prescaler
│   ├── sample_trig.v             # Trigger matching (edge/level/mask)
│   ├── data_capture.v            # Capture control (buffer/stream mode)
│   ├── data_read.v               # Data readout and USB interface
│   ├── cy_config_decoder.v       # USB TLV command decoder
│   ├── cy_config_reg.v           # Configuration register file
│   ├── axi4_control.v            # AXI4 master controller
│   ├── axi4_wcontrol.v           # AXI4 write channel
│   ├── axi4_rcontrol.v           # AXI4 read channel
│   ├── axi4_ddr_unit.v           # DDR3 memory interface wrapper
│   ├── gowin_rpll/               # Gowin PLL IP (100MHz core clock)
│   ├── gowin_rpll1/              # Gowin PLL IP (sample clock)
│   ├── fifo_hs/                  # Write FIFO (Gowin IP)
│   ├── rfifo_hs/                 # Read FIFO (Gowin IP)
│   ├── consfifo_hs/              # Continuous mode FIFO (Gowin IP)
│   └── ddr3_memory_interface/    # DDR3 controller (Gowin IP)
├── impl/                         # Gowin implementation results
└── logic.gprj                    # Gowin IDE project file
```

## Architecture

The system uses a **three-layer architecture**:

| Layer | Component | Function |
|-------|-----------|----------|
| **PC Host** | sigrok/PulseView | Device management, waveform display, protocol decoding |
| **FX2 Controller** | CY7C68013A | USB protocol bridge, GPIF bus control, command dispatch |
| **FPGA Logic** | GW2A-18 | High-speed sampling, trigger matching, DDR3 caching |

### Data Flow

**Buffer mode** (high-speed capture):
```
PC → USB EP0 → FX2 → GPIF → FPGA config → IDDR sampling → DDR3 → GPIF read → USB EP6 → PC
```

**Stream mode** (continuous capture):
```
PC → USB EP0 → FX2 → GPIF → FPGA config → sampling → cons_fifo → EP6 AUTOIN → USB → PC
```

## Key Features

- **16 channels** parallel sampling
- **200MHz** max sample rate (100MHz core + IDDR dual-edge)
- **Up to 2GB** DDR3 SDRAM storage
- **Buffer & Stream** dual-mode data acquisition
- **Hardware trigger**: edge (rise/fall/both), level (high/low), mask trigger
- **USB 2.0 High-Speed** (480Mbps, ~40MB/s effective bandwidth)
- **Compatible with sigrok/PulseView** for waveform display and protocol decoding

## Build Instructions

1. Install [Gowin EDA](https://www.gowinsemi.com/) (V1.9.12.03 or later)
2. Open `logic/logic.gprj` in Gowin IDE
3. Run **Synthesis → Place & Route → Generate Bitstream**
4. The output files will be in `logic/impl/pnr/`

## Related Repositories

| Repository | Description |
|------------|-------------|
| [FoLogic-fw-keil-master](https://github.com/yuzhe-TheFool/FoLogic-fw-keil-master) | FX2LP (CY7C68013A) firmware source code (Keil C51) |
| [pulseview](https://github.com/yuzhe-TheFool/pulseview) | Host software for waveform display, protocol decoding ([Releases](https://github.com/yuzhe-TheFool/pulseview/releases/tag/tag1)) |

## License

This project is licensed under the **GNU General Public License v3 or later** (GPL-3.0-or-later).

Some components are third-party IP:
- **Gowin PLL/FIFO/DDR3 IP** — Property of Gowin Semiconductor
- **DDR3 Model** — Property of Micron Technology
- **FX2 Simulation Model** — Original work, GPL v3

## References

- [DreamSourceLab/DSLogic-hdl](https://github.com/DreamSourceLab/DSLogic-hdl) — Reference FPGA HDL design
- [DreamSourceLab/DSLogic-fw-keil](https://github.com/DreamSourceLab/DSLogic-fw-keil) — Original FX2 firmware reference
- [sigrok/PulseView](https://sigrok.org/wiki/Main_Page) — Upstream host software
