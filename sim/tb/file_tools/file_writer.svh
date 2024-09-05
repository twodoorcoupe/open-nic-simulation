class FileWriter #(int w_data = 512, int w_user = 48);
    localparam int w_keep  = w_data / 8;

    virtual axis #(.w_data(w_data), .w_user(w_user)) bus;
    int file;
    static int is_finished = 0;

    function new (string location, virtual axis #(.w_data(w_data), .w_user(w_user)) bus);
        this.bus  = bus;
        file = $fopen(location, "w");
    endfunction

    static function finish;
        is_finished = 1;
    endfunction

    task write_beat;
        string line;
        string values [0:2];

        values[0] = StringUtils#(w_data)::vector_to_string(bus.tdata);
        values[1] = StringUtils#(w_keep)::vector_to_string(bus.tkeep);
        values[2].bintoa(bus.tlast);

        line = {"!", StringUtils#(3)::merge_line(values), "\n"};
        $fwrite(file, line);
        if (bus.tlast) begin
            $fwrite(file, "\n");
        end
    endtask

    task write_user;
        string line;
        line = {"?", StringUtils#(w_user)::vector_to_string(bus.tuser), "\n"};
        $fwrite(file, line);
    endtask

    task start;
        if (!file) return;
        bus.tready <= 1'b1;
        while (!is_finished) begin
            @(negedge bus.clk);
            if (bus.tvalid) begin
                if (bus.tlast == 1'b1) write_user();
                write_beat();
            end
        end
        bus.tready <= 1'b0;
        $fclose(file);
    endtask
endclass