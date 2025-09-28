return {
    {
        "mfussenegger/nvim-dap",
        -- tag = "0.9.0",
        commit = "7367cec8e8f7a0b1e4566af9a7ef5959d11206a7",
        event = "VeryLazy",
        config = function()
            local dap = require("dap")
            require("dap").defaults.fallback.switchbuf = "usevisible,usetab,newtab"
            -- require("dap").defaults.fallback.switchbuf = "usevisible,split"
            dap.adapters = {
                gdb = {
                    type = "executable",
                    command = "gdb",
                    args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
                },
                python = function(cb, config)
                    if config.request == "attach" then
                        ---@diagnostic disable-next-line: undefined-field
                        local port = (config.connect or config).port
                        ---@diagnostic disable-next-line: undefined-field
                        local host = (config.connect or config).host or "127.0.0.1"
                        cb({
                            type = "server",
                            port = assert(port, "`connect.port` is required for a python `attach` configuration"),
                            host = host,
                            options = {
                                source_filetype = "python",
                            },
                        })
                    else
                        cb({
                            type = "executable",
                            command = "/home/blduan/.local/share/nvim/mason/packages/debugpy/venv/bin/python",
                            args = { "-m", "debugpy.adapter" },
                            options = {
                                source_filetype = "python",
                            },
                        })
                    end
                end,
            }
            dap.configurations = {
                c = {
                    {
                        name = "Launch",
                        type = "gdb",
                        request = "launch",
                        console = "integratedTerminal",
                        program = function()
                            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                        end,
                        args = {}, -- provide arguments if needed
                        cwd = "${workspaceFolder}",
                        stopAtBeginningOfMainSubprogram = false,
                    },
                    {
                        name = "Select and attach to process",
                        type = "gdb",
                        request = "attach",
                        program = function()
                            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                        end,
                        pid = function()
                            local name = vim.fn.input("Executable name (filter): ")
                            return require("dap.utils").pick_process({ filter = name })
                        end,
                        cwd = "${workspaceFolder}",
                    },
                    {
                        name = "Attach to gdbserver :1234",
                        type = "gdb",
                        request = "attach",
                        target = "localhost:1234",
                        program = function()
                            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                        end,
                        cwd = "${workspaceFolder}",
                    },
                },
                python = {
                    {
                        -- The first three options are required by nvim-dap
                        type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
                        request = "launch",
                        name = "Launch file",
                        console = "integratedTerminal",

                        -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

                        program = "${file}", -- This configuration will launch the current file if used.
                        pythonPath = function()
                            -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
                            -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
                            -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
                            local cwd = vim.fn.getcwd()
                            if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
                                return cwd .. "/venv/bin/python"
                            elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
                                return cwd .. "/.venv/bin/python"
                            else
                                return "/usr/bin/python"
                            end
                        end,
                    },
                },
            }
        end,
    },
}
