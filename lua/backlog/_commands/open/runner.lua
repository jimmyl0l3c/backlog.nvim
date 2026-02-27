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

    if detect and not project then
        local path ---@type string
        if vim.bo[0].buftype ~= "" then
            path = assert(vim.uv.cwd())
        else
            path = vim.api.nvim_buf_get_name(0)
        end
        path = vim.fs.abspath(path)

        sidebar.open({ path = path })
        return
    end

    sidebar.open({ project_id = project })
end

return M
