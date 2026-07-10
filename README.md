# FoLogic-fw-keil

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-red.svg)](https://www.gnu.org/licenses/gpl-3.0)

**FoLogic-fw** is an open-source firmware for **FoLogic** — a 16-channel 200MHz logic analyzer
based on **FPGA + USB 2.0 PHY (CY7C68013A)** architecture.

This firmware runs on the **Cypress EZ-USB FX2LP (CY7C68013A)** microcontroller,
handling USB protocol, GPIF bus control, and command dispatching between the
PC host and the FPGA logic.

This project is derived from [DreamSourceLab/DSLogic-fw-keil](https://github.com/DreamSourceLab/DSLogic-fw-keil),
with significant modifications and enhancements for the FoLogic logic analyzer platform.

## Project Structure

| Directory/File       | Description                              |
|----------------------|------------------------------------------|
| `Source/`            | Firmware source code                     |
| `Source/include/`    | Header files (Fx2, registers, etc.)      |
| `Output/`            | Compiled binary output                   |
| `FoLogic.uvproj`     | Keil uVision project file                |
| `hex2bix.exe`        | Cypress hex2bix converter utility         |

## Components

The firmware consists of the following source files:

| File                | Description                                                    |
|---------------------|----------------------------------------------------------------|
| `FoLogic.c`         | Main logic: command processing, GPIF control, endpoint setup   |
| `interface.c`       | GPIF waveform definitions, capture start/stop, interface switching |
| `fw.c`              | Cypress firmware framework: USB task dispatcher, device request parser |
| `dscr.a51`          | USB descriptor table (device/config/string descriptors)        |

## Build Instructions

1. Install [Keil C51](https://www.keil.com/c51/) IDE
2. Open `FoLogic.uvproj` in Keil uVision
3. Build the project (**Project → Build Target**)
4. The compiled firmware will be generated in the `Output/` directory:
   - `FoLogic.fw` - Firmware image for Cypress FX2
   - `FoLogic.iic` - I2C EEPROM image for boot loading

> **Note:** The build process automatically runs `hex2bix` to convert the HEX output
> to `.fw` and `.iic` formats suitable for FX2 loading.

## Hardware Platform

| Component         | Specification                                       |
|-------------------|-----------------------------------------------------|
| **USB Controller**| Cypress CY7C68013A (EZ-USB FX2LP), 48MHz           |
| **FPGA**          | Gowin GW2A-18 (LogiPi G1 core board)               |
| **DDR3**          | Compatible with DDR3-800, up to 2GB                 |
| **Sampling**      | 16 channels, up to 200MHz (DDR, IDDR dual-edge)    |
| **Interface**     | GPIF FIFO (30MHz, 16-bit)                           |
| **USB Speed**     | USB 2.0 High-Speed (480Mbps, ~40MB/s effective)    |

## Related Repositories

| Repository | Description |
|------------|-------------|
| [logic_gowin_pro](https://github.com/yuzhe-TheFool/logic_gowin_pro) | FPGA HDL source code (Gowin GW2A-18) |
| [pulseview](https://github.com/yuzhe-TheFool/pulseview) | Host software for waveform display, protocol decoding ([Releases](https://github.com/yuzhe-TheFool/pulseview/releases/tag/tag1)) |

## License

FoLogic-firmware is licensed under the **GNU General Public License v3 or later** (GPL-3.0-or-later).

It uses additional library EZUSB.lib, provided by Cypress (http://www.cypress.com).

This project is a derivative work of [DSLogic-fw-keil](https://github.com/DreamSourceLab/DSLogic-fw-keil)
by DreamSourceLab, which is licensed under GPL v2 or later.

## References

- [DreamSourceLab/DSLogic-fw-keil](https://github.com/DreamSourceLab/DSLogic-fw-keil) — Original reference project
- [DreamSourceLab/DSLogic-hdl](https://github.com/DreamSourceLab/DSLogic-hdl) — Reference FPGA HDL design
- [sigrok/PulseView](https://sigrok.org/wiki/Main_Page) — Upstream host software
