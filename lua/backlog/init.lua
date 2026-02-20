--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local data = require("backlog._core.data")
local states = require("backlog._core.states")
local configuration = require("backlog._core.configuration")
local arbitrary_thing_runner = require("backlog._commands.arbitrary_thing.runner")
local copy_logs_runner = require("backlog._commands.copy_logs.runner")
local count_sheep = require("backlog._commands.goodnight_moon.count_sheep")
local read = require("backlog._commands.goodnight_moon.read")
local say_runner = require("backlog._commands.hello_world.say.runner")
local sleep = require("backlog._commands.goodnight_moon.sleep")

local header_lines = 1

local M = { cursor = 1, items = {} }

configuration.initialize_data_if_needed()
data.load()

--- Update plugin configuration.
---
---@param opts backlog.Configuration All of the user's fallback settings.
---
function M.setup(opts) vim.g.backlog_configuration = opts end

local function render(buf)
    vim.bo[buf].readonly = false
    vim.bo[buf].modifiable = true

    local lines = {}
    local marks = {} -- {row, col_start, col_end, hl_group}

    local title = " Backlog"
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
        append("  ", is_selected and "BacklogSelected" or nil)
        append(state.icon, state.highlight or nil)
        append(" ", is_selected and "BacklogSelected" or nil)
        append(item.ticket, state.ticket_highlight or "BacklogTicket")
        append(" ", nil)
        append(item.title, state.scope_highlight or "BacklogName")

        table.insert(lines, line)

        -- full-line select
        if is_selected then table.insert(marks, { row, 0, #line, "BacklogSelected", hl_eol = true, priority = 100 }) end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].readonly = true
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
        virt_lines_above = false, -- render below the title line
    })
    for _, m in ipairs(marks) do
        vim.api.nvim_buf_set_extmark(buf, M.ns, m[1], m[2], {
            end_col = m[3],
            hl_group = m[4],
            hl_eol = m.hl_eol,
            priority = m.priority or 200,
        })
    end
end

local function map(buf, key, fn) vim.keymap.set("n", key, fn, { buffer = buf, noremap = true, silent = true }) end

local function map_state(buf, key, state)
    map(buf, key, function()
        local item = M.items[M.cursor]
        if item then
            item.state = state
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
            render(buf)
        end
    end)

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

    vim.api.nvim_set_hl(0, "BacklogTicket", { fg = "#9ccfd8", bold = true })
    vim.api.nvim_set_hl(0, "BacklogTicketSubtle", { fg = "#31748f", bold = true })

    vim.api.nvim_set_hl(0, "BacklogName", { fg = "#cdd6f4" })
    vim.api.nvim_set_hl(0, "BacklogNameWarn", { fg = "#f6c177", bold = true })
    vim.api.nvim_set_hl(0, "BacklogNameHighlight", { fg = "#9ccfd8", bold = true })
    vim.api.nvim_set_hl(0, "BacklogNameSubtle", { fg = "#6e6a86", italic = true })
end

function M.open_sidebar()
    if not M.buf then
        M.items = data.store.tasks
        M.ns = vim.api.nvim_create_namespace("backlog")

        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(buf, "todo")
        vim.bo[buf].buftype = "nofile"

        setup_highlights()
        setup_keymaps(buf)
        render(buf)
        M.buf = buf
    end

    vim.api.nvim_open_win(M.buf, true, { split = "right" })
end

-- TODO: (you) - Change this file to whatever you need. These are just examples

--- Print the `names`.
---
---@param names string[]? Some text to print out. e.g. `{"a", "b", "c"}`.
---
function M.run_arbitrary_thing(names) arbitrary_thing_runner.run(names) end

--- Copy the log data from the given `path` to the user's clipboard.
---
---@param path string?
---    A path on-disk to look for logs. If none is given, the default fallback
---    location is used instead.
---
function M.run_copy_logs(path) copy_logs_runner.run(path) end

--- Print `phrase` according to the other options.
---
---@param phrase string[]
---    The text to say.
---@param repeat_ number?
---    A 1-or-more value. The number of times to print `word`.
---@param style string?
---    Control how the text should be shown.
---
function M.run_hello_world_say_phrase(phrase, repeat_, style) say_runner.run_say_phrase(phrase, repeat_, style) end

--- Print `phrase` according to the other options.
---
---@param word string
---    The text to say.
---@param repeat_ number?
---    A 1-or-more value. The number of times to print `word`.
---@param style string?
---    Control how the text should be shown.
---
function M.run_hello_world_say_word(word, repeat_, style) say_runner.run_say_word(word, repeat_, style) end

--- Count a sheep for each `count`.
---
---@param count number Prints 1 sheep per `count`. A value that is 1-or-greater.
---
function M.run_goodnight_moon_count_sheep(count) count_sheep.run(count) end

--- Print the name of the book.
---
---@param book string The name of the book.
---
function M.run_goodnight_moon_read(book) read.run(book) end

--- Print Zzz each `count`.
---
---@param count number? Prints 1 Zzz per `count`. A value that is 1-or-greater.
---
function M.run_goodnight_moon_sleep(count) sleep.run(count) end

return M
