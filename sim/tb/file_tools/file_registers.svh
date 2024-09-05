class FileRegisters;
    virtual axil bus;
    int file_in;
    int file_out;

    function new (string location_in, string location_out, virtual axil bus);
        this.bus  = bus;
        file_in   = $fopen(location_in, "r");
        file_out  = $fopen(location_out, "w");
    endfunction

    task parse_line;
        input string line;
        logic [31:0] data;
        logic [31:0] address_write;
        logic [31:0] address_read;
        string output_line;
        string split_line[] = StringUtils#(3)::split_line(line);

        fork
            // A register needs to be written
            if (split_line[0].substr(0, 0) != "-") begin
                data          = StringUtils#(32)::string_to_vector(split_line[1]);
                address_write = StringUtils#(32)::string_to_vector(split_line[0]);
                bus.write_register(address_write, data);
                output_line = $sformatf("%h <- %h #%t", address_write, data, $time);
                $fwrite(file_out, {output_line, "\n"});
            end

            // A register needs to be read
            if (split_line[2].substr(0, 0) != "-") begin
                address_read = StringUtils#(32)::string_to_vector(split_line[2]);
                bus.read_register(address_read, data);
                output_line = $sformatf("%h -> %h #%t", address_read, data, $time);
                $fwrite(file_out, {output_line, "\n"});
            end
        join
    endtask;

    task start;
        string line, command, value;
        integer tmp;

        if (!file_in || !file_out) return;
        while (!$feof(file_in)) begin
            tmp     = $fgets(line, file_in);
            command = line.substr(0, 0);
            value   = line.substr(1, line.len() - 2);
            if (StringUtils#(0)::contains(AXIL_COMMANDS, command) == 1'b0)
                continue;

            if (command == "!") parse_line(value);
            else begin
                make_delay(value, command, tmp);
                repeat (tmp) @(negedge bus.clk);
            end
        end
        $fclose(file_in);
        $fclose(file_out);
    endtask
endclass