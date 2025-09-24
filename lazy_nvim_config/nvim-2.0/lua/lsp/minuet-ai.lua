return {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("minuet").setup({
            -- Your configuration options here
            provider = "openai_compatible",
            n_completions = 1, -- recommend for local model for resource saving
            -- I recommend beginning with a small context window size and incrementally
            -- expanding it, depending on your local computing power. A context window
            -- of 512, serves as an good starting point to estimate your computing
            -- power. Once you have a reliable estimate of your local computing power,
            -- you should adjust the context window to a larger value.
            context_window = 512,
            provider_options = {
                openai_compatible = {
                    model = "qwen2.5-coder-32b-instruct",
                    -- system = "see [Prompt] section for the default value",
                    -- few_shots = "see [Prompt] section for the default value",
                    -- chat_input = "See [Prompt Section for default value]",
                    stream = true,
                    end_point = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
                    api_key = function()
                        return os.getenv("QWEN3_CODER_PLUS_2025")
                    end,
                    name = "dashscope",
                    optional = {
                        stop = nil,
                        max_tokens = nil,
                    },
                },
                -- openai_fim_compatible = {
                --     -- For Windows users, TERM may not be present in environment variables.
                --     -- Consider using APPDATA instead.
                --     api_key = "TERM",
                --     name = "Ollama",
                --     end_point = "http://192.168.100.1:11434/v1/completions",
                --     model = "qwen2.5-coder:0.5b",
                --     optional = {
                --         max_tokens = 56,
                --         top_p = 0.9,
                --     },
                -- },
            },
        })
    end,
}
