-- This goes through the timeline and creates regions for all clips without the file extensions.
function main()
    local itemCount = reaper.CountMediaItems(0)
    
    for i = 0, itemCount - 1 do
        local item = reaper.GetMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        
        if take ~= nil then
            _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
            local itemName, _ = takeName:match("(.+)%.(.+)$")
            itemName = itemName or takeName
            
            if itemName ~= nil then
                local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                local itemEnd = itemPos + itemLength
                reaper.AddProjectMarker2(0, true, itemPos, itemEnd, itemName, -1, 0xFF0000)
            end
        end
    end
end

main()
reaper.UpdateArrange()
