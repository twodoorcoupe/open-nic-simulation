import difflib
import logging
import os
import subprocess

from .axi_lite import get_transactions
from .axi_stream import axis_to_packets, set_globals


LAUNCH_SCRIPT_LOCATION = os.path.dirname(__file__) + "/run_simulation.tcl"
VIVADO_SUPPORTED_VERSIONS = ['2022.1']


class SimulationError(Exception):
    pass


class InterfacesManager:

    def __init__(self):
        self.received_packets = dict()
        self.expected_packets = dict()
        self.interfaces = dict()
        self.sim_location = None
        self.box = None

    def _get_interface_names(self):
        interfaces_range = int(os.environ["NUM_CMAC_PORT"])
        for i in range(interfaces_range):
            yield f"phy{i}"
        if self.box == "__250mhz__":
            interfaces_range = int(os.environ["NUM_QDMA"]) * int(os.environ["NUM_PHYS_FUNC"])
        for i in range(interfaces_range):
            yield f"dma{i}"
        yield "registers"

    def open_interfaces(self):
        self.box = os.environ["USER_BOX"]
        self.sim_location = os.environ["SIM_LOCATION"]
        set_globals(self.box, os.environ["NUM_QUEUE"])
        for interface_name in self._get_interface_names():
            self.interfaces[interface_name] = open(f"{self.sim_location}/axi_in_{interface_name}.txt", 'w')
            self.expected_packets[interface_name] = []

    def close_interfaces(self):
        for interface_file in self.interfaces.values():
            interface_file.close()

    def _get_interface(self, name):
        if name not in self.interfaces.keys():
            log.error(f"Invalid interface name {name}")
            return
        return self.interfaces[name]

    def add_sent_packets(self, name, text):
        file = self._get_interface(name)
        if file:
            file.write(text)

    def add_expected_packets(self, name, packets):
        file = self._get_interface(name)
        if file:
            self.expected_packets[name].extend(packets)

    def add_received_packets(self):
        for interface_name in self._get_interface_names():
            file = open(f"{self.sim_location}/axi_out_{interface_name}.txt", 'r')
            if interface_name == "registers":
                packets = get_transactions(file)
            else:
                packets = axis_to_packets(file, interface_name)
            self.received_packets[interface_name] = packets
            file.close()

    @staticmethod
    def _compare_packet_lists(received_packets, expected_packets, interface_name=None):
        differ = difflib.Differ()
        correct = True
        for received, expected in zip(received_packets, expected_packets):
            if interface_name:
                received = received.show2(dump = True)
                expected = expected.show2(dump = True)
            if received == expected:
                continue
            correct = False
            difference = list(differ.compare(received.splitlines(), expected.splitlines()))
            difference_string = '\n'.join(difference)
            if interface_name:
                log.warning(f"Packet mismatch for {interface_name}:\n{difference_string}")
            else:
                log.warning(f"Register mismatch:\n{difference_string}")

        difference = len(received_packets) - len(expected_packets)
        if interface_name and difference != 0:
            if difference > 0:
                log.warning(f"Received {difference} more packets than expected for interface {interface_name}")
            elif difference < 0:
                log.warning(f"Expected {-difference} more packet than received from interface {interface_name}")
        return correct

    def compare_packets(self):
        packets_correct = True
        for interface_name in self._get_interface_names():
            expected_packets = self.expected_packets[interface_name]
            if not expected_packets or interface_name == "registers":
                continue
            received_values = self.received_packets[interface_name]
            result = self._compare_packet_lists(received_values, expected_packets, interface_name = interface_name)
            packets_correct = packets_correct and result
        if packets_correct:
            log.info("All packets were as expected")

        expected_values = self.expected_packets["registers"]
        if expected_values:
            received_values = self.received_packets["registers"]
            if self._compare_packet_lists(received_values, expected_values):
                log.info("All register values were as expected")


def _check_vivado_version():
    vivado_version = os.environ.get("XILINX_VIVADO", None)
    if not vivado_version:
        raise SimulationError("Please source the Vivado scripts (settings64.sh)")
    vivado_version = vivado_version[-6:]
    if vivado_version not in VIVADO_SUPPORTED_VERSIONS:
        raise SimulationError(f"Please use proper Vivado version, {vivado_version} is not supported")


def initialize_simulation(log_location=""):
    try:
        interface_manager.open_interfaces()

        log.setLevel(logging.DEBUG)
        terminal_handler = logging.StreamHandler()
        terminal_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', '%H:%M:%S')
        terminal_handler.setFormatter(formatter)
        log.addHandler(terminal_handler)

        if log_location:
            file_handler = logging.FileHandler(log_location, mode = 'w')
            file_handler.setLevel(logging.DEBUG)
            formatter = logging.Formatter('%(asctime)s %(message)s', '%H:%M:%S')
            file_handler.setFormatter(formatter)
            log.addHandler(file_handler)
    except KeyError as e:
        log.error("Please source sim/settings.sh")
        log.debug(e)
    except OSError as e:
        log.error("please check that SIM_LOCATION and LOG_LOCATION are correct")
        log.debug(e)


def run_simulation(vivado_mode="batch"):
    try:
        if vivado_mode != "batch" and vivado_mode != "gui":
            vivado_mode = "batch"
            log.warning("Please make sure vivado_mode is either 'batch' or 'gui'. Defaulting to 'batch'")
        interface_manager.close_interfaces()

        _check_vivado_version()
        log.info(f"Starting Vivado simulation")
        command = ['vivado', '-mode', f'{vivado_mode}', '-source', f'{LAUNCH_SCRIPT_LOCATION}']
        process = subprocess.Popen(command, stdout = subprocess.PIPE, stderr = subprocess.PIPE, text = True)
        with process.stdout:
            for line in iter(process.stdout.readline, ''):
                log.debug(line.strip())
        with process.stderr:
            for line in iter(process.stderr.readline, ''):
                log.error(line.strip())
        process.wait()
        log.info(f"Simulation finished")

        interface_manager.add_received_packets()
        interface_manager.compare_packets()
    except SimulationError as e:
        log.error(e)
    except subprocess.SubprocessError as e:
        log.error("Could not start Vivado simulation")
        log.debug(e)
    except KeyError as e:
        log.error("Please source sim/settings.sh")
        log.debug(e)
    except OSError as e:
        log.error("Please check that SIM_LOCATION and LOG_LOCATION are correct")
        log.debug(e)


log = logging.getLogger("simulation")
interface_manager = InterfacesManager()
