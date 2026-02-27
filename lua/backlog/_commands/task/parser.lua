--- The main parser for the `:Backlog task` command.

local cmdparse = require("mega.cmdparse")

local M = {}

local function stripId(v)
    local _, _, id = string.find(v, "^([^|]+)")
    return id
end

---@return mega.cmdparse.ParameterParser # The main parser for the `:Backlog task` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "task", help = "Task management." })
    local subparsers = parser:add_subparsers({ destination = "commands", help = "All task commands.", required = true })

    local id_choices = {
        "id",
        type = "string",
        help = "The id of the task.",
        required = true,
        choices = function()
            local data = require("backlog._core.data")
            if not data.store or not data.store.tasks then return {} end
            return vim.tbl_map(
                function(task) return table.concat({ task.id, task.project, task.title }, "|") end,
                data.store.tasks
            )
        end,
    }

    local add = subparsers:add_parser({ "add", help = "Add new task." })
    add:add_parameter({
        "project",
        type = "string",
        help = "The id of project.",
        required = true,
        choices = function()
            local data = require("backlog._core.data")
            if not data.store or not data.store.projects then return {} end
            return vim.tbl_map(function(project) return project.id end, data.store.projects)
        end,
    })
    add:add_parameter({ "title", type = "string", help = "Title of the task", required = true })

    local edit = subparsers:add_parser({ "edit", help = "Edit existing task" })
    edit:add_parameter(id_choices)
    edit:add_parameter({
        "field",
        type = "string",
        help = "Field to update",
        required = true,
        choices = function()
            local data = require("backlog._core.data")
            return vim.tbl_filter(
                function(k) return not vim.tbl_contains({ "id", "added_timestamp", "comments" }, k) end,
                vim.tbl_keys(data.new_task({ title = "" }))
            )
        end,
    })
    edit:add_parameter({ "value", type = "string", help = "New value", required = true })

    local delete = subparsers:add_parser({ "delete", help = "Delete task." })
    delete:add_parameter(id_choices)

    add:set_execute(function(args)
        ---@cast args mega.cmdparse.NamespaceExecuteArguments
        local add_ = require("backlog._commands.task.add")
        add_.run(args.namespace.project, args.namespace.title)
    end)

    edit:set_execute(function(args)
        ---@cast args mega.cmdparse.NamespaceExecuteArguments
        local opts = {}
        opts[args.namespace.field] = args.namespace.value

        local id = stripId(args.namespace.id)

        local edit_ = require("backlog._commands.task.edit")
        edit_.run(id, opts)
    end)

    delete:set_execute(function(args)
        ---@cast args mega.cmdparse.NamespaceExecuteArguments
        local id = stripId(args.namespace.id)

        local delete_ = require("backlog._commands.task.delete")
        delete_.run(id)
    end)

    return parser
end

return M
