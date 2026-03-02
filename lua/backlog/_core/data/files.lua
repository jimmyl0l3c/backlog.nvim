local logging = require("mega.logging")

local constants = require("backlog._core.data.constants")

local _LOGGER = logging.get_logger("backlog._core.data.files")

local M = {}

local function ensure_dir(path)
    local dir = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
end

--- Get path to the tasks file.
---@param project backlog.Project
---@return string
function M.tasks_path(project)
    if project.data_path ~= nil and project.data_path ~= "" then return project.data_path end
    return string.format("%s/%s.json", constants.TASKS_DIR, project.id)
end

--- Get path to the task's detail file.
---@param task backlog.Task
---@return string
function M.detail_path(task)
    if task.detail ~= nil and task.detail ~= "" then return task.detail end
    return string.format("%s/%s-%s.json", constants.DETAIL_DIR, task.project, task.id)
end

--- Save current state to file.
---@param path string path to save to
---@param data table data to save
---@return boolean success
function M.save_file(path, data)
    ensure_dir(path)
    local ok, encoded = pcall(vim.fn.json_encode, data)
    if not ok then return false end
    vim.fn.writefile({ encoded }, path)
    return true
end

--- Load projects from JSON and return them.
---@param path string path to the data file
---@return backlog.data.Projects
function M.load_projects(path)
    if vim.fn.filereadable(path) == 0 then
        ---@type backlog.data.Projects
        return { version = constants.VERSION, projects = {} }
    end
    local raw = table.concat(vim.fn.readfile(path), "\n")
    local ok, data = pcall(vim.fn.json_decode, raw)
    if not ok or type(data) ~= "table" then
        _LOGGER:error("backlog: failed to parse " .. path)
        ---@type backlog.data.Projects
        return { version = constants.VERSION, projects = {} }
    end
    data.version = data.version or constants.VERSION
    data.projects = data.projects or {}
    return data
end

--- Load tasks from JSON and return them.
---@param path string path to the data file
---@return backlog.data.Tasks?
function M.load_tasks(path)
    if vim.fn.filereadable(path) == 0 then return nil end
    local raw = table.concat(vim.fn.readfile(path), "\n")
    local ok, data = pcall(vim.fn.json_decode, raw)
    if not ok or type(data) ~= "table" then
        _LOGGER:error("backlog: failed to parse " .. path)
        return nil
    end
    assert(data.project, "project is required field of tasks file")
    data.version = data.version or constants.VERSION
    data.tasks = data.tasks or {}
    return data
end

return M
