--- The main file that implements `project edit` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.project.edit")

local M = {}

--- Edit project.
---
---@param id string The id of the project.
---@param title string The title of the project.
---@param path string The path of the project.
---
function M.run(id, title, path)
    _LOGGER:debug("Running project edit.", id, title, path)

    local data = require("backlog._core.data")

    local p, i = data.find_project(id)
    if not p or not i then
        vim.notify("Project not found: " .. id, vim.log.levels.ERROR)
        return
    end

    data.store.projects[i] = { id = id, title = title or p.title, path = path or p.path }

    vim.notify("Project updated: " .. id, vim.log.levels.INFO)

    if data.save() then vim.notify("Backlog saved.", vim.log.levels.INFO) end
end

return M
