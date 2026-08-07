local platform = require("config.platform")

if platform.is_windows then
    return {}
end

return {
    "MysticalDevil/inlay-hints.nvim",
    event = "LspAttach",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
        require("inlay-hints").setup()
    end,
}
