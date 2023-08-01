local Utils = require("tw-values.utils")
local Parser = require("tw-values.treesitter")


local M = {}

function M.defaults()
    local defaults = {
        border = "rounded",
    }
    return defaults
end

M.options = {}
-- Not sure how to use this yet
-- M.namespace_id = vim.api.nvim_create_namespace("RegstoreNS")

function M.setup(options)
    options = options or {}
    M.options = vim.tbl_deep_extend("force", M.defaults(), options)
    print(vim.inspect(M.options))
    print("Setup called")
end


function TreesitterTest(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local cursor = vim.treesitter.get_node({
        bufnr = bufnr,
        ignore_injections = false
    })

    if cursor == nil then
        print("No cursor found")
        return
    end

    local parent = cursor:parent()
    local parent_parent = parent:parent()

    print(parent:type(), parent_parent:type())

    local parser = Parser.get_treesitter(bufnr)

    if parser == nil then
        print("No parser found")
        return
    end

    for id, node in parser:iter_captures(parent_parent, bufnr, 0, -1) do
        local name = parser.captures[id]

        if (name == "values") then
            local values = vim.treesitter.get_node_text(node, bufnr)
            local range = { vim.treesitter.get_node_range(node) }


            local tw = Utils.get_tw_client()

            if tw == nil then
                print("No tailwindcss client found")
                return
            end

            local results = {
                "{"
            }

            local init_col = range[2]
            local init_row = range[1]
            local classes = Utils.mysplit(values, " ", init_col, init_row)
            local index = 0
            local unknown_classes = {}

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

                    if result == nil then
                        table.insert(unknown_classes, #unknown_classes + 1, " ." .. class.str)
                    else
                        -- print(vim.inspect(result.contents))
                        local extracted, should_add_newline = Extract(result)

                        if (should_add_newline) then
                            table.insert(extracted, 1, " ")
                        end

                        for i, value in ipairs(extracted) do
                            table.insert(results, #results + 1, value)
                        end
                    end


                    if index == #classes then
                        table.insert(results, #results + 1, "}")
                        local height = #results + 1

                        print(vim.inspect(unknown_classes))
                        local longest = Utils.get_longest(results)

                        OpenFloats(results, unknown_classes, longest, height)
                    end
                end, bufnr)
            end
        end
    end
end

local CLASS_CHAR = "."
local MEDIA_QUER_CHAR = "@"

function Extract(lsp_result)
    local pre_text = lsp_result.contents.value

    -- Get first line
    local first_line = string.match(pre_text, "([^\n]+)")
    local first_char = string.sub(pre_text, 1, 1)
    local is_psuedo_class = string.match(first_line, ":")

    if is_psuedo_class then
        return ExtractWithPadding(pre_text), true
    elseif first_char == CLASS_CHAR then
        return ExtractClass(pre_text), false
    elseif first_char == MEDIA_QUER_CHAR then
        return ExtractWithPadding(pre_text), true
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

function ExtractWithPadding(text)
    local extracted = vim.split(text, "\n")
    print(vim.inspect(extracted))

    local padded = Utils.leftpad_table(extracted, 4, " ")
    return padded
end

function ExtractPseudoClass(text)
    local extracted = vim.split(text, "\n")

    table.remove(extracted, 1)
    table.remove(extracted, #extracted)

    return extracted
end

function OpenFloats(results, uknown_classes, width, height)
    -- If no results, do nothing
    if (#results == 0) then
        return
    end

    local buf, win = vim.lsp.util.open_floating_preview(results, "css", {
        border = M.options.border,
        width = width,
        height = height,
        title = "Tailwind CSS values",
    })

    -- Open a window below it
    local win_info = vim.api.nvim_win_get_position(win)

    if (#uknown_classes == 0) then
        return
    end

    -- Createa  new window
    local extra_buf = vim.api.nvim_create_buf(true, true)
    local new_win_title = "Unknown classes"
    local new_win_width = Utils.get_longest(uknown_classes, #new_win_title)
    vim.api.nvim_buf_set_lines(extra_buf, 0, -1, false, uknown_classes)

    print(M.options.border)

    local new_win = vim.api.nvim_open_win(extra_buf, false, {
        relative = "win",
        row = win_info[1],
        col = win_info[2],
        height = #uknown_classes,
        width = new_win_width,
        style = "minimal",
        title = new_win_title,
        title_pos = "center",
        border = M.options.border,
    })

    vim.api.nvim_create_autocmd({
        'BufWipeout'
    }, {
        buffer = buf,
        callback = function()
            print("Cursor moved")
            vim.api.nvim_win_close(new_win, true)
        end
    })
end

vim.keymap.set("n", "<leader>tt", "<cmd>lua TreesitterTest()<cr>", { noremap = true, silent = true })

return M;
