--- The main parser for the `:Backlog open` command.

local cmdparse = require("mega.cmdparse")

local M = {}

---@return mega.cmdparse.ParameterParser # The main parser for the `:Backlog open` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "open", help = "Open tasks of specified project, or all tasks." })

    parser:add_parameter({
        "project",
        required = false,
        type = "string",
        help = "Id of the project",
        choices = function()
            local data = require("backlog._core.data")
            if not data.store or not data.store.projects then return {} end
            return vim.tbl_map(function(project) return project.id end, data.store.projects)
        end,
    })
    parser:add_parameter({
        names = { "--detect", "-d" },
        action = "store_true",
        help = "Detect project",
    })

    parser:set_execute(function(data)
        ---@cast data mega.cmdparse.NamespaceExecuteArguments
        local open_ = require("backlog._commands.open.runner")
        open_.run(data.namespace.project, data.namespace.detect)
    end)

    return parser
end

return M
