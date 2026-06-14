local M = {}

local current_file = debug.getinfo(1, "S").source:gsub("^@", "")
local current_dir = vim.fs.dirname(current_file)
local assets_dir = current_dir.."/../../assets"

---@class NvimStatusCatConfig
---@field foreground_width number Width of the foreground image
---@field height number Height of the progress bar and background images
---@field min_window_width number If the window width is less than this, don't create images there
---@field position number Number between 0 and 1. 0 being the left of the statusline and 1 the right
---@field background_img_path string Path to the image that will be used as the background
---@field progress_img_path string Path to the image that will be used as the progress bar
---@field foreground_img_path string Path to the image that will be used as the foreground
---@field width number Width of the images.
local default_config = {
	foreground_width = 4,
	width = 2,
	height = 1,

	min_window_width = 80,

	position = 0.5,

	background_img_path = assets_dir.."/outerspace.png",
	progress_img_path = assets_dir.."/rainbow.png",
	foreground_img_path = assets_dir.."/nyan.png",
}

---@param opts? NvimStatusCatConfig
function M.setup(opts)
	opts = vim.tbl_deep_extend("force", default_config, opts or {})

	require("nvim-statuscat.render").start_rendering(opts)
end

return M
