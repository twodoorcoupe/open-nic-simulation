class FileReader #(int w_data = 512, int w_user = 48);
    localparam int w_keep = w_data / 8;

    virtual axis #(.w_data(w_data), .w_user(w_user)) bus;
    int file;
    int is_finished;

    function new (string location, virtual axis #(.w_data(w_data), .w_user(w_user)) bus);
        this.bus  = bus;
        file = $fopen(location, "r");
        is_finished = 0;
    endfunction

    function int get_finished;
        return is_finished;
    endfunction

    task send_beat;
        input string       line;
        logic [w_data-1:0] data;
        logic [w_keep-1:0] keep;
        logic              last;

        string split_line[] = StringUtils#(3)::split_line(line);
        data = StringUtils#(w_data)::string_to_vector(split_line[0]);
        keep = StringUtils#(w_keep)::string_to_vector(split_line[1]);
        last = split_line[2].atobin();

        bus.send_beat(data, keep, last);
        @(negedge bus.clk);
        bus.tvalid <= 1'b0;
    endtask

    task send_user;
        input string line;
        logic [w_user-1:0] user = StringUtils#(w_user)::string_to_vector(line);
        bus.send_user(user);
    endtask

    task start;
        string line, command, value;
        integer tmp;

        if (!file) return;
        while (!$feof(file)) begin
            tmp     = $fgets(line, file);
            command = line.substr(0, 0);
            value   = line.substr(1, line.len() - 2);
            if (StringUtils#(0)::contains(AXIS_COMMANDS, command) == 1'b0)
                continue;

            if      (command == "!") send_beat(value);
            else if (command == "?") send_user(value);
            else begin
                make_delay(value, command, tmp);
                repeat (tmp) @(negedge bus.clk);
            end
        end
        $fclose(file);
        is_finished = 1;
    endtask
endclass