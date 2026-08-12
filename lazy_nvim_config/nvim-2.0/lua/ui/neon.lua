return {
    "rafamadriz/neon",
    enabled = false,
    -- event = "VimEnter",
    event = "VeryLazy",
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
        vim.g.neon_style = "dark"
        -- vim.g.neon_style = "default"
        -- vim.g.neon_style = "light"
        -- vim.cmd({ cmd = "colorscheme", args = { "neon" } })
    end,
}
