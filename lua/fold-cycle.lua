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

local function open_all_folds()
  vim.cmd('silent! %foldopen!')
end

local function close_all_folds()
  vim.cmd('silent! %foldclose!')
end

-- open all folds of a specified fold level in the branch
local function open_branch_by_level(fold_start, fold_end, level)
  local line = fold_start
  while line < fold_end do
    if vim.fn.foldlevel(line) <= level and is_fold_closed(line) then
      local next_fold_end = vim.fn.foldclosedend(line)
      vim.cmd.foldopen { range = { line } }
      line = next_fold_end + 1
    else
      line = line + 1
    end
  end
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
    open_all_folds()
  end
end

-- close all folds in branch
function M.close_all()
  if vim.fn.foldlevel('.') > 0 then
    close_branch()
  else
    close_all_folds()
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
function M.open(opts)
  local cycle = type(opts) ~= 'table' or opts.cycle == nil or opts.cycle

  -- if current line is folded
  if is_fold_closed() then
    vim.cmd.foldopen()
    return
  end

  local fold_start, fold_end, min_fold_level
  local fold_level = vim.fn.foldlevel('.')
  if fold_level > 0 then
    fold_start, fold_end = find_fold()
  else
    fold_start = 1
    fold_end = vim.fn.line('$')
  end

  for line = fold_start, fold_end do
    if is_fold_closed(line) then
      local level = vim.fn.foldlevel(line)
      if min_fold_level == nil or level < min_fold_level then
        min_fold_level = level
      end
    end
  end

  -- if current line is unfolded but branch can still be further unfolded
  if min_fold_level then
    open_branch_by_level(fold_start, fold_end, min_fold_level)
  elseif cycle then
    if fold_level > 0 then
      -- if branch is completely unfolded
      close_branch()
    else
      close_all_folds()
    end
  end
end

-- close one level of folds in branch
function M.close(opts)
  local cycle = type(opts) ~= 'table' or opts.cycle == nil or opts.cycle

  -- if current line is folded
  if is_fold_closed() and cycle then
    open_branch()
    return
  end

  local fold_start, fold_end, max_fold_level
  local fold_level = vim.fn.foldlevel('.')
  if fold_level > 0 then
    fold_start, fold_end = find_fold()
    max_fold_level = fold_level
  else
    fold_start = 1
    fold_end = vim.fn.line('$')
  end

  for line = fold_start, fold_end do
    if is_fold_opened(line) then
      local level = vim.fn.foldlevel(line)
      if max_fold_level == nil or level > max_fold_level then
        max_fold_level = level
      end
    end
  end

  if max_fold_level and max_fold_level > 0 then
    if max_fold_level == fold_level then
      -- if there are no open folds in branch with a fold level different from current line
      vim.cmd.foldclose()
    else
      close_branch_by_level(fold_start, fold_end, max_fold_level)
    end
  elseif cycle then
    open_all_folds()
  end
end

return M
