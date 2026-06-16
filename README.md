# Statuscat
Uses the experimental image api (vim.ui.img) to draw a buffer progress bar with images.
By default, it comes with nyan cat assets, taken from nyan-mode for Emacs.

This is ***hacky*** and ***experimental***, don't expect stuff to work very well. For example, it flickers a bit and will render above any text that you have in the statusline.

# Usage
**Requires Neovim >= 0.13 (vim.ui.img support) and a terminal that supports Kitty's graphics protocol**

Download the plugin using your package manager and call setup with your preferred options:
```lua
require("nvim-statuscat").setup(opts)
```


```lua
---@class NvimStatusCatConfig
---@field foreground_width integer Width of the foreground image.
---@field width integer Width of the progress bar and background images.
---@field height integer Height of the images.
---@field min_window_width integer If the window width is less than this, don't render there.
---@field position number Number between 0 and 1. 0 being the left of the statusline and 1 the right.
---@field background_img_path string Path to the image that will be used as the background.
---@field progress_img_path string Path to the image that will be used as the progress bar.
---@field foreground_img_path string[] Path to the image(s) that will be used as the foreground.
---@field fps integer? Frames per second if you have an animated foreground. Irrelevant otherwise.
local default_config = {
	foreground_width = 4,
	width = 2,
	height = 1,

	min_window_width = 80,

	position = 0.5,

	background_img_path = assets_dir.."/outerspace.png",
	progress_img_path = assets_dir.."/rainbow.png",
	foreground_img_path = {
		--assets_dir.."/nyan.png",
		assets_dir.."/nyan1.png",
		assets_dir.."/nyan2.png",
		assets_dir.."/nyan3.png",
		assets_dir.."/nyan4.png",
		assets_dir.."/nyan5.png",
		assets_dir.."/nyan6.png",
	},

	fps = 12,
}
```

# See also
[nyan-mode](https://github.com/TeMPOraL/nyan-mode) for the original idea and the nyan cat assets
