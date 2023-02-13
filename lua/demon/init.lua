local examQuestions = require "demon.exam-questions"

local M = {
    -- 显示帮助信息的缓冲区
    helpBuffer = nil,
    -- 显示题目
    topicBuffer = nil,
    -- 作答区域
    answerAreaBuffer = nil,
    -- 显示答案的比对结果和参考答案
    resultBuffer = nil,
    -- 当前题目
    topic = nil,
    -- 已经出现过的题目
    hasAppeared = {},
    namespace = nil,
}

function M.setup()
    M.namespace = vim.api.nvim_create_namespace "Demon"
    vim.api.nvim_set_hl(M.namespace, "NormalFloat", { bg = "#000000" })
    vim.api.nvim_set_hl(M.namespace, "Success", { fg = "#00FF00", ctermfg = "Green" })
    vim.api.nvim_set_hl(M.namespace, "Error", { fg = "#FF0000", ctermfg = "Red" })

    vim.api.nvim_create_autocmd("VimEnter", {
        callback = M._start,
    })
end

function M._start()
    -- 显示帮助信息
    M.helpBuffer = M._createBuffer "help"
    vim.fn.setbufline(M.helpBuffer, 1, "按 Ctrl + n 跳转到下一题，按 Ctrl + e 检查答案")
    M._createWindow(M.helpBuffer, 2, 46, 1)

    -- 显示题目
    M.topicBuffer = M._createBuffer "topic"
    M._createWindow(M.topicBuffer, 5, 92, 1)

    -- 作答区域
    M.answerAreaBuffer = M._createBuffer "answer area"
    vim.fn.setbufline(M.answerAreaBuffer, 1, "请在此作答：")
    vim.fn.setbufline(M.answerAreaBuffer, 2, "")
    local window = M._createWindow(M.answerAreaBuffer, 8, 92, 10, true)
    vim.api.nvim_win_set_cursor(window, { 2, 0 })

    -- 显示答案的比对结果和参考答案
    M.resultBuffer = M._createBuffer "result"
    vim.fn.setbufline(M.resultBuffer, 1, "比对结果：")
    M._createWindow(M.resultBuffer, 20, 92, 20)

    vim.cmd.startinsert()

    vim.keymap.set("n", "<C-e>", M._verify, {})
    vim.keymap.set("i", "<C-e>", M._verify, {})
    vim.keymap.set("n", "<C-n>", M._next, {})
    vim.keymap.set("i", "<C-n>", M._next, {})

    M._next()
end

function M._createBuffer(name)
    local buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buffer, name)
    vim.bo[buffer].filetype = "demon"
    return buffer
end

function M._createWindow(buffer, y, width, height, enter)
    enter = not not enter

    local x = math.floor(vim.o.columns / 2 - width / 2)
    local window = vim.api.nvim_open_win(buffer, not not enter, {
        relative = "editor",
        row = y,
        col = x,
        width = width,
        height = height,
        focusable = enter,
        border = "rounded",
    })
    vim.api.nvim_win_set_hl_ns(window, M.namespace)
    return window
end

-- 下一题
function M._next(buffer)
    if #M.hasAppeared == #examQuestions then
        -- 所有题目出题完毕
        vim.fn.setbufline(M.topicBuffer, 1, "所有题目测试完毕，按 Ctrl + n 重新开始测试")
        M.hasAppeared = {}
        return
    end

    -- 随机获取题目
    while true do
        math.randomseed(os.time())
        local index = math.random(1, #examQuestions)
        if not vim.tbl_contains(M.hasAppeared, index) then
            table.insert(M.hasAppeared, index)
            M.topic = examQuestions[index]
            break
        end
    end

    vim.fn.setbufline(M.topicBuffer, 1, M.topic.title)
    vim.fn.setbufline(M.answerAreaBuffer, 2, "")
    lineCount = vim.api.nvim_buf_line_count(M.answerAreaBuffer)
    if lineCount > 3 then
        vim.fn.deletebufline(M.answerAreaBuffer, 3, lineCount)
    end
end

function M._verify()
    local lineCount = vim.api.nvim_buf_line_count(M.answerAreaBuffer)
    local lines = vim.fn.getbufline(M.answerAreaBuffer, 2, lineCount)

    vim.fn.deletebufline(M.resultBuffer, 2, vim.api.nvim_buf_line_count(M.resultBuffer))

    local answer01 = vim.fn.join(M.topic.answer)
    local answer02 = vim.fn.join(lines)
    if answer01 == answer02 then
        vim.fn.setbufline(M.resultBuffer, 2, "回答正确")
        vim.api.nvim_buf_add_highlight(M.resultBuffer, M.namespace, "Success", 1, 0, -1)
    else
        vim.fn.setbufline(M.resultBuffer, 2, "回答错误")
        vim.api.nvim_buf_add_highlight(M.resultBuffer, M.namespace, "Error", 1, 0, -1)
    end
    vim.fn.setbufline(M.resultBuffer, 3, "参考答案如下")
    vim.fn.setbufline(M.resultBuffer, 4, M.topic.answer)
end

return { setup = M.setup }
