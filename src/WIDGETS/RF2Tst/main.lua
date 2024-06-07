
local options = {}

local CRSF_FRAME_CUSTOM_TELEM   = 0x88

local units = {
  [UNIT_RAW]    = "",
  [UNIT_VOLTS]  = "V",
  [UNIT_AMPS]   = "A",
  [UNIT_KTS]    = "Kts",
  [UNIT_KMH]    = "Kph",
  [UNIT_METERS] = "m",
  [UNIT_RPMS]   = "rpm",
  [UNIT_DEGREE] = "deg",
}


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


local RFSensors = {
  [0x00A3]  = { name="Tcpu",       unit=UNIT_CELSIUS,             prec=0,  length=1,  dec=decU8, value=0, count=0 },
  [0x0142]  = { name="CPU%",       unit=UNIT_PERCENT,             prec=0,  length=1,  dec=decU8, value=0, count=0 },
  [0x0143]  = { name="SYS%",       unit=UNIT_PERCENT,             prec=0,  length=1,  dec=decU8, value=0, count=0 },
  [0x0144]  = { name="RT% ",       unit=UNIT_PERCENT,             prec=0,  length=1,  dec=decU8, value=0, count=0 },
}

local total_frames = 0
local total_loops = 0
local total_sensors = 0
local last_id = 0

local function crossfirePop()
    local command, data = crossfireTelemetryPop()
    if command ~= nil and data ~= nil then
        if command == CRSF_FRAME_CUSTOM_TELEM then
            total_frames = total_frames + 1
            local sid = 0
            local ptr = 1
            local val = 0
            while ptr <= #data - 2 do
                total_loops = total_loops + 1
                sid,ptr = decU16(data, ptr)
                local sensor = RFSensors[sid]
                last_id = sid
        		    if sensor then
                    total_sensors = total_sensors + 1
                    val,ptr = sensor.dec(data, ptr)
                    sensor.value = val
                    sensor.count = sensor.count + 1
                    setTelemetryValue(sid, 0, 0, val, sensor.unit, sensor.prec, sensor.name)
                else
                    break
                end
            end
        end
        return true
    end
    return false
end

local function crossfirePopAll()
    while crossfirePop() do end
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
  local success = pcall(crossfirePopAll)
end

local function refresh(wgt)
  background(wgt)

  local x =  wgt.zone.x
  local y =  wgt.zone.y

  local txt = string.format("Total %d : %d : %d", total_frames, total_loops, total_sensors)
  lcd.drawText(x, y, txt, 0)
  y = y + 16

  local txt = string.format("Last ID: %d", last_id)
  lcd.drawText(x, y, txt, 0)
  y = y + 16

  for i,s in pairs(RFSensors) do
    local txt = string.format("%04X: [%d]  %s = %s", i, s.count, s.name, s.value)
    lcd.drawText(x, y, txt, 0)
    y = y + 16
  end
end


return { name="RF2Tst", options=options, create=create, update=update, refresh=refresh, background=background }
