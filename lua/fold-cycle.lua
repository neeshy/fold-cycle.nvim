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

local function open_all_folds()
  vim.cmd('silent! %foldopen!')
end

local function close_all_folds()
  vim.cmd('silent! %foldclose!')
end

-- Open all child folds of a specified level
local function open_folds_by_level(fold_start, fold_end, level)
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

-- Close all child folds of a specified level
local function close_folds_by_level(fold_start, fold_end, level)
  local line = fold_start
  while line < fold_end do
    if is_fold_closed(line) then
      line = vim.fn.foldclosedend(line) + 1
    elseif vim.fn.foldlevel(line) >= level then
      vim.cmd.foldclose { range = { line } }
      line = vim.fn.foldclosedend(line) + 1
    else
      line = line + 1
    end
  end
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
    open_all_folds()
  end
end

-- Close all folds
function M.close_all()
  if vim.fn.foldlevel('.') > 0 then
    close_folds()
  else
    close_all_folds()
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
function M.open(opts)
  local cycle = type(opts) ~= 'table' or opts.cycle == nil or opts.cycle

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

  -- If current line is unfolded but nested folds can still be further unfolded
  if min_fold_level then
    if fold_level > 0 then
      open_folds()
    else
      open_all_folds()
    end
  elseif cycle then
    if fold_level > 0 then
      -- If there are no nested closed folds
      close_folds()
    else
      close_all_folds()
    end
  end
end

-- Close one level of folds
function M.close(opts)
  local cycle = type(opts) ~= 'table' or opts.cycle == nil or opts.cycle

  if is_fold_closed() and cycle then
    open_folds()
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
      -- If there are no open child folds with a level different from current line
      vim.cmd.foldclose()
    else
      close_folds_by_level(fold_start, fold_end, fold_level + 1)
    end
  elseif cycle then
    open_all_folds()
  end
end

return M
