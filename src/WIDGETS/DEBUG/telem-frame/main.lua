
local options = {}

local CRSF_FRAME_CUSTOM_TELEM   = 0x88


local function decU8(data, pos)
  return data[pos], pos+1
end

local function decS8(data, pos)
  local val,ptr = decU8(data,pos)
  return val < 0x80 and val or val - 0x100, ptr
end

local function decU16(data, pos)
  return bit32.lshift(data[pos],8) + data[pos+1], pos+2
end

local function decS16(data, pos)
  local val,ptr = decU16(data,pos)
  return val < 0x8000 and val or val - 0x10000, ptr
end

local function decU24(data, pos)
  return bit32.lshift(data[pos],16) + bit32.lshift(data[pos+1],8) + data[pos+2], pos+3
end

local function decS24(data, pos)
  local val,ptr = decU24(data,pos)
  return val < 0x800000 and val or val - 0x1000000, ptr
end

local function decU32(data, pos)
  return bit32.lshift(data[pos],24) + bit32.lshift(data[pos+1],16) + bit32.lshift(data[pos+2],8) + data[pos+3], pos+4
end

local function decS32(data, pos)
  local val,ptr = decU32(data,pos)
  return val < 0x80000000 and val or val - 0x100000000, ptr
end


local data_frame = nil
local total_frames = 0

local function crossfirePop()
    local command, data = crossfireTelemetryPop()
    if command ~= nil and data ~= nil then
        if command == CRSF_FRAME_CUSTOM_TELEM then
            data_frame = data
            total_frames = total_frames + 1
        end
    end
end


local function create(zone, options)
  local wgt = { zone=zone, options=options }
  offsetX = (wgt.zone.w - 178) / 2
  offsetY = (wgt.zone.h - 148) / 2
  return wgt
end

local function update(wgt, options)
  wgt.options = options
end

local function background(wgt)
  local success = pcall(crossfirePop)
end

local function refresh(wgt)
  background(wgt)

  local x =  wgt.zone.x
  local y =  wgt.zone.y

  local txt = string.format("Total %d", total_frames)
  lcd.drawText(x, y, txt, 0)
  y = y + 16

  if data_frame then
      local xx = x
      local txt = string.format("Data:")
      lcd.drawText(xx, y, txt, 0)
      xx = xx + 45
      for i = 1, #data_frame do
          local str = string.format("%02X", data_frame[i])
          lcd.drawText(xx, y, str, 0)
          xx = xx + 25
      end
  end

end


return { name="DEBUG", options=options, create=create, update=update, refresh=refresh, background=background }
