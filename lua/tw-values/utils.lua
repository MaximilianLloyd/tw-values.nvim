local M = {}

M.leftpad = function(str, length, char)
    char = char or " " -- Default to padding with spaces
    return string.rep(char, length) .. str
end

M.leftpad_table = function(t, length, char)
    local new_table = {}

    for _, value in ipairs(t) do
        table.insert(new_table, M.leftpad(value, length, char))
    end

    return new_table
end

M.count_leading_whitespace = function(line)
    local leadingWhitespace = string.match(line, "^[ \t]*")
    return leadingWhitespace and #leadingWhitespace or 0
end

M.mysplit = function(inputstr, sep, init_col, init_row)
    if sep == nil then
        sep = "%s"
    end

    local t = {}
    -- If there are mulitple new lines
    local row_offset = init_row

    for row in string.gmatch(inputstr, "([^\n]+)") do
        local offset = 0
        local whitespace = M.count_leading_whitespace(row)
        local base_col = init_col

        if whitespace ~= 0 then
            base_col = whitespace
        end

        for str in string.gmatch(row, "([^" .. sep .. "]+)") do
            local start_pos, _ = row:find(str, offset + 1, true)
            local new_col = base_col + start_pos - 1

            table.insert(t, {
                str = str,
                col = new_col,
                row = row_offset,
            })
            offset = offset + #str + 1
        end

        -- Increment for each new line
        row_offset = row_offset + 1
    end
    return t
end

M.get_root = function(bufnr)
    local parser = vim.treesitter.get_parser(bufnr, "tsx")
    -- vim.treesitter.par
    local tree = parser:parse()[1]

    return tree:root()
end

M.get_longest = function(t, init_len)
    local longest = init_len or 0

    for _, value in ipairs(t) do
        if #value > longest then
            longest = #value
        end
    end

    return longest
end

M.get_tw_client = function()
    local clients = vim.lsp.get_clients({name = "tailwindcss"})

    if not clients[1] then
        print("No tailwindcss client found")
        return
    end

    return clients[1]
end

M.format_to_css = function(t)
    local result = {
        "{"
    }

    for _, value in ipairs(t) do
        table.insert(result, #result + 1, value)
    end

    table.insert(result, #result + 1, "}")

    return result
end



return M
