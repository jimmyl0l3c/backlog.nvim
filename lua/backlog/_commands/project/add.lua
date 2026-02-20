--- The main file that implements `project add` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.project.add")

local M = {}

--- Add project.
---
---@param id string The id of the new project.
---@param title string The title of the new project.
---@param path string The path of the new project.
---
function M.run(id, title, path)
    _LOGGER:debug("Running project add.", id, title, path)

    local data = require("backlog._core.data")

    if not data.new_project({ id = id, title = title, path = path }) then
        vim.notify("Project could not be created: " .. id, vim.log.levels.ERROR)
        return
    end

    vim.notify("Project created: " .. id, vim.log.levels.INFO)

    if data.save() then vim.notify("Backlog saved.", vim.log.levels.INFO) end
end

return M
