-- Open the current project (cwd) in a GUI IDE.
--
-- Plugin-free: every known IDE launcher is probed with executable(), and the
-- ones that exist are offered through vim.ui.select. If only one is installed
-- it opens straight away without a prompt.

local M = {}

-- JetBrains Toolbox installs its launchers here; keep it as a fallback in case
-- the directory is missing from $PATH (e.g. nvim started outside a login shell).
local TOOLBOX = vim.fn.expand("~/.local/share/JetBrains/Toolbox/scripts")

local candidates = {
  { name = "PyCharm", cmd = "pycharm" },
  { name = "IntelliJ IDEA", cmd = "idea" },
  { name = "GoLand", cmd = "goland" },
  { name = "WebStorm", cmd = "webstorm" },
  { name = "VS Code", cmd = "code" },
}

local function resolve(cmd)
  if vim.fn.executable(cmd) == 1 then
    return cmd
  end
  local toolbox = TOOLBOX .. "/" .. cmd
  if vim.fn.executable(toolbox) == 1 then
    return toolbox
  end
  return nil
end

local function installed()
  local found = {}
  for _, ide in ipairs(candidates) do
    local exe = resolve(ide.cmd)
    if exe then
      table.insert(found, { name = ide.name, exe = exe })
    end
  end
  return found
end

local function launch(ide, target)
  vim.fn.jobstart({ ide.exe, target }, { detach = true })
  vim.notify("Opening " .. vim.fn.fnamemodify(target, ":~") .. " in " .. ide.name)
end

-- target defaults to the cwd; pass a path to open something else
function M.open(target)
  target = target or vim.fn.getcwd()

  local ides = installed()
  if #ides == 0 then
    vim.notify("No IDE launcher found", vim.log.levels.WARN)
    return
  end
  if #ides == 1 then
    launch(ides[1], target)
    return
  end

  vim.ui.select(ides, {
    prompt = "Open in IDE:",
    format_item = function(ide)
      return ide.name
    end,
  }, function(choice)
    if choice then
      launch(choice, target)
    end
  end)
end

return M
