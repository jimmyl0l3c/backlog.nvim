local logging = require("mega.logging")

local _LOGGER = logging.get_logger("backlog._core.data.store")

local constants = require("backlog._core.data.constants")
local files = require("backlog._core.data.files")

local states = require("backlog._core.states")

local M = {
    ---@type backlog.data.Store
    store = { projects = {}, tasks = {} },
}

math.randomseed(os.time())

--- Generate random id
---@return string
local function uid() return string.format("%x%x", os.time(), math.random(0xffff)) end

--- Create a new project based on opts.
---@param opts backlog.Project
---@return backlog.Project
function M.new_project(opts)
    assert(opts.id, "project requires an id")
    ---@type backlog.Project
    return {
        id = opts.id,
        title = opts.title or opts.id,
        tags = opts.tags or {},
        root_path = opts.root_path or "",
        data_path = files.tasks_path(opts),
    }
end

--- Create a new task based on opts.
---@param opts backlog.Task
---@return backlog.Task
function M.new_task(opts)
    assert(opts.title, "task requires a title")
    ---@type backlog.Task
    return {
        id = uid(),
        project = opts.project or constants.GLOBAL_PROJECT.id,
        title = opts.title,
        state = opts.state or "todo",
        deadline = opts.deadline or "",
        ticket = opts.ticket or "",
        priority = opts.priority or 100,
        detail = opts.detail or "",
        added_timestamp = os.date("%Y-%m-%d") --[[@as string]],
        done_timestamp = opts.done_timestamp or "",
        comments = opts.comments or {},
    }
end

--- Create a new task comment.
---@param content string
---@return backlog.TaskComment
function M.new_comment(content)
    return {
        content = content,
        timestamp = os.date("%Y-%m-%d"),
    }
end

function M.init()
    M.store = M.load()

    if #M.store.projects == 0 then
        local m = require("backlog._compat.v0")
        if m.migrate_to_v1() then M.store = M.load() end
    end

    -- Ensure default global project exists
    if not M.find_project(constants.GLOBAL_PROJECT.id) then M.add_project(constants.GLOBAL_PROJECT) end
    if not M.store.tasks[constants.GLOBAL_PROJECT.id] then M.store.tasks[constants.GLOBAL_PROJECT.id] = {} end
end

--- Load all data to data store.
---@return backlog.data.Store
function M.load()
    local projects = files.load_projects(constants.PROJECTS_PATH)
    ---@type backlog.data.Store
    local data = { projects = projects.projects, tasks = {} }
    for _, p in ipairs(projects.projects) do
        local tasks = files.load_tasks(p.data_path)
        if tasks then data.tasks[p.id] = tasks.tasks end
    end
    return data
end

--- Save current state to file.
---@return boolean success
function M.save()
    ---@type backlog.data.Projects
    local projects = { version = constants.VERSION, projects = M.store.projects }
    if not files.save_file(constants.PROJECTS_PATH, projects) then
        vim.notify("backlog: could not save projects", vim.log.levels.ERROR)
        return false
    end

    local path_map = {}
    for _, p in ipairs(M.store.projects) do
        path_map[p.id] = p.data_path
    end

    local failed = 0
    for p, ts in pairs(M.store.tasks) do
        ---@type backlog.data.Tasks
        local tasks = { version = constants.VERSION, project = p, tasks = ts }
        if not files.save_file(path_map[p], tasks) then
            vim.notify("backlog: could not save tasks of " .. p, vim.log.levels.ERROR)
            failed = failed + 1
        end
    end

    return failed == 0
end

--- Add project to backlog
---@param opts backlog.Project project options
---@return backlog.Project?
function M.add_project(opts)
    if not opts.id then
        vim.notify("backlog: project id is required", vim.log.levels.ERROR)
        return nil
    end

    if M.find_project(opts.id) then
        vim.notify("backlog: project id already exists: " .. opts.id, vim.log.levels.ERROR)
        return nil
    end

    local proj = M.new_project(opts)
    table.insert(M.store.projects, proj)
    M.store.tasks[proj.id] = {}
    return proj
end

--- Find project by id.
---@param id string project id
---@return backlog.Project? p, number? i project and its index
function M.find_project(id)
    for i, p in ipairs(M.store.projects) do
        if p.id == id then return p, i end
    end
    return nil
end

