-- =====================================================================
--  CSV loader for historical M1 candles, with provenance.
--
--  load(path, opts) -> candles, info
--    Header row required. Columns (case-insensitive):
--      time | timestamp | datetime | date [+ time]   and   open, high, low, close
--    Time formats: unix seconds, unix milliseconds, "YYYY-MM-DD HH:MM[:SS]",
--    "YYYY.MM.DD HH:MM[:SS]", ISO "YYYY-MM-DDTHH:MM[:SS][Z]", or separate
--    date + time columns. Times are taken as UTC unless opts.tz_offset_min
--    is given (minutes EAST of UTC that the file uses, e.g. 120 for UTC+2).
--    Rows that cannot be parsed are COUNTED and reported (info.bad_rows),
--    never repaired. Order is not changed: info.order_errors lists the
--    first non-increasing timestamps (the backtester refuses such files).
--    info.fnv1a = 32-bit FNV-1a checksum of the raw file bytes (provenance).
-- =====================================================================
local M = {}

local function days_from_civil (y, m, d)       -- proleptic Gregorian -> days since 1970-01-01
    y = (m <= 2) and (y - 1) or y
    local era = (y >= 0 and y or y - 399) // 400
    local yoe = y - era * 400
    local mp = (m + 9) % 12
    local doy = (153 * mp + 2) // 5 + d - 1
    local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return era * 146097 + doe - 719468
end
M.days_from_civil = days_from_civil

function M.parse_time (s, s2)
    if s == nil then return nil end
    s = s:gsub ("^%s+", ""):gsub ("%s+$", "")
    if s2 and s2 ~= "" then s = s .. " " .. s2:gsub ("^%s+", "") end
    local n = tonumber (s)
    if n then
        if n > 1e12 then n = n / 1000 end
        return math.floor (n)
    end
    local y, mo, d, rest = s:match ("^(%d%d%d%d)[%-%.](%d%d)[%-%.](%d%d)[ T]?(.*)$")
    if not y then return nil end
    local hh, mm, ss = rest:match ("^(%d%d):(%d%d):?(%d*)")
    if rest ~= "" and not hh then return nil end
    local t = days_from_civil (tonumber (y), tonumber (mo), tonumber (d)) * 86400
    if hh then t = t + tonumber (hh) * 3600 + tonumber (mm) * 60 + (tonumber (ss) or 0) end
    return math.floor (t)
end

local function fnv1a (s)
    local h = 2166136261
    for i = 1, #s do
        h = h ~ s:byte (i)
        h = (h * 16777619) & 0xffffffff
    end
    return string.format ("%08x", h)
end
M.fnv1a = fnv1a

local function split (line, sep)
    local cols = {}
    for c in (line .. sep):gmatch ("([^" .. sep .. "]*)" .. sep) do
        cols[#cols + 1] = c:gsub ('^%s*"?', ""):gsub ('"?%s*$', "")
    end
    return cols
end

function M.load (path, opts)
    opts = opts or {}
    local fh = assert (io.open (path, "rb"), "cannot open " .. tostring (path))
    local raw = fh:read ("a"); fh:close ()
    local info = { path = path, bytes = #raw, fnv1a = fnv1a (raw), rows = 0, bad_rows = 0, order_errors = {},
                   tz_offset_min = opts.tz_offset_min or 0 }
    local out, idx, sep = {}, nil, nil
    for line in raw:gmatch ("[^\r\n]+") do
        if not idx then
            sep = (line:find (";") and not line:find (",")) and ";" or ((line:find ("\t") and not line:find (",")) and "\t" or ",")
            local h = {}
            for i, c in ipairs (split (line, sep)) do h[c:lower ():gsub ("[<>]", "")] = i end
            idx = { o = h.open, h = h.high, l = h.low, c = h.close,
                    t = h.timestamp or h.datetime or h.time or h.date, t2 = (h.date and h.time) and h.time or nil }
            if h.date and h.time then idx.t = h.date end
            assert (idx.o and idx.h and idx.l and idx.c and idx.t, "CSV header must name time and open/high/low/close columns")
        else
            info.rows = info.rows + 1
            local c = split (line, sep)
            local t = M.parse_time (c[idx.t], idx.t2 and c[idx.t2] or nil)
            local o, h, l, cl = tonumber (c[idx.o]), tonumber (c[idx.h]), tonumber (c[idx.l]), tonumber (c[idx.c])
            if t and o and h and l and cl then
                t = t - info.tz_offset_min * 60
                local prev = out[#out]
                if prev and t <= prev.t and #info.order_errors < 5 then info.order_errors[#info.order_errors + 1] = info.rows end
                out[#out + 1] = { t = t, o = o, h = h, l = l, c = cl }
            else
                info.bad_rows = info.bad_rows + 1
            end
        end
    end
    if #out > 0 then info.first_t, info.last_t = out[1].t, out[#out].t end
    return out, info
end

function M.iso (t)
    local days, sec = t // 86400, t % 86400
    -- civil from days (inverse of days_from_civil)
    local z = days + 719468
    local era = (z >= 0 and z or z - 146096) // 146097
    local doe = z - era * 146097
    local yoe = (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365
    local y = yoe + era * 400
    local doy = doe - (365 * yoe + yoe // 4 - yoe // 100)
    local mp = (5 * doy + 2) // 153
    local d = doy - (153 * mp + 2) // 5 + 1
    local m = mp < 10 and mp + 3 or mp - 9
    if m <= 2 then y = y + 1 end
    return string.format ("%04d-%02d-%02d %02d:%02d:%02dZ", y, m, d, sec // 3600, sec % 3600 // 60, sec % 60)
end

return M
