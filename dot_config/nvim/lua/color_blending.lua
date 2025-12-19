local M = {}

---@class RGB
---@field r number A number between 0 and 255
---@field g number A number between 0 and 255
---@field b number A number between 0 and 255

---@alias HexColor string Hex color code, eg #abc123
---@alias Alpha number Number between 0 and 1

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
  -- stylua: ignore
  if hex == "NONE" then return hex end

  local rgb = hex_to_rgb(hex)
  local max = math.max(rgb.r, rgb.g, rgb.b)
  rgb.r = rgb.r + amt * (rgb.r / max)
  rgb.g = rgb.g + amt * (rgb.g / max)
  rgb.b = rgb.b + amt * (rgb.b / max)
  rgb.r = (rgb.r < 0) and 0 or (rgb.r > 255) and 255 or rgb.r
  rgb.g = (rgb.g < 0) and 0 or (rgb.g > 255) and 255 or rgb.g
  rgb.b = (rgb.b < 0) and 0 or (rgb.b > 255) and 255 or rgb.b
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

return M
