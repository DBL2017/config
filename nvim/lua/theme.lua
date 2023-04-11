-- theme nord
-- vim.cmd[[colorscheme nord]]
--------------------------------
-- theme material
local installStatus = pcall(require, 'material')

if installStatus then
    vim.cmd([[colorscheme material]])
end
