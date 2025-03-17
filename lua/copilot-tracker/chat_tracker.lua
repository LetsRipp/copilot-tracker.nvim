-- File: chat_tracker.lua
-- Author: hobo
-- License: MIT
-- Description: Tracks CopilotChat usage
-- Version: 0.0.1
-- Created: 2025-17-03
-- Repo: git@github.com:LetsRipp/copilot-tracker.nvim.git

-- Tracks CopilotChat usage
-- Easier than completion tracking because:
-- 1. Can hook into CopilotChat.nvim events
-- 2. Can track prompts used, response length, etc.
-- 3. Need to capture which built-in prompts are used vs custom prompts

-- This is conceptual and would need to be adapted to the actual Copilot API
local function setup_inline_tracking()
  -- Get the Copilot module
  local copilot = require('copilot.suggestion')

  -- Store original functions to hook into them
  local original_show = copilot.show
  local original_accept = copilot.accept

  -- Track the current suggestion
  local current_suggestion = {
    text = nil,
    start_time = nil,
  }

  -- Override the show function
  copilot.show = function(...)
    -- Call the original function
    local result = original_show(...)

    -- Store information about the suggestion
    current_suggestion.text = copilot.get_displayed_suggestion()
    current_suggestion.start_time = vim.loop.now()

    return result
  end

  -- Override the accept function
  copilot.accept = function(...)
    -- Record the acceptance before calling the original function
    if current_suggestion.text then
      local duration = vim.loop.now() - current_suggestion.start_time
      local suggestion_length = #current_suggestion.text

      -- Record the completion
      require('copilot-tracker.storage').record_completion({
        type = 'inline',
        text = current_suggestion.text,
        length = suggestion_length,
        duration = duration,
        filetype = vim.bo.filetype,
        timestamp = os.time(),
      })

      -- Reset the state
      current_suggestion = {
        text = nil,
        start_time = nil,
      }
    end

    -- Call the original function
    return original_accept(...)
  end

  -- Also hook into the clear/dismiss function to reset state
  local original_clear = copilot.clear
  copilot.clear = function(...)
    current_suggestion = {
      text = nil,
      start_time = nil,
    }
    return original_clear(...)
  end
end
