return {
    "hat0uma/csvview.nvim",
    lazy = true,
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    config = function()
        require("csvview").setup({
            keymaps = {
                -- Text objects for selecting fields
                textobject_field_inner = { "if", mode = { "o", "x" } },
                textobject_field_outer = { "af", mode = { "o", "x" } },
                -- Excel-like navigation:
                -- Use <Tab> and <S-Tab> to move horizontally between fields.
                -- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
                -- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
                jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
                jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
                jump_next_row = { "<Enter>", mode = { "n", "v" } },
                jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
            },
            parser = { comments = { "#", "//" } },
            view = {
                --- minimum width of a column
                --- @type integer
                min_column_width = 5,

                --- spacing between columns
                --- @type integer
                spacing = 2,

                --- The display method of the delimiter
                --- "highlight" highlights the delimiter
                --- "border" displays the delimiter with `│`
                --- You can also specify it on the command line.
                --- e.g:
                --- :CsvViewEnable display_mode=border
                ---@type CsvView.Options.View.DisplayMode
                display_mode = "border",

                --- The line number of the header row
                --- Controls which line should be treated as the header for the CSV table.
                --- This affects both visual styling and the sticky header feature.
                ---
                --- Values:
                --- - `true`: Automatically detect the header line (default)
                --- - `integer`: Specific line number to use as header (1-based)
                --- - `false`: No header line, treat all lines as data rows
                ---
                --- When a header is defined, it will be:
                --- - Highlighted with the CsvViewHeaderLine highlight group
                --- - Used for the sticky header feature if enabled
                --- - Excluded from normal data processing in some contexts
                ---
                --- See also: `view.sticky_header`
                --- @type integer|false|true
                header_lnum = true,

                --- The sticky header feature settings
                --- If `view.header_lnum` is set, the header line is displayed at the top of the window.
                sticky_header = {
                    --- Whether to enable the sticky header feature
                    --- @type boolean
                    enabled = true,

                    --- The separator character for the sticky header window
                    --- set `false` to disable the separator
                    --- @type string|false
                    separator = "─",
                },
            },
        })
    end,
}
