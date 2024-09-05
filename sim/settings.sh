#!/bin/bash

# PROJECT_LOCATION is the location of the vivado project file
# SIM_LOCATION is the directory where to put the axi simulation files
# USER_BOX is either __250mhz__ or __322mhz__ or __full__
export PROJECT_LOCATION="${HOME}/Documents/Projects/open-nic-simulation/build/au55c/open_nic_shell/open_nic_shell.xpr"
export SIM_LOCATION="${HOME}"
export USER_BOX="__250mhz__"

# OpenNIC design parameters
export MIN_PKT_LEN=64
export MAX_PKT_LEN=1518
export NUM_QUEUE=512
export NUM_QDMA=1
export NUM_PHYS_FUNC=2
export NUM_CMAC_PORT=2



if [ ! -d "$(eval echo "${PROJECT_LOCATION%/*}")" ]; then
    echo "ERROR: The directory specified in PROJECT_LOCATION does not exist."
fi
if [ ! -d "$(eval echo "${SIM_LOCATION%/*}")" ]; then
    echo "ERROR: The directory specified in SIM_LOCATION does not exist."
fi
if [ "$USER_BOX" != "__250mhz__" ] && [ "$USER_BOX" != "__322mhz__" ] && [ "$USER_BOX" != "__full__" ]; then
    echo "ERROR: USER_BOX must be either __250mhz__, __322mhz__, or __full__"
fi
if [ "$MIN_PKT_LEN" -lt 64 ] || [ "$MIN_PKT_LEN" -gt 256 ]; then
    echo "ERROR: MIN_PKT_LEN must be between 64 and 256. Current value: $MIN_PKT_LEN"
fi
if [ "$MAX_PKT_LEN" -lt 256 ] || [ "$MAX_PKT_LEN" -gt 9600 ]; then
    echo "ERROR: MAX_PKT_LEN must be between 256 and 9600. Current value: $MAX_PKT_LEN"
fi
if [ "$NUM_PHYS_FUNC" -lt 1 ] || [ "$NUM_PHYS_FUNC" -gt 4 ]; then
    echo "ERROR: NUM_PHYS_FUNC must be between 1 and 4. Current value: $NUM_PHYS_FUNC"
fi
if [ "$NUM_QUEUE" -lt 1 ] || [ "$NUM_QUEUE" -gt 2048 ]; then
    echo "ERROR: NUM_QUEUE must be between 1 and 2048. Current value: $NUM_QUEUE"
fi
if [ "$NUM_QDMA" -lt 1 ] || [ "$NUM_QDMA" -gt 2 ]; then
    echo "ERROR: NUM_QDMA must be between 1 and 2. Current value: $NUM_QDMA"
fi
if [ "$NUM_CMAC_PORT" -lt 1 ] || [ "$NUM_CMAC_PORT" -gt 2 ]; then
    echo "ERROR: NUM_CMAC_PORT must be between 1 and 2. Current value: $NUM_CMAC_PORT"
fi
