--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local data = require("backlog._core.data")
local configuration = require("backlog._core.configuration")

local open_cmd = require("backlog._commands.open.runner")
local close_cmd = require("backlog._commands.close.runner")

local M = {}

configuration.initialize_data_if_needed()
data.load()

--- Update plugin configuration.
---
---@param opts backlog.Configuration All of the user's fallback settings.
---
function M.setup(opts) vim.g.backlog_configuration = opts end

--- Open sidebar with tasks of specified project, or with all if project is nil.
---
---@param project string? project id to filter tasks
function M.open_sidebar(project) open_cmd.run(project) end

--- Close tasks sidebar.
function M.close_sidebar() close_cmd.run() end

-- TODO: expose project add, edit, delete
-- TODO: expose task add, edit, delete

return M
