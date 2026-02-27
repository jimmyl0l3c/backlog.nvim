--- A collection of types to be included / used in other Lua files.
---
--- These types are either required by the Lua API or required for the normal
--- operation of this Lua plugin.
---

---@class backlog.Project The project for grouping tasks.
---@field id string Human-readable project id.
---@field title string Optional more descriptive title of a project, uses id otherwise.
---@field path string? Optional path pattern for automatic detection of project.

---@class backlog.Task A task.
---@field id string Automatically generated id used to idetify tasks.
---@field project string Project id the task belongs to.
---@field title string Task title, the main information shown in the backlog.
---@field state backlog.States State of the task, should be one of `backlog.States`
---@field deadline string Optional task deadline, should be in format `%Y-%m-%d`.
---@field ticket string Optional ticket number the task is related to. (e.g. GH issue number)
---@field priority number Priority of the task used for sorting backlog.
---@field detail string Optional path to a markdown file with detailed description of the task.
---@field added_timestamp string Created timestamp, automatically set when creating a task.
---@field done_timestamp string Done/cancelled timestamp, automatically set when state changes to
---@field comments backlog.TaskComment[] Optional comments of a task.

---@class backlog.TaskComment A task comment.
---@field content string Comments content.
---@field timestamp string Created timestamp, automatically set when creating a comment.

---@class backlog.ResolveProjectOpts
---@field project_id string?
---@field path string?

---@class backlog.Configuration The user's customizations for this plugin.
---@field column_definitions backlog.Compositor.ColumnDefinition[]?
---@field commands backlog.ConfigurationCommands? Customize the fallback behavior of all `:Backlog` commands.
---@field logging backlog.LoggingConfiguration? Control how and which logs print to file / Neovim.
---@field win_opts vim.api.keyset.win_config? Sidebar window config.
---@field projects backlog.ProjectConfiguration?
---@field states table<backlog.States, backlog.StateConfiguration>?
---    Customize how tasks are displayed based on their state.
---@field tools backlog.ConfigurationTools? Optional third-party tool integrations.

---@class backlog.ProjectConfiguration
---@field root_markers string[]

---@class backlog.StateConfiguration
---@field icon string Icon displayed in the task list.
---@field highlight string Highlight group used for the icon.
---@field scope_highlight string? Highlight group used for the task title.
---@field ticket_highlight string? Highlight group used for the ticket of the task.

---@class backlog.HighlightMarker
---@field row number Row number
---@field col_start number Start position on the row
---@field col_end number End position on the row
---@field hl_group string Highlight group name
---@field hl_eol boolean?
---@field priority number?

---@class backlog.ConfigurationCommands
---    Customize the fallback behavior of all `:Backlog` commands.
---@field goodnight_moon backlog.ConfigurationGoodnightMoon?
---    The default values when a user calls `:Backlog goodnight-moon`.
---@field hello_world backlog.ConfigurationHelloWorld?
---    The default values when a user calls `:Backlog hello-world`.

---@class backlog.ConfigurationGoodnightMoon
---    The default values when a user calls `:Backlog goodnight-moon`.
---@field read backlog.ConfigurationGoodnightMoonRead?
---    The default values when a user calls `:Backlog goodnight-moon read`.

---@class backlog.LoggingConfiguration
---    Control whether or not logging is printed to the console or to disk.
---@field level (
---    | "trace"
---    | "debug"
---    | "info"
---    | "warn" | "error"
---    | "fatal"
---    | vim.log.levels.DEBUG
---    | vim.log.levels.ERROR
---    | vim.log.levels.INFO
---    | vim.log.levels.TRACE
---    | vim.log.levels.WARN)?
---    Any messages above this level will be logged.
---@field use_console boolean?
---    Should print the output to neovim while running. Warning: This is very
---    spammy. You probably don't want to enable this unless you have to.
---@field use_file boolean?
---    Should write to a file.
---@field output_path string?
---    The default path on-disk where log files will be written to.
---    Defaults to "/home/selecaoone/.local/share/nvim/plugin_name.log".

---@class backlog.ConfigurationGoodnightMoonRead
---    The default values when a user calls `:Backlog goodnight-moon read`.
---@field phrase string
---    The book to read if no book is given by the user.

---@class backlog.ConfigurationHelloWorld
---    The default values when a user calls `:Backlog hello-world`.
---@field say backlog.ConfigurationHelloWorldSay?
---    The default values when a user calls `:Backlog hello-world say`.

---@class backlog.ConfigurationHelloWorldSay
---    The default values when a user calls `:Backlog hello-world say`.
---@field repeat number
---    A 1-or-more value. When 1, the phrase is said once. When 2+, the phrase
---    is repeated that many times.
---@field style "lowercase" | "uppercase"
---    Control how the text is displayed. e.g. "uppercase" changes "hello" to "HELLO".

---@class backlog.ConfigurationTools
---    Optional third-party tool integrations.
---@field lualine backlog.ConfigurationToolsLualine?
---    A Vim statusline replacement that will show the command that the user just ran.

---@alias backlog.ConfigurationToolsLualine table<string, backlog.ConfigurationToolsLualineData>
---    Each runnable command and its display text.

---@class backlog.ConfigurationToolsLualineData
---    The display values that will be used when a specific `backlog`
---    command runs.
---@diagnostic disable-next-line: undefined-doc-name
---@field color vim.api.keyset.highlight?
---    The foreground/background color to use for the Lualine status.
---@field prefix string?
---    The text to display in lualine.
