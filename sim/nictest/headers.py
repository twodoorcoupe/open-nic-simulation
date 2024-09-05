from scapy.layers.inet import IP
from scapy.layers.l2 import ARP, Dot1Q, Ether


def make_mac_hdr(src_mac=None, dst_mac=None, ether_type=None, **kwargs):
    hdr = Ether()
    if src_mac:
        hdr.src = src_mac
    if dst_mac:
        hdr.dst = dst_mac
    if ether_type:
        hdr.type = ether_type
    return hdr


def make_ip_hdr(src_ip=None, dst_ip=None, ttl=None, **kwargs):
    hdr = IP()
    if src_ip:
        hdr[IP].src = src_ip
    if dst_ip:
        hdr[IP].dst = dst_ip
    if ttl:
        hdr[IP].ttl = ttl
    return hdr


def make_arp_hdr(op=None, src_mac=None, dst_mac=None, src_ip=None, dst_ip=None, **kwargs):
    hdr = ARP()
    if op:
        hdr.op = op
    if src_mac:
        hdr.hwsrc = src_mac
    if dst_mac:
        hdr.hwdst = dst_mac
    if src_ip:
        hdr.psrc = src_ip
    if dst_ip:
        hdr.pdst = dst_ip
    return hdr


def make_vlan_hdr(vlan=None, id=None, prio=None, **kwargs):
    hdr = Dot1Q()
    if vlan:
        hdr.vlan = vlan
    if id:
        hdr.id = id
    if prio:
        hdr.prio = prio
    return hdr
