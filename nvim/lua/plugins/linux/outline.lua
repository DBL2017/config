return {
    "hedyhli/outline.nvim",
    event = "VeryLazy",
    enabled = true,
    cmd = { "Outline", "OutlineToggle" },
    dependencies = {
        "epheien/outline-treesitter-provider.nvim",
        --  sudo apt install universal-ctags
        "epheien/outline-ctags-provider.nvim",
    },
    config = function()
        require("outline").setup({
            outline_window = {
                position = "right",
                width = 20,
                auto_width = {
                    enabled = true,
                    max_width = 40,
                    include_symbol_details = false,
                },
                relative_width = true,
                auto_close = true,
                auto_jump = false,
                jump_highlight_duration = 300,
                center_on_jump = true,

                show_numbers = true,
                show_relative_numbers = false,
                wrap = false,

                show_cursorline = true,
                hide_cursor = false,

                focus_on_open = true,
                winhl = "",
                no_provider_message = "Nosupportedprovider...",
            },

            outline_items = {
                show_symbol_details = true,
                show_symbol_lineno = false,
                highlight_hovered_item = true,
                auto_set_cursor = true,
                auto_update_events = {
                    follow = { "CursorMoved" },
                    items = { "InsertLeave", "WinEnter", "BufEnter", "BufWinEnter", "TabEnter", "BufWritePost" },
                },
            },

            preview_window = {
                auto_preview = true,
                open_hover_on_preview = true,
                width = 65,
                min_width = 30,
                relative_width = true,
                height = 70,
                min_height = 10,
                relative_height = true,
                border = "rounded",
            },

            providers = {
                priority = { "lsp", "coc", "markdown", "norg", "man", "ctags", "treesitter" },
                lsp = {
                    blacklist_clients = {},
                },
                markdown = {
                    filetypes = { "markdown" },
                },
            },
            symbols = {
                filter = nil,

                icon_fetcher = nil,
                icon_source = nil,
                icons = {
                    File = { icon = "󰈔", hl = "Identifier" },
                    Module = { icon = "󰆧", hl = "Include" },
                    Namespace = { icon = "󰅪", hl = "Include" },
                    Package = { icon = "󰏗", hl = "Include" },
                    Class = { icon = "𝓒", hl = "Type" },
                    Method = { icon = "ƒ", hl = "Function" },
                    Property = { icon = "", hl = "Identifier" },
                    Field = { icon = "󰆨", hl = "Identifier" },
                    Constructor = { icon = "", hl = "Special" },
                    Enum = { icon = "ℰ", hl = "Type" },
                    Interface = { icon = "󰜰", hl = "Type" },
                    Function = { icon = "󰊕", hl = "Function" },
                    Variable = { icon = "", hl = "Constant" },
                    Constant = { icon = "󰏿", hl = "Constant" },
                    String = { icon = "𝓐", hl = "String" },
                    Number = { icon = "#", hl = "Number" },
                    Boolean = { icon = "⊨", hl = "Boolean" },
                    Array = { icon = "󰅪", hl = "Constant" },
                    Object = { icon = "+", hl = "Type" },
                    Key = { icon = "󰌋", hl = "Type" },
                    Null = { icon = "NULL", hl = "Type" },
                    EnumMember = { icon = "", hl = "Identifier" },
                    Struct = { icon = "𝓢", hl = "Structure" },
                    Event = { icon = "🗲", hl = "Type" },
                    Operator = { icon = "+", hl = "Identifier" },
                    TypeParameter = { icon = "𝙏", hl = "Identifier" },
                    Component = { icon = "󰅴", hl = "Function" },
                    Fragment = { icon = "󰅴", hl = "Constant" },
                    TypeAlias = { icon = "", hl = "Type" },
                    Parameter = { icon = "", hl = "Identifier" },
                    StaticMethod = { icon = "", hl = "Function" },
                    Macro = { icon = "", hl = "Function" },
                },
            },
        })
    end,
}
