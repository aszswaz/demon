local PROJECT_DIR = vim.fn.expand("<script>:h")

local runtimePaths = vim.api.nvim_list_runtime_paths()
runtimePaths[1] = PROJECT_DIR
vim.o.runtimepath = vim.fn.join(runtimePaths, ",")

vim.o.number = false
vim.o.filetype = false
vim.o.syntax = false

local demon = require "demon"
demon.setup()
