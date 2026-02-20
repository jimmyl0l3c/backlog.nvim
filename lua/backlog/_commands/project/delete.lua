--- The main file that implements `project delete` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.project.delete")

local M = {}

--- Delete project.
---
---@param id string The id of the project to delete.
---
function M.run(id)
    _LOGGER:debug("Running project delete.", id)

    local data = require("backlog._core.data")

    if not data.remove_project(id) then
        vim.notify("Project could not be deleted: " .. id, vim.log.levels.ERROR)
        return
    end

    vim.notify("Project deleted: " .. id, vim.log.levels.INFO)

    if data.save() then vim.notify("Backlog saved.", vim.log.levels.INFO) end
end

return M
