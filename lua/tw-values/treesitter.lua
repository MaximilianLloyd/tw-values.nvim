local M = {}

local standard = function(lang)
    return vim.treesitter.query.parse(lang, [[
      (quoted_attribute_value
      (attribute_value) @values
      )
    ]])
end

local tsx_parser = function()
    return {
        vim.treesitter.query.parse("tsx", [[
            (jsx_attribute
              (property_identifier) @attr_name
              (#match? @attr_name "className")
              (string
              (string_fragment) @values
              )
            )
        ]]),
        vim.treesitter.query.parse("tsx", [[
              (string
              (string_fragment) @values
              )
        ]]),
    }
end

-- For template strings
local typescript_parser = function()
    return {
        standard("html")
    }
end

local astro_parser = function()
    return {
        standard("astro")
    }
end

local vue_parser = function()
    return {
        standard("vue")
    }
end

local svelte_parser = function()
    return {
        standard("svelte")
    }
end

local html_parser = function()
    return {
        standard("html")
    }
end

local htmldjango_parser = function()
    return {
        standard("html")
    }
end

M.parsers = {
    typescriptreact = tsx_parser,
    typescript = typescript_parser,
    astro = astro_parser,
    vue = vue_parser,
    svelte = svelte_parser,
    html = html_parser,
    htmldjango = htmldjango_parser,
}

M.get_treesitter = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local ft = vim.bo[bufnr].ft

    if (M.parsers[ft] == nil) then
        vim.notify("No parser found for " .. ft, vim.log.levels.ERROR)
        return
    end

    return M.parsers[ft]()
end

return M
