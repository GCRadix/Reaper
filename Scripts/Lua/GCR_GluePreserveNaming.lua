function main()
    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount == 0 then return end
    local firstItem = reaper.GetSelectedMediaItem(0, 0)
    local firstTake = reaper.GetActiveTake(firstItem)
    if firstTake == nil then return end
    local _, takeName = reaper.GetSetMediaItemTakeInfo_String(firstTake, "P_NAME", "", false)
    local itemName, _ = takeName:match("(.+)%.(.+)$")
    itemName = itemName or takeName
    if itemName == nil then itemName = takeName end
    
    reaper.Main_OnCommand(40362, 0)
    
    local gluedItem = reaper.GetSelectedMediaItem(0, 0)
    local gluedTake = reaper.GetActiveTake(gluedItem)
    
    if gluedTake then
        reaper.GetSetMediaItemTakeInfo_String(gluedTake, "P_NAME", itemName, true)
    end
end

main()
reaper.UpdateArrange()