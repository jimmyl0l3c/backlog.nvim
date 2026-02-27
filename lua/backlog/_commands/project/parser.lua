--- The main parser for the `:Backlog project` command.

local cmdparse = require("mega.cmdparse")

local M = {}

---@return mega.cmdparse.ParameterParser # The main parser for the `:Backlog project` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "project", help = "Project management." })
    local subparsers =
        parser:add_subparsers({ destination = "commands", help = "All project commands.", required = true })

    local prj_params = {
        { "title", type = "string", help = "The title of the project." },
        { names = { "--path", "-p" }, type = "string", help = "The root path of the project." },
    }
    local id_choices = {
        "id",
        type = "string",
        help = "The id of the project.",
        required = true,
        choices = function()
            local data = require("backlog._core.data")
            if not data.store or not data.store.projects then return {} end
            return vim.tbl_map(function(project) return project.id end, data.store.projects)
        end,
    }

    local add = subparsers:add_parser({ "add", help = "Add new project." })
    add:add_parameter({ "id", type = "string", help = "The id of the project.", required = true })
    add:add_parameter({
        names = { "--detect", "-d" },
        action = "store_true",
        help = "Detect project root",
    })

    local edit = subparsers:add_parser({ "edit", help = "Edit existing project" })
    edit:add_parameter(id_choices)

    for _, param in ipairs(prj_params) do
        add:add_parameter(param)
        edit:add_parameter(param)
    end

    local delete = subparsers:add_parser({ "delete", help = "Delete project." })
    delete:add_parameter(id_choices)

    add:set_execute(function(data)
        ---@cast data mega.cmdparse.NamespaceExecuteArguments
        local add_ = require("backlog._commands.project.add")
        add_.run(data.namespace.id, data.namespace.title, data.namespace.path, data.namespace.detect)
    end)

    edit:set_execute(function(data)
        ---@cast data mega.cmdparse.NamespaceExecuteArguments
        local edit_ = require("backlog._commands.project.edit")
        edit_.run(data.namespace.id, data.namespace.title, data.namespace.path)
    end)

    delete:set_execute(function(data)
        ---@cast data mega.cmdparse.NamespaceExecuteArguments
        local delete_ = require("backlog._commands.project.delete")
        delete_.run(data.namespace.id)
    end)

    return parser
end

return M
