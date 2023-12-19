--[[ require("bufferline").setup{
    options = {
        mode = "buffers",
        numbers = function(opts)
            return string.format('%s.%s', opt.raise(opts.id), opts.lower(opts.ordinal))
        end
    }
} ]]
