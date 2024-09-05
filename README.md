# OpenNIC Simulation Infrastructure
Intended for Vivado 2022.1

## How to use
1. Simply run `build.tcl` in the `script` folder.
```
vivado -source build.tcl -mode batch
```
Or follow OpenNIC's shell build instructions [here](https://github.com/Xilinx/open-nic-shell?tab=readme-ov-file#how-to-build) for more information on build options.

2. Modify `settings.sh` in the `sim` folder to specify things like the Vivado project's location.

3. Source Vivado's scripts (`settings64.sh`) and `settings.sh` in the `sim` folder.

4. Run your simulation script with python.

## Simulation API
For more details look at `sim/nictest/__init__.py`

- initialize -> Creates the simulation files
- finish -> Runs the Vivado simulation and scoreboard

Packet operations:

- send_packets
- expect_packets

Register operations:

- regwrite
- regread

Delays:

- make_cycles_delay
- make_relative_delay
- make_absolute_delay

Packet generations:
For more details look at `sim/nictest/packets.py`

## AXI Files Grammar
AXI Stream:

```
<axis>  := (<user> | <beat> | <delay>)*

<beat>  := "!" <hex>"," <hex>"," <hex> -> DATA, KEEP, LAST
<user>  := "?" <hex>                   -> USER
<delay> := "@" <digits>                -> absolute time (ns)
           "+" <digits>                -> relative time (ns)
           "*" <digits>                -> relative time (cycles)

<hex>    := (<digits> | "A" | ... | "F")+
<digits> := ("0" | "1" | ... | "9")+
```

AXI Lite:

```
<axil>       := ( <transact> | <delay>)+

<transact>   := "!" <write_addr>"," <write_data>"," <read_addr>
<write_addr> := <hex> | "-"                 -> WRITE ADDRESS
<write_data> := <hex> | "-"                 -> WRITE DATA
<read_addr>  := <hex> | "-"                 -> READ DATA 
<delay>      := "@" <digits>                -> absolute time (ns)
                "+" <digits>                -> relative time (ns)
                "*" <digits>                -> relative time (cycles)

<hex>    := (<digits> | "A" | ... | "F")+
<digits> := ("0" | "1" | ... | "9")+
```
