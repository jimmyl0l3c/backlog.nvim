--- The main file that implements `project add` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.project.add")

local M = {}

--- Add project.
---
---@param id string The id of the new project.
---@param title string The title of the new project.
---@param path string The path of the new project.
---@param detect boolean When true, attempts to detect project's root path.
---
function M.run(id, title, path, detect)
    _LOGGER:debug("Running project add.", id, title, path, detect)

    local data = require("backlog._core.data")
    local configuration = require("backlog._core.configuration")

    if detect and not path then path = vim.fs.root(0, configuration.DATA.projects.root_markers) or "" end

    if not data.add_project({ id = id, title = title, path = path }) then return end

    vim.notify("Project created: " .. id, vim.log.levels.INFO)

    if data.save() then vim.notify("Backlog saved.", vim.log.levels.INFO) end
end

return M
