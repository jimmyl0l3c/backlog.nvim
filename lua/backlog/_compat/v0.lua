---@class backlog.v0.Projects
---@field projects backlog.v0.Project[]
---@field tasks backlog.v0.Task[]

---@class backlog.v0.Project The project for grouping tasks.
---@field id string Human-readable project id.
---@field title string Optional more descriptive title of a project, uses id otherwise.
---@field path string? Optional path pattern for automatic detection of project.

---@class backlog.v0.Task A task.
---@field id string Automatically generated id used to idetify tasks.
---@field project string Project id the task belongs to.
---@field title string Task title, the main information shown in the backlog.
---@field state backlog.States State of the task, should be one of `backlog.States`
---@field deadline string Optional task deadline, should be in format `%Y-%m-%d`.
---@field ticket string Optional ticket number the task is related to. (e.g. GH issue number)
---@field priority number Priority of the task used for sorting backlog.
---@field detail string Optional path to a markdown file with detailed description of the task.
---@field added_timestamp string Created timestamp, automatically set when creating a task.
---@field done_timestamp string Done/cancelled timestamp, automatically set when state changes to
---@field comments backlog.v0.TaskComment[] Optional comments of a task.

---@class backlog.v0.TaskComment A task comment.
---@field content string Comments content.
---@field timestamp string Created timestamp, automatically set when creating a comment.

local data_root = vim.fn.stdpath("data") .. "/backlog"
local tasks_root = data_root .. "/tasks"
local projects_path = data_root .. "/projects.json"
local data_path = data_root .. "/data.json"

local M = {}

--- Load data from `data.json` and return it.
---@return backlog.v0.Projects
function M._load_v0()
    if vim.fn.filereadable(data_path) == 0 then return { projects = {}, tasks = {} } end
    local raw = table.concat(vim.fn.readfile(data_path), "\n")
    local ok, data = pcall(vim.fn.json_decode, raw)
    if not ok or type(data) ~= "table" then
        vim.notify("backlog: failed to parse data.json", vim.log.levels.ERROR)
        return { projects = {}, tasks = {} }
    end
    data.projects = data.projects or {}
    data.tasks = data.tasks or {}
    return data
end

function M.migrate_to_v1()
    vim.notify("backlog: migrating data structure to v1")

    local data = require("backlog._core.data")

    local legacy_data = M._load_v0()

    ---@type backlog.data.Projects
    local projects = { version = 1, projects = {} }
    local failures = 0

    for _, proj in ipairs(legacy_data.projects) do
        local tasks_path = tasks_root .. "/" .. proj.id .. ".json"
        if proj.id == "global" then tasks_path = data_root .. "global.json" end

        table.insert(projects.projects, {
            id = proj.id,
            title = proj.title,
            tags = {},
            root_path = proj.path or "",
            data_path = tasks_path,
        } --[[@as backlog.Project]])

        ---@type backlog.data.Tasks
        local tasks = {
            version = 1,
            project = proj.id,
            tasks = vim.tbl_filter(function(task)
                ---@cast task backlog.v0.Task
                return task.project == proj.id
            end, legacy_data.tasks),
        }

        if not data.save_file(tasks_path, tasks) then
            vim.notify("backlog: failed to save tasks " .. tasks_path, vim.log.levels.ERROR)
            failures = failures + 1
        end
    end

    if not data.save_file(projects_path, projects) then
        vim.notify("backlog: failed to save projects " .. projects_path, vim.log.levels.ERROR)
        failures = failures + 1
    end

    if failures == 0 then
        local _, ok = pcall(vim.fs.rm, data_path, { force = true })
        if ok then
            vim.notify("backlog: migration finished successfully", vim.log.levels.INFO)
        else
            vim.notify("backlog: data migrated, but failed to remove old data file " .. data_path, vim.log.levels.ERROR)
        end
    else
        vim.notify("backlog: data migrated with errors", vim.log.levels.WARN)
    end
end

return M
