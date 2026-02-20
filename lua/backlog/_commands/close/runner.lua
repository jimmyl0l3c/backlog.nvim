--- The main file that implements `close` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.close")

local M = {}

--- Close tasks sidebar.
function M.run()
    _LOGGER:debug("Closing sidebar.")
    require("backlog._core.sidebar").close()
end

return M
