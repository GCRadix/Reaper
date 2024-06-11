-- NOTE: This script requires js_ReaScriptAPI extension to work
-- https://github.com/juliansader/ReaExtensions/tree/master/js_ReaScriptAPI/

local title = reaper.JS_Localize('Region/Marker Manager', 'common')

package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
local rtk = require('rtk')

function GetAllRegions(lv)
  local cnt = reaper.JS_ListView_GetItemCount(lv)  
  local t = {}
  for i = 0, cnt-1 do
    if reaper.JS_ListView_GetItemText(lv, i, 1):match("R%d") then
      t[#t+1] = i
    end
  end
  return t
end

function GetSelectedRegions(lv)
  local cnt = reaper.JS_ListView_GetItemCount(lv)  
  local t = {}
  for i = 0, cnt-1 do
    local item_state = reaper.JS_ListView_GetItemState(lv, i)
    if reaper.JS_ListView_GetItemText(lv, i, 1):match("R%d") then
      if item_state == 3 or item_state == 2 then
        t[#t+1]= i
      end
    end
  end
  return t
end

function GetNestedRegions(lv, regions)
  local cnt = reaper.JS_ListView_GetItemCount(lv)  
  local t = {}
  for i = 0, cnt-1 do
    if reaper.JS_ListView_GetItemText(lv, i, 1):match("R%d") then
      local region_start = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, i, 3), 2)
      local region_end = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, i, 4), 2)
      for j = 1, #regions do
        -- exclude the region itself
        if regions[j] ~= i then
          -- check if the region is within a selected region
          local sel_region_start = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, regions[j], 3), 2)
          local sel_region_end = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, regions[j], 4), 2)
          if region_start >= sel_region_start and region_end <= sel_region_end then
            t[#t+1]= i
            break
          end
        end
      end
    end
  end
  return t
end

function TableContainsValue(table, value)
  for i = 1, #table do
    if table[i] == value then 
      return true
    end
  end
  return false
end

function LvSelectItem(hwnd, index, selected)
  if selected then -- Select item @ index
    reaper.JS_ListView_SetItemState(hwnd, index, 2, 2)
  else -- Unselect item @ index
    reaper.JS_ListView_SetItemState(hwnd, index, 1, -1)
  end
end

function Main()
  -- Open Region Manager window if not found,
  local manager = reaper.JS_Window_Find(title, true)
  if not manager then
    reaper.Main_OnCommand(40326, 0) -- View: Show region/marker manager window
    manager = reaper.JS_Window_Find(title, true) 
  end

  retval, user_input_csv = reaper.GetUserInputs("Region renamer", 4, 
  "Add prefix,Add suffix,Recapitalize (Y/N),Ending before", 
  "N,,,"
  )

  if retval == false then 
    return
  end

  local user_input = {}
  for value in string.gmatch(user_input_csv, '([^,]*),?') do
    table.insert(user_input, value)
  end

  select_nested = user_input[1] == "Y" or user_input[1] == "y"
  search_query = user_input[2]
  after_time = user_input[3]
  before_time = user_input[4] 

  -- Fix in case of empty last value
  if before_time == nil then
    before_time = ''
  end

  local before_time_secs, after_time_secs
  if before_time ~= '' then
    before_time_secs = reaper.parse_timestr_pos(before_time, 2)
  end
  if after_time ~= '' then
    after_time_secs = reaper.parse_timestr_pos(after_time, 2)
  end

  if manager then
    reaper.DockWindowActivate(manager) -- OPTIONAL: Select/show manager if docked
    reaper.JS_Window_SetForeground(manager)-- Set focus on Manager window
    local lv = reaper.JS_Window_FindChild(manager, 'List2', true)

    local region_indexes = GetAllRegions(lv)
    local selected_region_indexes = GetSelectedRegions(lv)
    local nested_region_indexes = GetNestedRegions(lv, selected_region_indexes)

    local sel_region = region_indexes[1]
    
    if sel_region then
      for i = 1, #region_indexes do -- get current selection/focused region item
        local should_select = false
        local region_name = reaper.JS_ListView_GetItemText(lv, region_indexes[i], 2)
        local region_start = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, region_indexes[i], 3), 2)
        local region_end = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, region_indexes[i], 4), 2)
        if select_nested == false or TableContainsValue(nested_region_indexes, region_indexes[i]) then
          if search_query == '' or region_name.find(region_name, search_query) then
              if before_time_secs == nil or region_end < before_time_secs then
                  if after_time_secs == nil or region_start > after_time_secs then
                      should_select = true
                  end
              end
          end
        end
        if should_select then
            reaper.JS_ListView_SetItemState(lv, region_indexes[i], 2, 2) 
        else
            reaper.JS_ListView_SetItemState(lv, region_indexes[i], 1, -1) 
        end
      end 

      reaper.JS_Window_SetFocus(lv)
    end 
  end 
end

if not reaper.APIExists('JS_Localize') then
  reaper.MB('js_ReaScriptAPI extension is required for this script.', 'Extension Not Found', 0)
else
  reaper.defer(Main) 
end