--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local store = require("backlog._core.data.store")
local configuration = require("backlog._core.configuration")

local open_cmd = require("backlog._commands.open.runner")
local close_cmd = require("backlog._commands.close.runner")

local M = {}

configuration.initialize_data_if_needed()
store.init()

--- Update plugin configuration.
---
---@param opts backlog.Configuration All of the user's fallback settings.
---
function M.setup(opts) vim.g.backlog_configuration = opts end

--- Open sidebar with tasks of specified project, or with all if project is nil.
---
---@param project string? project id to filter tasks
---@param detect boolean if true, attempts to detect project based on current path
function M.open_sidebar(project, detect) open_cmd.run(project, detect) end

--- Close tasks sidebar.
function M.close_sidebar() close_cmd.run() end

--- Add a new project
---@param opts backlog.Project
---@return backlog.Project?
function M.add_project(opts) return store.add_project(opts) end

--- Edit project
---@param id string
---@param opts backlog.Project
---@return backlog.Project?
function M.edit_project(id, opts)
    local p, i = store.find_project(id)
    if not p or not i then
        vim.notify("Project not found: " .. id, vim.log.levels.ERROR)
        return nil
    end

    p.title = opts.title or p.title
    p.root_path = opts.root_path or p.root_path
    return p
end

--- Delete project
---@param id string
---@return boolean success
function M.delete_project(id) return store.remove_project(id) end

--- Add new task
---@param opts backlog.Task
---@return backlog.Task?
function M.add_task(opts) return store.add_task(opts) end

--- Edit task
---@param id string
---@param opts backlog.Task
---@return backlog.Task?
function M.edit_task(id, opts) return store.edit_task(id, opts) end

--- Delete task
---@param id string
---@return boolean success
function M.delete_task(id) return store.remove_task(id) end

return M
