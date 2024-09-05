import nictest


packets = [nictest.make_ip_pkt(98) for i in range(3)]
other = [nictest.make_ip_pkt(98) for i in range(3)]

nictest.initialize()

nictest.send_packets("dma0", packets)
nictest.send_packets("phy0", packets)
nictest.send_packets("dma1", packets)
nictest.send_packets("phy1", packets)

nictest.expect_packets("dma0", packets)
nictest.expect_packets("phy0", packets)
nictest.expect_packets("dma1", packets)
nictest.expect_packets("phy1", other[:-1])

nictest.regrwrite("0000_0004", "0000_0001")
nictest.regread("0000_0008", "0000_000F")

nictest.finish(vivado_mode = "batch")
