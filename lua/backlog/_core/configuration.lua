--- All functions and data to help customize `backlog` for this user.

local logging = require("mega.logging")

local states = require("backlog._core.states")

local _LOGGER = logging.get_logger("backlog._core.configuration")

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_backlog = false

---@type backlog.Configuration
M.DATA = {}

---@type backlog.Configuration
local _DEFAULTS = {
    logging = { level = "info", use_console = false, use_file = false },
    win_opts = { split = "right" },
    column_definitions = {
        {
            cell = function(item, ci)
                if ci ~= nil then return {} end
                local state = M.DATA.states[item.state]
                return { parts = { { text = "  " .. state.icon, hl_group = state.highlight } } }
            end,
            fixed_size = { rpad = 1, empty_fill = 2 },
        },
        {
            cell = function(item, ci)
                if ci ~= nil then return {} end
                local state = M.DATA.states[item.state]
                return {
                    parts = {
                        { text = "[", hl_group = "BacklogSubtle" },
                        { text = item.project, hl_group = state.ticket_highlight or "BacklogTicket" },
                        { text = "]", hl_group = "BacklogSubtle" },
                    },
                }
            end,
        },
        {
            cell = function(item, ci)
                if ci ~= nil then return {} end
                local state = M.DATA.states[item.state]
                return {
                    parts = { { text = item.ticket, hl_group = state.ticket_highlight or "BacklogTicket" } },
                }
            end,
        },
        {
            cell = function(item, ci)
                if ci ~= nil then return { parts = { { text = " • " .. item.comments[ci].content } } } end

                local state = M.DATA.states[item.state]
                return {
                    parts = { { text = item.title, hl_group = state.scope_highlight or "BacklogName" } },
                }
            end,
        },
        {
            cell = function(item, ci)
                if ci ~= nil then return {} end
                return { parts = { { text = tostring(item.priority), hl_group = "BacklogSubtle" } } }
            end,
        },
    },
    states = {
        [states.ToDo] = {
            icon = "󰄱",
            highlight = "BacklogSubtle",
        },
        [states.Next] = {
            icon = "",
            highlight = "BacklogHighlight",
            scope_highlight = "BacklogNameHighlight",
            ticket_highlight = "BacklogTicketHighlight",
        },
        [states.Priority] = {
            icon = "",
            highlight = "BacklogWarn",
            scope_highlight = "BacklogNameWarn",
            ticket_highlight = "BacklogTicketHighlight",
        },
        [states.Cancelled] = {
            icon = "󰰱",
            highlight = "BacklogError",
            scope_highlight = "BacklogNameSubtle",
            ticket_highlight = "BacklogTicketSubtle",
        },
        [states.Done] = {
            icon = "",
            highlight = "BacklogDone",
            scope_highlight = "BacklogNameSubtle",
            ticket_highlight = "BacklogTicketSubtle",
        },
    },
    keys = {
        [states.ToDo] = { "r" },
        [states.Next] = { ">", "n" },
        [states.Priority] = { "!" },
        [states.Cancelled] = { "~", "D" },
        [states.Done] = { "x" },
    },
}

-- TODO: (you) Update these sections depending on your intended plugin features.
local _EXTRA_DEFAULTS = {
    commands = {
        goodnight_moon = { read = { phrase = "A good book" } },
    },
    tools = {
        lualine = {
            arbitrary_thing = {
                -- color = { link = "#555555" },
                color = "Visual",
                text = " Arbitrary Thing",
            },
            copy_logs = {
                -- color = { link = "#D3D3D3" },
                color = "Comment",
                text = "󰈔 Copy Logs",
            },
            goodnight_moon = {
                -- color = { fg = "#0000FF" },
                color = "Question",
                text = "⏾ Goodnight moon",
            },
            hello_world = {
                -- color = { fg = "#FFA07A" },
                color = "Title",
                text = " Hello, World!",
            },
        },
        telescope = {
            goodnight_moon = {
                { "Foo Book", "Author A" },
                { "Bar Book Title", "John Doe" },
                { "Fizz Drink", "Some Name" },
                { "Buzz Bee", "Cool Person" },
            },
            hello_world = { "Hi there!", "Hello, Sailor!", "What's up, doc?" },
        },
    },
}

_DEFAULTS = vim.tbl_deep_extend("force", _DEFAULTS, _EXTRA_DEFAULTS)

--- Setup `backlog` for the first time, if needed.
function M.initialize_data_if_needed()
    if vim.g.loaded_backlog then return end

    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.backlog_configuration or {})

    vim.g.loaded_backlog = true

    local configuration = M.DATA.logging or {}
    ---@cast configuration mega.logging.SparseLoggerOptions
    logging.set_configuration("backlog", configuration)

    _LOGGER:fmt_debug("Initialized backlog's configuration.")
end

--- Merge `data` with the user's current configuration.
---
---@param data backlog.Configuration? All extra customizations for this plugin.
---@return backlog.Configuration # The configuration with 100% filled out values.
---
function M.resolve_data(data)
    M.initialize_data_if_needed()

    return vim.tbl_deep_extend("force", M.DATA, data or {})
end

return M
