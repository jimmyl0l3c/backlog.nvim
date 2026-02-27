--- The main file that implements `task delete` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.task.delete")

local M = {}

--- Delete task.
---
---@param id string? The id of the task to delete.
function M.run(id)
    _LOGGER:debug("Running task delete.", id)

    if not id then
        vim.notify("Task id is required.", vim.log.levels.ERROR)
        return
    end

    local data = require("backlog._core.data")

    if not data.remove_task(id) then
        vim.notify("Task could not be deleted: " .. id, vim.log.levels.ERROR)
        return
    end

    vim.notify("Task deleted: " .. id, vim.log.levels.INFO)

    if data.save() then vim.notify("Backlog saved.", vim.log.levels.INFO) end
end

return M
