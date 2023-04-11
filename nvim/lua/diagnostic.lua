-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
vim.diagnostic.config({
    virtual_text = {
        -- source = "always",
        source = "always",
        spacing = 2,
        -- format = function(diagnostic)
        --     if diagnostic.severity == vim.diagnostic.severity.ERROR then
        --         return string.format("E: %s", diagnostic.message)
        --     end
        --     return diagnostic.message
        -- end,
        prefix = "●",
        -- suffix = function(diagnostic)
        --     -- if diagnostic.severity == vim.diagnostic.severity.ERROR then
        --     --     return string.format("E: %s", diagnostic.message)
        --     -- end
        --     vim.inspect(diagnostic.message, { newline = "" })
        --     return diagnostic.code
        -- end,
    },
    signs = true,
    float = {
        show_header = true,
        source = "always",
        border = "rounded",
        focusable = true,
    },
})

local opt = {
    noremap = true,
    silent = true,
}
