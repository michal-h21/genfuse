#!/usr/bin/env lua
local os = require "os"
local io = require "io"
local lfs = require "lfs"

local notification = function(text)
  os.execute('zenity --notification --window-icon="info" --text="'.. text .. '"')
end

local find_files = function(prefix, count)
  local image_files = {}
  for i=0, count -1 do
    local current_name = string.format("%s%04d.tif", prefix, i)
    local f = io.open(current_name, "r") 
    if f then 
      image_files[#image_files+1] = current_name 
      f:close()
    else
      -- notification("Cannot find image: ".. current_name)
    end
  end
  return image_files
end

local enfuse = function(image_files, params, output)
  local params = params or {}
  params.gray_projector = params.gray_projector or "l-star"
  params.hard_mask = params.hard_mask or "--hard-mask"
  local enfuse = io.popen("enfuse --exposure-weight=1.0 --saturation-weight=0.2 --contrast-weight=0.2 " .. params.hard_mask.. " --gray-projector=" .. params.gray_projector .. " --contrast-edge-scale=0.3 --output=" .. output .. " " ..  table.concat(image_files, " "), "r" )

  local result = enfuse:read("*all")
  enfuse:close()
  notification("Blended image written to " .. output)
end

-- the output file is based on the first input file
-- "-blend.jpg" suffix is added
local make_output_name = function(base_file, suffix)
  return base_file:gsub("(%..-)$", suffix)
end

-- get selected files in nautilus
local selected = os.getenv('NAUTILUS_SCRIPT_SELECTED_FILE_PATHS') 
-- local selected = table.concat(arg, "\n")



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


local align = io.popen("align_image_stack -C -a " ..prefix .. " " .. table.concat(files, " "),"r")
local result = align:read("*all")
align:close()
notification("Images aligned")
-- remove temp file created by os.tmpname()
os.remove(prefix)

-- find the generated aligned files
local image_files = find_files(prefix, #files)

if #image_files == 0 then
  notification("Cannot find aligned files, exiting")
  os.exit()
end

-- blend images using various methods
local base_file = files[1]
-- luminance seems to work best
-- local output = make_output_name(base_file, "-blend.jpg")
-- enfuse(image_files, {}, output)
-- enfuse(image_files, {hard_mask=""}, make_output_name(base_file, "-soft.jpg"))
enfuse(image_files, {gray_projector="luminance"}, make_output_name(base_file, "-luminance.jpg"))


-- remove temporary files
for _, file in ipairs(image_files) do
  os.remove(file)
end
