from scapy.layers.l2 import Ether

from .axi_lite import set_transaction
from .axi_stream import packets_to_axis, set_delay
from .packets import *
from .simulation import interface_manager, initialize_simulation, log, run_simulation


def initialize(log_location: str = "") -> None:
    """
    Initializes the simulation. Creates the simulation files

    Args:
        log_location (str): location of where to put log file, leave blank for no log
    """
    initialize_simulation(log_location)


def finish(vivado_mode: str = "batch") -> None:
    """
    Runs Vivado and checks that the received packets match the expected ones

    Args:
        vivado_mode (str): either "batch" or "gui"
    """
    run_simulation(vivado_mode)


# PACKET OPERATIONS


def send_packets(name: str, packets: Ether | list[Ether]) -> None:
    """
    Sends the packets to the interface with the given name

    Args:
        name (str): the name of the interface to which the packets are sent
        packets (Ether | list[Ether]): packets to send, only one is fine as well
    """
    if not isinstance(packets, list):
        packets = [packets]
    axis = packets_to_axis(name, packets)
    interface_manager.add_sent_packets(name, axis)


def expect_packets(name: str, packets: Ether | list[Ether]) -> None:
    """
    Adds the packets to the list of expected ones for the given interface

    Args:
        name (str): the name of the interface from which the packets are expected
        packets (Ether | list[Ether]): packets to expect, only one is fine as well
    """

    if not isinstance(packets, list):
        packets = [packets]
    interface_manager.add_expected_packets(name, packets)


# REGISTER OPERATIONS


def regrwrite(write_addr: str, write_data: str) -> None:
    """
    Writes data in the register at the given address

    Args:
        write_addr (str): the register address in hexadecimal format
        write_data (str): the data to be written in hexadecimal format
    """
    axil = set_transaction(write_addr = write_addr, write_data = write_data)
    interface_manager.add_sent_packets("registers", axil)


def regread(read_addr: str, expected_data: str) -> None:
    """
    Makes the simulation read at the given address

    Args:
        read_addr (str): the register address in hexadecimal format
        expected_data (str): the expected data to be read in hexadecimal format
    """
    axil = axi_lite.set_transaction(read_addr = read_addr)
    interface_manager.add_sent_packets("registers", axil)
    packet = f"{read_addr} -> {expected_data}\n".replace("_", "")
    interface_manager.add_expected_packets("registers", [packet])


# DELAY GENERATION


def make_cycles_delay(name: str, amount: int) -> None:
    """
    Adds a delay to the simulation of the given interface, measured in clock cycles

    Args:
        name (str): the name of the interface to which the delay is added
        amount (int): The amount of clock cycles to wait for. If 0 or less, a random amount is selected
    """
    axis = axi_stream.set_delay("*", amount)
    interface_manager.add_sent_packets(name, axis)


def make_relative_delay(name: str, amount: int) -> None:
    """
    Adds a delay to the simulation of the given interface, measured in nanoseconds

    Args:
        name (str): the name of the interface to which the delay is added
        amount (int): The amount of nanoseconds to wait for. If 0 or less, a random amount is selected
    """
    axis = axi_stream.set_delay("+", amount)
    interface_manager.add_sent_packets(name, axis)


def make_absolute_delay(name: str, time: int) -> None:
    """
    Makes the simulation of the given interface wait until the given time, in nanoseconds

    Args:
        name (str): the name of the interface to which the delay is added
        time (int): The time to wait until. Must be greater than 0
    """
    if time < 0:
        raise ValueError
    axis = axi_stream.set_delay("@", time)
    interface_manager.add_sent_packets(name, axis)
