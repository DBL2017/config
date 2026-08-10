return {
    "folke/trouble.nvim",
    version = "v3.7.1",
    opts = {
        focus = true, -- Focus the window when opened
        -- win = {
        --     height = 0.45,
        -- },
        modes = {
            preview_float = {
                mode = "lsp",
                preview = {
                    type = "float",
                    relative = "editor",
                    border = "rounded",
                    title = "Preview",
                    title_pos = "center",
                    position = { 0, -2 },
                    size = { width = 0.3, height = 0.3 },
                    zindex = 200,
                },
            },
        },
    }, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    config = function()
        require("trouble").setup({
            focus = true, -- Focus the window when opened
            win = {
                ---@field type "split"
                ---@field relative "editor" | "win" cursor is only valid for float
                ---@field size number | {width:number, height:number} when a table is provided, either the width or height is used based on the position
                ---@field position "top" | "bottom" | "left" | "right"
                type = "split",
                relative = "win",
                size = { height = 0.5, width = 1 },
                position = "bottom",
                --     type = "float", --vertical
                --     relative = "editor", -- win,cursor
                --     border = "rounded",
                --     title = "Trouble",
                --     title_pos = "center",
                --     size = {
                --         width = 0.4,
                --         height = 0.45,
                --     },
            },
        })
    end,
}
