# pong-fpga

Two-player Pong in VHDL for the Digilent Arty A7-35T, output on a VGA monitor through a Pmod VGA adapter.
Project for the FPGA & VHDL course at DHBW (2026).

## Status

Work in progress. Submission is due 17.11.2026; the demo follows on 18.11 or 25.11.2026.

## Requirements

See [docs/requirements.md](docs/requirements.md): the course brief as numbered requirements, the grading scheme,
a suggested module split and open questions.

## Hardware

- Digilent Arty A7-35T (`xc7a35ticsg324-1L`)
- Digilent Pmod VGA
- Monitor with VGA input and a VGA cable
- Buttons BTN0 to BTN3: two per player (up/down)

## Repository layout

| Path | Content |
|---|---|
| `src/` | synthesizable VHDL |
| `sim/` | testbenches |
| `constraints/` | `.xdc` pin and clock constraints (Digilent Arty A7-35 master file from the course, all pins commented out) |
| `docs/` | requirements and design notes |
| `vivado/` | Vivado project (`pong.xpr`); only the `.xpr` is tracked |
| `create_project.tcl` | recreates `vivado/` from the repo: `vivado -mode batch -source create_project.tcl` |

## Rules

All code in this repository is written by the group. Nothing is copied from the internet (course rule).
