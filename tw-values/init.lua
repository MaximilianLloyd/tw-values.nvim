local M = {}

function count_leading_whitespace(line)
    local leadingWhitespace = string.match(line, "^[ \t]*")
    return leadingWhitespace and #leadingWhitespace or 0
end

function mysplit(inputstr, sep, init_col, init_row)
    if sep == nil then
        sep = "%s"
    end
    local t = {}


    -- If there are mulitple new lines
    local row_offset = init_row

    for row in string.gmatch(inputstr, "([^\n]+)") do
        local offset = 0
        local whitespace = count_leading_whitespace(row)
        local base_col = init_col

        if whitespace ~= 0 then
            print("Whitespace found")
            base_col = whitespace
        end

        for str in string.gmatch(row, "([^" .. sep .. "]+)") do
            local start_pos, end_pos = row:find(str, offset + 1, true)
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

local get_root = function(bufnr)
    local parser = vim.treesitter.get_parser(bufnr, "tsx")
    -- vim.treesitter.par
    local tree = parser:parse()[1]

    return tree:root()
end

function TreesitterTest(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local root = get_root(bufnr)
    local cursor = vim.treesitter.get_node({
        bufnr = bufnr,
    })

    if cursor == nil then
        print("No cursor found")
        return
    end

    if cursor:type() ~= "string_fragment" then
        print("Cursor is not a string_fragment")
        return
    end


    local parsed_cursor = vim.treesitter.get_node_text(cursor, bufnr)
    local clients = vim.lsp.get_active_clients()

    local tw = nil

    for _, client in pairs(clients) do
        if client.name == "tailwindcss" then
            tw = client
        end
    end

    if tw == nil then
        print("No tailwindcss client found")
        return
    end

    local results = {
        ".test {"
    }

    local range = { vim.treesitter.get_node_range(cursor) }
    local init_col = range[2]
    local init_row = range[1]

    local classes = mysplit(parsed_cursor, " ", init_col, init_row)

    print(vim.inspect(classes))
    local index = 0
    local longest = 0

    for _, class in ipairs(classes) do
        tw.request("textDocument/hover", {
            textDocument = vim.lsp.util.make_text_document_params(),
            position = {
                line = class.row,
                character = class.col
            }

        }, function(err, result, ctx, config)
            index = index + 1

            if err then
                print("Error getting tailwind config")
                return
            end

            -- print(vim.inspect(result.contents))
            local extracted = Extract(result)

            for i, value in ipairs(extracted) do
                table.insert(results, #results + 1, value)

                if value:len() > longest then
                    longest = #value
                end
            end

            if index == #classes then
                table.insert(results, #results + 1, "}")
                local height = #results + 1

                OpenFloat(results, longest, height)
            end
        end, bufnr)
    end
end

local CLASS_CHAR = "."
local MEDIA_QUER_CHAR = "@"

function Extract(lsp_result)
    local pre_text = lsp_result.contents.value

    local first_char = string.sub(pre_text, 1, 1)

    if first_char == CLASS_CHAR then
        return ExtractClass(pre_text)
    elseif first_char == MEDIA_QUER_CHAR then
        return ExtractMediaQuery(pre_text)
    end

    -- Error
    vim.notify("Unable to extract class, file an issue on github.", vim.log.levels.ERROR)
end

function ExtractClass(text)
    local extracted = vim.split(text, "\n")

    table.remove(extracted, 1)
    table.remove(extracted, #extracted)

    return extracted
end

function ExtractMediaQuery(text)
    local extracted = vim.split(text, "\n")
    return extracted
end

function OpenFloat(results, width, height)
    vim.lsp.util.open_floating_preview(results, "css", {
        border = "rounded",
        width = width,
        height = height,
    })
end


--
vim.keymap.set("n", "<leader>tt", "<cmd>lua TreesitterTest()<cr>", { noremap = true, silent = true })

return M;
