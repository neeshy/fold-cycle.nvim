local M = {}

function M.setup() end

local function is_fold_opened(line)
  return vim.fn.foldclosed(line or '.') == -1
end

local function is_fold_closed(line)
  return vim.fn.foldclosed(line or '.') ~= -1
end

-- Find the range of the current fold
local function find_fold()
  local fold_start = vim.fn.foldclosed('.')
  local fold_end

  -- Is the line folded? If not, close it and later reopen it
  if fold_start == -1 then
    local view = vim.fn.winsaveview()
    vim.cmd.foldclose()
    fold_start = vim.fn.foldclosed('.')
    fold_end = vim.fn.foldclosedend('.')
    vim.cmd.foldopen()
    vim.fn.winrestview(view)
  else
    fold_end = vim.fn.foldclosedend('.')
  end

  return fold_start, fold_end
end

-- Recursively open all folds under cursor
local function open_folds()
  vim.cmd.foldopen { range = { find_fold() }, bang = true }
end

-- Recursively close all folds under cursor
local function close_folds()
  local fold_level = vim.fn.foldlevel('.')
  local fold_start, fold_end = find_fold()

  -- Close all child folds recursively. The deepest folds must be closed first.
  -- This is a workaround for the behavior of `foldclose!` which closes parent folds as well
  local stack = {}
  local line = fold_start + 1
  while line <= fold_end do
    if is_fold_closed(line) then
      line = vim.fn.foldclosedend(line) + 1
    else
      local level = vim.fn.foldlevel(line)
      if level > fold_level then
        fold_level = level
        stack[#stack + 1] = line
      elseif level < fold_level then
        fold_level = level
        vim.cmd.foldclose { range = { table.remove(stack), line - 1 } }
      end
      line = line + 1
    end
  end

  vim.cmd.foldclose { range = { fold_start } }
end

-- Open all folds
function M.open_all()
  if vim.fn.foldlevel('.') > 0 then
    open_folds()
  else
    vim.cmd('silent! %foldopen!')
  end
end

-- Close all folds
function M.close_all()
  if vim.fn.foldlevel('.') > 0 then
    close_folds()
  else
    vim.cmd('silent! %foldclose!')
  end
end

-- Open/close all folds
function M.toggle_all()
  if vim.fn.foldlevel('.') > 0 then
    if is_fold_closed() then
      open_folds()
    else
      close_folds()
    end
  end
end

-- Open one level of folds
function M.open()
  if is_fold_closed() then
    vim.cmd.foldopen()
  else
    M.open_all()
  end
end

-- Close one level of folds
function M.close()
  local fold_level = vim.fn.foldlevel('.')
  if fold_level == 0 then
    vim.cmd.foldclose { range = { 1, vim.fn.line('$') } }
    return
  end

  local fold_start, fold_end = find_fold()

  local close = true
  local line = fold_start + 1
  while line < fold_end do
    if is_fold_closed(line) then
      line = vim.fn.foldclosedend(line) + 1
    elseif vim.fn.foldlevel(line) == fold_level + 1 then
      vim.cmd.foldclose { range = { line } }
      close = false
      line = vim.fn.foldclosedend(line) + 1
    else
      line = line + 1
    end
  end

  if close then
    vim.cmd.foldclose()
  end
end

return M
