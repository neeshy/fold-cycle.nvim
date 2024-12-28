local M = {}

function M.setup() end

local function is_fold_opened(line)
  return vim.fn.foldclosed(line or '.') == -1
end

local function is_fold_closed(line)
  return vim.fn.foldclosed(line or '.') ~= -1
end

-- find last/first line of the current fold branch
local function find_fold()
  local fold_start = vim.fn.foldclosed('.')
  local fold_end

  -- is the line folded? if not, close it and later reopen it
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

-- close all folds of a specified fold level in the branch
local function close_branch_by_level(fold_start, fold_end, level)
  local line = fold_start
  while line < fold_end do
    if is_fold_opened(line) then
      if vim.fn.foldlevel(line) >= level then
        vim.cmd.foldclose { range = { line } }
        line = vim.fn.foldclosedend(line) + 1
      else
        line = line + 1
      end
    else
      line = vim.fn.foldclosedend(line) + 1
    end
  end
end

-- recursively open all folds in branch
local function open_branch()
  local fold_start, fold_end = find_fold()
  vim.cmd.foldopen { range = { fold_start, fold_end }, bang = true }
end

-- recursively close all folds in branch
local function close_branch()
  local min_fold_level = vim.fn.foldlevel('.')
  local max_fold_level = min_fold_level
  local fold_start, fold_end = find_fold()
  for line = fold_start, fold_end do
    if is_fold_opened(line) then
      local level = vim.fn.foldlevel(line)
      if level > max_fold_level then
        max_fold_level = level
      end
    end
  end

  for level = max_fold_level, min_fold_level, -1 do
    close_branch_by_level(fold_start, fold_end, level)
  end
end

-- open all folds in branch
function M.open_all()
  if vim.fn.foldlevel('.') > 0 then
    open_branch()
  else
    vim.cmd('silent! %foldopen!')
  end
end

-- close all folds in branch
function M.close_all()
  if vim.fn.foldlevel('.') > 0 then
    close_branch()
  else
    vim.cmd('silent! %foldclose!')
  end
end

-- open/close all folds in branch
function M.toggle_all()
  if vim.fn.foldlevel('.') > 0 then
    if is_fold_closed() then
      open_branch()
    else
      close_branch()
    end
  end
end

-- open one level of folds in branch
function M.open()
  -- if current line is folded
  if is_fold_closed() then
    vim.cmd.foldopen()
  else
    M.open_all()
  end
end

-- close one level of folds in branch
function M.close()
  local fold_start, fold_end
  local fold_level = vim.fn.foldlevel('.')
  if fold_level > 0 then
    fold_start, fold_end = find_fold()
  else
    fold_start = 1
    fold_end = vim.fn.line('$')
  end

  local close = true
  local line = fold_start
  while line < fold_end do
    if is_fold_opened() then
      if vim.fn.foldlevel(line) == fold_level + 1 then
        close = false
        vim.cmd.foldclose { range = { line } }
        line = vim.fn.foldclosedend(line) + 1
      else
        line = line + 1
      end
    else
      line = vim.fn.foldclosedend(line) + 1
    end
  end

  if close then
    vim.cmd.foldclose()
  end
end

return M
