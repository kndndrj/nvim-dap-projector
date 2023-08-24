-- This package provides functions to convert various
-- structures to NuiTree nodes

local NuiTree = require("nui.tree")
local utils = require("projector.utils")

local M = {}

-- retrieve nodes from active tasks (hidden and visible)
---@param tasks Task[] list of all tasks
---@return Node[]
function M.active_task_nodes(tasks)
  local visible_nodes = {}
  local hidden_nodes = {}

  ---@param actions task_action[]
  ---@param parent_id string
  ---@return Node[]
  local function parse_actions(actions, parent_id)
    actions = actions or {}
    local action_nodes = {}
    for _, action in ipairs(actions) do
      local id = parent_id .. action.label

      -- create action node
      local node = NuiTree.Node({
        id = id,
        name = action.label,
        type = "action",
        action_1 = function()
          action.action()
        end,
      }, parse_actions(action.nested, id))

      -- expand by default (show nested actions)
      node:expand()

      table.insert(action_nodes, node)
    end

    return action_nodes
  end

  for _, task in ipairs(tasks) do
    if task:is_live() then
      local is_visible = task:is_visible()
      local type = "task_hidden"
      local meta = task:metadata()
      if is_visible then
        type = "task_visible"
      end
      local _, current_mode = task:modes()

      local node = NuiTree.Node({
        id = meta.id,
        name = meta.name,
        type = type,
        comment = current_mode,
        -- show
        action_1 = function()
          task:show()
        end,
        -- restart
        action_2 = function()
          task:run { restart = true }
        end,
        -- kill
        action_3 = function()
          task:kill()
        end,
      }, parse_actions(task:actions(), meta.id))

      -- expand by default (show actions)
      node:expand()

      if is_visible then
        table.insert(visible_nodes, node)
      else
        table.insert(hidden_nodes, node)
      end
    end
  end

  -- merge visible and hidden tasks together
  vim.list_extend(visible_nodes, hidden_nodes)

  return visible_nodes
end

-- retrieve nodes from inactive tasks
---@param tasks Task[] list of all tasks
---@return Node[]
function M.inactive_task_nodes(tasks)
  local normal_nodes = {}

  -- nodes that are hidden in the menu (because of presentation options)
  local menuhidden_nodes = {}

  for _, task in ipairs(tasks) do
    if not task:is_live() then
      -- handle modes
      local comment
      local modes, _ = task:modes()
      local action
      local children = {}
      if #modes == 1 then
        action = function()
          task:run { mode = modes[1] }
        end
        comment = modes[1]
      elseif #modes > 1 then
        for _, mode in ipairs(modes) do
          table.insert(
            children,
            NuiTree.Node {
              id = task:metadata().id .. mode,
              name = mode,
              type = "mode",
              action_1 = function()
                task:run { mode = mode }
              end,
            }
          )
        end
      end

      local node = NuiTree.Node({
        id = task:metadata().id,
        name = task:metadata().name,
        comment = comment,
        type = "task_inactive",
        action_1 = action,
      }, children)

      -- put in appropriate list based on presentation
      if task:presentation().menu.show then
        table.insert(normal_nodes, node)
      else
        table.insert(menuhidden_nodes, node)
      end
    end
  end

  -- if there aren't any normal nodes, return hidden ones as normal
  if #normal_nodes < 1 then
    return menuhidden_nodes
  end

  -- if there aren't any hidden nodes, return just the normal ones
  if #menuhidden_nodes < 1 then
    return normal_nodes
  end

  -- if there are hidden and normal nodes, add hidden ones under a fold

  local hidden_fold_node = NuiTree.Node({
    id = "__menuhidden_nodes_ui__",
    name = "hidden tasks",
    type = "",
  }, menuhidden_nodes)

  return utils.merge_lists(normal_nodes, M.separator_nodes(1), { hidden_fold_node })
end

-- get blank separator nodes
---@param count? integer default is 1
---@return Node[]
function M.separator_nodes(count)
  if not count or count < 1 then
    count = 1
  end

  local nodes = {}
  for i = 1, count do
    local node = NuiTree.Node {
      id = "__separator_node_" .. i .. tostring(math.random()),
      name = "",
      type = "",
    }
    table.insert(nodes, node)
  end

  return nodes
end

-- retrieve loader nodes
---@param loaders Loader[] list of loaders
---@return Node[]
function M.loader_nodes(loaders)
  local nodes = {}

  for _, loader in ipairs(loaders) do
    table.insert(
      nodes,
      NuiTree.Node {
        id = tostring(math.random()),
        name = "asdf",
        type = "loader",
        action_1 = function() end,
      }
    )
  end

  return nodes
end

-- retrieve loader nodes
---@return Node[]
function M.help_no_task_nodes()
  return {
    NuiTree.Node {
      id = tostring(math.random()),
      name = "No tasks available!",
      type = "",
    },
    NuiTree.Node {
      id = tostring(math.random()),
      name = "Press here for help",
      comment = ":h projector",
      type = "",
      action_1 = function()
        vim.cmd(":h projector")
      end,
    },
  }
end

-- retrieve loader nodes
---@return Node[]
function M.help_no_loader_nodes()
  return {
    NuiTree.Node {
      id = tostring(math.random()),
      name = "No loaders configured!",
      type = "",
    },
    NuiTree.Node {
      id = tostring(math.random()),
      name = "Press here for help",
      comment = ":h projector-loaders",
      type = "",
      action_1 = function()
        vim.cmd(":h projector-loaders")
      end,
    },
  }
end

return M
