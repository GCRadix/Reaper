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
      local item_state = reaper.JS_ListView_GetItemState(lv, i)
      local r = {
        index=i, 
        name=reaper.JS_ListView_GetItemText(lv, i, 2),
        start_time = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, i, 3), 2),
        end_time = reaper.parse_timestr_pos(reaper.JS_ListView_GetItemText(lv, i, 4), 2),
        is_selected = (item_state == 3 or item_state == 2)
      }
      t[#t+1] = r
    end
  end
  return t
end

function GetNestedRegions(lv, regions)
  local t = {}
  for i = 1, #regions do
    for j = 1, #regions do
      -- exclude the already selected region itself
      if regions[j].is_selected and regions[j].index ~= regions[i].index then
        -- check if the region is within this selected region
        if regions[i].start_time >= regions[j].start_time and regions[i].end_time <= regions[j].end_time then
          t[#t+1]= regions[i]
          break
        end
      end
    end
  end
  return t
end

function TableContainsRegion(table, region)
  for i = 1, #table do
    if table[i].index == region.index then 
      return true
    end
  end
  return false
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

function PerformSelection(select_nested, search_query, before_time, after_time)

  local before_time_secs, after_time_secs
  if before_time ~= '' then
    before_time_secs = reaper.parse_timestr_pos(before_time, 2)
  end
  if after_time ~= '' then
    after_time_secs = reaper.parse_timestr_pos(after_time, 2)
  end

  local manager = reaper.JS_Window_Find(title, true)
  if manager then
    reaper.DockWindowActivate(manager) -- OPTIONAL: Select/show manager if docked
    reaper.JS_Window_SetForeground(manager)-- Set focus on Manager window
    local lv = reaper.JS_Window_FindChild(manager, 'List2', true)

    local regions = GetAllRegions(lv)
    local nested_regions = GetNestedRegions(lv, regions)

    for i = 1, #regions do -- get current selection/focused region item
      local region = regions[i]
      local should_select = false
      if select_nested == false or TableContainsRegion(nested_regions, region) then
        if search_query == '' or string.find(region.name, search_query) then
            if before_time_secs == nil or region.end_time < before_time_secs then
                if after_time_secs == nil or region.start_time > after_time_secs then
                    should_select = true
                end
            end
        end
      end
      if should_select then
          reaper.JS_ListView_SetItemState(lv, region.index, 2, 2) 
      else
          reaper.JS_ListView_SetItemState(lv, region.index, 1, -1) 
      end
    end 

    reaper.JS_Window_SetFocus(lv)
  end 
end

function OpenUI()
  local selector = rtk.Window{w=300, h=300, title="Region Selector"}

  local box_main = rtk.VBox{fillw=true, margin=20, w=1.0}
  local cb_select_nested = rtk.CheckBox{'Nested within selected regions', bmargin=20, w=1.0}
  local entry_search_query = rtk.Entry{placeholder='Name containing text', textwidth=15, bmargin=20, w=1.0}
  local entry_after_time = rtk.Entry{placeholder='Starting after (0.0.00)', textwidth=15, bmargin=20, w=1.0}
  local entry_before_time = rtk.Entry{placeholder='Ending before (0.0.00)', textwidth=15, bmargin=20, w=1.0}

  local box_buttons = rtk.HBox()
  local btn_submit = rtk.Button{label='Run', rmargin=10, color="green", w=80}
  btn_submit.onclick = function()
    PerformSelection(cb_select_nested.value, entry_search_query.value, entry_after_time.value, entry_before_time.value)
    selector:close()
  end
  local btn_cancel = rtk.Button{label='Close', w=80}
  btn_cancel.onclick = function()
    selector:close()
  end
  box_buttons:add(btn_submit)
  box_buttons:add(btn_cancel)

  box_main:add(cb_select_nested)
  box_main:add(entry_search_query)
  box_main:add(entry_after_time)
  box_main:add(entry_before_time)
  box_main:add(box_buttons)

  selector:add(box_main)
  
  selector.onkeypresspost = function(self, event)
    if not event.handled and event.keycode == rtk.keycodes.ENTER and
       not selector.docked then
        PerformSelection(cb_select_nested.value, entry_search_query.value, entry_after_time.value, entry_before_time.value)
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