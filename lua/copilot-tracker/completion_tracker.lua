-- File: completion_tracker.lua
-- Author: hobo
-- License: MIT
-- Description: Tracks code completions from Copilot
-- Version: 0.0.1
-- Created: 2025-17-03
-- Repo: git@github.com:LetsRipp/copilot-tracker.nvim.git

-- Tracks code completions from Copilot
-- Challenges:
-- 1. Need to hook into zbirenbaum/copilot.lua events
-- 2. Detect when suggestions are accepted vs. ignored
-- 3. Track suggestion length, language context, etc.
-- 4. May need to monkey-patch the copilot plugin or use its events if available

-- Track completions via cmp
local function setup_cmp_tracking()
  local cmp = require('cmp')

  -- Store the current completion state
  local current_completion = {
    is_copilot_suggestion = false,
    suggestion_text = nil,
    start_time = nil,
  }

  -- Hook into cmp events
  cmp.event:on('menu_opened', function()
    -- Check if any of the visible items are from Copilot
    local entries = cmp.get_entries()
    for _, entry in ipairs(entries or {}) do
      if entry.source.name == 'copilot' then
        current_completion.is_copilot_suggestion = true
        current_completion.suggestion_text = entry:get_insert_text()
        current_completion.start_time = vim.loop.now()
        break
      end
    end
  end)

  cmp.event:on('confirm_done', function(event)
    -- If the confirmed item is from Copilot, record it
    if current_completion.is_copilot_suggestion and event.entry.source.name == 'copilot' then
      local duration = vim.loop.now() - current_completion.start_time
      local suggestion_length = #current_completion.suggestion_text

      -- Record the completion
      require('copilot-tracker.storage').record_completion({
        type = 'cmp',
        text = current_completion.suggestion_text,
        length = suggestion_length,
        duration = duration,
        filetype = vim.bo.filetype,
        timestamp = os.time(),
      })
    end

   -- Reset the state
    current_completion = {
      is_copilot_suggestion = false,
      suggestion_text = nil,
      start_time = nil,
    }
  end)

  cmp.event:on('menu_closed', function()
    -- Reset the state when menu closes without selection
    current_completion = {
      is_copilot_suggestion = false,
      suggestion_text = nil,
      start_time = nil,
    }
  end)
end
