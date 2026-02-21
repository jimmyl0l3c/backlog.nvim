local configuration = require("backlog._core.configuration")
local data = require("backlog._core.data")
local states = require("backlog._core.states")

local header_lines = 1

local M = { cursor = 1, items = {}, project = nil }

local function render(buf)
    vim.bo[buf].modifiable = true

    local lines = {}
    local marks = {} -- {row, col_start, col_end, hl_group}

    local title = " Backlog"
    if M.project then title = title .. " - " .. M.project.title end

    table.insert(lines, title)

    for i, item in ipairs(M.items) do
        local row = i - 1 + header_lines
        local col = 0
        local line = ""

        local function append(text, hl_group)
            if hl_group then table.insert(marks, { row, col, col + #text, hl_group }) end
            line = line .. text
            col = col + #text
        end

        local is_selected = i == M.cursor

        local state = configuration.DATA.states[item.state]
        append("  ", nil)
        append(state.icon, state.highlight or nil)
        append(" ", nil)
        append(item.ticket, state.ticket_highlight or "BacklogTicket")
        append(" ", nil)
        append(item.title, state.scope_highlight or "BacklogName")

        table.insert(lines, line)

        -- full-line select
        if is_selected then table.insert(marks, { row, 0, #line, "BacklogSelected", hl_eol = true, priority = 100 }) end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)

    local border = string.rep("─", #title + 1)

    vim.api.nvim_buf_set_extmark(buf, M.ns, 0, 0, {
        end_col = #lines[1],
        hl_group = "BacklogTitle",
        priority = 200,
        virt_lines = {
            { { border, "BacklogBorder" } },
        },
        virt_lines_above = false,
    })
    for _, m in ipairs(marks) do
        vim.api.nvim_buf_set_extmark(buf, M.ns, m[1], m[2], {
            end_col = m[3],
            hl_group = m[4],
            hl_eol = m.hl_eol,
            priority = m.priority or 200,
        })
    end

    vim.bo[buf].modified = false
end

local function update_items(buf, project_id)
    local project = project_id and data.find_project(project_id) or nil
    local items = project_id and data.tasks_for_project(project_id) or data.store.tasks

    M.project = project
    M.items = items

    render(buf or M.buf)
end

local function map(buf, key, fn) vim.keymap.set("n", key, fn, { buffer = buf, noremap = true, silent = true }) end

local function map_state(buf, key, state)
    map(buf, key, function()
        local item = M.items[M.cursor]
        if not item then return end

        local updated = data.set_task_state(item.id, state)
        if updated then
            M.items[M.cursor] = updated
            render(buf)
        end
    end)
end

local function setup_keymaps(buf)
    map(buf, "j", function()
        M.cursor = math.min(M.cursor + vim.v.count1, #M.items)
        render(buf)
        vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
    end)

    map(buf, "k", function()
        M.cursor = math.max(M.cursor - vim.v.count1, 1)
        render(buf)
        vim.api.nvim_win_set_cursor(0, { M.cursor + header_lines, 0 })
    end)

    for state, keys in pairs(configuration.DATA.keys) do
        for _, key in ipairs(keys) do
            map_state(buf, key, state)
        end
    end

    map(buf, "<CR>", function()
        local item = M.items[M.cursor]
        if item then
            item.state = item.state == states.Done and states.ToDo or states.Done
            item.done_timestamp = item.state == states.Done and os.date("%Y-%m-%d") or ""
            render(buf)
        end
    end)

    map(buf, "q", M.close)

    map(buf, "a", function()
        vim.ui.input({ prompt = "Add task" }, function(input)
            if not input then return end
            local project_id = M.project and M.project.id or nil
            data.add_task({ project = project_id, title = input })
            update_items(buf, project_id)
        end)
    end)

    map(buf, "e", function()
        local item = M.items[M.cursor]
        if not item then return end
        vim.ui.input({ prompt = "Edit task", default = item.title }, function(input)
            if not input or input == item.title then return end

            local updated = data.edit_task(item.id, { title = input })
            if not updated then return end
            M.items[M.cursor] = updated
            render(buf)
        end)
    end)
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
