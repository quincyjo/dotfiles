local p = require("themes.qubit.palette")

local M = {}

---@alias HexColor string
---@alias Alpha number 0-1

---@alias RGB {
---    r: number,
---    g: number,
---    b: number,
---}

---@param hex HexColor
---@return RGB
function M.hex_to_rgb(hex)
	if hex == nil then
		return { r = 0, g = 0, b = 0 }
	end
	return {
		r = tonumber(hex:sub(2, 3), 16),
		g = tonumber(hex:sub(4, 5), 16),
		b = tonumber(hex:sub(6, 7), 16),
	}
end

--- Convert an RGB color to a hex color string.
---@param rgb RGB
---@return HexColor
function M.rgb_to_hex(rgb)
	-- Note that if awesome is not built against luajit, then this will error
	-- out. It can be fixed by adding a floor or ceil to the values before
	-- formatting the string.
	return string.format("#%02x%02x%02x", rgb.r, rgb.g, rgb.b)
end

--- Lighten a color. If amt is 1 or less, then it will be treated as a
--- percentage. Otherwise, it will be treated as an absolute amount and added to
--- each channel weighted to perserve hue.
---@param hex HexColor
---@param amt number
---@return HexColor
function M.lighten(hex, amt)
	local rgb = M.hex_to_rgb(hex)
	if amt <= 1 then
		-- percentage
		local ratio = 1 + amt
		rgb.r = rgb.r * ratio
		rgb.g = rgb.g * ratio
		rgb.b = rgb.b * ratio
	else
		-- ratiod absolute
		local max = math.max(rgb.r, rgb.g, rgb.b)
		rgb.r = rgb.r + amt * (rgb.r / max)
		rgb.g = rgb.g + amt * (rgb.g / max)
		rgb.b = rgb.b + amt * (rgb.b / max)
	end
	rgb.r = (rgb.r < 0) and 0 or (rgb.r > 255) and 255 or rgb.r
	rgb.g = (rgb.g < 0) and 0 or (rgb.g > 255) and 255 or rgb.g
	rgb.b = (rgb.b < 0) and 0 or (rgb.b > 255) and 255 or rgb.b
	return M.rgb_to_hex(rgb)
end

---@param rgb RGB
---@param alpha Alpha
---@param background HexColor
---@return HexColor
function M.rgba(rgb, alpha, background)
	local bg_rgb = M.hex_to_rgb(background)
	return M.rgb_to_hex({
		r = (1 - alpha) * bg_rgb.r + alpha * rgb.r,
		g = (1 - alpha) * bg_rgb.g + alpha * rgb.g,
		b = (1 - alpha) * bg_rgb.b + alpha * rgb.b,
	})
end

---@param hex HexColor
---@param alpha Alpha
---@param base? HexColor
---@return HexColor
function M.blend(hex, alpha, base)
	local rgb = M.hex_to_rgb(hex)
	return M.rgba(rgb, alpha, base or p.bg)
end

--- Cache of WCAG relative luminance of palette colors.
local palette_relative_luminance = {}

--- Compute WCAG relative luminance of a hex color.
---@param hex HexColor
---@return number
local function relative_luminance(hex)
	if palette_relative_luminance[hex] then
		return palette_relative_luminance[hex]
	end
	local rgb = M.hex_to_rgb(hex)
	local function linearize(c)
		c = c / 255
		if c <= 0.04045 then
			return c / 12.92
		else
			return ((c + 0.055) / 1.055) ^ 2.4
		end
	end
	return 0.2126 * linearize(rgb.r) + 0.7152 * linearize(rgb.g) + 0.0722 * linearize(rgb.b)
end

for _, hex in pairs(p) do
	palette_relative_luminance[hex] = relative_luminance(hex)
end

--- Return whichever of two colors has higher WCAG contrast against bg.
---@param bg HexColor
---@param a HexColor
---@param b HexColor
---@return HexColor
local function higher_contrast(bg, a, b)
	local l_bg = relative_luminance(bg)
	local function contrast(hex)
		local l = relative_luminance(hex)
		local lighter = math.max(l_bg, l)
		local darker = math.min(l_bg, l)
		return (lighter + 0.05) / (darker + 0.05)
	end
	return contrast(a) >= contrast(b) and a or b
end

--- Return the palette's primary fg color relative to bg.
---@param bg HexColor
---@return HexColor
function M.fg_for(bg)
	return higher_contrast(bg, p.fg, p.black)
end

--- Return the palette's secondary fg color relative to bg.
---@param bg HexColor
---@return HexColor
function M.fg_2_for(bg)
	return higher_contrast(bg, p.fg_2, p.bg_2)
end

return M
