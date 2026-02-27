--- The main file that implements `task edit` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.task.edit")

local M = {}

--- Edit task.
---
---@param id string? The id of the task to edit.
---@param opts backlog.Task
function M.run(id, opts)
    _LOGGER:debug("Running task edit.", id, opts)

    if not id then
        vim.notify("Task id is required.", vim.log.levels.ERROR)
        return
    end

    local data = require("backlog._core.data")

    if not data.edit_task(id, opts) then
        vim.notify("Task could not be updated: " .. id, vim.log.levels.ERROR)
        return
    end

    vim.notify("Task updated: " .. id, vim.log.levels.INFO)

    if data.save() then vim.notify("Backlog saved.", vim.log.levels.INFO) end
end

return M
