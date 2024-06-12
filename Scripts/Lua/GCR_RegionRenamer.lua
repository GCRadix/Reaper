-- NOTE: This script requires js_ReaScriptAPI extension to work
-- https://github.com/juliansader/ReaExtensions/tree/master/js_ReaScriptAPI/

local title = reaper.JS_Localize('Region/Marker Manager', 'common')

package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
local rtk = require('rtk')

function GetSelectedRegions(lv)
  local cnt = reaper.JS_ListView_GetItemCount(lv)  
  local t = {}
  for i = 0, cnt-1 do
    if reaper.JS_ListView_GetItemText(lv, i, 1):match("R%d") then
      local item_state = reaper.JS_ListView_GetItemState(lv, i)
      local selected = item_state == 2 or item_state == 3
      if selected then
        local r = {
          index=tonumber(string.sub(reaper.JS_ListView_GetItemText(lv, i, 1), 2)), 
          name=reaper.JS_ListView_GetItemText(lv, i, 2),
          start_time = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, i, 3), 2),
          end_time = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, i, 4), 2)
        }
        t[#t+1] = r
      end
    end
  end
  return t
end

function Main()
  -- Open Region Manager window if not found,
  local manager = reaper.JS_Window_Find(title, true)
  if not manager then
    reaper.Main_OnCommand(40326, 0) -- View: Show region/marker manager window
    manager = reaper.JS_Window_Find(title, true) 
  end

  OpenUI()
end

function toTitleCase(input)
  -- Function to capitalize the first letter of a word
  local function capitalize(word)
      return word:sub(1, 1):upper() .. word:sub(2):lower()
  end

  -- Create a table to store the output
  local output = {}
  
  -- Iterate through the input string
  local i = 1
  while i <= #input do
      local c = input:sub(i, i)
      if c:match("[_%-%s%.]") then
          -- If the character is a separator, add it to the output
          table.insert(output, c)
          i = i + 1
      else
          -- If the character is not a separator, find the end of the word
          local j = i
          while j <= #input and not input:sub(j, j):match("[_%-%s%.]") do
              j = j + 1
          end
          -- Capitalize the word and add it to the output
          table.insert(output, capitalize(input:sub(i, j - 1)))
          i = j
      end
  end

  -- Join the output table into a single string
  return table.concat(output)
end

local function formatAlphabetic(num, length, uppercase)
  local result = ""
  local a = uppercase and "A" or "a"
  local base = 26
  num = num - 1
  while num >= 0 do
      result = string.char(a:byte() + (num % base)) .. result
      num = math.floor(num / base) - 1
  end
  while #result < length do
      result = a .. result
  end
  return result
end

function PerformRename(prefix, suffix, casing, num_settings, replace_settings)
  
  local manager = reaper.JS_Window_Find(title, true)
  if manager then
    reaper.DockWindowActivate(manager) -- OPTIONAL: Select/show manager if docked
    reaper.JS_Window_SetForeground(manager)-- Set focus on Manager window
    local lv = reaper.JS_Window_FindChild(manager, 'List2', true)

    local regions = GetSelectedRegions(lv)

    for i = 1, #regions do
      local region = regions[i]
      local new_name = prefix .. region.name .. suffix

      -- Replace
      if replace_settings_from ~= '' then
        new_name = string.gsub(new_name, replace_settings.from, replace_settings.to)
      end

      -- Casing
      if casing == "title" then
        new_name = toTitleCase(new_name)
      elseif casing == "upper" then
        new_name = string.upper(new_name)
      elseif casing == "lower" then
        new_name = string.lower(new_name)
      end

      -- Numeration
      if num_settings.mode == "numbers" then
        new_name = new_name .. num_settings.separator .. string.format("%0" .. num_settings.charnum .. "d", i)
      elseif num_settings.mode == "upper" then
        new_name = new_name .. num_settings.separator .. formatAlphabetic(i, num_settings.charnum, true)
      elseif num_settings.mode == "lower" then
        new_name = new_name .. num_settings.separator .. formatAlphabetic(i, num_settings.charnum, false)
      end

      reaper.SetProjectMarker4(0, region.index, true, region.start_time, region.end_time, new_name, 0, 0)
    end 

    reaper.JS_Window_SetFocus(lv)
  end 
end

function OpenUI()
  local selector = rtk.Window{w=300, h=500, title="Region Renamer"}

  local box_main = rtk.VBox{fillw=true, margin=20, w=1.0}
  local entry_prefix = rtk.Entry{placeholder='Add prefix', textwidth=15, bmargin=10, w=1.0}
  local entry_suffix = rtk.Entry{placeholder='Add suffix', textwidth=15, bmargin=10, w=1.0}

  local text_casing = rtk.Text{'Casing', tmargin=10, bmargin=10, halign='center'}
  local menu_casing = rtk.OptionMenu{
    menu={
        {"Unchanged", id='unchanged'},
        {'Title case', id='title'},
        {'Uppercase', id='upper'},
        {'Lowercase', id='lower'},
    }, bmargin=10, w=1.0, selected="unchanged"
  }

  local text_numeration = rtk.Text{'Numeration', tmargin=10, bmargin=10, halign='center'}
  local menu_numeration_mode = rtk.OptionMenu{
    menu={
        {"None", id='none'},
        {'Numbers', id='numbers'},
        {'Letters (uppercase)', id='upper'},
        {'Letters (lowercase)', id='lower'},
    }, bmargin=10, w=1.0, selected="none"
  }
  local entry_numeration_separator = rtk.Entry{placeholder='Numeration seperator (e.g. "_")', textwidth=15, bmargin=10, w=1.0}
  local entry_numeration_charnum = rtk.Entry{placeholder='Numeration length (1-10)', textwidth=15, bmargin=10, w=1.0}

  local text_replace = rtk.Text{'Replace', tmargin=10, bmargin=10, halign='center'}
  local entry_replace_from = rtk.Entry{placeholder='From', textwidth=15, bmargin=10, w=1.0}
  local entry_replace_to = rtk.Entry{placeholder='To', textwidth=15, bmargin=10, w=1.0}

  local box_buttons = rtk.HBox{tmargin=10}
  local btn_submit = rtk.Button{label='Run', rmargin=10, color="green", w=80}
  btn_submit.onclick = function()
    local charnum = tonumber(entry_numeration_charnum.value)
    if charnum == nil or charnum <= 0 then charnum = 1 end
    if charnum > 10 then charnum = 10 end
    local numeration_settings = {mode=menu_numeration_mode.selected_id, separator=entry_numeration_separator.value, charnum=charnum}

    local replace_settings = {from=entry_replace_from.value, to=entry_replace_to.value}
    PerformRename(entry_prefix.value, entry_suffix.value, menu_casing.selected_id, numeration_settings, replace_settings)
    selector:close()
  end
  local btn_cancel = rtk.Button{label='Close', w=80}
  btn_cancel.onclick = function()
    selector:close()
  end
  box_buttons:add(btn_submit)
  box_buttons:add(btn_cancel)

  box_main:add(entry_prefix)
  box_main:add(entry_suffix)
  box_main:add(text_replace)
  box_main:add(entry_replace_from)
  box_main:add(entry_replace_to)
  box_main:add(text_casing)
  box_main:add(menu_casing)
  box_main:add(text_numeration)
  box_main:add(menu_numeration_mode)
  box_main:add(entry_numeration_separator)
  box_main:add(entry_numeration_charnum)

  box_main:add(box_buttons)

  selector:add(box_main)
  
  selector.onkeypresspost = function(self, event)
    if not event.handled and event.keycode == rtk.keycodes.ENTER and
       not selector.docked then
        local charnum = tonumber(entry_numeration_charnum.value)
        if charnum == nil or charnum <= 0 then charnum = 1 end
        if charnum > 10 then charnum = 10 end
        local numeration_settings = {mode=menu_numeration_mode.selected_id, separator=entry_numeration_separator.value, charnum=charnum}

        local replace_settings = {from=entry_replace_from.value, to=entry_replace_to.value}
        PerformRename(entry_prefix.value, entry_suffix.value, menu_casing.selected_id, numeration_settings, replace_settings)
        selector:close()
    end
  end

  selector:open{align='center'}
end

if not reaper.APIExists('JS_Localize') then
  reaper.MB('js_ReaScriptAPI extension is required for this script.', 'Extension Not Found', 0)
else
  reaper.defer(Main) 
end