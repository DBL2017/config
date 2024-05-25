-- 该插件用于配置要安装非lsp server的其他工具
return {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
        "williamboman/mason.nvim",
    },
    config = function()
        require("mason-tool-installer").setup({
            -- a list of all tools you want to ensure are installed upon
            -- start
            ensure_installed = {
                { "black",  version = "22.8.0" },
                { "cmake",  version = "0.1.5" },
                { "stylua", version = "v0.11.1" },
                "jsonlint",
                "jq",
                "beautysh",
                "markdownlint",
                "cmakelang",
                "shellcheck",
                "black",
                { "codespell", version = "2.2.1" },
                { "lua_ls",    version = "3.6.22" }
            },

            -- if set to true this will check each tool for updates. If updates
            -- are available the tool will be updated. This setting does not
            -- affect :MasonToolsUpdate or :MasonToolsInstall.
            -- Default: false
            auto_update = false,

            -- automatically install / update on startup. If set to false nothing
            -- will happen on startup. You can use :MasonToolsInstall or
            -- :MasonToolsUpdate to install tools and check for updates.
            -- Default: true
            run_on_start = true,

            -- set a delay (in ms) before the installation starts. This is only
            -- effective if run_on_start is set to true.
            -- e.g.: 5000 = 5 second delay, 10000 = 10 second delay, etc...
            -- Default: 0
            start_delay = 3000, -- 3 second delay

            -- Only attempt to install if 'debounce_hours' number of hours has
            -- elapsed since the last time Neovim was started. This stores a
            -- timestamp in a file named stdpath('data')/mason-tool-installer-debounce.
            -- This is only relevant when you are using 'run_on_start'. It has no
            -- effect when running manually via ':MasonToolsInstall' etc....
            -- Default: nil
            -- debounce_hours = 5, -- at least 5 hours between attempts to install/update
        })
    end
}
