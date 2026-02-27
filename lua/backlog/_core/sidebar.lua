local configuration = require("backlog._core.configuration")
local data = require("backlog._core.data")
local states = require("backlog._core.states")
local compositor = require("backlog._core.rendering.compositor")

local header_lines = 1 -- TODO: get from view or compositor

local M = {
    cursor = 1,
    items = {},
    project = nil,
    pending_del = {},
    compositor = nil,
}

--- Update cursor to select specified item, noop if item is not found.
---@param item backlog.Task
local function set_cursor(item, comment_id)
    if not M.compositor or not item then return end

    local index = M.compositor:get_index(item, comment_id)
    if not index then return end

    M.cursor = index
    vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
end

local function render(buf, clean)
    if clean then M.compositor:prepare(M.items) end
    M.compositor:render({ cursor = M.cursor, project = M.project, buf = buf, ns = M.ns })
end

local function update_items(buf, project_id)
    local project = project_id and data.find_project(project_id) or nil
    local items = project_id and data.tasks_for_project(project_id) or vim.tbl_extend("force", {}, data.store.tasks)

    data.sort_tasks(items)

    M.project = project
    M.items = items

    render(buf or M.buf, true)
end

local function map(buf, key, fn, opts)
    opts = vim.tbl_extend("force", { buffer = buf, noremap = true, silent = true }, opts or {})
    vim.keymap.set("n", key, fn, opts)
end

local function map_state(buf, key, state)
    map(buf, key, function()
        local task, _ = M.compositor:get_item(M.cursor)
        if not task then return end

        data.set_task_state(task, state)
        render(buf, true)
    end, nil)
end

_G.sidebar_delete = function(type)
    if not M.compositor or not M.items then return end

    local start_row, end_row

    if type == "line" then
        start_row = vim.api.nvim_buf_get_mark(M.buf, "[")[1]
        end_row = vim.api.nvim_buf_get_mark(M.buf, "]")[1]
    elseif type == "char" then
        start_row = M.cursor
        end_row = M.cursor
    end

    local first = start_row - header_lines
    local last = end_row - header_lines

    local selection = M.compositor:select(first, last)
    local prev = 1

    for _, item in ipairs(selection) do
        table.insert(M.pending_del, item.task.id)

        for j = prev, #M.items do
            if M.items[j].id == item.task.id then
                table.remove(M.items, j)
                prev = j
                break
            end
        end
    end

    M.compositor:prepare(M.items)
    M.cursor = math.min(M.cursor, M.compositor:row_count())
    M.cursor = math.max(M.cursor, 1)

    render(M.buf, false)
    vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
end

local function setup_keymaps(buf)
    map(buf, "j", function()
        M.cursor = math.min(M.cursor + vim.v.count1, M.compositor:row_count())
        render(buf, false)
        vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
    end, nil)

    map(buf, "k", function()
        M.cursor = math.max(M.cursor - vim.v.count1, 1)
        render(buf, false)
        vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
    end, nil)

    for state, keys in pairs(configuration.DATA.keys) do
        for _, key in ipairs(keys) do
            map_state(buf, key, state)
        end
    end

    map(buf, "<CR>", function()
        local task, _ = M.compositor:get_item(M.cursor)
        if not task then return end

        local state = task.state == states.Done and states.ToDo or states.Done
        data.set_task_state(task, state)
        render(buf, true)
    end, nil)

    map(buf, "q", M.close, nil)

    map(buf, "a", function()
        vim.ui.input({ prompt = "Add task" }, function(input)
            if not input then return end
            local project_id = M.project and M.project.id or nil
            data.add_task({ project = project_id, title = input })
            update_items(buf, project_id)
        end)
    end, nil)

    map(buf, "C", function()
        local task, _ = M.compositor:get_item(M.cursor)
        if not task then return end

        vim.ui.input({ prompt = "Add comment to task" }, function(input)
            if not input then return end
            data.add_comment(task, input)
            render(buf, true)
        end)
    end, nil)

    map(buf, "e", function()
        local task, cid = M.compositor:get_item(M.cursor)
        if not task then return end
        local current = cid and task.comments[cid].content or task.title

        vim.ui.input({ prompt = cid and "Edit comment" or "Edit task", default = current }, function(input)
            if not input or input == current then return end
            if cid then
                task.comments[cid].content = input
            else
                task.title = input
            end
            render(buf, true)
        end)
    end, nil)

    map(buf, "+", function()
        local task, cid = M.compositor:get_item(M.cursor)
        if not task then return end

        task.priority = task.priority + vim.v.count1
        data.sort_tasks(M.items)

        M.compositor:prepare(M.items)
        set_cursor(task, cid)
        render(buf, false)
    end, nil)

    map(buf, "-", function()
        local task, cid = M.compositor:get_item(M.cursor)
        if not task then return end

        task.priority = task.priority - vim.v.count1
        data.sort_tasks(M.items)

        M.compositor:prepare(M.items)
        set_cursor(task, cid)
        render(buf, false)
    end, nil)

    map(buf, "t", function()
        local task, _ = M.compositor:get_item(M.cursor)
        if not task then return end

        vim.ui.input({ prompt = "Edit task's ticket", default = task.ticket or "" }, function(input)
            if not input or input == task.ticket then return end

            task.ticket = input
            render(buf, true)
        end)
    end, nil)

    map(buf, "d", function()
        vim.o.operatorfunc = "v:lua.sidebar_delete"
        return "g@"
    end, { expr = true })

    map(buf, "dd", function()
        vim.o.operatorfunc = "v:lua.sidebar_delete"
        return "g@_"
    end, { expr = true })

    map(buf, "dj", function()
        vim.o.operatorfunc = "v:lua.sidebar_delete"
        return "g@j"
    end, { expr = true })

    map(buf, "dk", function()
        vim.o.operatorfunc = "v:lua.sidebar_delete"
        return "g@k"
    end, { expr = true })
