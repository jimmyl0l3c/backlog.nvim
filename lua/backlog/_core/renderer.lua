local View = require("backlog._core.view")
local configuration = require("backlog._core.configuration")

local M = {}

function M.render(opts)
    local v = View:new()
    v:add_header(opts.project)

    for i, item in ipairs(opts.items) do
        local is_selected = i == opts.cursor

        local state = configuration.DATA.states[item.state]
        v:append("  ", nil)
        v:append(state.icon, state.highlight or nil)

        if not opts.project then
            v:append(" [", "BacklogSubtle")
            v:append(item.project, state.ticket_highlight or "BacklogTicket") -- TODO: change highlight
            v:append("]", "BacklogSubtle")
        end

        v:append(" ", nil)
        v:append(item.ticket, state.ticket_highlight or "BacklogTicket")
        v:append(" ", nil)
        v:append(item.title, state.scope_highlight or "BacklogName")

        v:append(" " .. item.priority, "BacklogSubtle")

        v:end_line()
        if is_selected then v:highlight_last() end

        -- for j, comment in ipairs(item.comments) do
        --     table.insert(lines, j .. " " .. comment.content)
        --     row = row + 1
        -- end
    end

    v:render(opts.ns, opts.buf)
end

return M
