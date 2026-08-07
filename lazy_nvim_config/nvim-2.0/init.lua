require("config.basic")
require("config.lazy")
require("config.keymappings")
require("config.autocmds")
local os = require("config.os")
if os.is_linux or os.is_mac then
    require("config.lspconfig")
    require("config.diagnostic")
end
