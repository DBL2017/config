-- ~/.config/nvim/lua/custom/custom_comment.lua
local config = require("nvim-comment.config")
local M = {}

local function trim(s)
    return s:match("^%s*(.-)%s*$") or ""
end

local function extract_name(line)
    if not line then
        return ""
    end
    line = trim(line)
    -- naive: return the trimmed line so templates can use it; users can provide better extractors in future
    return line
end

M.insert_comment = function(kind)
    local ft = vim.bo.filetype or ""

    if not config.is_enabled_filetype(ft) then
        vim.notify("nvim-comment: filetype not enabled for comment generation: " .. ft, vim.log.levels.WARN)
        return
    end

    local row0 = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based insert index
    local cur_line = vim.api.nvim_buf_get_lines(0, row0, row0 + 1, false)[1] or ""
    local name = extract_name(cur_line)
    local indent = cur_line:match("^(%s*)") or ""

    local template = config.get_template(ft, kind, name, indent)
    if not template then
        vim.notify("nvim-comment: No template for filetype='" .. ft .. "' kind='" .. tostring(kind) .. "'", vim.log.levels.WARN)
        return
    end

    -- insert before current line (maintains cursor on original line)
    vim.api.nvim_buf_set_lines(0, row0, row0, false, template)
end

return M
