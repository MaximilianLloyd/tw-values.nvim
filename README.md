<div align="center">

# tw-values.nvim
#### Show CSS values of all tailwindcss classes on an element

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![TailwindCSS](https://img.shields.io/badge/tailwindcss-%2338B2AC.svg?style=for-the-badge&logo=tailwind-css&logoColor=white)](https://tailwindcss.com)

</div>

![Preview of tw-values.nvim in neovim](/preview.jpg)

---

## WIP

This is a work in progress, if you experience any problems feel free to make an issue or contribute with a PR.

some notes:
- This plugin looks for an existing running tailwind LSP server.
- Under the hood this plugin uses the LSP hover functionality, if this is altered significantly in the tailwind LSP server this plugin can break.

---

## Why did i make this?

When you apply a lot of classes in tailwind, it can be taxing to read through all of them and think about what each one does.

---

## Installation

Install using your favorite plugin manager.

### Packer

```lua
...
use({ "MaximilianLloyd/tw-values.nvim" })
...
```

### Lazy
```lua
...
{
    "MaximilianLloyd/tw-values.nvim",
    keys = {
        { "<leader>sv", "<cmd>TWValues<cr>", desc = "Show tailwind CSS values" },
    },
    opts = {
        border = "rounded", -- Valid window border style,
        show_unknown_classes = true, -- Shows the unknown classes popup
        focus_preview = true, -- Sets the preview as the current window
        copy_register = "", -- The register to copy values to,
        keymaps = {
            copy = "<C-y>"  -- Normal mode keymap to copy the CSS values between {}
        }
    }
},
...
```

---

## Configuration

Right now the configurtion options are quite minmal.

```lua
...
{
    border = "rounded", -- Valid window border style,
    show_unknown_classes = true, -- Shows the unknown classes popup
    focus_preview = false, -- Sets the preview as the current window
    copy_register = "", -- The register to copy values to,
    keymaps = {
        copy = "<C-y>"  -- Normal mode keymap to copy the CSS values between {}
    }
}
...
```
---

## Features

- See the computed values of TW classes.
- Copy CSS values with focus_preview=true, very usefull when porting over to normal CSS.

---

## Supported languages
The currently supported languages are the following:
- typescriptreact
- typescript
- astro
- vue
- svelte
- html

Uses HTML parser as fallback, which works for a lot of variants. Like htmldjango etc.
