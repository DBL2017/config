return {
    "igorlfs/nvim-dap-view",
    ependencies = { "mfussenegger/nvim-dap" },
    enabled = true,
    -- -@module 'dap-view'
    -- -@type dapview.Config
    config = function()
        require("dap-view").setup({
            winbar = {
                show = true,
                -- You can add a "console" section to merge the terminal with the other views
                sections = {
                    "sessions",
                    "scopes",
                    "watches",
                    "breakpoints",
                    "exceptions",
                    "threads",
                    "repl",
                    "console",
                    "disassembly",
                },
                -- Must be one of the sections declared above
                default_section = "watches",
                -- Configure each section individually
                base_sections = {
                    breakpoints = {
                        keymap = "B",
                        label = "Breakpoints [B]",
                        short_label = "[B]",
                        action = function()
                            require("dap-view.views").switch_to_view("breakpoints")
                        end,
                    },
                    scopes = {
                        keymap = "S",
                        label = "Scopes [S]",
                        short_label = "[S]",
                        action = function()
                            require("dap-view.views").switch_to_view("scopes")
                        end,
                    },
                    exceptions = {
                        keymap = "E",
                        label = "Exceptions [E]",
                        short_label = "[E]",
                        action = function()
                            require("dap-view.views").switch_to_view("exceptions")
                        end,
                    },
                    watches = {
                        keymap = "W",
                        label = "Watches [W]",
                        short_label = "[W]",
                        action = function()
                            require("dap-view.views").switch_to_view("watches")
                        end,
                    },
                    threads = {
                        keymap = "T",
                        label = "Threads [T]",
                        short_label = "[T]",
                        action = function()
                            require("dap-view.views").switch_to_view("threads")
                        end,
                    },
                    repl = {
                        keymap = "R",
                        label = "REPL [R]",
                        short_label = "[R]",
                        action = function()
                            require("dap-view.repl").show()
                        end,
                    },
                    sessions = {
                        keymap = "K", -- I ran out of mnemonics
                        label = "Sessions [K]",
                        short_label = "[K]",
                        action = function()
                            require("dap-view.views").switch_to_view("sessions")
                        end,
                    },
                    console = {
                        keymap = "C",
                        label = "Console [C]",
                        short_label = "[C]",
                        action = function()
                            require("dap-view.views").switch_to_view("console")
                        end,
                    },
                },
                -- Add your own sections
                custom_sections = {},
                controls = {
                    enabled = true,
                    position = "right",
                    buttons = {
                        "play",
                        "step_into",
                        "step_over",
                        "step_out",
                        "step_back",
                        "run_last",
                        "terminate",
                        "disconnect",
                    },
                    custom_buttons = {},
                },
            },
            windows = {
                height = 0.35,
                position = "below",
                terminal = {
                    width = 0.5,
                    position = "left",
                    -- List of debug adapters for which the terminal should be ALWAYS hidden
                    hide = {},
                    -- Hide the terminal when starting a new session
                    start_hidden = false,
                },
            },
            icons = {
                disabled = "",
                disconnect = "",
                enabled = "",
                filter = "󰈲",
                negate = " ",
                pause = "",
                play = "",
                run_last = "",
                step_back = "",
                step_into = "",
                step_out = "",
                step_over = "",
                terminate = "",
            },
            help = {
                border = "rounded",
            },
            -- Controls how to jump when selecting a breakpoint or navigating the stack
            -- Comma separated list, like the built-in 'switchbuf'. See :help 'switchbuf'
            -- Only a subset of the options is available: newtab, useopen, usetab and uselast
            -- Can also be a function that takes the current winnr and the bufnr that will jumped to
            -- If a function, should return the winnr of the destination window
            switchbuf = "usetab,newtab",
            -- Auto open when a session is started and auto close when all sessions finish
            auto_toggle = true,
            -- Reopen dapview when switching tabs
            follow_tab = true,
        })
        local dap = require("dap")
        local dapview = require("dap-view")
        dap.listeners.before.attach.dapui_config = function()
            dapview.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapview.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapview.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapview.close()
        end
    end,
}
