
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
