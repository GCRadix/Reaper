# Reaper Scripts and Tools
This is a collection of reaper scrpits and automations by GCRadix. <br/>
If you'd like to request other tools or adjustments to the current ones, please contact Lukas Keil on slack or via lkeil@gcradix.com.

# Script Reference

## GCR_BatchCreateRegionsForClips
Creates a Region for every clip on the timeline with the name of the clip without file extensions.

## GCR_SelectionCreateRegionsForClips
Creates a Region for selected clips on the timeline with the name of the clip without file extensions.

## GCR_GluePreserveNaming
Glues together a selection of clips uses the first item's name for the resulting clip.

# Installation

## By Copy
1. Copy the scripts from this folder into your reaper scripts path.<br/>
2. Usually at `AppData\Roaming\REAPER\Scripts\...`
3. Restart Reaper.<br/>
(For Lua Scripts:)<br/>
4. In Reaper go into the Actions Menu.
5. On the bottom right, under `New action...`, use `Load Script` to add the script to your actions.

## As New Scripts

1. Open the Actions List
Launch Reaper.
Navigate to the `Actions` menu at the top of the screen.
Select `Show action list...` to open the Actions List window.

2. New ReaScript
In the Actions List window, click on the `ReaScript:` button, then choose `New`.
A dialog box will appear, asking you to save a new script file. Reaper scripts can be saved anywhere, but it's a good idea to keep them in a dedicated folder for organization.

3. Choose Scripting Language
You will be prompted to choose a scripting language. Select `Lua` or the scripting language that you would like to import, then click `OK`.

4. Write or Paste the Script
A text editor window will open within Reaper. This is where you can write or paste the Lua script code provided earlier.
Paste the entire script into this editor. Be sure it's exactly as provided, without any modifications unless you're familiar with Lua and want to make specific changes.

5. Save and Close the Editor
After pasting the script, click the `File` menu within the script editor, then choose `Save` (or press `Ctrl+S` on your keyboard).
Give your script a meaningful name that reflects its purpose, such as "Create Regions from Items.lua" or "Glue and Rename Items.lua".
Close the script editor window.

6. Run Your Script
Back in the Actions List window, your new script should now be listed under the `ReaScript` section. If you don't see it immediately, you can use the `Filter` box at the bottom of the Actions List window to search for it by the name you gave it.
To run the script, select it from the list and click the `Run` button on the right side of the Actions List window.
