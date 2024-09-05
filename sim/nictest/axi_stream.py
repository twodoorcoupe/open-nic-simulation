import io
import random

from scapy.layers.l2 import Ether


W_TDATA = 64
W_TUSER = 2
W_TKEEP = W_TDATA // 8
box = ""
current_qid = 0
max_qid = 0


def set_globals(user_box, num_queues):
    global box, max_qid
    box = user_box
    max_qid = num_queues


def _set_beat(file, packet):
    # divide the packet into beats
    beats = []
    raw_packet = bytes(packet)
    num_beats = len(raw_packet) // W_TDATA
    for i in range(num_beats):
        beat_index = i * W_TDATA
        beats.append(raw_packet[beat_index:beat_index + W_TDATA])
    last_beat = raw_packet[num_beats * W_TDATA:]

    # add in the beats except the last one
    for beat in beats:
        tdata = beat[::-1].hex()
        tkeep = 'f' * W_TKEEP * 2
        file.write(f"!{tdata}, {tkeep}, 0\n")

    # handle the last beat
    last_keep = 0
    for i in range(len(last_beat)):
        last_keep |= (1 << i)
    num_bytes = (last_keep.bit_length() + 7) // 8
    tdata = last_beat[::-1].rjust(W_TDATA, b'\x00').hex()
    tkeep = last_keep.to_bytes(num_bytes, byteorder = 'little')[::-1].rjust(W_TKEEP, b'\x00').hex()
    file.write(f"!{tdata}, {tkeep}, 1\n")


def _set_plugin_tuser(file, name, packet):
    tuser_size = len(bytes(packet)).to_bytes(W_TUSER, byteorder = 'big').hex()
    tuser_src = 0
    tuser_dst = 0

    interface_type = name[:3]
    interface_index = int(name[3]) + 1
    masked_value = interface_index & 0xFFFF
    if interface_type == "dma":
        tuser_src |= masked_value
    else:  # phy
        tuser_src |= (masked_value << 6)

    tuser_src = f"{tuser_src:04x}"
    tuser_dst = f"{tuser_dst:04x}"
    file.write(f"?{tuser_size}{tuser_src}{tuser_dst}\n")


def _set_full_tuser(file, name, packet):
    global current_qid
    packet_size = len(bytes(packet))
    tuser_size = format(packet_size, f'032b')
    tuser_qid = format(current_qid, f'011b')
    tuser_mty = format(W_TDATA - packet_size % W_TDATA, f'06b')

    tuser = tuser_size + tuser_qid + tuser_mty
    tuser += '000'  # Pad to 52 bits for the testbench
    hex_tuser = hex(int(tuser, 2))[2:].zfill(13)
    file.write(f"?{hex_tuser}\n")

    current_qid += 1
    if current_qid == max_qid:
        current_qid = 0


def set_delay(mode, amount=0, random_amount=False):
    if random_amount or amount <= 0:
        amount = random.randint(1, 1000)
    return f"{mode}{amount}\n"


def packets_to_axis(name, packets):
    file = io.StringIO()
    for packet in packets:
        if box == "__250mhz__":
            _set_plugin_tuser(file, name, packet)
        elif box == "__full__":
            _set_full_tuser(file, name, packet)
        else:
            file.write("?0\n")
        _set_beat(file, packet)
        file.write("\n")
    return file.getvalue()


def axis_to_packets(file, name):
    packets, tdata = [], []
    mty = 0
    is_full_dma = box == "__full__" and name[:3] == "dma"
    for line in file:
        if not line:
            continue

        # tdata, tkeep, tlast fields
        if line.startswith("!"):
            beat = line[1:].replace(" ", "").split(',')
            tdata.append(bytes.fromhex(beat[0])[::-1])
            tkeep = bytes.fromhex(beat[1])[::-1]
            tlast = int(beat[2])

            # create the scapy packet in the last beat
            if tlast == 1:
                if is_full_dma:
                    null_bytes = mty
                else:
                    null_bytes = 0
                    for byte in tkeep:
                        for i in range(8):
                            if (byte & (1 << i)) == 0:
                                null_bytes += 1
                packet = b''.join(tdata)[:-null_bytes]
                packets.append(Ether(packet))
                tdata = []

        elif line.startswith("?") and is_full_dma:
            clean_line = line[1:].replace(" ", "")
            tuser = bin(int(clean_line, 16))[2:].zfill(52)
            mty = int(tuser[44:49], 2)

    return packets
