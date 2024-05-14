
-- Get user input and selected items.
retval, user_input = reaper.GetUserInputs("Pitch Offset", 1, "Max Offset (cents)", "")
if not retval then return end
local max_offset = tonumber(user_input) * 0.01
local sel_items = {}
local num_sel_items = reaper.CountSelectedMediaItems(0)
for i = 0, num_sel_items - 1 do
    sel_items[i+1] = reaper.GetSelectedMediaItem(0, i)
end

-- Randomly offset the pitch of each selected item within the user-defined range
for i, item in ipairs(sel_items) do
    local item_pitch = reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_PITCH")
    local random_offset = (math.random() * 2 - 1) * max_offset
    local new_pitch = item_pitch + random_offset
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_PITCH", new_pitch)
    reaper.UpdateArrange()
end
