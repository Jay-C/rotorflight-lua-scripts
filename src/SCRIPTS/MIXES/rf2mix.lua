
local CRSF_FRAME_CUSTOM_TELEM   = 0x88


local function decU8(data, pos)
    return data[pos], pos+1
end

local function decS8(data, pos)
  local val,pos = decU8(data,pos)
  return val < 0x80 and val or val - 0x100, pos
end

local function decU16(data, pos)
    return bit32.lshift(data[pos],8) + data[pos+1], pos+2
end

local function decS16(data, pos)
  local val,pos = decU16(data,pos)
  return val < 0x8000 and val or val - 0x10000, pos
end

local function decU24(data, pos)
    return bit32.lshift(data[pos],16) + bit32.lshift(data[pos+1],8) + data[pos+2], pos+3
end

local function decS24(data, pos)
  local val,pos = decU24(data,pos)
  return val < 0x800000 and val or val - 0x1000000, pos
end

local function decU32(data, pos)
    return bit32.lshift(data[pos],24) + bit32.lshift(data[pos+1],16) + bit32.lshift(data[pos+2],8) + data[pos+3], pos+4
end

local function decS32(data, pos)
  local val,pos = decU32(data,pos)
  return val < 0x80000000 and val or val - 0x100000000, pos
end

local RFSensors = {
    [0x0001]  = { name="Modl",       unit=UNIT_RAW,                 prec=0,    dec=decU8   },
    [0x0011]  = { name="Vbat",       unit=UNIT_VOLTS,               prec=2,    dec=decU16  },
    [0x0012]  = { name="Curr",       unit=UNIT_AMPS,                prec=2,    dec=decU16  },
    [0x0013]  = { name="Capa",       unit=UNIT_MAH,                 prec=3,    dec=decU16  },
    [0x0014]  = { name="SOC ",       unit=UNIT_PERCENT,             prec=0,    dec=decU8   },
    [0x0015]  = { name="Tbat",       unit=UNIT_CELSIUS,             prec=0,    dec=decU8   },
    [0x0080]  = { name="Vesc",       unit=UNIT_VOLTS,               prec=2,    dec=decU16  },
    [0x0081]  = { name="Vbec",       unit=UNIT_VOLTS,               prec=2,    dec=decU16  },
    [0x0082]  = { name="Vbus",       unit=UNIT_VOLTS,               prec=2,    dec=decU16  },
    [0x0083]  = { name="Vmcu",       unit=UNIT_VOLTS,               prec=2,    dec=decU16  },
    [0x0090]  = { name="Iesc",       unit=UNIT_AMPS,                prec=2,    dec=decU16  },
    [0x0091]  = { name="Ibec",       unit=UNIT_AMPS,                prec=2,    dec=decU16  },
    [0x0092]  = { name="Ibus",       unit=UNIT_AMPS,                prec=2,    dec=decU16  },
    [0x0093]  = { name="Imcu",       unit=UNIT_AMPS,                prec=2,    dec=decU16  },
    [0x00A0]  = { name="Tesc",       unit=UNIT_CELSIUS,             prec=0,    dec=decU8   },
    [0x00A1]  = { name="Tbec",       unit=UNIT_CELSIUS,             prec=0,    dec=decU8   },
    [0x00A3]  = { name="Tcpu",       unit=UNIT_CELSIUS,             prec=0,    dec=decU8   },
    [0x00A4]  = { name="Tair",       unit=UNIT_CELSIUS,             prec=0,    dec=decU8   },
    [0x00A5]  = { name="Tmtr",       unit=UNIT_CELSIUS,             prec=0,    dec=decU8   },
    [0x00B1]  = { name="Alt ",       unit=UNIT_METERS,              prec=2,    dec=decS24  },
    [0x00B2]  = { name="Var ",       unit=UNIT_METERS,              prec=2,    dec=decS16  },
    [0x00C0]  = { name="Hspd",       unit=UNIT_RPMS,                prec=0,    dec=decU16  },
    [0x00C1]  = { name="Tspd",       unit=UNIT_RPMS,                prec=0,    dec=decU16  },
    [0x0101]  = { name="Ptch",       unit=UNIT_DEGREE,              prec=1,    dec=decU16  },
    [0x0102]  = { name="Roll",       unit=UNIT_DEGREE,              prec=1,    dec=decU16  },
    [0x0103]  = { name="Yaw ",       unit=UNIT_DEGREE,              prec=1,    dec=decU16  },
    [0x0111]  = { name="AccX",       unit=UNIT_G,                   prec=1,    dec=decS16  },
    [0x0112]  = { name="AccY",       unit=UNIT_G,                   prec=1,    dec=decS16  },
    [0x0113]  = { name="AccZ",       unit=UNIT_G,                   prec=1,    dec=decS16  },
    [0x0121]  = { name="SATS",       unit=UNIT_RAW,                 prec=0,    dec=decU8   },
    [0x0122]  = { name="Ghdg",       unit=UNIT_DEGREE,              prec=1,    dec=decS16  },
    [0x0123]  = { name="Galt",       unit=UNIT_METERS,              prec=1,    dec=decS16  },
    [0x0124]  = { name="Gdst",       unit=UNIT_METERS,              prec=1,    dec=decU16  },
    [0x0124]  = { name="Gdspd",      unit=UNIT_METERS_PER_SECOND,   prec=2,    dec=decU16  },
    [0x0141]  = { name="TIME",       unit=UNIT_RAW,                 prec=0,    dec=decU16  },
    [0x0142]  = { name="CPU%",       unit=UNIT_PERCENT,             prec=0,    dec=decU8   },
    [0x0143]  = { name="SYS%",       unit=UNIT_PERCENT,             prec=0,    dec=decU8   },
    [0x0144]  = { name="RT% ",       unit=UNIT_PERCENT,             prec=0,    dec=decU8   },
    [0x0200]  = { name="FM  ",       unit=UNIT_BITFIELD,            prec=0,    dec=decU32  },
    [0x0201]  = { name="ARM ",       unit=UNIT_BITFIELD,            prec=0,    dec=decU32  },
    [0x0202]  = { name="Resc",       unit=UNIT_RAW,                 prec=0,    dec=decU8   },
    [0x0203]  = { name="Gov ",       unit=UNIT_RAW,                 prec=0,    dec=decU8   },
}

local function crossfirePop()
    local command, data = crossfireTelemetryPop()
    if command ~= nil and data ~= nil then
        if command == CRSF_FRAME_CUSTOM_TELEM then
            local sid, val
            local ptr = 1
            while ptr <= #data - 2 do
                sid,ptr = decU16(data, ptr)
                local sensor = RFSensors[sid]
                if sensor then
                    val,ptr = sensor.dec(data, ptr)
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

local function background()
    pcall(crossfirePopAll)
end

return { run=background }
