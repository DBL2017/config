local ftMap = {
    vim = "indent",
    python = { "indent" },
    git = "",
}
return {
    "kevinhwang91/nvim-ufo",
    enabled = false,
    dependencies = {
        "kevinhwang91/promise-async",
    },
    config = function()
        -- Option 2: nvim lsp as LSP client
        -- Tell the server the capability of foldingRange,
        -- Neovim hasn't added foldingRange to default capabilities, users must add it manually
        -- local capabilities = vim.lsp.protocol.make_client_capabilities()
        -- capabilities.textDocument.foldingRange = {
        --     dynamicRegistration = false,
        --     lineFoldingOnly = true,
        -- }
        -- local language_servers = vim.lsp.get_clients() -- or list servers manually like {'gopls', 'clangd'}
        -- for _, ls in ipairs(language_servers) do
        --     require("lspconfig")[ls].setup({
        --         capabilities = capabilities,
        --         -- you can add other fields for setting up lsp server in this table
        --     })
        -- end
        -- require("ufo").setup()
        --
        -- -- Option 3: treesitter as a main provider instead
        -- (Note: the `nvim-treesitter` plugin is *not* needed.)
        -- ufo uses the same query files for folding (queries/<lang>/folds.scm)
        -- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
        require("ufo").setup({
            -- provider_selector = function(bufnr, filetype, buftype)
            --     -- if you prefer treesitter provider rather than lsp,
            --     -- return ftMap[filetype] or {'treesitter', 'indent'}
            --     return ftMap[filetype]
            --
            --     -- refer to ./doc/example.lua for detail
            -- end,
            provider_selector = function(bufnr, filetype, buftype)
                return { "treesitter", "indent" }
            end,
            open_fold_hl_timeout = 150,
            close_fold_kinds_for_ft = {
                -- default = { "imports", "comment" },
                -- json = { "array" },
                -- c = { "comment", "region" },
            },
            close_fold_current_line_for_ft = {
                default = true,
                c = true,
            },
            preview = {
                win_config = {
                    border = { "", "─", "", "", "", "─", "", "" },
                    winhighlight = "Normal:Folded",
                    winblend = 0,
                },
                mappings = {
                    scrollU = "<C-u>",
                    scrollD = "<C-d>",
                    jumpTop = "[",
                    jumpBot = "]",
                },
            },
            fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = (" 󰁂 %d "):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, { chunkText, hlGroup })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        -- str width returned from truncate() may less than 2nd argument, need padding
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, "MoreMsg" })
                return newVirtText
            end,
        })
    end,
}
