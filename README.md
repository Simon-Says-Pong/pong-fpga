# pong-fpga

Two-player Pong in VHDL for the Digilent Arty A7-35T, output on a VGA monitor through a Pmod VGA adapter.
Project for the FPGA & VHDL course at DHBW (2026).

## Status
Submission was due 17.11.2026; the demo follows on 25.11.2026.

## Requirements

See [docs/requirements.md](docs/requirements.md): the course brief as numbered requirements, the grading scheme,
a suggested module split and open questions.

## Hardware

- Digilent Arty A7-35T (`xc7a35ticsg324-1L`)
- Digilent Pmod VGA
- Monitor with VGA input and a VGA cable
- Buttons `btn[0]` to `btn[3]`: two per player (up/down); red RESET button (`ck_rst`) resets the whole design

## Getting started

Requires **Vivado 2026.1** (the Clocking Wizard IP is locked to this version).

1. Clone the repo:

   ```bash
   git clone https://github.com/Simon-Says-Pong/pong-fpga.git
   ```

2. Build the Vivado project from the repo, either from a terminal in the repo root:

   ```bash
   vivado -mode batch -source create_project.tcl
   ```

   (if `vivado` is not on the PATH: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat` or your install path),
   or in the Vivado **Tcl Console**:

   ```
   cd C:/path/to/pong-fpga
   source create_project.tcl
   ```

   The script creates `vivado/pong.xpr` for `xc7a35ticsg324-1L`, adds `src/`, `sim/`, the XDC and the
   Clocking Wizard (`ip/clk_wiz_0`), regenerates the IP output products and sets all `.vhd` files to VHDL 2008.

3. Open `vivado/pong.xpr`.

Alternative: open the committed `vivado/pong.xpr` directly. Then right-click `clk_wiz_0` under
*IP Sources* → **Generate Output Products** once, because only the `.xci` is in git.

### Working rules

- **Close the project before running the script**; it overwrites `vivado/`.
- **New files go into `src/` (design) or `sim/` (testbenches).** In *Add Sources*, untick
  *Copy sources into project*, and set the file type to VHDL 2008. Files created in Vivado's default location
  end up in `vivado/pong.srcs/` and never reach git.
- **`vivado/pong.xpr` changes on every open and run.** Commit it only for intentional project-setting changes,
  otherwise discard it: `git restore vivado/pong.xpr`.
- **Do not upgrade the IP** if Vivado offers to; that rewrites the `.xci` for everyone.
- **Top-level port names must match the XDC:** `CLK100MHZ`, `ck_rst`, `btn : std_logic_vector(3 downto 0)`.
- **Simulation:** module testbenches run in GHDL (`--std=08`) or XSim. Anything that includes `clk_gen`
  (the MMCM) must run in Vivado's simulator (XSim).

## Repository layout

| Path | Content |
|---|---|
| `src/` | synthesizable VHDL |
| `sim/` | testbenches |
| `constraints/` | `arty_a7_35.xdc`: Digilent Arty A7-35 master file; only the pins in use are uncommented |
| `ip/` | IP cores; only the `.xci` configuration is tracked |
| `docs/` | requirements, design notes and diagrams (`docs/graphs/`) |
| `vivado/` | Vivado project (`pong.xpr`); only the `.xpr` is tracked |
| `create_project.tcl` | recreates `vivado/` from the repo (see Getting started) |
