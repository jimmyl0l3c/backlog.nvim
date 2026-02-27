---@class backlog.View
---@field lines string[]
---@field marks backlog.HighlightMarker[]
local View = {
    _line = "",
    _col = 0,
    _header_len = 0,
}

--- Create new backlog view
---@return backlog.View
function View:new()
    local newObject = setmetatable({}, self)
    self.__index = self
    newObject.lines = {}
    newObject.marks = {}
    return newObject
end

--- Add header to the view
---@param project backlog.Project?
function View:add_header(project)
    local title = " Backlog"
    if project then title = title .. " - " .. project.title end
    self._header_len = #title
    self:append(title, nil)
    self:end_line()
end

function View:append(text, hl_group)
    if hl_group then
        table.insert(self.marks, {
            row = #self.lines,
            col_start = self._col,
            col_end = self._col + #text,
            hl_group = hl_group,
        })
    end
    self._line = self._line .. text
    self._col = self._col + #text
end

function View:end_line()
    table.insert(self.lines, self._line)
    self._line = ""
    self._col = 0
end

function View:highlight_line(index)
    table.insert(self.marks, {
        row = math.max(index - 1, 0),
        col_start = 0,
        col_end = #self.lines[index],
        hl_group = "BacklogSelected",
        hl_eol = true,
        priority = 100,
    })
end

function View:highlight_last() self:highlight_line(#self.lines) end

function View:render(ns, buf)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, self.lines)
    vim.bo[buf].modifiable = false

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    local border = string.rep("─", self._header_len + 1)
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
        end_col = #self.lines[1],
        hl_group = "BacklogTitle",
        priority = 200,
        virt_lines = {
            { { border, "BacklogBorder" } },
        },
        virt_lines_above = false,
    })

    for _, m in ipairs(self.marks) do
        vim.api.nvim_buf_set_extmark(buf, ns, m.row, m.col_start, {
            end_col = m.col_end,
            hl_group = m.hl_group,
            hl_eol = m.hl_eol,
            priority = m.priority or 200,
        })
    end

    vim.bo[buf].modified = false
end

return View
