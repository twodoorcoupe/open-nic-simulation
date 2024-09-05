from scapy.layers.inet import ICMP
from scapy.packet import Raw
from scapy.volatile import RandString

from .headers import *


def _generate_load(length):
    return Raw(RandString(length))


def make_ip_pkt(
        pkt_len: int = 60, src_mac: str = None, dst_mac: str = None,
        src_ip: str = None, dst_ip: str = None, ttl: int = None
) -> Ether:
    """
    Creates an ip packet of the given length with a random payload

    Args:
        pkt_len (int, optional): length in bytes of the packet including the header. Defaults to 60
        src_mac (str, optional): source mac address
        dst_mac (str, optional): destination mac address
        src_ip (str, optional): source ip address
        dst_ip (str, optional): destination ip address
        ttl (int, optional): time to live

    Returns:
        Ether: the resulting ethernet frame
    """
    if pkt_len < 60:
        pkt_len = 60
    pkt = (make_mac_hdr(src_mac = src_mac, dst_mac = dst_mac) /
           make_ip_hdr(src_ip = src_ip, dst_ip = dst_ip, ttl = ttl) /
           _generate_load(pkt_len - 34))
    return pkt


def make_vlan_pkt(
        pkt_len: int = 60, src_mac: str = None, dst_mac: str = None,
        vlan: int = None, id: int = None, prio: int = None,
        src_ip: str = None, dst_ip: str = None, ttl: int = None
) -> Ether:
    """
    Creates a vlan packet of the given length with a random payload

    Args:
        pkt_len (int, optional): length in bytes of the packet including the header. Defaults to 60
        src_mac (str, optional): source mac address
        dst_mac (str, optional): destination mac address
        vlan (int, optional): vlan id
        id (int, optional): vlan id
        prio (int, optional): frame's priority
        src_ip (str, optional): source ip address
        dst_ip (str, optional): destination ip address
        ttl (int, optional): time to live

    Returns:
        Ether: the resulting scapy packet
    """
    if pkt_len < 60:
        pkt_len = 60
    pkt = (make_mac_hdr(src_mac = src_mac, dst_mac = dst_mac) /
           make_vlan_hdr(vlan = vlan, id = id, prio = prio,) /
           make_ip_hdr(src_ip = src_ip, dst_ip = dst_ip, ttl = ttl) /
           _generate_load(pkt_len - 34))
    return pkt


def make_icmp_reply_pkt(
        data: bytearray = None, src_mac: str = None, dst_mac: str = None,
        src_ip: str = None, dst_ip: str = None, ttl: int = None
) -> Ether:
    """
    Creates an icmp reply packet with the given data

    Args:
        data (bytearray, optional): the contents of the packet
        src_mac (str, optional): source mac address
        dst_mac (str, optional): destination mac address
        src_ip (str, optional): source ip address
        dst_ip (str, optional): destination ip address
        ttl (int, optional): time to live

    Returns:
        Ether: the resulting scapy packet
    """
    pkt = (make_mac_hdr(src_mac = src_mac, dst_mac = dst_mac) /
           make_ip_hdr(src_ip = src_ip, dst_ip = dst_ip, ttl = ttl) /
           ICMP(type = "echo-reply"))
    if data:
        pkt = pkt / data
    else:
        pkt = pkt / ("\x00" * 56)
    return pkt


def make_icmp_request_pkt(
        src_mac: str = None, dst_mac: str = None,
        src_ip: str = None, dst_ip: str = None, ttl: int = None
) -> Ether:
    """
    Creates an icmp echo request packet

    Args:
        src_mac (str, optional): source mac address
        dst_mac (str, optional): destination mac address
        src_ip (str, optional): source ip address
        dst_ip (str, optional): destination ip address
        ttl (int, optional): time to live

    Returns:
        Ether: the resulting scapy packet
    """
    pkt = (make_mac_hdr(src_mac = src_mac, dst_mac = dst_mac) /
           make_ip_hdr(src_ip = src_ip, dst_ip = dst_ip, ttl = ttl) /
           ICMP(type = "echo-request") /
           ("\x00" * 56))
    return pkt


def make_icmp_ttl_exceed_pkt(
        src_mac: str = None, dst_mac: str = None,
        src_ip: str = None, dst_ip: str = None, ttl: int = None
) -> Ether:
    """
    Creates an icmp ttl exceeded packet

    Args:
        src_mac (str, optional): source mac address
        dst_mac (str, optional): destination mac address
        src_ip (str, optional): source ip address
        dst_ip (str, optional): destination ip address
        ttl (int, optional): time to live

    Returns:
        Ether: the resulting scapy packet
    """
    pkt = (make_mac_hdr(src_mac = src_mac, dst_mac = dst_mac) /
           make_ip_hdr(src_ip = src_ip, dst_ip = dst_ip, ttl = ttl) /
           ICMP(type = 11, code = 0))
    return pkt


def make_icmp_host_unreach_pkt(
        src_mac: str = None, dst_mac: str = None,
        src_ip: str = None, dst_ip: str = None, ttl: int = None
) -> Ether:
    """
    creates an icmp host unreachable packet

    args:
        src_mac (str, optional): source mac address
        dst_mac (str, optional): destination mac address
        src_ip (str, optional): source ip address
        dst_ip (str, optional): destination ip address
        ttl (int, optional): time to live

    returns:
        Ether: the resulting scapy packet
    """
    pkt = (make_mac_hdr(src_mac = src_mac, dst_mac = dst_mac) /
           make_ip_hdr(src_ip = src_ip, dst_ip = dst_ip, ttl = ttl) /
           ICMP(type = 3, code = 0))
    return pkt


def make_arp_request_pkt(
        src_mac: str = None, dst_mac: str = None,
        src_ip: str = None, dst_ip: str = None,
) -> Ether:
    """
    Creates an arp request packet

    Args:
        src_mac (str, optional): source mac address
        dst_mac (str, optional): destination mac address
        src_ip (str, optional): source ip address
        dst_ip (str, optional): destination ip address

    Returns:
        Ether: the resulting scapy packet
    """
    pkt = (make_mac_hdr(src_mac = src_mac, dst_mac = dst_mac) /
           make_arp_hdr(op = "who-has", src_ip = src_ip, dst_ip = dst_ip) /
           ("\x00" * 18))
    return pkt


def make_arp_reply_pkt(
        src_mac: str = None, dst_mac: str = None,
        src_ip: str = None, dst_ip: str = None,
) -> Ether:
    """
    Creates an arp reply packet

    Args:
        src_mac (str, optional): source mac address
        dst_mac (str, optional): destination mac address
        src_ip (str, optional): source ip address
        dst_ip (str, optional): destination ip address

    Returns:
        Ether: the resulting scapy packet
    """
    pkt = (make_mac_hdr(src_mac = src_mac, dst_mac = dst_mac) /
           make_arp_hdr(op = "is-at", src_ip = src_ip, dst_ip = dst_ip) /
           ("\x00" * 18))
    return pkt
