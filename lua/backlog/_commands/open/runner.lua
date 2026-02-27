--- The main file that implements `open` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._commands.open")

local M = {}

--- Open tasks sidebar and filter tasks by project.
---
---@param project string|nil Id of the project.
---@param detect boolean If specified, attempts to detect project based on current path.
---
function M.run(project, detect)
    _LOGGER:debug("Filtering tasks by project.", project)

    local sidebar = require("backlog._core.sidebar")
    local configuration = require("backlog._core.configuration")

    if detect and not project then
        sidebar.open({ root_markers = configuration.DATA.projects.root_markers })
        return
    end

    sidebar.open({ project_id = project })
end

return M
