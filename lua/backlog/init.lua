--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local data = require("backlog._core.data")
local configuration = require("backlog._core.configuration")

local open_cmd = require("backlog._commands.open.runner")
local close_cmd = require("backlog._commands.close.runner")

local M = {}

configuration.initialize_data_if_needed()
data.init()

--- Update plugin configuration.
---
---@param opts backlog.Configuration All of the user's fallback settings.
---
function M.setup(opts) vim.g.backlog_configuration = opts end

--- Open sidebar with tasks of specified project, or with all if project is nil.
---
---@param project string? project id to filter tasks
function M.open_sidebar(project) open_cmd.run(project) end

--- Close tasks sidebar.
function M.close_sidebar() close_cmd.run() end

--- Add a new project
---@param opts backlog.Project
---@return backlog.Project?
function M.add_project(opts) return data.add_project(opts) end

--- Edit project
---@param id string
---@param opts backlog.Project
---@return backlog.Project?
function M.edit_project(id, opts)
    local p, i = data.find_project(id)
    if not p or not i then
        vim.notify("Project not found: " .. id, vim.log.levels.ERROR)
        return nil
    end

    p.title = opts.title or p.title
    p.path = opts.path or p.path
    return p
end

--- Delete project
---@param id string
---@return boolean success
function M.delete_project(id) return data.remove_project(id) end

--- Add new task
---@param opts backlog.Task
---@return backlog.Task?
function M.add_task(opts) return data.add_task(opts) end

--- Edit task
---@param id string
---@param opts backlog.Task
---@return backlog.Task?
function M.edit_task(id, opts) return data.edit_task(id, opts) end

--- Delete task
---@param id string
---@return boolean success
function M.delete_task(id) return data.remove_task(id) end

return M
