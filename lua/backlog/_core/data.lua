local M = { store = {} }

local data_path = vim.fn.stdpath("data") .. "/backlog/data.json"

local function ensure_dir()
    local dir = vim.fn.fnamemodify(data_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
end

function M.new_project(opts)
    assert(opts.id, "project requires an id")
    assert(opts.title, "project requires a title")
    return {
        id = opts.id,
        title = opts.title,
        path = opts.path or "",
    }
end

function M.new_task(opts)
    assert(opts.project, "task requires a project id")
    assert(opts.title, "task requires a title")
    return {
        project = opts.project, -- project.id
        title = opts.title,
        state = opts.state or "todo",
        deadline = opts.deadline or "",
        ticket = opts.ticket or "",
        priority = opts.priority or 100,
        detail = opts.detail or "",
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
    -- Ensure both keys exist
    data.projects = data.projects or {}
    data.tasks = data.tasks or {}
    M.store = data
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
    if M.find_project(opts.id) then
        vim.notify("backlog: project id already exists: " .. opts.id, vim.log.levels.WARN)
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
    if not M.find_project(opts.project) then
        vim.notify("backlog: unknown project id: " .. opts.project, vim.log.levels.ERROR)
        return nil
    end
    local task = M.new_task(opts)
    table.insert(M.store.tasks, task)
    return task
end

function M.tasks_for_project(project_id)
    return vim.tbl_filter(function(t) return t.project == project_id end, M.store.tasks)
end

function M.find_task(project_id, title)
    for i, t in ipairs(M.store.tasks) do
        if t.project == project_id and t.title == title then return t, i end
    end
    return nil
end

function M.add_comment(task_index, content)
    local task = M.store.tasks[task_index]
    if not task then
        vim.notify("backlog: task not found at index " .. task_index, vim.log.levels.WARN)
        return
    end
    table.insert(task.comments, M.new_comment(content))
end

return M
