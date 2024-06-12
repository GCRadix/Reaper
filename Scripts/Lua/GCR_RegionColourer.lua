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

function PerformColour(mode, color_a, color_b)
  
  local manager = reaper.JS_Window_Find(title, true)
  if manager then
    reaper.DockWindowActivate(manager) -- OPTIONAL: Select/show manager if docked
    reaper.JS_Window_SetForeground(manager)-- Set focus on Manager window
    local lv = reaper.JS_Window_FindChild(manager, 'List2', true)

    local regions = GetSelectedRegions(lv)

    for i = 1, #regions do

      local region = regions[i]

      local color = 0
      if mode == 'gradient' then
        local r1,g1,b1 = reaper.ColorFromNative(color_a)
        local r2,g2,b2 = reaper.ColorFromNative(color_b)
        local r = math.floor(r1 + (r2 - r1) * i / #regions)
        local g = math.floor(g1 + (g2 - g1) * i / #regions)
        local b = math.floor(b1 + (b2 - b1) * i / #regions)
        color = reaper.ColorToNative(r, g, b)|0x1000000
      elseif mode == 'single' then
        color = color_a|0x1000000
      end

      local r,g,b = reaper.ColorFromNative(color_a)
      reaper.SetProjectMarker4(0, region.index, true, region.start_time, region.end_time, region.name, color, 0)
    end 

    reaper.JS_Window_SetFocus(lv)
  end 
end

function OpenUI()
  local selector = rtk.Window{w=300, h=300, title="Region Colourer"}

  local box_main = rtk.VBox{fillw=true, margin=20, w=1.0}

  local text_mode = rtk.Text{'Mode', tmargin=10, bmargin=10, halign='center'}
  local menu_mode = rtk.OptionMenu{
    menu={
        {"Single", id='single'},
        {'Gradient', id='gradient'},
    }, bmargin=20, w=1.0, selected="gradient"
  }
  box_main:add(text_mode)
  box_main:add(menu_mode)

  math.randomseed(os.time())
  local color_a = reaper.ColorToNative(math.random(0,255), math.random(0,255), math.random(0,255))
  local color_b = reaper.ColorToNative(math.random(0,255), math.random(0,255), math.random(0,255))

  local box_colors = rtk.HBox{fillw=true, bmargin=10}
  local btn_color_a = rtk.Button{label="", w=1.0, h=100, rmargin=5, fillw=true, fillh=true, color=color_a, gradient=0}
  local btn_color_b = rtk.Button{label="", w=1.0, h=100, lmargin=5, fillw=true, fillh=true, color=color_b, gradient=0}
  btn_color_a.onclick = function()
    local retval, color = reaper.GR_SelectColor(nil)
    if retval then
      color_a = color
      btn_color_a:attr('color', color_a)
    end
  end
  btn_color_b.onclick = function()
    if menu_mode.selected_id == 'single' then
      return
    end
    local retval, color = reaper.GR_SelectColor(nil)
    if retval then
      color_b = color
      btn_color_b:attr('color', color_b)
    end
  end

  menu_mode.onchange = function(self)
    if self.selected_id == 'single' then
      btn_color_b:attr('w', 0.0)
      btn_color_a:attr('w', 1.0)
    else
      btn_color_b:attr('w', 1.0)
      btn_color_a:attr('w', 1.0)
    end
  end

  box_colors:add(btn_color_a, {fillw=true, expand=true})
  box_colors:add(btn_color_b, {fillw=true, expand=true})
  box_main:add(box_colors)

  local box_buttons = rtk.HBox{tmargin=10}
  local btn_submit = rtk.Button{label='Run', rmargin=10, color="green", w=80}
  btn_submit.onclick = function()
    PerformColour(menu_mode.selected_id, color_a, color_b)
    selector:close()
  end
  local btn_cancel = rtk.Button{label='Close', w=80}
  btn_cancel.onclick = function()
    selector:close()
  end
  box_buttons:add(btn_submit)
  box_buttons:add(btn_cancel)

  box_main:add(box_buttons)

  selector:add(box_main)

  selector.onkeypresspost = function(self, event)
    if not event.handled and event.keycode == rtk.keycodes.ENTER and
       not selector.docked then
        PerformColour(menu_mode.selected_id, color_a, color_b)
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