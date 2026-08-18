local M = {}

-- 默认配置
M.options = {
    -- enabled_filetypes can be nil/empty (means all filetypes enabled) or a set/table of filetypes to enable
    enabled_filetypes = nil,
    -- templates: mapping filetype -> { function = {...lines...}, variable = {...}, macro = {...} }
    templates = {},
}

local default_templates = {
    c = {
        ["function"] = {
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
        },
        ["variable"] = {
            "/*",
            " * brief ",
            " */",
        },
        ["macro"] = {
            "/*",
            " * brief ",
            " */",
        },
    },
    cpp = nil, -- will fallback to c
    lua = {
        ["function"] = {
            "--[[",
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
            "--]]",
        },
        ["variable"] = {
            "--[[",
            " * brief ",
            "--]]",
        },
        ["macro"] = {
            "--[[",
            " * brief ",
            "--]]",
        },
    },
}

local function as_set(t)
    -- convert array or map into set map[ft]=true
    if not t then
        return nil
    end
    if type(t) ~= "table" then
        return nil
    end
    local res = {}
    local is_array = (#t > 0)
    if is_array then
        for _, v in ipairs(t) do
            res[v] = true
        end
    else
        -- assume map-like already
        for k, v in pairs(t) do
            if v then
                res[k] = true
            end
        end
    end
    return res
end

function M.setup(opts)
    -- Ensure opts is a table and merge using deep extend
    opts = opts or {}
    if type(opts) ~= "table" then
        vim.notify("nvim-comment: setup expects a table, got " .. type(opts), vim.log.levels.WARN)
        return
    end

    -- shallow merge for top-level options
    M.options = vim.tbl_extend("force", M.options, opts or {})

    -- normalize enabled_filetypes to a set for quick checks
    if M.options.enabled_filetypes then
        M.options._enabled_set = as_set(M.options.enabled_filetypes)
    else
        M.options._enabled_set = nil
    end

    -- ensure templates table exists
    M.options.templates = M.options.templates or {}
end

function M.is_enabled_filetype(ft)
    if not M.options._enabled_set then
        return true
    end
    return M.options._enabled_set[ft] == true
end

function M.get_template(ft, kind, function_state, indent)
    indent = indent or ""
    local templates = M.options.templates
    local ft_templates = templates[ft]
    if not ft_templates then
        -- fallback to default_templates
        ft_templates = default_templates[ft]
        if not ft_templates and ft == "cpp" then
            ft_templates = default_templates["c"]
        end
    end
    if not ft_templates then
        return nil
    end
    local tpl = ft_templates[kind]
    if not tpl then
        return nil
    end

    -- tpl is expected to be a table of lines; make a copy and replace placeholders
    local out = {}
    for i, line in ipairs(tpl) do
        local l = line:gsub("%${function_state}", function_state or "")
        out[i] = indent .. l
    end
    return out
end

return M
