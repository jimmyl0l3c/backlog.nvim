
---@class backlog.Compositor.FixedCellSize
---@field rpad number? fixed right padding
---@field empty_fill number? fixed width used when field is empty

---@class backlog.Compositor.ColumnDefinition
---@field id string
---@field cell backlog.Compositor.Cell|fun(item:backlog.Task, ci:number?):backlog.Compositor.Cell
---@field fixed_size? backlog.Compositor.FixedCellSize

---@class backlog.Compositor.Text
---@field text string
---@field hl_group? string

---@class backlog.Compositor.Cell
---@field parts backlog.Compositor.Text[]

---@class backlog.Compositor.ProcessedCell
---@field col_id string Id of the column definition
---@field parts backlog.Compositor.Text[]

---@class backlog.Compositor.CellSize
---@field width number
---@field fixed? backlog.Compositor.FixedCellSize

---@class backlog.Compositor.Row
---@field cells backlog.Compositor.ProcessedCell[]
---@field task backlog.Task
---@field comment_id? number

---@class backlog.Compositor.Selection
---@field index number
---@field task backlog.Task
---@field comment_id? number

---@class backlog.Compositor.RenderOpts
---@field project backlog.Project
---@field cursor number
---@field ns number
---@field buf number
---@field hiden_cols string[]? ids of columns to hide
