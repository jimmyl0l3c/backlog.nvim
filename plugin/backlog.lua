--- All `backlog` command definitions.

local cmdparse = require("mega.cmdparse")

local _PREFIX = "Backlog"

---@type mega.cmdparse.ParserCreator
local _SUBCOMMANDS = function()
    local project_cmd = require("backlog._commands.project.parser")
    local task_cmd = require("backlog._commands.task.parser")
    local open_cmd = require("backlog._commands.open.parser")
    local close_cmd = require("backlog._commands.close.parser")

    local parser = cmdparse.ParameterParser.new({ name = _PREFIX, help = "The root of all commands." })
    local subparsers = parser:add_subparsers({ "commands", help = "All runnable commands." })

    subparsers:add_parser(project_cmd.make_parser())
    subparsers:add_parser(task_cmd.make_parser())
    subparsers:add_parser(open_cmd.make_parser())
    subparsers:add_parser(close_cmd.make_parser())

    return parser
end

cmdparse.create_user_command(_SUBCOMMANDS, _PREFIX)

vim.keymap.set("n", "<Plug>(BacklogSayHi)", function()
    local configuration = require("backlog._core.configuration")
    -- local backlog = require("backlog")

    configuration.initialize_data_if_needed()

    require("backlog._core.sidebar").open(nil)
end, { desc = "Open task sidebar." })
