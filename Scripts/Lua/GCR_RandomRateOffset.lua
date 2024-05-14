function randomizeItemRatesAndLengths()
    local userOK, userInput = reaper.GetUserInputs("Randomize Rates", 1, "Max Rate Offset:", "0.25")
    
    if not userOK then
        return reaper.ShowMessageBox("Input canceled. Please enter a valid number.", "Error", 0)
    end
    
    local rateOffset = tonumber(userInput)
    
    if not rateOffset then
        return reaper.ShowMessageBox("Invalid input. Please enter a valid number.", "Error", 0)
    end
    
    local selectedItemCount = reaper.CountSelectedMediaItems(0)
    if selectedItemCount == 0 then
        return reaper.ShowMessageBox("No items selected.", "Error", 0)
    end
    
    for i = 0, selectedItemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        
        if take then
            local currentRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
            local randomOffset = math.random(-rateOffset * 100, rateOffset * 100) / 100
            local newRate = currentRate + randomOffset
            
            local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local newLength = itemLength * currentRate / newRate
            
            reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", newRate)
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", newLength)
        end
    end
    
    reaper.UpdateArrange()
end

reaper.Undo_BeginBlock()
randomizeItemRatesAndLengths()
reaper.Undo_EndBlock("Randomize Item Rates and Lengths", -1)
