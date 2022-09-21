-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`

--[[ 初始自动安装packer ]]
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

    --[[ 1.检测是否已安装Packer.nvim ]]
    if fn.empty(fn.glob(install_path)) > 0 then
        vim.notify("正在安装Packer.nvim，安装路径如下：" .. install_path)
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
        vim.cmd([[packadd packer.nvim]])
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require("packer").startup({
    function(use)
        -- Packer can manage itself
        use("wbthomason/packer.nvim")

        use({
            "nvim-treesitter/nvim-treesitter",
            run = function()
                require("nvim-treesitter.install").update({ with_sync = true })
            end,
        })
        use("nvim-treesitter/nvim-treesitter-context")

        -- statusline
        use("kyazdani42/nvim-web-devicons")
        use({
            "nvim-lualine/lualine.nvim",
            requires = { "kyazdani42/nvim-web-devicons", opt = true },
        })
        -- using packer.nvim
        -- use {'akinsho/bufferline.nvim', tag = "v2.*", requires = 'kyazdani42/nvim-web-devicons'}

        -- file explorer
        use({
            "kyazdani42/nvim-tree.lua",
            requires = {
                "kyazdani42/nvim-web-devicons", -- optional, for file icons
            },
            tag = "nightly", -- optional, updated every week. (see issue #1193)
        })

        use({
            "lewis6991/gitsigns.nvim",
            -- tag = 'release' -- To use the latest release (do not use this if you run Neovim nightly or dev builds!)
        })

        -- telescope 模糊查找
        use({
            "nvim-telescope/telescope.nvim",
            tag = "0.1.0",
            -- or                            , branch = '0.1.x',
            requires = { { "nvim-lua/plenary.nvim" } },
        })

        -- comment
        use({ "numToStr/Comment.nvim" })

        --LSP
        use({
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "neovim/nvim-lspconfig",
        })
        -- complete
        use({ "hrsh7th/nvim-cmp" })
        -- sources
        use({
            "hrsh7th/cmp-calc",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-vsnip",
            "hrsh7th/cmp-omni",
            "hrsh7th/cmp-emoji",
            "hrsh7th/cmp-nvim-lua",
            "hrsh7th/cmp-nvim-lsp",
            "f3fora/cmp-spell",
            "hrsh7th/cmp-nvim-lsp-document-symbol",
            "hrsh7th/cmp-nvim-lsp-signature-help",
            "ray-x/cmp-treesitter",
        })

        -- diagnostics show
        use({
            "folke/trouble.nvim",
            requires = "kyazdani42/nvim-web-devicons",
        })
        -- theme
        use({
            "shaunsingh/nord.nvim",
        })

        -- If you are using Packer
        use({ "marko-cerovac/material.nvim" })

        -- formatter
        use({ "mhartington/formatter.nvim" })

        if packer_bootstrap then
            require("packer").sync()
        end
    end,
    config = {
        max_jobs = 10,

        -- The default print log level. One of: "trace", "debug", "info", "warn", "error", "fatal".
        log = { level = "info" },

        clone_timeout = 60,

        -- Lua format string used for "aaa/bbb" style plugins
        default_url_format = "https://github.com/%s",
        disable_commands = false,
        display = {
            open_fn = function()
                return require("packer.util").float({
                    border = "rounded",
                })
            end,
        },
        prompt_border = "single",
        profile = {
            enable = true,
            threshold = 1,
        },
        autoremove = true,
    },
})
