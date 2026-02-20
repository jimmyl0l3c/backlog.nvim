--- The main file that implements `open` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.open")

local M = {}

--- Open tasks sidebar and filter tasks by project.
---
---@param project string|nil Id of the project.
---
function M.run(project)
    _LOGGER:debug("Filtering tasks by project.", project)

    local data = require("backlog._core.data")

    local items = project and data.tasks_for_project(project) or data.store.tasks

    require("backlog._core.sidebar").open(items)
end

return M
