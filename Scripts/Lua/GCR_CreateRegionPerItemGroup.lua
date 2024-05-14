-- Get user-defined region name
retval, user_input = reaper.GetUserInputs("Create Regions", 1, "Region name:", "")
if not retval then return end

-- Get selected items and create a cache of their start and end positions
local item_cache = {}
local sel_items = reaper.CountSelectedMediaItems(0)
for i = 0, sel_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len
    
    table.insert(item_cache, {item_pos, item_end})
end

-- Sort the cache by start position
table.sort(item_cache, function(a, b) return a[1] < b[1] end)

-- Create groups of items that have overlapping time ranges
local groups = {}
local group_start = item_cache[1][1]
local group_end = item_cache[1][2]
for i = 2, sel_items do
    local item_start = item_cache[i][1]
    local item_end = item_cache[i][2]
    
    if item_start < group_end then
        group_end = math.max(group_end, item_end)
    else
        table.insert(groups, {group_start, group_end})
        group_start = item_start
        group_end = item_end
    end
end
table.insert(groups, {group_start, group_end})

-- Create regions for each group of overlapping items
for i, group in ipairs(groups) do
    local region_name = user_input .. "_" .. string.format("%02d", i)
    local region_start = group[1]
    local region_end = group[2]
    reaper.AddProjectMarker2(0, true, region_start, region_end, region_name, i, 0)
end
