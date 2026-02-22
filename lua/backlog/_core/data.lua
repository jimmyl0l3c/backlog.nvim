local states = require("backlog._core.states")

local data_path = vim.fn.stdpath("data") .. "/backlog/data.json"

local global_project = {
    id = "global",
    title = "Global",
    path = nil,
}

local M = { store = {} }

local function ensure_dir()
    local dir = vim.fn.fnamemodify(data_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
end

math.randomseed(os.time())
local function uid() return string.format("%x%x", os.time(), math.random(0xffff)) end

function M.new_project(opts)
    assert(opts.id, "project requires an id")
    return {
        id = opts.id,
        title = opts.title or opts.id,
        path = opts.path or "",
    }
end

function M.new_task(opts)
    assert(opts.title, "task requires a title")
    return {
        id = uid(),
        project = opts.project or global_project.id,
        title = opts.title,
        state = opts.state or "todo",
        deadline = opts.deadline or "",
        ticket = opts.ticket or "",
        priority = opts.priority or 100,
        detail = opts.detail or "",
        added_timestamp = os.date("%Y-%m-%d"),
        done_timestamp = opts.done_timestamp or "",
        comments = opts.comments or {},
    }
end

function M.new_comment(content)
    return {
        content = content,
        timestamp = os.date("%Y-%m-%d"),
    }
end

function M.load()
    if vim.fn.filereadable(data_path) == 0 then return { projects = {}, tasks = {} } end
    local raw = table.concat(vim.fn.readfile(data_path), "\n")
    local ok, data = pcall(vim.fn.json_decode, raw)
    if not ok or type(data) ~= "table" then
        vim.notify("backlog: failed to parse data.json", vim.log.levels.ERROR)
        return { projects = {}, tasks = {} }
    end
    data.projects = data.projects or {}
    data.tasks = data.tasks or {}
    M.store = data
    if not M.find_project(global_project.id) then M.add_project(global_project) end
end

function M.save()
    ensure_dir()
    local ok, encoded = pcall(vim.fn.json_encode, M.store)
    if not ok then
        vim.notify("backlog: failed to encode data", vim.log.levels.ERROR)
        return false
    end
    vim.fn.writefile({ encoded }, data_path)
    return true
end

function M.add_project(opts)
    if not opts.id then
        vim.notify("project id is required", vim.log.levels.ERROR)
        return nil
    end

    if M.find_project(opts.id) then
        vim.notify("backlog: project id already exists: " .. opts.id, vim.log.levels.ERROR)
        return nil
    end
    local proj = M.new_project(opts)
    table.insert(M.store.projects, proj)
    return proj
end

function M.find_project(id)
    for i, p in ipairs(M.store.projects) do
        if p.id == id then return p, i end
    end
    return nil
end

function M.remove_project(id)
    local _, i = M.find_project(id)
    if not i then return false end
    table.remove(M.store.projects, i)
    M.store.tasks = vim.tbl_filter(function(t) return t.project ~= id end, M.store.tasks)
    return true
end

function M.add_task(opts)
    if not opts.title then
        vim.notify("backlog: task title is required", vim.log.levels.ERROR)
        return nil
    end

    opts.project = opts.project or global_project.id

    if not M.find_project(opts.project) then
        vim.notify("backlog: unknown project id: " .. (opts.project or "nil"), vim.log.levels.ERROR)
        return nil
    end
    local task = M.new_task(opts)
    table.insert(M.store.tasks, task)
    return task
end

function M.tasks_for_project(project_id)
    return vim.tbl_filter(function(t) return t.project == project_id end, M.store.tasks)
end

function M.find_task(id)
    for i, p in ipairs(M.store.tasks) do
        if p.id == id then return p, i end
    end
    return nil
end

function M.remove_task(id)
    local _, i = M.find_task(id)
    if not i then return false end
    table.remove(M.store.tasks, i)
    return true
end

function M.add_comment(task_index, content)
    local task = M.store.tasks[task_index]
    if not task then
        vim.notify("backlog: task not found at index " .. task_index, vim.log.levels.WARN)
        return
    end
    table.insert(task.comments, M.new_comment(content))
end

function M.edit_task(task_id, opts)
    local p, i = M.find_task(task_id)
    if not p or not i then
        vim.notify("backlog: task not found", vim.log.levels.ERROR)
        return nil
    end

    local updated = {
        id = p.id,
        project = opts.project or p.project,
        title = opts.title or p.title,
        state = p.state,
        deadline = opts.deadline or p.deadline,
        ticket = opts.ticket or p.ticket,
        priority = opts.priority or p.priority,
        detail = opts.detail or p.detail,
        added_timestamp = p.added_timestamp,
        done_timestamp = p.done_timestamp,
        comments = opts.comments or p.comments,
    }
    M.store.tasks[i] = updated
    return updated
end

function M.set_task_state(task_id, state)
    local p, i = M.find_task(task_id)
    if not p or not i then
        vim.notify("backlog: task not found", vim.log.levels.ERROR)
        return nil
    end

    p.state = state or "todo"
    p.done_timestamp = (p.state == states.Done or p.state == states.Cancelled) and os.date("%Y-%m-%d") or ""
    M.store.tasks[i] = p
    return p
end

return M
