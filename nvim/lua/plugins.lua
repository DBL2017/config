-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`

--[[ 初始自动安装packer ]]
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

    --[[ 1.检测是否已安装Packer.nvim ]]
    if fn.empty(fn.glob(install_path)) > 0 then
        vim.notify("正在安装Packer.nvim，安装路径如下："..install_path)
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim',install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup({
    function(use)
        -- Packer can manage itself
        use 'wbthomason/packer.nvim'

        --[[ -- Post-install/update hook with neovim command
           [ use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' } ]]

        use {
            'nvim-treesitter/nvim-treesitter',
            run = function() 
                require('nvim-treesitter.install')
                .update({ with_sync = true }) 
            end
        }

        -- statusline
        use {
            'nvim-lualine/lualine.nvim',
            requires = { 'kyazdani42/nvim-web-devicons', opt = true }
        }
        -- using packer.nvim
        use {'akinsho/bufferline.nvim', tag = "v2.*", requires = 'kyazdani42/nvim-web-devicons'}

        use {
            'kyazdani42/nvim-tree.lua',
            requires = {
                'kyazdani42/nvim-web-devicons', -- optional, for file icons
            },
            tag = 'nightly' -- optional, updated every week. (see issue #1193)
        }

        if packer_bootstrap then
            require('packer' ).sync()
        end
    end,
    config = {
        max_jobs = 3,

        -- The default print log level. One of: "trace", "debug", "info", "warn", "error", "fatal".
        log = { level = 'trace' }, 
        
        clone_timeout = 300,

        -- Lua format string used for "aaa/bbb" style plugins
        default_url_format = 'https://github.com/%s',
        disable_commands = false,
        --[[ display = {
           [     open_fn = require('packer.util').float
           [ }, ]]
        profile = {
            enable = true,
            threshold = 1
        },
        autoremove = true
    }
})
