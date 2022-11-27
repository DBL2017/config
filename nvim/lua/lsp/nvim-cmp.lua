local installStatus = pcall(require, "cmp")
local comparatorStatus = pcall(require, "cmp-under-comparator")
local luasnipStatus = pcall(require, "luasnip")
local cmpbufStatus = pcall(require, "cmp_buffer")

if installStatus == false then
    vim.notify("没有找到cmp")
    return
end

if comparatorStatus == false then
    vim.notify("没有找到cmp-under-comparator")
    return
end

if luasnipStatus == false then
    vim.notify("没有找到luasnip")
    return
end

if cmpbufStatus == false then
    vim.notify("没有找到cmp_buffer")
    return
end

local cmp = require("cmp")
local cmp_under_comparator = require("cmp-under-comparator")
local luasnip = require("luasnip")
local cmp_buffer = require("cmp_buffer")

local kind_icons = {
    Text = "",
    Method = "",
    Function = "",
    Constructor = "",
    Field = "ﰠ",
    Variable = "",
    Class = "ﴯ",
    Interface = "",
    Module = "",
    Property = "ﰠ",
    Unit = "塞",
    Value = "",
    Enum = "",
    Keyword = "",
    Snippet = "",
    Color = "",
    File = "",
    Reference = "",
    Folder = "",
    EnumMember = "",
    Constant = "",
    Struct = "פּ",
    Event = "",
    Operator = "",
    TypeParameter = "",
}

cmp.setup({

    -- 指定 snippet 引擎
    snippet = {
        expand = function(args)
            -- For `luasnip` users.
            luasnip.lsp_expand(args.body)
        end,
    },
    formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
            -- print(vim.inspect(vim_item, { newline = "", indent = "" }))
            -- Kind icons
            ---- This concatonates the icons with the name of the item kind
            vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)
            -- vim_item.kind = kind_icons[vim_item.kind]
            -- vim_item.abbr = global.trim(vim_item.abbr)
            -- print(entry.source.name)
            if entry.source.name == "nvim_lsp" then
                vim_item.abbr = " •" .. vim_item.abbr
            else
                vim_item.abbr = " " .. vim_item.abbr
            end
            -- Source
            vim_item.menu = ({
                nvim_lsp = "[LSP]",
                buffer = "[BUF]",
                npm = "[NPM]",
                ultisnips = "[SNI]",
                latex_symbols = "[LTX]",
                path = "[PTH]",
                look = "[LOK]",
                nerdfont = "[NDF]",
                emoji = "[EMJ]",
                nvim_lua = "[NML]",
            })[entry.source.name] or "[OTH]"

            -- print(vim.inspect(entry.source.name, { newline = "", indent = "" }))
            return vim_item
        end,
    },
    completion = {
        -- autocomplete = false,
        keyword_length = 2,
    },
    -- 提示窗口配置
    window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
        completion = {
            -- border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
            border = "rounded",
            winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
            col_offset = 0,
            side_padding = 1,
        },
        documentation = {
            -- border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
            border = "rounded",
            winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
        },
    },
    -- 快捷键
    mapping = cmp.mapping.preset.insert({
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-q>"] = cmp.mapping.close(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = function(fallback)
            if cmp.visible() then
                cmp.select_next_item({ behavior = cmp.SelectBehavior })
            else
                fallback()
            end
        end,
        ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end,
    }),
    -- 候选排序
    sorting = {
        comparators = {
            -- -- The rest of your comparators...
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp_under_comparator.under,
            function(...)
                cmp_buffer:compare_locality(...)
            end,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
        },
    },
    -- 来源
    sources = cmp.config.sources({
        -- lsp的数据源
        { name = "nvim_lsp" },
        -- For luasnip users.
        { name = "luasnip" },

        {
            name = "buffer",
            option = {
                keyword_pattern = [[\k\+]],
                get_bufnrs = function()
                    local bufs = {}
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        bufs[vim.api.nvim_win_get_buf(win)] = true
                    end
                    return vim.tbl_keys(bufs)
                end,
            },
        },

        -- 它为当前缓冲区中的所有行提供源，该source有重大问题，会导致nvim卡死
        -- { name = "buffer-lines", option = {
        --     max_indents = 1,
        -- } },

        -- nvim-cmp source for omnifunc.
        { name = "omni" },

        --for displaying function signatures with the current parameter emphasized:
        { name = "nvim_lsp_signature_help" },
        -- allows you to autocomplete npm packages and its versions.
        -- The source is only active if you're in a package.json file.
        { name = "npm", keyword_length = 4 },

        -- nvim-cmp source for emojis.
        { name = "emoji" },

        -- nvim-cmp source for nerdfont icons.
        { name = "nerdfont" },

        -- Add latex symbol support for nvim-cmp.
        { name = "lua-latex-symbols", option = { cache = true } },

        -- look command source for nvim-cmp
        {
            name = "look",
            keyword_length = 2,
            option = {
                convert_case = true,
                loud = true,
                --dict = '/usr/share/dict/words'
            },
        },

        -- Using all treesitter highlight nodes as completion candicates. LRU cache is used to improve performance.
        { name = "treesitter" },
    }, {
        --nvim-cmp source for filesystem paths.
        {
            name = "path",
            option = {
                -- 选中目录后是否追加/
                trailing_slash = true,
                label_trailing_slash = true,
            },
        },
    }),
})

-- Use buffer source for `/`.
cmp.setup.cmdline("/", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        -- The purpose is the demonstration customize / search by nvim-cmp.
        { name = "nvim_lsp_document_symbol" },
    }, {
        { name = "buffer" },
    }),
})
-- Use cmdline & path source for ':'.
cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = "path" },
    }, {
        -- nvim-cmp source for vim's cmdline.
        { name = "cmdline" },
    }),
})
-- Only enable `nvim_lua` for nvim_lua
cmp.setup.filetype({ "lua", "Lua" }, {
    sources = {
        -- lsp的数据源
        { name = "nvim_lsp" },
        -- For luasnip users.
        { name = "luasnip" },
        -- nvim-cmp source for neovim Lua API.
        { name = "nvim_lua" },
    },
})

-- Only enable `buffer-lines` for C and C++
cmp.setup.filetype({ "c", "cpp" }, {
    sources = {

        -- lsp的数据源
        { name = "nvim_lsp" },
        -- For luasnip users.
        { name = "luasnip" },
        {
            name = "buffer",
            option = {
                keyword_pattern = [[\k\+]],
                get_bufnrs = function()
                    local bufs = {}
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        bufs[vim.api.nvim_win_get_buf(win)] = true
                    end
                    return vim.tbl_keys(bufs)
                end,
            },
        },

        -- 它为当前缓冲区中的所有行提供源
        { name = "buffer-lines", option = {
            max_indents = 1,
        } },

        -- nvim-cmp source for omnifunc.
        { name = "omni" },

        --for displaying function signatures with the current parameter emphasized:
        { name = "nvim_lsp_signature_help" },
    },
})
