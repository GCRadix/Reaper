-- Get user-defined prefix and suffix
retval, user_input = reaper.GetUserInputs("Rename Regions", 2, "Prefix,Suffix", "")
if not retval then return end

prefix, suffix = user_input:match("([^,]+),([^,]+)")
num_selected = reaper.CountSelectedRegions(0)

for i=0, num_selected-1 do
    region_idx = reaper.GetSelectedRegion(0, i)
    retval, is_region, _, start_time, end_time, name, _, _ = reaper.EnumProjectMarkers3(0, region_idx)
    new_name = prefix .. name .. suffix
    reaper.SetProjectMarker3(0, region_idx, is_region, start_time, end_time, new_name, -1)
end
