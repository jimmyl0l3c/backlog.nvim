local View = require("backlog._core.rendering.view")
local configuration = require("backlog._core.configuration")

---@class backlog.Compositor
---@field definitions backlog.Compositor.ColumnDefinition[]
---@field rows backlog.Compositor.Row[]
---@field colSizing backlog.Compositor.CellSize[]
local Compositor = { spacing = 1 }

--- Create new column compositor
---@return backlog.Compositor
function Compositor:new()
    local newObject = setmetatable({}, self)
    self.__index = self
    newObject.rows = {}
    newObject.definitions = vim.tbl_extend("force", {}, configuration.DATA.column_definitions)
    newObject.colSizing = {}
    for _, def in ipairs(newObject.definitions) do
        newObject.colSizing[def.id] = { width = 0, fixed = def.fixed_size }
    end
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

function Compositor:_reset()
    self.rows = {}
    for _, size in pairs(self.colSizing) do
        size.width = 0
    end
end

function Compositor:prepare(items)
    self:_reset()

    for _, item in ipairs(items) do
        local row = { cells = {}, task = item } ---@type backlog.Compositor.Row
        table.insert(self.rows, row)

        for _, def in ipairs(self.definitions) do
            local cell = def.cell(item, nil)
            local colsize = self.colSizing[def.id]
            colsize.width = math.max(colsize.width, cellWidth(cell))
            table.insert(row.cells, vim.tbl_extend("force", { col_id = def.id }, cell))
        end

        for j = 1, #item.comments, 1 do
            local comment_row = { cells = {}, task = item, comment_id = j } ---@type backlog.Compositor.Row
            table.insert(self.rows, comment_row)

            for _, def in ipairs(self.definitions) do
                local cell = def.cell(item, j)
                local colsize = self.colSizing[def.id]
                colsize.width = math.max(colsize.width, cellWidth(cell))
                table.insert(comment_row.cells, vim.tbl_extend("force", { col_id = def.id }, cell))
            end
        end
    end
end

--- Render single column
---@param v backlog.View
---@param col backlog.Compositor.ProcessedCell
function Compositor:_render_col(v, col)
    local width = 0
    for _, part in ipairs(col.parts or {}) do
        v:append(part.text, part.hl_group)
        width = width + #part.text
    end

    local size = self.colSizing[col.col_id]
    local rpad = size.width - width
    if size.fixed then
        rpad = size.fixed.rpad or 0
        if width == 0 then rpad = rpad + (size.fixed.empty_fill or 0) end
    end
    v:append(string.rep(" ", rpad + self.spacing), nil)
end

--- Create columns view
---@param opts backlog.Compositor.RenderOpts
function Compositor:render(opts)
    local hidden = opts.hiden_cols or {}
    if opts.project then table.insert(hidden, "project") end

    local v = View:new()
    v:add_header(opts.project)

    for i, row in ipairs(self.rows) do
        for _, col in ipairs(row.cells) do
            if self.colSizing[col.col_id].width > 0 and not vim.tbl_contains(hidden, col.col_id) then
                self:_render_col(v, col)
            end
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
