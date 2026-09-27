local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    setting = setting or {}
    local x1 = setting.x1
    local y1 = setting.y1
    local x2 = setting.x2
    local y2 = setting.y2
    local thickness = setting.thickness or 1
    local color = setting.color or {255, 255, 255, 255} -- r,g,b,a

    --sluit laatste punt aan op eerste (closed) en type van die laatste koppeling

    -- true when a position was explicitly provided via settings or set_points
    local has_explicit_points = (x1 ~= nil) or (y1 ~= nil) or (x2 ~= nil) or (y2 ~= nil)

    -- normalize defaults to 0 if not provided (storage vars)
    x1 = x1 or 0
    y1 = y1 or 0
    x2 = x2 or 0
    y2 = y2 or 0

    local segs = {}

    local function make_seg()
        local p= images_prim.new()
    
        -- fallback: wrap a raw windower.prim
        -- if not p then
        --     local name = "actor_line_prim_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e6))
        --     if windower and windower.prim and windower.prim.create then
        --         pcall(function() windower.prim.create(name) end)
        --     end

        --     p = {
        --         _name = name,
        --         set_pos = function(self, x, y)
        --             if windower and windower.prim and windower.prim.set_position then
        --                 windower.prim.set_position(self._name, x, y)
        --             end
        --         end,
        --         set_size = function(self, w, h)
        --             if windower and windower.prim and windower.prim.set_size then
        --                 windower.prim.set_size(self._name, w, h)
        --             end
        --         end,
        --         set_fit = function(self, v)
        --             if windower and windower.prim and windower.prim.set_fit_to_texture then
        --                 windower.prim.set_fit_to_texture(self._name, v)
        --             end
        --         end,
        --         set_color = function(self, r, g, b, a)
        --             if windower and windower.prim and windower.prim.set_color then
        --                 pcall(function() windower.prim.set_color(self._name, a, r, g, b) end)
        --                 pcall(function() windower.prim.set_color(self._name, r, g, b, a) end)
        --             end
        --         end,
        --         show = function(self)
        --             if windower and windower.prim and windower.prim.set_visibility then
        --                 windower.prim.set_visibility(self._name, true)
        --             end
        --         end,
        --         hide = function(self)
        --             if windower and windower.prim and windower.prim.set_visibility then
        --                 windower.prim.set_visibility(self._name, false)
        --             end
        --         end,
        --         destroy = function(self)
        --             if windower and windower.prim and windower.prim.delete then
        --                 windower.prim.delete(self._name)
        --             end
        --         end,
        --     }
        -- end

        if p.set_size then p:set_size(thickness, thickness) end
        if p.set_fit  then p:set_fit(false) end
        if p.set_color then p:set_color(color[1], color[2], color[3], color[4]) end
        -- if p.show then p:show() end




        return p
    end

    local line_obj, id = ui_base:new({
        type     = 'line',
        base_x   = math.min(x1, x2),
        base_y   = math.min(y1, y2),
        width    = math.abs(x2 - x1) + thickness,
        height   = math.abs(y2 - y1) + thickness,
        visible  = true,
        thickness = thickness,
        _segs = segs,
        _closed = setting.closed or false,
        closed_segment_type = setting.closed_segment_type or 'line',
        samples = setting.samples or 64,
        name = setting.name or nil,
    })

    local function bresenham(ax, ay, bx, by)
        local pts = {}
        ax = math.floor(ax); ay = math.floor(ay)
        bx = math.floor(bx); by = math.floor(by)
        local dx = math.abs(bx - ax)
        local sx = ax < bx and 1 or -1
        local dy = -math.abs(by - ay)
        local sy = ay < by and 1 or -1
        local err = dx + dy
        while true do
            pts[#pts+1] = {x = ax, y = ay}
            if ax == bx and ay == by then break end
            local e2 = 2 * err
            if e2 >= dy then
                err = err + dy
                ax = ax + sx
            end
            if e2 <= dx then
                err = err + dx
                ay = ay + sy
            end
        end
        return pts
    end

    local function sample_curve(ctrl_pts, samples)
        samples = math.max(2, math.floor(samples or 32))
        local out = {}
        local function lerp(a, b, t) return (1 - t) * a + t * b end

        local n = #ctrl_pts
        if n == 0 then return out end
        if n == 1 then return { { x = ctrl_pts[1].x, y = ctrl_pts[1].y } } end

        -- keep existing exact-bezier handling for 2..4 to preserve previous behaviour
        if n == 2 then
            local a, b = ctrl_pts[1], ctrl_pts[2]
            for i = 0, samples do
                local t = i / samples
                out[#out+1] = { x = lerp(a.x, b.x, t), y = lerp(a.y, b.y, t) }
            end
            return out
        end

        if n == 3 then
            local p0, p1, p2 = ctrl_pts[1], ctrl_pts[2], ctrl_pts[3]
            for i = 0, samples do
                local t = i / samples; local u = 1 - t
                local x = u*u*p0.x + 2*u*t*p1.x + t*t*p2.x
                local y = u*u*p0.y + 2*u*t*p1.y + t*t*p2.y
                out[#out+1] = { x = x, y = y }
            end
            return out
        end

        if n == 4 then
            local p0, p1, p2, p3 = ctrl_pts[1], ctrl_pts[2], ctrl_pts[3], ctrl_pts[4]
            for i = 0, samples do
                local t = i / samples; local u = 1 - t
                local x = u*u*u*p0.x + 3*u*u*t*p1.x + 3*u*t*t*p2.x + t*t*t*p3.x
                local y = u*u*u*p0.y + 3*u*u*t*p1.y + 3*u*t*t*p2.y + t*t*t*p3.y
                out[#out+1] = { x = x, y = y }
            end
            return out
        end

        -- For 5+ points: Catmull-Rom spline (smooth through control points)
        -- choose per-segment samples so total is roughly 'samples'
        local total_segments = n - 1
        local seg_samples = math.max(2, math.floor(samples / total_segments))

        local closed = (ctrl_pts[1].x == ctrl_pts[n].x and ctrl_pts[1].y == ctrl_pts[n].y)
        for s = 1, total_segments do
            -- determine p0..p3 for this segment (p1 = ctrl_pts[s], p2 = ctrl_pts[s+1])
            local p1 = ctrl_pts[s]
            local p2 = ctrl_pts[s+1]
            local p0, p3

            if s == 1 then
                if closed then p0 = ctrl_pts[n-1] else p0 = p1 end
            else
                p0 = ctrl_pts[s-1]
            end

            if s == total_segments then
                if closed then p3 = ctrl_pts[2] else p3 = p2 end
            else
                p3 = ctrl_pts[s+2]
            end

            -- Catmull-Rom cubic coefficients (uniform parameterization)
            for i = 0, seg_samples - 1 do
                local t = i / seg_samples
                local t2 = t * t
                local t3 = t2 * t

                local ax = (-0.5*p0.x) + (1.5*p1.x) - (1.5*p2.x) + (0.5*p3.x)
                local bx = p0.x - (2.5*p1.x) + (2*p2.x) - (0.5*p3.x)
                local cx = (-0.5*p0.x) + (0.5*p2.x)
                local dx = p1.x

                local ay = (-0.5*p0.y) + (1.5*p1.y) - (1.5*p2.y) + (0.5*p3.y)
                local by = p0.y - (2.5*p1.y) + (2*p2.y) - (0.5*p3.y)
                local cy = (-0.5*p0.y) + (0.5*p2.y)
                local dy = p1.y

                local x = ax * t3 + bx * t2 + cx * t + dx
                local y = ay * t3 + by * t2 + cy * t + dy

                -- avoid duplicate of last point of previous segment
                if not (#out > 0 and math.abs(out[#out].x - x) < 1e-6 and math.abs(out[#out].y - y) < 1e-6) then
                    out[#out+1] = { x = x, y = y }
                end
            end
        end

        -- append final endpoint
        out[#out+1] = { x = ctrl_pts[n].x, y = ctrl_pts[n].y }

        return out
    end

    local function ensure_seg(i)
        if not segs[i] then
            segs[i] = make_seg()
            if line_obj.add_internal then
                line_obj:add_internal(segs[i])
            elseif line_obj._internal_add then
                line_obj:_internal_add(segs[i])
            end
        end
        return segs[i]
    end

    local function clear_extra_segs(n)
        for i = n + 1, #segs do
            if segs[i] then
                if segs[i].hide then segs[i]:hide() end
                if segs[i].destroy then segs[i]:destroy() end
                segs[i] = nil
            end
        end
    end

    -- update_prim: produce absolute samples, then place prims using coordinates RELATIVE to _x1,_y1
    local function update_prim(self)
        local pts_abs = {}

        -- 1) append per-segment straight/curve segments if configured
        if self._is_lines and self._lines_points_rel and #self._lines_points_rel >= 2 then
            local base_x0 = self._x1 or 0
            local base_y0 = self._y1 or 0
            local count = #self._lines_points_rel
            local iter_count = self._closed and count or (count - 1)

            if count >= 2 then
                for i = 1, iter_count do
                    local a_rel = self._lines_points_rel[i]
                    local next_i = i + 1
                    if next_i > count then next_i = 1 end
                    local b_rel = self._lines_points_rel[next_i]

                    local ax = (a_rel.x or 0) + base_x0
                    local ay = (a_rel.y or 0) + base_y0
                    local bx = (b_rel.x or 0) + base_x0
                    local by = (b_rel.y or 0) + base_y0

                    local seg_type = (self._lines_segment_types and self._lines_segment_types[i])
                                    or (self._closed and i == count and (self._closed_segment_type or 'line'))
                                    or 'line'

                    if seg_type == 'line' then
                        if ax == bx or ay == by then
                            if ax == bx then
                                local ys = math.floor(math.min(ay, by))
                                local ye = math.floor(math.max(ay, by))
                                local start_y = ys
                                if #pts_abs > 0 and pts_abs[#pts_abs].x == ax and pts_abs[#pts_abs].y == ys then start_y = ys + 1 end
                                for yy = start_y, ye do pts_abs[#pts_abs+1] = { x = ax, y = yy } end
                            else
                                local xs = math.floor(math.min(ax, bx))
                                local xe = math.floor(math.max(ax, bx))
                                local start_x = xs
                                if #pts_abs > 0 and pts_abs[#pts_abs].x == xs and pts_abs[#pts_abs].y == ay then start_x = xs + 1 end
                                for xx = start_x, xe do pts_abs[#pts_abs+1] = { x = xx, y = ay } end
                            end
                        else
                            local seg_pts = bresenham(ax, ay, bx, by)
                            for j = 1, #seg_pts do
                                if not (j == 1 and #pts_abs > 0 and pts_abs[#pts_abs].x == seg_pts[j].x and pts_abs[#pts_abs].y == seg_pts[j].y) then
                                    pts_abs[#pts_abs+1] = seg_pts[j]
                                end
                            end
                        end

                    elseif seg_type == 'curve' then
                        local ctrl_rel = (self._lines_segment_ctrls and self._lines_segment_ctrls[i]) or nil
                        local abs_ctrl = {}

                        if ctrl_rel and #ctrl_rel >= 1 then
                            for ci, cp in ipairs(ctrl_rel) do
                                abs_ctrl[#abs_ctrl+1] = { x = (cp.x or 0) + base_x0, y = (cp.y or 0) + base_y0 }
                            end
                            table.insert(abs_ctrl, 1, { x = ax, y = ay })
                            abs_ctrl[#abs_ctrl+1] = { x = bx, y = by }
                        else
                            -- fallback: treat endpoints as control points; keep at least 3 points for nicer curve if closed
                            abs_ctrl[1] = { x = ax, y = ay }
                            abs_ctrl[2] = { x = bx, y = by }
                        end

                        -- if closed per-segment curve and only two control points, add a midpoint to force curvature
                        if self._closed and #abs_ctrl == 2 then
                            local a = abs_ctrl[1]; local b = abs_ctrl[2]
                            local mid = { x = (a.x + b.x) / 2, y = (a.y + b.y) / 2 }
                            abs_ctrl = { a, mid, b }
                        end

                        local seg_pts = sample_curve(abs_ctrl, self._curve_samples or 32)
                        for j = 1, #seg_pts do
                            if not (j == 1 and #pts_abs > 0 and pts_abs[#pts_abs].x == seg_pts[j].x and pts_abs[#pts_abs].y == seg_pts[j].y) then
                                pts_abs[#pts_abs+1] = seg_pts[j]
                            end
                        end

                    else
                        local seg_pts = bresenham(ax, ay, bx, by)
                        for j = 1, #seg_pts do
                            if not (j == 1 and #pts_abs > 0 and pts_abs[#pts_abs].x == seg_pts[j].x and pts_abs[#pts_abs].y == seg_pts[j].y) then
                                pts_abs[#pts_abs+1] = seg_pts[j]
                            end
                        end
                    end
                end
            end
        end

        -- 2) append global curve-mode if present (backwards compatibility)
        if self._curve_ctrl_rel and #self._curve_ctrl_rel > 0 then
            local base_x0 = self._x1 or 0
            local base_y0 = self._y1 or 0
            local abs_ctrl = {}
            for i, p in ipairs(self._curve_ctrl_rel) do
                abs_ctrl[#abs_ctrl+1] = { x = (p.x or 0) + base_x0, y = (p.y or 0) + base_y0 }
            end

            if self._closed and #abs_ctrl >= 1 then
                if #abs_ctrl == 2 then
                    local a, b = abs_ctrl[1], abs_ctrl[2]
                    local mid = { x = (a.x + b.x) / 2, y = (a.y + b.y) / 2 }
                    abs_ctrl = { a, mid, b }
                else
                    local f, l = abs_ctrl[1], abs_ctrl[#abs_ctrl]
                    if not (f.x == l.x and f.y == l.y) then
                        abs_ctrl[#abs_ctrl+1] = { x = f.x, y = f.y }
                    end
                end
            end

            local curve_pts = sample_curve(abs_ctrl, self._curve_samples or 32)
            for j = 1, #curve_pts do
                if not (#pts_abs > 0 and pts_abs[#pts_abs].x == curve_pts[j].x and pts_abs[#pts_abs].y == curve_pts[j].y) then
                    pts_abs[#pts_abs+1] = curve_pts[j]
                end
            end
        end

        -- 3) fallback single straight line if nothing produced so far
        if #pts_abs == 0 then
            local ax, ay = self._x1 or 0, self._y1 or 0
            local bx, by = self._x2 or ax, self._y2 or ay
            pts_abs = bresenham(ax, ay, bx, by)
        end

        if not pts_abs or #pts_abs == 0 then
            clear_extra_segs(0)
            self.width = 0
            self.height = 0
            return
        end

        -- compute base and make positions relative to start
        local base_x = math.floor(self._x1 or 0)
        local base_y = math.floor(self._y1 or 0)
        self.base_x = base_x
        self.base_y = base_y

        -- coalesce consecutive horizontal/vertical pixels into runs, account for thickness and add corner fills
        local runs = {}
        local corner_fills = {}
        local idx = 1
        local half = math.floor((self.thickness - 1) / 2)

        while idx <= #pts_abs do
            local p = pts_abs[idx]
            local RUN_start = idx
            local RUN_end = idx

            -- horizontal run
            if idx < #pts_abs and pts_abs[idx+1].y == p.y and math.abs(pts_abs[idx+1].x - p.x) == 1 then
                local dir = pts_abs[idx+1].x - p.x
                RUN_end = idx + 1
                while RUN_end < #pts_abs and pts_abs[RUN_end+1].y == p.y and (pts_abs[RUN_end+1].x - pts_abs[RUN_end].x) == dir do
                    RUN_end = RUN_end + 1
                end
                local xs = pts_abs[RUN_start].x
                local xe = pts_abs[RUN_end].x
                if xs > xe then xs, xe = xe, xs end
                runs[#runs+1] = { x = xs, y = p.y - half, w = (xe - xs) + 1, h = self.thickness }

                local next_idx = RUN_end + 1
                if next_idx <= #pts_abs then
                    local corner = pts_abs[RUN_end]
                    corner_fills[#corner_fills+1] = { x = corner.x - half, y = corner.y - half, w = self.thickness, h = self.thickness }
                end

                idx = RUN_end + 1

            -- vertical run
            elseif idx < #pts_abs and pts_abs[idx+1].x == p.x and math.abs(pts_abs[idx+1].y - p.y) == 1 then
                local dir = pts_abs[idx+1].y - p.y
                RUN_end = idx + 1
                while RUN_end < #pts_abs and pts_abs[RUN_end+1].x == p.x and (pts_abs[RUN_end+1].y - pts_abs[RUN_end].y) == dir do
                    RUN_end = RUN_end + 1
                end
                local ys = pts_abs[RUN_start].y
                local ye = pts_abs[RUN_end].y
                if ys > ye then ys, ye = ye, ys end
                runs[#runs+1] = { x = p.x - half, y = ys, w = self.thickness, h = (ye - ys) + 1 }

                local next_idx = RUN_end + 1
                if next_idx <= #pts_abs then
                    local corner = pts_abs[RUN_end]
                    corner_fills[#corner_fills+1] = { x = corner.x - half, y = corner.y - half, w = self.thickness, h = self.thickness }
                end

                idx = RUN_end + 1

            else
                -- isolated pixel -> centered square of size thickness
                runs[#runs+1] = { x = p.x - half, y = p.y - half, w = self.thickness, h = self.thickness }
                corner_fills[#corner_fills+1] = { x = p.x - half, y = p.y - half, w = self.thickness, h = self.thickness }
                idx = idx + 1
            end
        end

        -- append unique corner fills
        if #corner_fills > 0 then
            local seen = {}
            for _, cf in ipairs(corner_fills) do
                local key = tostring(cf.x) .. ',' .. tostring(cf.y) .. ',' .. tostring(cf.w) .. ',' .. tostring(cf.h)
                if not seen[key] then
                    seen[key] = true
                    runs[#runs+1] = cf
                end
            end
        end

        -- apply runs to prims (positions relative to start)
        for i = 1, #runs do
            local r = runs[i]
            local seg = ensure_seg(i)
            local px = math.floor(r.x - base_x)
            local py = math.floor(r.y - base_y)
            if seg.set_pos then seg:set_pos(px, py) end
            if seg.set_size then seg:set_size(r.w, r.h) end
            -- prefer per-segment color if present, else use global color
            local seg_color = (self._seg_colors and self._seg_colors[i]) or color
            if seg.set_color then pcall(seg.set_color, seg, seg_color[1], seg_color[2], seg_color[3], seg_color[4]) end
            if seg.set_visibility then seg:set_visibility(self.visible) end
        end

        clear_extra_segs(#runs)

        -- update reported size
        local max_right, max_bottom = 0, 0
        for _, r in ipairs(runs) do
            local rel_right = (r.x - base_x) + r.w
            local rel_bottom = (r.y - base_y) + r.h
            if rel_right > max_right then max_right = rel_right end
            if rel_bottom > max_bottom then max_bottom = rel_bottom end
        end
        self.width = math.max(1, max_right)
        self.height = math.max(1, max_bottom)
        if self.update_absolute_position then self:update_absolute_position() end
    end

    -- verplaats startpunt (x1,y1) naar nieuw coordinaat en update alle prim-posities
    -- behoudt de relatieve vorm: x2/y2 worden meeverplaatst zodat de lijn hetzelfde relatieve verschil houdt.
    function line_obj:set_start(nx, ny)
        if type(nx) ~= 'number' or type(ny) ~= 'number' then return false end

        local old_x1 = self._x1 or 0
        local old_y1 = self._y1 or 0
        local dx = nx - old_x1
        local dy = ny - old_y1

        -- zet nieuwe start
        self._x1 = nx
        self._y1 = ny

        -- verplaats endpunt relatief zodat de lijn zijn vorm behoudt
        if self._x2 ~= nil then self._x2 = (self._x2 or old_x1) + dx end
        if self._y2 ~= nil then self._y2 = (self._y2 or old_y1) + dy end

        self.base_x = nx
        self.base_y = ny

        -- als control points REL opgeslagen zijn hoeven we niets aan te passen; update_prim rekent daarvan absolute punten
        update_prim(self)
        return true
    end

    -- set absolute start/end; curves stored relative to start will follow
    function line_obj:set_points(ax, ay, bx, by)
        self._x1 = ax or self._x1 or 0
        self._y1 = ay or self._y1 or 0
        self._x2 = bx or self._x2 or self._x1
        self._y2 = by or self._y2 or self._y1
        has_explicit_points = true
        update_prim(self)
    end

    function line_obj:set_lines(points, types)
        if type(points) ~= 'table' or #points < 2 then return false end

        -- helper to read coordinates safely from {x=..,y=..} or {x,y}
        local function read_point(p)
            if type(p) ~= 'table' then return 0, 0 end
            local x = p.x
            local y = p.y
            if x == nil and p[1] ~= nil then x = p[1] end
            if y == nil and p[2] ~= nil then y = p[2] end
            return x or 0, y or 0
        end

        -- work on a local copy so caller's table isn't mutated
        local pts = {}
        for i, p in ipairs(points) do pts[i] = p end
        local orig_count = #points

        -- if closed requested, append a copy of the first point to the end (if different)
        if self._closed then
            local fx, fy = read_point(pts[1])
            local lx, ly = read_point(pts[#pts])
            if not (fx == lx and fy == ly) then
                -- print('Closing line by adding first point to end:',fx,fy,lx,ly)
                pts[#pts + 1] = { x = fx, y = fy }
            end
        end
        -- print('Line set_lines with ' .. tostring(#pts) .. ' points (original ' .. tostring(orig_count) .. ')')
        -- disable curve-mode, enable lines-mode
        self._curve_samples = nil
        self._is_lines = true
        self._curve_ctrl_rel = nil

        -- initialize storage arrays
        self._lines_points_rel = {}
        self._lines_segment_types = {}
        self._lines_segment_ctrls = {}

        -- if no explicit start was set, derive start/end from the (possibly modified) pts list
        if not has_explicit_points then
            local fx, fy = read_point(pts[1])
            local lx, ly = read_point(pts[#pts])
            self._x1 = fx or 0
            self._y1 = fy or 0
            self._x2 = lx or self._x1
            self._y2 = ly or self._y1
        end

        -- store points relative to start and fill per-segment metadata
        local count = #pts
        for i = 1, count do
            local px, py = read_point(pts[i])
            self._lines_points_rel[i] = { x = px - (self._x1 or 0), y = py - (self._y1 or 0) }

            if i < count then
                -- segment from i -> i+1
                local seg_type
                if type(pts[i]) == 'table' and type(pts[i].type) == 'string' then
                    seg_type = pts[i].type
                elseif types and type(types[i]) == 'string' then
                    seg_type = types[i]
                else
                    seg_type = 'line'
                end
                self._lines_segment_types[i] = seg_type

                if seg_type == 'curve' and type(pts[i]) == 'table' and pts[i].ctrl then
                    local ctrl_rel = {}
                    for ci, cp in ipairs(pts[i].ctrl) do
                        local cpx, cpy = read_point(cp)
                        ctrl_rel[ci] = { x = cpx - (self._x1 or 0), y = cpy - (self._y1 or 0) }
                    end
                    self._lines_segment_ctrls[i] = ctrl_rel
                else
                    self._lines_segment_ctrls[i] = nil
                end
            end
        end

        -- if closed, ensure the closing segment type/ctrl come from original inputs or fallback setting
        if self._closed and orig_count >= 2 then
            local last_seg_idx = orig_count -- segment connecting original last -> original first
            local last_type = nil

            if types and type(types[last_seg_idx]) == 'string' then
                last_type = types[last_seg_idx]
            elseif type(points[last_seg_idx]) == 'table' and type(points[last_seg_idx].type) == 'string' then
                last_type = points[last_seg_idx].type
            else
                last_type = self._closed_segment_type or 'line'
            end

            self._lines_segment_types[last_seg_idx] = last_type

            if last_type == 'curve' and type(points[last_seg_idx]) == 'table' and points[last_seg_idx].ctrl then
                local ctrl_rel = {}
                for ci, cp in ipairs(points[last_seg_idx].ctrl) do
                    local cpx, cpy = read_point(cp)
                    ctrl_rel[ci] = { x = cpx - (self._x1 or 0), y = cpy - (self._y1 or 0) }
                end
                self._lines_segment_ctrls[last_seg_idx] = ctrl_rel
            end
        end

        update_prim(self)
        return true
    end

    -- expect control points RELATIVE to start (0,0 == start). store as-rel
    function line_obj:set_curve(ctrl_pts, samples)
        if type(ctrl_pts) ~= 'table' or #ctrl_pts < 2 then return false end

        local orig_count = #ctrl_pts
        self._curve_samples = samples or (orig_count * (self.samples or 64))

        -- normaliseer input naar lokale absolute lijst
        local pts = {}
        for i, p in ipairs(ctrl_pts) do
            if type(p) == 'table' then
                local x = p.x; local y = p.y
                if x == nil and p[1] ~= nil then x = p[1] end
                if y == nil and p[2] ~= nil then y = p[2] end
                pts[#pts+1] = { x = x or 0, y = y or 0 }
            else
                pts[#pts+1] = { x = tonumber(p) or 0, y = 0 }
            end
        end

        -- sluit lijst indien nodig (voeg eerste toe aan eind)
        if self._closed and #pts >= 1 then
            local f, l = pts[1], pts[#pts]
            if not (f.x == l.x and f.y == l.y) then
                pts[#pts+1] = { x = f.x, y = f.y }
            end
        end

        -- indien geen expliciete start, derive start/end uit ctrl list
        if not has_explicit_points then
            local first = pts[1]; local last = pts[#pts]
            self._x1 = first.x or 0; self._y1 = first.y or 0
            self._x2 = last.x  or self._x1; self._y2 = last.y  or self._y1
        end

        -- sla control points RELATIEF op aan start
        self._curve_ctrl_rel = {}
        for i, p in ipairs(pts) do
            self._curve_ctrl_rel[i] = { x = p.x - (self._x1 or 0), y = p.y - (self._y1 or 0) }
        end

        -- zorg dat per-segment metadata bestaat en dat de sluitende segment (originele count) als curve gemarkeerd is
        self._lines_segment_types = self._lines_segment_types or {}
        if self._closed and orig_count >= 2 then
            self._lines_segment_types[orig_count] = 'curve'
        end

        update_prim(self)
        return true
    end

    function line_obj:set_thickness(t)
        self.thickness = t or thickness
        thickness = self.thickness
        for _, s in ipairs(segs) do
            if s.set_size then s:set_size(self.thickness, self.thickness) end
        end
        update_prim(self)
    end

    function line_obj:set_color(c)
        if type(c) == 'table' then
            color = c
            self._seg_colors = self._seg_colors or {}
            for i = 1, #segs do
                self._seg_colors[i] = {color[1], color[2], color[3], color[4]}
            end
            for _, s in ipairs(segs) do
                if s.set_color then s:set_color(color[1], color[2], color[3], color[4]) end
            end
        end
    end

    -- set per-segment colors. mode = 'random' | 'gradient' | nil (reset)
    -- opts for 'random': { min = {r,g,b,a}, max = {r,g,b,a}, seed = number }
    -- opts for 'gradient': { from = {r,g,b,a}, to = {r,g,b,a}, count = number }
    function line_obj:set_segment_colors(mode, opts)
        mode = mode and tostring(mode) or 'gradient'
        if mode == 'gradient' and opts == nil then
            opts = { from = {255,255,255,255}, to = {0,0,0,255}, count = #segs }
        else
            opts = opts or {}
        end
        if opts.count==nil then opts.count = #segs end
        -- determine number of segments to color; prefer current prim count, fallback to 1
        local n = opts.count or math.max(1, #segs)

        -- helper clamp/lerp
        local function clamp01(x) if x < 0 then return 0 elseif x > 1 then return 1 else return x end end
        local function lerp(a, b, t) return a + (b - a) * t end
        local function round(v) return math.floor(v + 0.5) end

        if mode == 'random' then
            local minc = opts.min or {0,0,0,255}
            local maxc = opts.max or {255,255,255,255}
            if opts.seed then math.randomseed(opts.seed) end
            self._seg_colors = {}
            for i = 1, n do
                local r = math.random(minc[1] or 0, maxc[1] or 255)
                local g = math.random(minc[2] or 0, maxc[2] or 255)
                local b = math.random(minc[3] or 0, maxc[3] or 255)
                local a = opts.alpha or (maxc[4] or minc[4] or 255)
                self._seg_colors[i] = { r, g, b, a }
            end

        elseif mode == 'gradient' then
            local from = opts.from or color or {255,255,255,255}
            local to   = opts.to   or {255,255,255,255}
            self._seg_colors = {}
            n = math.max(1, n)
            for i = 1, n do
                local t = (n == 1) and 0 or clamp01((i - 1) / (n - 1))
                local r = round(lerp(from[1] or 0, to[1] or 0, t))
                local g = round(lerp(from[2] or 0, to[2] or 0, t))
                local b = round(lerp(from[3] or 0, to[3] or 0, t))
                local a = round(lerp(from[4] or 255, to[4] or 255, t))
                self._seg_colors[i] = { r, g, b, a }
            end

        else
            -- reset to use global color again
            self._seg_colors = nil
        end

        -- immediately apply to existing prims if present
        for i = 1, #segs do
            local s = segs[i]
            if s and s.set_color then
                local sc = (self._seg_colors and self._seg_colors[i]) or color
                pcall(s.set_color, s, sc[1], sc[2], sc[3], sc[4])
            end
        end
    end

    -- convenience alias to reset
    function line_obj:clear_segment_colors()
        self._seg_colors = nil
        for i = 1, #segs do
            local s = segs[i]
            if s and s.set_color then
                pcall(s.set_color, s, color[1], color[2], color[3], color[4])
            end
        end
    end

    -- function line_obj:set_visible(v)
    --     self.visible = v and true or false
    --     for _, s in ipairs(segs) do
    --         if self.visible and s.show then 
    --             s:show() 
    --         elseif s.hide then 
    --             s:hide() 
    --         end
    --     end
    -- end

    function line_obj:on_update_draw_visibility(v)
        for _, s in ipairs(segs) do
            s:update_draw_visibility(v) 
        end
    end

    function line_obj:destroy()
        for i = #segs, 1, -1 do
            if segs[i] then
                if segs[i].hide then segs[i]:hide() end
                if segs[i].destroy then segs[i]:destroy() end
                segs[i] = nil
            end
        end
        if ui and ui.elements and ui.elements.remove_ref then ui.elements:remove_ref(id) end
    end

    function line_obj:count_images(only_visible)
        local n = 0
        for _, s in ipairs(segs) do
            if s then
                if only_visible then
                    if s.show then
                        -- assume presence of show/hide state not tracked; best-effort:
                        -- if prim lib exposes visibility getter, use that; otherwise count as visible
                        n = n + 1
                    else
                        n = n + 1
                    end
                else
                    n = n + 1
                end
            end
        end
        return n
    end
    
    -- init
    line_obj._x1 = x1; line_obj._y1 = y1; line_obj._x2 = x2; line_obj._y2 = y2
    line_obj.thickness = thickness

    if setting.lines and type(setting.lines) == 'table' and #setting.lines >= 2 then
        line_obj:set_lines(setting.lines)
    end

    update_prim(line_obj)
    -- ui.set_composed(line_obj,line_obj)

    return line_obj, #segs
end
