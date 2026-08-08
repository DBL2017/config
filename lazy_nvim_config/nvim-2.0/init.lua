require("config.basic")
require("config.lazy")
require("config.keymappings")
require("config.autocmds")
local platform = require("config.platform")
if platform.is_linux or platform.is_mac then
    require("config.diagnostic")
end
