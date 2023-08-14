local Utils = require("tw-values.utils")
local Parser = require("tw-values.treesitter")


local M = {}

function M.defaults()
    local defaults = {
        border = "rounded",
        show_unknown_classes = true,
        focus_preview = false,
        copy_register = "",
        keymaps = {
            copy = "<C-y>"
        }
    }
    return defaults
end

M.options = {}
-- Not sure how to use this yet
-- M.namespace_id = vim.api.nvim_create_namespace("RegstoreNS")

function M.setup(options)
    options = options or {}
    M.options = vim.tbl_deep_extend("force", M.defaults(), options)
end

function M.show(bufnr)
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

    -- Returns multiple
    local queries = Parser.get_treesitter(bufnr)

    if queries == nil then
        print("No parser found")
        return
    end

    local found_match = false

    for index, query in ipairs(queries) do
        if found_match then
            break
        end

        for id, node in query:iter_captures(parent, bufnr, 0, -1) do
            found_match = true
            local name = query.captures[id]

            if (name == "values") then
                local values = vim.treesitter.get_node_text(node, bufnr)
                local range = { vim.treesitter.get_node_range(node) }


                local tw = Utils.get_tw_client()

                if tw == nil then
                    vim.notify("No tailwindcss client found", vim.log.levels.ERROR)
                    return
                end

                local results = {}

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
                            vim.notify("Error getting tailwind config", vim.log.levels.ERROR)
                            return
                        end

                        if result == nil then
                            table.insert(unknown_classes, #unknown_classes + 1, " ." .. class.str)
                        else
                            local extracted, should_add_newline = Extract(result)

                            if (should_add_newline) then
                                table.insert(extracted, 1, " ")
                            end

                            for i, value in ipairs(extracted) do
                                table.insert(results, #results + 1, value)
                            end
                        end

                        if index == #classes then
                            OpenFloats(results, unknown_classes)
                        end
                    end, bufnr)
                end
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

    local padded = Utils.leftpad_table(extracted, 4, " ")
    return padded
end

function ExtractPseudoClass(text)
    local extracted = vim.split(text, "\n")

    table.remove(extracted, 1)
    table.remove(extracted, #extracted)

    return extracted
end

function OpenFloats(results, unkownclasses)
    -- If no results, do nothing
    if (#results == 0) then
        return
    end

    -- Indicates that the attribute is not class
    if (#results == 0 and #unkownclasses > 0) then
        return
    end

    local formatted_results = Utils.format_to_css(results)
    local title = "Tailwind CSS values"
    local longest = Utils.get_longest(formatted_results, #title)
    local height = #formatted_results


    local buf, win = vim.lsp.util.open_floating_preview(formatted_results, "css", {
        border = M.options.border,
        width = longest,
        height = height,
        title = "Tailwind CSS values",
    })
    -- Focus buf
    -- Open a window below it
    if (M.options.focus_preview == true) then
        SetKeymaps(buf, win)
    end
    -- Set keymap for buffer to yank text

    if (#unkownclasses == 0 or M.options.show_unknown_classes == false) then
        return
    end

    -- Createa  new window
    local extra_buf = vim.api.nvim_create_buf(true, true)
    local new_win_title = "Unknown classes"
    local new_win_width = Utils.get_longest(unkownclasses, #new_win_title)

    local win_info = vim.api.nvim_win_get_position(win)

    vim.api.nvim_buf_set_lines(extra_buf, 0, -1, false, unkownclasses)

    -- Redraw to get the correct height
    vim.cmd("redraw")

    local new_win = vim.api.nvim_open_win(extra_buf, false, {
        relative = "win",
        win = win,
        row = height + 1,
        col = 0,
        height = #unkownclasses,
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
            vim.api.nvim_win_close(new_win, true)


            -- Set maps back
        end
    })
end

function SetKeymaps(buf, win)
    vim.api.nvim_set_current_win(win)
    vim.keymap.set("n", M.options.keymaps.copy, function ()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        -- Remove first and last
        --
        table.remove(lines, 1)
        table.remove(lines, #lines)

        local joined = table.concat(lines, "\n")

        vim.fn.setreg(M.options.copy_register, joined)
        vim.notify("Copied to clipboard", vim.log.levels.INFO)
    end, {
        buffer = buf,
    })
end

return M;
