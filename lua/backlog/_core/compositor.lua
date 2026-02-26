local View = require("backlog._core.view")
local configuration = require("backlog._core.configuration")

-- TODO: move the types to separate file
-- TODO: move the default column definitions to configuration

---@class backlog.Compositor
---@field definitions backlog.Compositor.ColumnDefinition[]
---@field rows backlog.Compositor.Row[]
---@field colSizing backlog.Compositor.CellSize[]
local Compositor = { spacing = 1 }

---@class backlog.Compositor.FixedCellSize
---@field rpad number? fixed right padding
---@field empty_fill number? fixed width used when field is empty

---@class backlog.Compositor.ColumnDefinition
---@field cell backlog.Compositor.Cell|fun(item:backlog.Task, ci:number?):backlog.Compositor.Cell
---@field fixed_size? backlog.Compositor.FixedCellSize

---@class backlog.Compositor.Text
---@field text string
---@field hl_group? string

---@class backlog.Compositor.Cell
---@field parts backlog.Compositor.Text[]

---@class backlog.Compositor.CellSize
---@field width number
---@field fixed? backlog.Compositor.FixedCellSize

---@class backlog.Compositor.Row
---@field cells backlog.Compositor.Cell[]
---@field task backlog.Task
---@field comment_id? number

---@class backlog.Compositor.Selection
---@field index number
---@field task backlog.Task
---@field comment_id? number

--- Create new column compositor
---@return backlog.Compositor
function Compositor:new()
    local newObject = setmetatable({}, self)
    self.__index = self
    newObject.rows = {}
    newObject.definitions = {
        {
            cell = function(item, ci)
                if ci ~= nil then return {} end
                local state = configuration.DATA.states[item.state]
                return { parts = { { text = "  " .. state.icon, hl_group = state.highlight } } }
            end,
            fixed_size = { rpad = 1, empty_fill = 2 },
        },
        {
            cell = function(item, ci)
                if ci ~= nil then return {} end
                local state = configuration.DATA.states[item.state]
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
                local state = configuration.DATA.states[item.state]
                return {
                    parts = { { text = item.ticket, hl_group = state.ticket_highlight or "BacklogTicket" } },
                }
            end,
        },
        {
            cell = function(item, ci)
                if ci ~= nil then return { parts = { { text = " • " .. item.comments[ci].content } } } end

                local state = configuration.DATA.states[item.state]
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
    }
    newObject.colSizing = vim.tbl_map(
        function(def) return { width = 0, fixed = def.fixed_size } end,
        newObject.definitions
    )
    return newObject
end

--- Calculate cell width
---@param cell backlog.Compositor.Cell
---@return number
local function cellWidth(cell)
    if not cell.parts then return 0 end

    local w = 0
    for _, p in ipairs(cell.parts) do
        w = w + #p.text
    end
    return w
end

function Compositor:prepare(items)
    self.rows = {}

    for _, item in ipairs(items) do
        local row = { cells = {}, task = item } ---@type backlog.Compositor.Row
        table.insert(self.rows, row)

        for i, def in ipairs(self.definitions) do
            local cell = def.cell(item, nil)
            local colsize = self.colSizing[i]
            colsize.width = math.max(colsize.width, cellWidth(cell))
            table.insert(row.cells, cell)
        end

        for j = 1, #item.comments, 1 do
            local comment_row = { cells = {}, task = item, comment_id = j } ---@type backlog.Compositor.Row
            table.insert(self.rows, comment_row)

            for i, def in ipairs(self.definitions) do
                local cell = def.cell(item, j)
                local colsize = self.colSizing[i]
                colsize.width = math.max(colsize.width, cellWidth(cell))
                table.insert(comment_row.cells, cell)
            end
        end
    end
end

--- Create columns view
function Compositor:render(opts)
    local v = View:new()
    v:add_header(opts.project)

    for i, row in ipairs(self.rows) do
        for j, col in ipairs(row.cells) do
            local width = 0
            for _, part in ipairs(col.parts or {}) do
                v:append(part.text, part.hl_group)
                width = width + #part.text
            end

            local size = self.colSizing[j]
            local rpad = size.width - width
            if size.fixed then
                rpad = size.fixed.rpad or 0
                if width == 0 then rpad = rpad + (size.fixed.empty_fill or 0) end
            end
            v:append(string.rep(" ", rpad + self.spacing), nil)
        end

        v:end_line()
        if i == opts.cursor then v:highlight_last() end
    end

    v:render(opts.ns, opts.buf)
end

--- Get item at line index
---@param index number line index (=cursor)
---@return backlog.Task? task, number? comment_id
function Compositor:get_item(index)
    local item = self.rows[index]
    if item == nil then return nil end
    return item.task, item.comment_id
end

--- Find row with specified task or comment.
---@param item backlog.Task
---@param comment_id number
---@return number? index
function Compositor:get_index(item, comment_id)
    if not self.rows then return nil end
    for i, row in ipairs(self.rows) do
        if row.task.id == item.id and row.comment_id == comment_id then return i end
    end
    return nil
end

--- Get row count
---@return number
function Compositor:row_count()
    if not self.rows then return 0 end
    return #self.rows
end

--- Select rows
---@param first number index of the first row
---@param last number index of the last row
---@return backlog.Compositor.Selection[]
function Compositor:select(first, last)
    if not self.rows then return {} end

    first = math.max(1, first)
    last = math.min(#self.rows, last)

    if first > last then return {} end

    local selection = {}
    for i = first, last, 1 do
        local row = self.rows[i]
        table.insert(selection, {
            index = i,
            task = row.task,
            comment_id = row.comment_id,
        })
    end
    return selection
end

return Compositor
