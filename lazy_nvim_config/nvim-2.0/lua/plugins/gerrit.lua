return {
    "SafaeOuajih/gerrit.nvim",
    cmd = "Gerrit",
    opts = {},
    branch = "master",
    config = function()
        require("gerrit").setup({

            -- Sent as written: not scoped to the project, not narrowed by max_age.
            dashboard = {
                sections = {
                    { title = "Your changes", query = "status:open owner:self" },
                    { title = "Waiting for you", query = "status:open reviewer:self NOT owner:self is:attention" },
                    { title = "Recently merged", query = "status:merged owner:self limit:10" },
                },
            },
        })
    end,
}
