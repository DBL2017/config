-- ~/.config/nvim/lua/custom/templates.lua
local M = {}

local function generate_c_comment(type)
    local template = {}
    if type == "function" then
        template = {
            "/*",
            " * fn           ${function_state};",
            " * brief        ",
            " * details      ",
            " *",
            " * param[in]    ",
            " * param[out]   ",
            " *",
            " * return       ",
            " * retval       ",
            " *",
            " * note         ",
            " */",
        }
    elseif type == "variable" or type == "macro" then
        template = {
            "/*",
            " * brief ",
            " */",
        }
    end
    -- 替换占位符
    local function_state = vim.api.nvim_get_current_line()
    for i, line in ipairs(template) do
        line = line:gsub("${function_state}", function_state) -- 关键替换
        template[i] = line
    end
    return template
end

-- 注释模板生成器
local COMMENT_TEMPLATE_GENERATOR = {
    ["c"] = generate_c_comment,
}

M.insert_comment = function(type)
    -- local template = {}
    vim.notify(vim.bo.filetype)
    local template = COMMENT_TEMPLATE_GENERATOR[vim.bo.filetype] and COMMENT_TEMPLATE_GENERATOR[vim.bo.filetype](type)
        or vim.notify("No support " .. vim.bo.filetype)
    if template ~= nil then
        vim.api.nvim_buf_set_lines(
            0,
            vim.api.nvim_win_get_cursor(0)[1] - 1,
            vim.api.nvim_win_get_cursor(0)[1] - 1,
            false,
            template
        )
    end
end

return M
