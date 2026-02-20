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

local M = { cursor = 1, items = {} }

configuration.initialize_data_if_needed()
data.load()

--- Update plugin configuration.
---
---@param opts backlog.Configuration All of the user's fallback settings.
---
function M.setup(opts) vim.g.backlog_configuration = opts end

local function set_buf_lines(buf, lines)
    if not buf then return end
    vim.bo[buf].modifiable = true
    vim.bo[buf].readonly = false

    vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
end

local function render(buf)
    local lines = { "TODOs" }
    for i, item in ipairs(M.items) do
        local prefix = i == M.cursor and "> " or "  "
        local status = item.state == states.Done and "[x]" or "[ ]"
        table.insert(lines, prefix .. status .. " " .. item.title)
    end
    set_buf_lines(buf, lines)
end

local function map(buf, key, fn) vim.keymap.set("n", key, fn, { buffer = buf, noremap = true, silent = true }) end

local function setup_keymaps(buf)
    map(buf, "j", function()
        M.cursor = math.min(M.cursor + vim.v.count1, #M.items)
        render(buf)
        vim.api.nvim_win_set_cursor(0, { M.cursor + 1, 0 })
    end)

    map(buf, "k", function()
        M.cursor = math.max(M.cursor - vim.v.count1, 1)
        render(buf)
        vim.api.nvim_win_set_cursor(0, { M.cursor + 1, 0 })
    end)

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
            M.cursor = math.max(cur - 1, 1)
            if cur == 1 then vim.api.nvim_win_set_cursor(0, { 2, 0 }) end
            render(buf)
        end,
    })
end

function M.open_sidebar()
    if not M.buf then
        M.items = data.store.tasks

        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(buf, "todo")
        vim.bo[buf].buftype = "nofile"

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