end

local function setup_listeners(buf)
    vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = buf,
        callback = function()
            local cur = vim.api.nvim_win_get_cursor(0)[1]
            local first = header_lines + 1
            M.cursor = math.max(cur - header_lines, 1)
            if cur < first then vim.api.nvim_win_set_cursor(0, { first, 0 }) end
            render(buf, false)
        end,
    })

    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            for i = #M.pending_del, 1, -1 do
                local id = M.pending_del[i]
                if data.remove_task(id) then
                    table.remove(M.pending_del, i)
                else
                    vim.notify("Could not delete task: " .. id, vim.log.levels.ERROR)
                end
            end
            data.save()
            vim.bo[buf].modified = false
        end,
    })

    vim.api.nvim_create_autocmd("WinClosed", {
        callback = function(ev)
            if tonumber(ev.match) == M.win then M.win = nil end
        end,
    })
end

local function setup_highlights()
    vim.api.nvim_set_hl(0, "BacklogTitle", { fg = "#c4a7e7", bold = true })
    vim.api.nvim_set_hl(0, "BacklogBorder", { fg = "#45475a" })

    vim.api.nvim_set_hl(0, "BacklogSelected", { link = "Visual" })

    vim.api.nvim_set_hl(0, "BacklogSubtle", { fg = "#908caa" })
    vim.api.nvim_set_hl(0, "BacklogWarn", { fg = "#f6c177" })
    vim.api.nvim_set_hl(0, "BacklogError", { fg = "#ebbcba" })
    vim.api.nvim_set_hl(0, "BacklogHighlight", { fg = "#9ccfd8" })
    vim.api.nvim_set_hl(0, "BacklogDone", { fg = "#a6e3a1" })

    vim.api.nvim_set_hl(0, "BacklogTicket", { fg = "#31748f", bold = true })
    vim.api.nvim_set_hl(0, "BacklogTicketHighlight", { fg = "#9ccfd8", bold = true })
    vim.api.nvim_set_hl(0, "BacklogTicketSubtle", { fg = "#908caa", bold = true })

    vim.api.nvim_set_hl(0, "BacklogName", { fg = "#cdd6f4" })
    vim.api.nvim_set_hl(0, "BacklogNameWarn", { fg = "#f6c177", bold = true })
    vim.api.nvim_set_hl(0, "BacklogNameHighlight", { fg = "#9ccfd8", bold = true })
    vim.api.nvim_set_hl(0, "BacklogNameSubtle", { fg = "#6e6a86", italic = true })
end

--- Open sidebar with specified project's tasks or all when project is nil
---@param opts backlog.ResolveProjectOpts
function M.open(opts)
    if not M.buf then
        M.ns = vim.api.nvim_create_namespace("backlog")

        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(buf, "backlog")
        vim.bo[buf].buftype = "acwrite"

        setup_highlights()
        setup_keymaps(buf)
        setup_listeners(buf)
        M.buf = buf
        M.compositor = compositor:new()
    end

    local project, _ = data.resolve_project(opts)

    update_items(nil, (project or {}).id)

    if not M.win then M.win = vim.api.nvim_open_win(M.buf, true, configuration.DATA.win_opts) end
end

--- Close sidebar. Noop if sidebar is not open.
function M.close()
    if not M.win or not vim.api.nvim_win_is_valid(M.win) then return end
    vim.api.nvim_win_close(M.win, false)
    M.win = nil
end

return M
