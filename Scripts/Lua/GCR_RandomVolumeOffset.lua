-- Get user-defined maximum absolute offset value
retval, user_input = reaper.GetUserInputs("Volume Offset", 1, "Max Offset (dB)", "")
if not retval then return end

-- Parse user input
local max_offset = tonumber(user_input)

-- Get all selected items
local sel_items = {}
local num_sel_items = reaper.CountSelectedMediaItems(0)
for i = 0, num_sel_items - 1 do
    sel_items[i+1] = reaper.GetSelectedMediaItem(0, i)
end

-- Randomly offset the volume of each selected item within the user-defined range
for i, item in ipairs(sel_items) do
    local item_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
    local current_vol_offset = 20 * math.log(item_vol) / math.log(10)
    local random_offset = (math.random() * 2 - 1) * max_offset
    local new_vol_offset = current_vol_offset + random_offset
    local new_vol = 10^(new_vol_offset/20)
    reaper.SetMediaItemInfo_Value(item, "D_VOL", new_vol)
    reaper.UpdateArrange(item)
end
