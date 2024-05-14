local interval = 5 -- Auto-save interval in minutes
local intervalInSeconds = interval * 60

function autoSaveProject()
    local isProjectDirty = reaper.IsProjectDirty(0)
    if isProjectDirty == 1 then
        -- Generate a timestamped file name to avoid overwriting previous saves
        local projectPath, projectName = reaper.GetProjectPath(), reaper.GetProjectName(0, "")
        local timeStamp = os.date("%Y%m%d_%H%M%S")
        local savePath = projectPath .. "/" .. projectName .. "_AutoSave_" .. timeStamp .. ".rpp"

        -- Save the project
        reaper.Main_SaveProject(0, savePath, true)
        reaper.ShowConsoleMsg("Project auto-saved at: " .. savePath .. "\n")
    end

    -- Set the script to run again after the specified interval
    reaper.defer(function() reaper.defer(autoSaveProject) end)
    reaper.atexit(reaper.defer(autoSaveProject))
end

reaper.defer(autoSaveProject)
reaper.SetTimer(autoSaveProject, intervalInSeconds)