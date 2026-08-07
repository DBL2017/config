local uv = vim.uv or vim.loop

local M = {}

local sysname = uv.os_uname().sysname

M.is_windows = sysname == "Windows_NT"
M.is_linux = sysname == "Linux"
M.is_mac = sysname == "Darwin"

return M
