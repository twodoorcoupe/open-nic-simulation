import re


_hexadecimal_string = re.compile(r'[0-9A-Fa-f]+')


def _sanity_check(hex_str):
    hex_str = hex_str.replace("_", "")
    if not _hexadecimal_string.match(hex_str) or len(hex_str) != 8:
        raise ValueError(f"{hex_str} should be 8 character hexadecimal string")


def set_transaction(write_addr=None, write_data=None, read_addr=None):
    if read_addr is not None:
        write_addr = "-"
        write_data = "-"
        _sanity_check(read_addr)

    # write mode
    else:
        read_addr = "-"
        _sanity_check(write_data)
        _sanity_check(write_addr)
    return f"!{write_addr},{write_data},{read_addr}\n"


def get_transactions(file):
    transactions = []
    for line in file:
        stripped_line = line.replace(" ", "").replace("_", "")
        if not stripped_line:
            continue

        # add only read transactions
        if "->" in line:
            addr, data = stripped_line.split("->")
            transactions.append(f"{addr[:8]} -> {data[:8]}\n")
    return transactions
