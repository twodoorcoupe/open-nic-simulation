virtual class StringUtils #(int w = 512);
    static function logic [w-1:0] string_to_vector (input string data);
        logic [w-1:0] out;
        string char;
        for (int i = w, j = 0; i > 0 && j < data.len(); i -= 4, j++) begin
            char = data.substr(j, j);
            while (contains(HEX_CHARACTERS, char) == 1'b0) begin
                j++;
                char = data.substr(j, j);
            end
            out[i-1-:4] = data.substr(j, j).atohex();
        end
        return out;
    endfunction

    static function string vector_to_string (input logic [w-1:0] data);
        string out;
        string tmp;
        for (int i = w; i > 0; i -= 4) begin
            tmp.hextoa(data[i-1-:4]);
            out = {out, tmp};
        end
        return out;
    endfunction

    typedef string strings_t [0:w-1];
    static function strings_t split_line (input string line);
        strings_t out;
        string tmp, char;
        for (int i = 0, j = 0; i < line.len(); i++) begin
            char = line.substr(i, i);
            if (char == ",") begin
                out[j] = tmp;
                tmp = "";
                j++;
                continue;
            end
            if (contains(HEX_CHARACTERS, char) == 1'b0)
                continue;
            tmp = {tmp, line.substr(i, i)};
            if (i == line.len() - 1)
                out[j] = tmp;
        end
        return out;
    endfunction

    static function string merge_line (input string words [0:w-1]);
        string out;
        out = words[0];
        for (int i = 1; i < w; i++)
            out = {out, ", ", words[i]};
        return out;
    endfunction

    static function logic contains (input string line, input string char);
        for (int i = 0; i < line.len(); i++)
            if (char == line.substr(i, i))
                return 1'b1;
        return 1'b0;
    endfunction
endclass