-- =====================================================================
--  Minimal mock of the Quadcode Script runtime, for offline testing only.
--  It reproduces the documented execution model: the script runs once per
--  bar, `x[n]` reads n bars back, stateful built-ins (ema, rsi, sma, ...)
--  keep their own history per call site, and the last bar can be
--  re-evaluated several times (live ticks) without corrupting state.
--  Formulas follow the official quadcodescript-library where available.
-- =====================================================================
local M = {}

local NaN = 0 / 0
local function bad (x) return x == nil or x ~= x end

function M.new (bars)
    local E = { T = 0, plots = {}, shapes = {}, prints = {} }
    local env = setmetatable ({}, { __index = _G })
    E.env = env
    local state, line_count = {}, {}

    -- ------------------------------ series ------------------------------
    local S = {}
    local function is_series (x) return type (x) == "table" and getmetatable (x) == S end
    local function mk (getter) return setmetatable ({ get = getter }, S) end
    local function val (x, t)
        if is_series (x) then return x.get (t) end
        if type (x) == "boolean" then return x and 1 or 0 end
        return x
    end
    E.val = val

    S.__index = function (s, k)
        if type (k) == "number" then
            return mk (function (t)
                local tt = t - k
                if tt < 1 then return nil end
                return s.get (tt)
            end)
        end
        return rawget (S, k)
    end
    local function bin (op)
        return function (a, b)
            return mk (function (t)
                local x, y = val (a, t), val (b, t)
                if bad (x) or bad (y) then return nil end
                return op (x, y)
            end)
        end
    end
    S.__add = bin (function (x, y) return x + y end)
    S.__sub = bin (function (x, y) return x - y end)
    S.__mul = bin (function (x, y) return x * y end)
    S.__div = bin (function (x, y) return x / y end)
    S.__pow = bin (function (x, y) return x ^ y end)
    S.__unm = function (a) return mk (function (t) local x = val (a, t); if bad (x) then return nil end return -x end) end
    local function cmp (op)
        return function (a, b)
            local x, y = val (a, E.T), val (b, E.T)
            if bad (x) or bad (y) then return false end
            return op (x, y)
        end
    end
    S.__lt = cmp (function (x, y) return x < y end)
    S.__le = cmp (function (x, y) return x <= y end)
    S.__call = function (s) return s.get (E.T) end
    function S.set (s, v) s.arr[E.T] = val (v, E.T) end

    -- call-site keyed state (stable across bars, re-entrant per bar)
    local function site ()
        local lvl = 3
        while true do
            local info = debug.getinfo (lvl, "Sl")
            if info == nil then error ("call site not found") end
            if info.source == "=script" then
                local ln = info.currentline
                line_count[ln] = (line_count[ln] or 0) + 1
                local key = ln .. "#" .. line_count[ln]
                state[key] = state[key] or { arr = {} }
                return state[key]
            end
            lvl = lvl + 1
        end
    end
    local function arr_series (st) return mk (function (t) return st.arr[t] end) end

    -- --------------------------- price series ---------------------------
    local function price (f) return mk (function (t) local b = bars[t]; return b and b[f] end) end
    env.open, env.high, env.low, env.close = price ("o"), price ("h"), price ("l"), price ("c")
    env.hl2 = (env.high + env.low) / 2
    env.tr = mk (function (t)
        local b = bars[t]; if not b then return nil end
        local p = bars[t - 1]
        if not p then return b.h - b.l end
        return math.max (b.h - b.l, math.abs (b.h - p.c), math.abs (b.l - p.c))
    end)

    -- ------------------------- stateful built-ins -----------------------
    local function window (src, n, t)
        local out = {}
        for i = 0, n - 1 do
            local x = val (src, t - i)
            if t - i < 1 or bad (x) then return nil end
            out[#out + 1] = x
        end
        return out
    end
    env.sma = function (src, n)
        local st = site (); local T = E.T
        local w = window (src, n, T)
        if w then local s = 0; for _, x in ipairs (w) do s = s + x end; st.arr[T] = s / n else st.arr[T] = nil end
        return arr_series (st)
    end
    env.stdev = function (src, n)
        local st = site (); local T = E.T
        local w = window (src, n, T)
        if w then
            local m = 0; for _, x in ipairs (w) do m = m + x end; m = m / n
            local v = 0; for _, x in ipairs (w) do v = v + (x - m) ^ 2 end
            st.arr[T] = math.sqrt (v / n)
        else st.arr[T] = nil end
        return arr_series (st)
    end
    local function smooth (st, x, alpha)
        local T = E.T
        local prev = st.arr[T - 1]
        if bad (x) then st.arr[T] = prev
        elseif bad (prev) then st.arr[T] = x
        else st.arr[T] = prev + alpha * (x - prev) end
    end
    env.ema = function (src, n) local st = site (); smooth (st, val (src, E.T), 2 / (n + 1)); return arr_series (st) end
    env.rma = function (src, n) local st = site (); smooth (st, val (src, E.T), 1 / n); return arr_series (st) end
    env.rsi = function (src, n)
        local st = site (); local T = E.T
        st.up = st.up or {}; st.dn = st.dn or {}
        local x, p = val (src, T), val (src, T - 1)
        local d = (bad (x) or bad (p)) and 0 or (x - p)
        local function sm (a, v) local pr = a[T - 1]; a[T] = bad (pr) and v or (pr + (v - pr) / n) end
        sm (st.up, math.max (d, 0)); sm (st.dn, math.max (-d, 0))
        local u, w = st.up[T], st.dn[T]
        if w == 0 then st.arr[T] = (u == 0) and 50 or 100 else st.arr[T] = 100 - 100 / (1 + u / w) end
        return arr_series (st)
    end
    local function extreme (pick)
        return function (src, n)
            local st = site (); local T = E.T
            local w = window (src, n, T)
            if w then local m = w[1]; for _, x in ipairs (w) do m = pick (m, x) end; st.arr[T] = m else st.arr[T] = nil end
            return arr_series (st)
        end
    end
    env.highest = extreme (math.max)
    env.lowest  = extreme (math.min)
    env.value_when = function (cond, src, occ)
        local st = site (); local T = E.T
        st.hits = st.hits or {}
        while #st.hits > 0 and st.hits[#st.hits].t >= T do table.remove (st.hits) end -- re-entrant
        local c = val (cond, T)
        if c and c ~= 0 then st.hits[#st.hits + 1] = { t = T, v = val (src, T) } end
        local h = st.hits[#st.hits - occ]
        st.arr[T] = h and h.v or nil
        return arr_series (st)
    end
    env.make_series = function () local st = site (); local s = arr_series (st); rawset (s, "arr", st.arr); return s end

    -- ------------------------- stateless helpers -------------------------
    local function lift (f)
        return function (...)
            local args = { ... }
            for _, a in ipairs (args) do
                if is_series (a) then
                    return mk (function (t)
                        local vs = {}
                        for i, b in ipairs (args) do vs[i] = val (b, t); if bad (vs[i]) then return nil end end
                        return f (table.unpack (vs))
                    end)
                end
            end
            return f (...)
        end
    end
    env.max, env.min, env.abs = lift (math.max), lift (math.min), lift (math.abs)
    env.get_value = function (x, d)
        local v = val (x, E.T)
        if v == nil then return d end
        return v
    end
    env.nz = function (x, d) local v = val (x, E.T); if bad (v) then return d or 0 end return v end
    env.na = function (x) return bad (val (x, E.T)) end
    env.print = function (...) E.prints[#E.prints + 1] = table.concat ({ ... }, " ") end

    -- ---------------------------- inputs / ui ----------------------------
    local any = setmetatable ({}, { __index = function (_, k) return k end })
    env.input = setmetatable ({}, {
        __index = function (_, k) return "input." .. k end,
        __call = function (_, a, ...) if type (a) == "table" then return a.default end return a end
    })
    env.input_group = function (t) for k, v in pairs (t) do if type (k) == "string" then env[k] = v end end end
    env.instrument = function (t) E.instrument = t end
    env.shape_style, env.shape_size, env.shape_location = any, any, any
    env.style, env.na_mode, env.color = any, any, any
    env.rgba = function (r, g, b, a) return string.format ("rgba(%d,%d,%d,%s)", r, g, b, a) end
    local function rec (name, v)
        E.plots[name] = E.plots[name] or {}
        E.plots[name][E.T] = v
    end
    env.plot = function (s, name) rec (name or "plot", val (s, E.T)) end
    env.hline = function () end
    env.fill, env.fill_area = function () end, function () end
    env.rect = function (t) rec ("rect", val (t.second, E.T)); E.rect_color = E.rect_color or {}; E.rect_color[E.T] = t.color end
    env.plot_shape = function (cond, name, st, sz, col, loc, off, text)
        local c = val (cond, E.T)
        E.shapes[name] = E.shapes[name] or {}
        E.shapes[name][E.T] = (c and c ~= 0) and { offset = off or 0, text = text } or nil
    end

    function E.load (src)
        local chunk, err = load (src, "=script", "t", env)
        if not chunk then error (err) end
        E.chunk = chunk
    end
    function E.run_bar (T)
        E.T = T
        line_count = {}
        E.chunk ()
    end
    return E
end

return M
