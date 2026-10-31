local M = {}

local function get_data_path(filename)
    return vim.fn.stdpath("data") .. "/" .. filename
end

function M.load(filename, default_value)
    local data_path = get_data_path(filename)

    if vim.fn.filereadable(data_path) ~= 1 then
        return default_value
    end

    -- readfile 失败时返回空表并设置 v:errmsg,不抛 Lua 错误,
    -- 因此 pcall(readfile) 的防护是空转的;前面的 filereadable 检查已足够
    local data = vim.fn.readfile(data_path)

    local decode_ok, data_table = pcall(vim.json.decode, table.concat(data, "\n"))
    if not decode_ok then
        vim.notify("无法解析使用频率数据: " .. filename, vim.log.levels.ERROR)
        return default_value
    end

    return data_table
end

function M.save(filename, data)
    local encode_ok, encoded_data = pcall(vim.json.encode, data)
    if not encode_ok then
        vim.notify("无法编码使用频率数据: " .. filename, vim.log.levels.ERROR)
        return false
    end

    local data_path = get_data_path(filename)
    vim.fn.mkdir(vim.fn.fnamemodify(data_path, ":h"), "p")
    if vim.fn.writefile({ encoded_data }, data_path) ~= 0 then
        vim.notify("无法保存使用频率数据: " .. filename, vim.log.levels.ERROR)
        return false
    end

    return true
end

return M
