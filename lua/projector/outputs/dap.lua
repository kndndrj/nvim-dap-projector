local Output = require("projector.contract.output")
local has_dap, dap = pcall(require, "dap")
local has_dapui, dapui = pcall(require, "dapui")
---@cast dap -Loader

---@type Output
local DapOutput = Output:new()

---@param configuration task_configuration
---@diagnostic disable-next-line: unused-local
function DapOutput:init(configuration)
  if has_dap then
    self.status = "visible"

    -- set status if by any chance the above setting failed
    dap.listeners.before.event_initialized["projector"] = function()
      self.status = "visible"
    end
    -- set status to inactive and hide outputs on exit
    dap.listeners.before.event_terminated["projector"] = function()
      self.status = "inactive"
      self:done(true)
    end
    dap.listeners.before.event_exited["projector"] = function()
      self.status = "inactive"
    end

    dap.run(configuration)
  end
end

function DapOutput:show()
  if has_dapui then
    dapui.open()
    self.status = "visible"
  end
end

function DapOutput:hide()
  if has_dapui then
    dapui.close()
    self.status = "hidden"
  end
end

function DapOutput:kill()
  if has_dap then
    dap.terminate()
  end
  if has_dapui then
    dapui.close()
  end
  self.status = "inactive"
end

---@return task_action[]|nil
function DapOutput:list_actions()
  if not has_dap then
    return
  end

  local session = dap.session()
  if not session then
    return
  end

  if session.stopped_thread_id then
    return {
      {
        label = "Continue",
        action = function()
          session:_step("continue")
        end,
        override = true,
      },
    }
  end

  ---@type task_action[]
  local actions = {
    {
      label = "Terminate session",
      action = dap.terminate,
    },
    {
      label = "Pause a thread",
      action = dap.pause,
    },
    {
      label = "Restart session",
      action = dap.restart,
    },
    {
      label = "Disconnect (terminate = true)",
      action = function()
        dap.disconnect { terminateDebuggee = true }
      end,
    },
    {
      label = "Disconnect (terminate = false)",
      action = function()
        dap.disconnect { terminateDebuggee = false }
      end,
    },
  }

  -- Add stopped threads nested actions
  local stopped_threads = vim.tbl_filter(function(t)
    return t.stopped
  end, session.threads)

  if next(stopped_threads) then
    ---@type task_action[]
    local stopped_thread_actions = {}

    for _, t in pairs(stopped_threads) do
      table.insert(stopped_thread_actions, {
        label = t.name or t.id,
        action = function()
          session.stopped_thread_id = t.id
          session:_step("continue")
        end,
      })
    end

    -- Add an action with nested actions to the list
    table.insert(actions, 1, {
      label = "Resume stopped thread",
      nested = stopped_thread_actions,
    })
  end

  return actions
end

return DapOutput
