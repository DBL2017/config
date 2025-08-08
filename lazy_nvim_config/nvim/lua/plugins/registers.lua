return {
    {
        "tversteeg/registers.nvim",
        cmd = "Registers",
        config = true,
        keys = {
            { '"', mode = { "n", "v" } },
            { "<C-R>", mode = "i" },
        },
        name = "registers",
        config = function()
            local registers = require("registers")
            registers.setup({
                -- Show these registers in the order of the string
                show = '*+"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:',
                -- Show a line at the bottom with registers that aren't filled
                show_empty = false,
                -- Expose the :Registers user command
                register_user_command = true,
                -- Always transfer all selected registers to the system clipboard
                system_clipboard = true,
                -- Don't show whitespace at the begin and end of the register's content
                trim_whitespace = true,
                -- Don't show registers which are exclusively filled with whitespace
                hide_only_whitespace = true,
                -- Show a character next to the register name indicating how the register will be applied
                show_register_types = true,
                events = {
                    -- When a register line is highlighted, show a preview in the main buffer with how the register will be applied, but only if the register will be inserted or pasted
                    on_register_highlighted = registers.preview_highlighted_register({
                        if_mode = { "insert", "paste" },
                    }),
                },
                window = {
                    -- The window can't be wider than 100 characters
                    max_width = 100,
                    -- Show a small highlight in the sign column for the line the cursor is on
                    highlight_cursorline = true,
                    -- Don't draw a border around the registers window
                    border = "rounded",
                    -- Apply a tiny bit of transparency to the the window, letting some characters behind it bleed through
                    transparency = 0,
                },
            })
        end,
    },
}
