local M = {}

--- Helper function to clamp a value between a min and max
---@param value number
---@param min_val number
---@param max_val number
---@return number
local function clamp(value, min_val, max_val)
    return math.max(min_val, math.min(max_val, value))
end

---@param hex HexColor
---@return RGB
local function hex_to_rgb(hex)
    if hex == nil then
        return { r = 0, g = 0, b = 0 }
    end
    return {
        r = tonumber(hex:sub(2, 3), 16),
        g = tonumber(hex:sub(4, 5), 16),
        b = tonumber(hex:sub(6, 7), 16),
    }
end

---@param rgb RGB
---@return HexColor
local function rgb_to_hex(rgb)
    return string.format('#%02x%02x%02x', rgb.r, rgb.g, rgb.b)
end

---@param hex HexColor | "NONE"
---@param amt number
---@return HexColor
function M.lighten(hex, amt)
    if hex == "NONE" then return hex end

    local rgb = hex_to_rgb(hex)
    local max = math.max(rgb.r, rgb.g, rgb.b)
    rgb.r = rgb.r + amt * (rgb.r / max)
    rgb.g = rgb.g + amt * (rgb.g / max)
    rgb.b = rgb.b + amt * (rgb.b / max)
    rgb.r = clamp(rgb.r, 0, 255)
    rgb.g = clamp(rgb.g, 0, 255)
    rgb.b = clamp(rgb.b, 0, 255)
    return rgb_to_hex(rgb)
end

---@param rgb RGB
---@param alpha Alpha
---@param background HexColor
---@return HexColor
function M.rgba(rgb, alpha, background)
    local bg_rgb = hex_to_rgb(background)
    return rgb_to_hex {
        r = (1 - alpha) * bg_rgb.r + alpha * rgb.r,
        g = (1 - alpha) * bg_rgb.g + alpha * rgb.g,
        b = (1 - alpha) * bg_rgb.b + alpha * rgb.b,
    }
end

---@param hex HexColor | "NONE"
---@param alpha Alpha
---@param base? HexColor
---@return HexColor
function M.blend(hex, alpha, base)
    -- stylua: ignore
    if hex == "NONE" then return "NONE" end

    local rgb = hex_to_rgb(hex)
    return M.rgba(rgb, alpha, base or '#000000')
end

--- Convert RGB to HSL.
---@param rgb RGB
---@return HSL
local function rgb_to_hsl(rgb)
    local r, g, b = rgb.r / 255, rgb.g / 255, rgb.b / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max ~= min then
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    return {
        h = h * 360,
        s = s,
        l = l,
    }
end

--- Convert HSL to RGB
---@param hsl HSL
---@return RGB
local function hsl_to_rgb(hsl)
    local h = hsl.h / 360 -- scale to 0-1
    local r, g, b
    if hsl.s == 0 then    -- achromatic
        r, g, b = hsl.l, hsl.l, hsl.l
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then return p + (q - p) * 6 * t end
            if t < 1 / 2 then return q end
            if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p
        end
        local q = hsl.l < 0.5 and hsl.l * (1 + hsl.s) or hsl.l + hsl.s - hsl.l * hsl.s
        local p = 2 * hsl.l - q
        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    end
    return {
        r = r * 255,
        g = g * 255,
        b = b * 255,
    }
end

--- Main function to adjust lightness and saturation of a hex color
---@param color HexColor
---@param lightness_adj? number 0 to 1
---@param saturation_adj? number 0 to 1
---@return HexColor
function M.adjust_hex_color_hsl(color, saturation_adj, lightness_adj)
    local rgb = hex_to_rgb(color)
    local hsl = rgb_to_hsl(rgb)

    hsl.s = clamp(hsl.s + (saturation_adj or 0), 0, 1)
    hsl.l = clamp(hsl.l + (lightness_adj or 0), 0, 1)

    rgb = hsl_to_rgb(hsl)
    return rgb_to_hex(rgb)
end

---@param palette Palette
---@return Colors
function M.colors_from_palette(palette)
    return {
        bg = palette.bg,
        bg_2 = palette.bg_2,
        bg_3 = palette.bg_3,
        fg = palette.fg,
        fg_2 = palette.fg_2,
        black = palette.black,
        pink = palette.pink,
        red = palette.red,
        green = palette.green,
        blue = palette.blue,
        yellow = palette.yellow,
        purple = palette.purple,
        orange = palette.orange,
        cyan = palette.cyan,
        white = palette.white,
        bright_pink = M.lighten(palette.pink, 40),
        bright_red = M.lighten(palette.red, 40),
        bright_green = M.lighten(palette.green, 40),
        bright_yellow = M.lighten(palette.yellow, 40),
        bright_blue = M.lighten(palette.blue, 40),
        bright_cyan = M.lighten(palette.cyan, 40),
        bright_purple = M.lighten(palette.purple, 40),
        bright_white = M.lighten(palette.white, 40),
        comment = M.blend(palette.purple, 0.7, palette.bg),
        fuchsia = M.blend(palette.red, 0.8, palette.pink),
        grey = M.blend(palette.fg, 0.7, palette.bg),
        lavender = M.blend(palette.purple, 0.5, palette.blue),
        lilac = M.blend(palette.purple, 0.5, palette.bg),
        transparent_red = M.blend(palette.red, 0.05, palette.bg),
        transparent_green = M.blend(palette.green, 0.05, palette.bg),
        transparent_yellow = M.blend(palette.yellow, 0.05, palette.bg),
        transparent_blue = M.blend(palette.blue, 0.05, palette.bg),
    }
end

return M
