local M = {}

local standard = function(lang)
	return vim.treesitter.query.parse(
		lang,
		[[
    (attribute
      (attribute_name) @attr_name
        (quoted_attribute_value (attribute_value) @values)
        (#match? @attr_name "class")
    )
    ]]
	)
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

local templ_parser = function()
    return {
        standard("templ")
    }
end

M.parsers = {
    typescriptreact = tsx_parser,
    typescript = typescript_parser,
    astro = astro_parser,
    vue = vue_parser,
    svelte = svelte_parser,
    html = html_parser,
    templ = templ_parser,
}

M.get_treesitter = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local ft = vim.bo[bufnr].ft

    if (M.parsers[ft] == nil) then
        return {
            standard("html")
        }
    end

    return M.parsers[ft]()
end

return M
