local data_root = vim.fn.stdpath("data") .. "/backlog"

local M = {
    VERSION = 1,

    ---@type backlog.Project
    GLOBAL_PROJECT = {
        id = "global",
        title = "Global",
        tags = {},
        root_path = "",
        data_path = data_root .. "/global.json",
    },

    PROJECTS_PATH = data_root .. "/projects.json",
    TASKS_DIR = data_root .. "/tasks",
    DETAIL_DIR = data_root .. "/detail",
}

return M