--- Attempt to detect project by path.
---@param opts backlog.ResolveProjectOpts?
---@return backlog.Project? p, number? i
function M.resolve_project(opts)
    if not opts then return nil end
    if opts.project_id then return M.find_project(opts.project_id) end

    if not opts.path then return nil end
    _LOGGER:debug("Resolving project based on path.", opts.path)

    local result = nil

    for i, p in ipairs(M.store.projects) do
        local rel = nil
        if p.root_path and p.root_path ~= "" then rel = vim.fs.relpath(p.root_path, opts.path) end

        if rel then
            _LOGGER:debug("Detected project.", rel, p)
            if not result then
                result = { p = p, i = i, rel = rel }
            -- NOTE: find the closest match
            elseif #rel < #result.rel then
                result.p = p
                result.i = i
                result.rel = rel
            end
        end
    end

    if not result then return nil end
    _LOGGER:info("Resolved project.", result.p)
    return result.p, result.i
end

--- Remove project.
---@param id string project id
---@return boolean success
function M.remove_project(id)
    local _, i = M.find_project(id)
    if not i then return false end
    table.remove(M.store.projects, i)
    M.store.tasks[id] = nil
    return true
end

--- Add task to backlog.
---@param opts backlog.Task task options
---@return backlog.Task?
function M.add_task(opts)
    if not opts.title then
        vim.notify("backlog: task title is required", vim.log.levels.ERROR)
        return nil
    end

    opts.project = opts.project or constants.GLOBAL_PROJECT.id

    if not M.find_project(opts.project) then
        vim.notify("backlog: unknown project id: " .. (opts.project or "nil"), vim.log.levels.ERROR)
        return nil
    end

    local task = M.new_task(opts)
    table.insert(M.store.tasks[opts.project], task)
    return task
end

--- Filter tasks by project.
---@param project_id string project id
---@return backlog.Task[]
function M.tasks_for_project(project_id) return vim.tbl_extend("force", {}, M.store.tasks[project_id]) end

--- Return list of all tasks.
---@return backlog.Task[]
function M.all_tasks()
    local all = {}
    for _, ts in pairs(M.store.tasks) do
        vim.list_extend(all, ts)
    end
    return all
end

--- Find task by id.
---@param id string task id
---@return backlog.Task? t, number? i task and its index
function M.find_task(id)
    for _, ts in pairs(M.store.tasks) do
        for i, t in ipairs(ts) do
            if t.id == id then return t, i end
        end
    end
    return nil
end

--- Remove task.
---@param id string task id
---@return boolean success
function M.remove_task(id)
    local t, i = M.find_task(id)
    if not i or not t then return false end
    table.remove(M.store.tasks[t.project], i)
    return true
end

--- Add comment to a task.
---@param task backlog.Task task
---@param content string comment's content
function M.add_comment(task, content) table.insert(task.comments, M.new_comment(content)) end

--- Set tasks state (and done_timestamp if applicable).
---@param task backlog.Task task to update
---@param state backlog.States state
---@return backlog.Task
function M.set_task_state(task, state)
    task.state = state or states.ToDo
    task.done_timestamp = (task.state == states.Done or task.state == states.Cancelled) and os.date("%Y-%m-%d") --[[@as string]]
        or ""
    return task
end

--- Edit task.
---@param task_id string task id
---@param opts backlog.Task changes to apply
---@return backlog.Task?
function M.edit_task(task_id, opts)
    local t, _ = M.find_task(task_id)
    if not t then
        vim.notify("backlog: task not found " .. task_id, vim.log.levels.ERROR)
        return nil
    end

    t.project = opts.project or t.project
    t.title = opts.title or t.title
    t.deadline = opts.deadline or t.deadline
    t.ticket = opts.ticket or t.ticket
    t.priority = opts.priority or t.priority
    t.detail = opts.detail or t.detail
    t.comments = opts.comments or t.comments

    return t
end

--- Comparison function for strings that prefers non-empty strings.
---@param a string
---@param b string
---@return boolean
local function prioritize_nonempty(a, b)
    if #a == 0 or #b == 0 then return a > b end
    return a < b
end

--- Sort tasks in place.
---@param items backlog.Task[]
function M.sort_tasks(items)
    table.sort(items, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        if a.ticket ~= b.ticket then return prioritize_nonempty(a.ticket, b.ticket) end
        if a.project ~= b.project then return prioritize_nonempty(a.project, b.project) end
        return a.title < b.title
    end)
end

return M
