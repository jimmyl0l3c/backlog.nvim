local configuration = require("backlog._core.configuration")
local data = require("backlog._core.data")
local states = require("backlog._core.states")
local renderer = require("backlog._core.renderer")

local header_lines = 1

local M = {
    cursor = 1,
    items = {},
    project = nil,
    pending_del = {},
}

--- Update cursor to select specified item, noop if item is not found.
---@param item backlog.Task
local function set_cursor(item)
    if not M.items or not item then return end

    for i, p in ipairs(M.items) do
        if p.id == item.id then
            M.cursor = i
            vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
            return
        end
    end
end

local function render(buf)
    renderer.render({ cursor = M.cursor, items = M.items, project = M.project, buf = buf, ns = M.ns })
end

local function update_items(buf, project_id)
    local project = project_id and data.find_project(project_id) or nil
    local items = project_id and data.tasks_for_project(project_id) or vim.tbl_extend("force", {}, data.store.tasks)

    data.sort_tasks(items)

    M.project = project
    M.items = items

    render(buf or M.buf)
end

local function map(buf, key, fn, opts)
    opts = vim.tbl_extend("force", { buffer = buf, noremap = true, silent = true }, opts or {})
    vim.keymap.set("n", key, fn, opts)
end

local function map_state(buf, key, state)
    map(buf, key, function()
        local item = M.items[M.cursor]
        if not item then return end

        data.set_task_state(item, state)
        render(buf)
    end, nil)
end

_G.sidebar_delete = function(type)
    if not M.items then return end

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

    first = math.max(1, first)
    last = math.min(#M.items, last)

    if first > last then return end

    for _ = first, last do
        table.insert(M.pending_del, M.items[first].id)
        table.remove(M.items, first)
    end

    M.cursor = math.min(M.cursor, #M.items)
    M.cursor = math.max(M.cursor, 1)

    render(M.buf)
    vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
end

local function setup_keymaps(buf)
    map(buf, "j", function()
        M.cursor = math.min(M.cursor + vim.v.count1, #M.items)
        render(buf)
        vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
    end, nil)

    map(buf, "k", function()
        M.cursor = math.max(M.cursor - vim.v.count1, 1)
        render(buf)
        vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
    end, nil)

    for state, keys in pairs(configuration.DATA.keys) do
        for _, key in ipairs(keys) do
            map_state(buf, key, state)
        end
    end

    map(buf, "<CR>", function()
        local item = M.items[M.cursor]
        if not item then return end

        local state = item.state == states.Done and states.ToDo or states.Done
        data.set_task_state(item, state)
        render(buf)
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
        local item = M.items[M.cursor]
        if not item then return end

        vim.ui.input({ prompt = "Add comment to task" }, function(input)
            if not input then return end
            data.add_comment(item, input)
            render(buf)
        end)
    end, nil)

    map(buf, "e", function()
        local item = M.items[M.cursor]
        if not item then return end

        vim.ui.input({ prompt = "Edit task", default = item.title }, function(input)
            if not input or input == item.title then return end
            item.title = input
            render(buf)
        end)
    end, nil)

    map(buf, "+", function()
        local item = M.items[M.cursor]
        if not item then return end

        item.priority = item.priority + vim.v.count1
        data.sort_tasks(M.items)
        set_cursor(item)
        render(buf)
    end, nil)

    map(buf, "-", function()
        local item = M.items[M.cursor]
        if not item then return end

        item.priority = item.priority - vim.v.count1
        data.sort_tasks(M.items)
        set_cursor(item)
        render(buf)
    end, nil)

    map(buf, "t", function()
        local item = M.items[M.cursor]
        if not item then return end
        vim.ui.input({ prompt = "Edit task's ticket", default = item.ticket or "" }, function(input)
            if not input or input == item.ticket then return end

            item.ticket = input
            render(buf)
        end)
    end, nil)

    map(buf, "d", function()
        vim.opt.operatorfunc = "v:lua.sidebar_delete"
        return "g@"
    end, { expr = true })

    map(buf, "dd", function()
        vim.opt.operatorfunc = "v:lua.sidebar_delete"
        return vim.v.count1 .. "g@_"
    end, { expr = true })

    map(buf, "dj", function()
        vim.opt.operatorfunc = "v:lua.sidebar_delete"
        return "g@j"
    end, { expr = true })

    map(buf, "dk", function()
        vim.opt.operatorfunc = "v:lua.sidebar_delete"
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
            render(buf)
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
function M.open(project_id)
    if not M.buf then
        M.ns = vim.api.nvim_create_namespace("backlog")

        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(buf, "backlog")
        vim.bo[buf].buftype = "acwrite"

        setup_highlights()
        setup_keymaps(buf)
        setup_listeners(buf)
        M.buf = buf
    end

    update_items(nil, project_id)

    if not M.win then M.win = vim.api.nvim_open_win(M.buf, true, configuration.DATA.win_opts) end
end

--- Close sidebar. Noop if sidebar is not open.
function M.close()
    if not M.win or not vim.api.nvim_win_is_valid(M.win) then return end
    vim.api.nvim_win_close(M.win, false)
    M.win = nil
end

return M
