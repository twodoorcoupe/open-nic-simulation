task automatic make_delay;
    input  string   line;
    input  string   command;
    output integer  wait_cycles;
    realtime current_time;
    integer  delay;
    delay = line.atoi();
    wait_cycles = 0;

    if (command == "+") begin  // Relative time (nanoseconds)
        #(delay);
        wait_cycles = 1;
    end

    else if (command == "@") begin  // Absolute time (nanoseconds)
        current_time = $realtime;
        if (delay > current_time) begin
            #($ceil(delay - current_time));
            wait_cycles =  1;
        end
    end

    else  // Otherwise it's relative clock cycles
        wait_cycles = delay;
endtask