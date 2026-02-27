--- The main file that implements `task add` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.task.add")

local M = {}

--- Add task.
---
---@param project_id string? The id of the project.
---@param title string The title of the new task.
---
function M.run(project_id, title)
    _LOGGER:debug("Running task add.", project_id, title)

    local data = require("backlog._core.data")

    if not data.add_task({ project = project_id, title = title }) then
        vim.notify("Task could not be created.", vim.log.levels.ERROR)
        return
    end

    vim.notify("Task created.", vim.log.levels.INFO)

    if data.save() then vim.notify("Backlog saved.", vim.log.levels.INFO) end
end

return M
