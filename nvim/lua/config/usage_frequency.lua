local M = {}

local function get_data_path(filename)
    return vim.fn.stdpath("data") .. "/" .. filename
end

function M.load(filename, default_value)
    local data_path = get_data_path(filename)

    if vim.fn.filereadable(data_path) ~= 1 then
        return default_value
    end

    local read_ok, data_file = pcall(vim.fn.readfile, data_path)
    if not read_ok then
        vim.notify("无法读取使用频率数据: " .. filename, vim.log.levels.ERROR)
        return default_value
    end

    local decode_ok, data = pcall(vim.json.decode, table.concat(data_file, "\n"))
    if not decode_ok then
        vim.notify("无法解析使用频率数据: " .. filename, vim.log.levels.ERROR)
        return default_value
    end

    return data
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
