return {
    tplink = {
        username = function()
            return os.getenv("TPLINK_USERNAME")
        end,
        password = function()
            return os.getenv("TPLINK_PASSWORD")
        end,
    },
    siliconflow = {
        api_key = function()
            return os.getenv("SILICONFLOW_API_KEY")
        end,
    },
    kimi = {
        api_key = function()
            return os.getenv("KIMI_API_KEY")
        end,
    },
    claude = {
        api_key = function()
            return os.getenv("CLAUDE_API_KEY")
        end,
    },
    copilot = {
        api_key = function()
            return os.getenv("GITHUB_TOKEN")
        end,
    },
    dashscope = {
        api_key = function()
            return os.getenv("DASHSCOPE_API_KEY")
        end,
    },
}
