return {
    "hedyhli/outline.nvim",
    lazy = true,
    tag = "v1.1.0",
    enabled = true,
    cmd = { "Outline", "OutlineToggle" },
    config = function()
        require("outline").setup({
            outline_window = {
                -- Where to open the split window: right/left
                position = "right",
                -- The default split commands used are 'topleft vs' and 'botright vs'
                -- depending on `position`. You can change this by providing your own
                -- `split_command`.
                -- `position` will not be considered if `split_command` is non-nil.
                -- This should be a valid vim command used for opening the split for the
                -- outline window. Eg, 'rightbelow vsplit'.
                -- Width can be included (with will override the width setting below):
                -- Eg, `topleft 20vsp` to prevent a flash of windows when resizing.
                split_command = nil,

                -- Percentage or integer of columns
                width = 20,
                -- Whether width is relative to the total width of nvim
                -- When relative_width = true, this means take 25% of the total
                -- screen width for outline window.
                relative_width = true,

                -- Auto close the outline window if goto_location is triggered and not for
                -- peek_location
                auto_close = true,
                -- Automatically scroll to the location in code when navigating outline window.
                auto_jump = false,
                -- boolean or integer for milliseconds duration to apply a temporary highlight
                -- when jumping. false to disable.
                jump_highlight_duration = 300,
                -- Whether to center the cursor line vertically in the screen when
                -- jumping/focusing. Executes zz.
                center_on_jump = true,

                -- Vim options for the outline window
                show_numbers = true,
                show_relative_numbers = false,
                wrap = false,

                -- true/false/'focus_in_outline'/'focus_in_code'.
                -- The last two means only show cursorline when the focus is in outline/code.
                -- 'focus_in_outline' can be used if the outline_items.auto_set_cursor
                -- operations are too distracting due to visual contrast caused by cursorline.
                show_cursorline = true,
                -- Enable this only if you enabled cursorline so your cursor color can
                -- blend with the cursorline, in effect, as if your cursor is hidden
                -- in the outline window.
                -- This makes your line of cursor have the same color as if the cursor
                -- wasn't focused on the outline window.
                -- This feature is experimental.
                hide_cursor = false,

                -- Whether to auto-focus on the outline window when it is opened.
                -- Set to false to *always* retain focus on your previous buffer when opening
                -- outline.
                -- If you enable this you can still use bangs in :Outline! or :OutlineOpen! to
                -- retain focus on your code. If this is false, retaining focus will be
                -- enforced for :Outline/:OutlineOpen and you will not be able to have the
                -- other behaviour.
                focus_on_open = true,
                -- Winhighlight option for outline window.
                -- See :help 'winhl'
                -- To change background color to "CustomHl" for example, use "Normal:CustomHl".
                winhl = "",
            },
            outline_items = {
                -- Show extra details with the symbols (lsp dependent) as virtual next
                show_symbol_details = true,
                -- Show corresponding line numbers of each symbol on the left column as
                -- virtual text, for quick navigation when not focused on outline.
                -- Why? See this comment:
                -- https://github.com/simrat39/symbols-outline.nvim/issues/212#issuecomment-1793503563
                show_symbol_lineno = false,
                -- Whether to highlight the currently hovered symbol and all direct parents
                highlight_hovered_item = true,
                -- Whether to automatically set cursor location in outline to match
                -- location in code when focus is in code. If disabled you can use
                -- `:OutlineFollow[!]` from any window or `<C-g>` from outline window to
                -- trigger this manually.
                auto_set_cursor = true,
            },

            preview_window = {
                -- Automatically open preview of code location when navigating outline window
                auto_preview = true,
                -- Automatically open hover_symbol when opening preview (see keymaps for
                -- hover_symbol).
                -- If you disable this you can still open hover_symbol using your keymap
                -- below.
                open_hover_on_preview = false,
                width = 50, -- Percentage or integer of columns
                min_width = 30, -- Minimum number of columns
                -- Whether width is relative to the total width of nvim.
                -- When relative_width = true, this means take 50% of the total
                -- screen width for preview window, ensure the result width is at least 50
                -- characters wide.
                relative_width = true,
                height = 70, -- Percentage or integer of lines
                min_height = 10, -- Minimum number of lines
                -- Similar to relative_width, except the height is relative to the outline
                -- window's height.
                relative_height = true,
                -- Border option for floating preview window.
                -- Options include: single/double/rounded/solid/shadow or an array of border
                -- characters.
                -- See :help nvim_open_win() and search for "border" option.
                border = "rounded",
                -- winhl options for the preview window, see ':h winhl'
                winhl = "NormalFloat:",
                -- Pseudo-transparency of the preview window, see ':h winblend'
                winblend = 0,
                -- Experimental feature that let's you edit the source content live
                -- in the preview window. Like VS Code's "peek editor".
                live = false,
            },
        })
    end,
}
