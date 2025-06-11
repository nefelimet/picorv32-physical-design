# picorv32-physical-design
Physical design flow of the PicoRV32 processor using Cadence Genus and Innovus

<img src="https://github.com/user-attachments/assets/2334b25a-6588-4c73-95a6-faa307cef18b" alt="drawing" style="width:300px;"/>

## Description

This project describes the physical design flow of the PicoRV32 processor (https://github.com/YosysHQ/picorv32), using Genus and Innovus by Cadence. It was run on a university computing cluster, utilizing the Cadence GPDK45 library. No proprietary files are shared here, and file paths have been sanitized. 

## Constraints and Running

The initial constraints are written in the `initial.sdc` file.

The constraints included are shown below:


| Constraint        | Value         | 
| ----------------- |:-------------:| 
| Clock period      | 10 ns         | 
| Clock duty cycle  | 50%           |  
| Clock latency     | 400 ps        |  
| Clock uncertainty | 50 ps         |
| Clock transition | 100 ps         |
| Setup output delay | 1 ns         |
| Hold output delay | 0.4 ns        |
| Setup input delay | 1 ns          |
| Hold input delay | 0.4 ns         |
| Setup output load | 0.5 pF        |
| Hold output load | 0.01 pF        |
| Setup driving cell | BUFX2        |
| Hold driving cell | BUFX16        |

The tcl script contains all generic commands for reading the Verilog top module in Genus, synthesizing and extracting reports. The output file is in a format ready to be used by Innovus.

```bash
genus -f proj_dir/run.tcl
```

The outputs will be saved in the `output` folder.

## Reports

### Area report

| Metric        | Value         | 
| ----------------- |:-------------:| 
| Cell count      | 5202         | 
| Cell area  | 20946.816   um^2        |  
| Net area  | 7373.710    um^2      |
| Total area  | 28320.526  um^2        |



### Timing report

| Metric        | Value         | 
| ----------------- |:-------------:| 
| Slack      | 7518 ps         | 
| Data path delay  | 410 ps           |  

### Power report

| Metric        | Value         | 
| ----------------- |:-------------:| 
| Leakage power      | 0.001307 mW         | 
| Internal power  | 0.72865 mW           |  
| Switching power  | 1.60848 mW           |  
| Total power  | 2.33844 mW           |  

## Floorplanning

The Genus output was saved as a `genus.v` file. We invoke Innovus and import the netlist saved by Genus. We also load the technology file, timing library file, RC corners etc. To begin the floorplanning process, we specify the desired core utilization, and core margins to the IO boundary:

| Metric        | Value         | 
| ----------------- |:-------------:| 
| Core utilization      | 75%         | 
| Core to left  | 15 um           | 
| Core to right  | 15 um           |  
| Core to top  | 15 um           |  
| Core to bottom  | 15 um           |  

In Innovus the power ring was manually created, using the 2 top metals. The power stripes were also added.
|          | Layer         | Width | Spacing |
| ----------------- |----------------- |----------------- |:-------------:| 
| Top      | M11 (H)       | 3 um | 3 um |
| Bottom  | M11 (H)           | 3 um | 3 um |
| Left  | M10 (V)          |  3 um | 3 um |
| Right  | M10 (V)          |  3 um | 3 um |

The power stripes were placed on M10, in the vertical direction, with a width of 3um and a spacing of 3um. 

The power and ground pins were also created:

```tcl
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *
globalNetConnect VDD -type tiehi -instanceBasename *
globalNetConnect VSS -type tielo -instanceBasename *
createPGPin VSS -net VSS -geom Metal11 105 0 111 6
createPGPin VDD -net VDD -geom Metal10 65 0 75 12
editPowerVia -add_vias 1 -top_layer Metal11 -area {65 9 75 12} -bottom_layer Metal10
```

<img src="https://github.com/user-attachments/assets/e0b9d99f-57cc-4290-a9a1-78e9ad094a75" alt="drawing" style="width:300px;"/>

## Placement and Routing

The placement mode was checked through the Innovus terminal:

```tcl
getPlaceMode
```

output:
```tcl
-place_global_timing_effort = medium
-place_global_cong_effort = high
```

The placement is executed: `place_opt_design`.

<img src="https://github.com/user-attachments/assets/53653fa5-d845-44b3-9824-8792e78f2300" alt="drawing" style="width:300px;"/>

For routing we use Early Global Routing, utilizing all layers (M1 to M11). The congestion map is shown below:

<img src="https://github.com/user-attachments/assets/d602ecbe-f44a-45da-96c9-dc7bd9bd9fc5" alt="drawing" style="width:300px;"/>

63% of bins have a density higher than 75%.

## Clock Tree Synthesis

For Clock Tree Synthesis (CTS), a new Non-Default Rule (NDR) is created, in order to use double width and spacing for all metals. The double width helps reduce RC delay and IR drop in the clock wires, and the double spacing helps reduce crosstalk between clock wires, which could result in jitter. The NDR is created and saved as `ndr_cts`. The clock tree wires will be routed from M5 to M9 (since M10 and M11 are utilized for the power grid). Post-clock optimization is performed.

```tcl
create_route_type  -top_preferred_layer Metal9 -bottom_preferred_layer Metal5 -non_default_rule ndr_cts -name route_cts
set_ccopt_property  -target_skew 0.1
set_ccopt_property -target_max_trans 0.15
create_ccopt_clock_tree_spec -file clockspec.spec
ccopt_design
optDesign -postCTS
report_ccopt_clock_trees > proj_dir/output/cts_trees.txt
report_ccopt_skew_groups > proj_dir/output/cts_skew.txt
```

The results from the CTS are shown below:


| Metric        | Value         | 
| ----------------- |:-------------:| 
| Buffers count      | 16         | 
| Trunk wire length  | 398.365 um           | 
| Leaf wire length  | 5388.900 um           |  
| Total wire length  | 5787.265 um           |  
| Skew groups  | 8          |  
| Max skew  | 5 ps          |  
| Max delay  | 77 ps          |  


## DRC, Connectivity Checks and Metal Fills

After running DRC verification and connectivity verification, the number of violations is 0. The netlist check is run:

```tcl
checkDesign -netlist > proj_dir/output/check_design_netlist.txt
```

There are 0 errors and 4 warnings regarding: floating ports, ports connected to core instances, high fan-out nets and instances with input pins tied together.



| Metric        | Value         | 
| ----------------- |:-------------:| 
| Total standard cell number      | 5496         | 
| Total standard cell area  | 20991.28 um^2          | 
| Number of nets  | 6086           |  


At the end, the processor design looks like this:

<img src="https://github.com/user-attachments/assets/2334b25a-6588-4c73-95a6-faa307cef18b" alt="drawing" style="width:300px;"/>

## Design For Testability (DFT)

In this step, DFT logic is added in the stages before synthesis, and logic equivalence checks are performed to verify that the DFT logic has not altered the logic equivalence.

A new tcl file is created, which is similar to the original one, but contains the commands for setting the database properties to include DFT scan chains.

```bash
genus -f proj_dir/run_dft.tcl
```

The dft_check states that there are 0 DFT rule violations. The DFT check results are shown below:


| Metric        | Value         | 
| ----------------- |:-------------:| 
| Usable scan cells      | 48         | 
| Total number of test clock domains  | 1        | 
| Number of registers in scanclk (pre-synthesis) | 1728           |  
| Number of registers in scanclk (post-synthesis) | 1555           |  
| Percentage of registers that are scannable | 100% |
