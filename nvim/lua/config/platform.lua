local uv = vim.uv or vim.loop

local M = {}

local function has_compiler()
    return vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1 or vim.fn.executable("zig") == 1
end
-- 判断是否为办公室
local function is_office()
    local val = (os.getenv("OFFICE") or ""):lower()
    return val == "1" or val == "true" or val == "yes" or val == "on"
end

local sysname = uv.os_uname().sysname

M.is_windows = sysname == "Windows_NT"
M.is_linux = sysname == "Linux"
M.is_mac = sysname == "Darwin"
-- :lua print((vim.uv or vim.loop).os_uname().sysname)
M.is_office = is_office()
M.has_compiler = has_compiler()

return M
