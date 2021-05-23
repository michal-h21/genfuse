#!/usr/bin/env lua
local os = require "os"
local io = require "io"
local lfs = require "lfs"

local notification = function(text)
  os.execute('zenity --notification --window-icon="info" --text="'.. text .. '"')
end

local selected = os.getenv('NAUTILUS_SCRIPT_SELECTED_FILE_PATHS')



local files = {}
for f in selected:gmatch("([^\n]+)") do
  files[#files+1] = f
end

-- terminate script if no files were selected
if #files == 0 then
  notification("No files selected")
  os.exit()
end

notification("Aligning:\n " .. selected)

-- save the aligned files to a temp dir
local prefix = os.tmpname()

local align = io.popen("align_image_stack -C -a " ..prefix .. " " .. table.concat(files),"r")
local result = align:read("*all")
align:close()
notification(result)

