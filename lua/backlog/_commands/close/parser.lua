--- The main parser for the `:Backlog close` command.

local cmdparse = require("mega.cmdparse")

local M = {}

---@return mega.cmdparse.ParameterParser # The main parser for the `:Backlog close` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "close", help = "Close sidebar." })

    parser:set_execute(function(_)
        local close_ = require("backlog._commands.close.runner")
        close_.run()
    end)

    return parser
end

return M
