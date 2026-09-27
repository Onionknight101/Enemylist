require('base/ui/prim/texts_prim')

local size = 10
local font_name = 'Consolas'
local metrics = require('base/ui/font_metrics/fonts/'..font_name)

local modus = nil -- of bijvoorbeeld: modus = "Paladin"
local save_info = true
local kerning_check = true
local letters = {}

if modus == nil then
    for c = 32, 126 do -- ASCII printable
        table.insert(letters, string.char(c))
    end
else
    for i = 1, #modus do
        table.insert(letters, modus:sub(i, i))
    end
end

local prims = {}
local tested = {}

--maak hoogte test prims
local function make_tmp_prim(txt)
    local p = texts_prim.new(txt, {
        x = 0, y = 0 ,
        text = { font = font_name, size = size, red = 255, green = 255, blue = 255, alpha = 255 },
        bg = { alpha = 0, visible = false },
    })
    if p and p.show then p:show() end
    return p
end
local p_single = make_tmp_prim("Wy")
local p_two = make_tmp_prim("Wy\nWy")
local p_three = make_tmp_prim("Wy\nWy\nWy")
local p_asc = make_tmp_prim("H")
local p_desc = make_tmp_prim("g")
local prims_ready_delay = 2 

-- Voeg alle losse letters toe
for _, char in ipairs(letters) do
    local t = texts_prim.new(char, {
        x = 0, y = 0,
        text = {
            font = font_name,
            size = size,
            red = 255, green = 255, blue = 255, alpha = 255,
        },
        bg = {alpha = 0, visible = false},
    })
    t:show()
    table.insert(prims, {prim = t, char = char})
end

-- Voeg kerningparen toe: alle combinaties van letters (ASCII) of per modus
if(kerning_check==true) then
    if modus == nil then
        for _, c1 in ipairs(letters) do
            for _, c2 in ipairs(letters) do
                local pair = c1 .. c2
                local t_pair = texts_prim.new(pair, {
                    x = 0, y = 0,
                    text = {
                        font = font_name,
                        size = size,
                        red = 255, green = 255, blue = 255, alpha = 255,
                    },
                    bg = {alpha = 0, visible = false},
                })
                t_pair:show()
                table.insert(prims, {prim = t_pair, char = pair, is_pair = true})
            end
        end
    else
        local t = texts_prim.new(modus, {
            x = 0, y = 0,
            text = {
                font = font_name,
                size = size,
                red = 255, green = 255, blue = 255, alpha = 255,
            },
            bg = {alpha = 0, visible = false},
        })
        t:show()
        table.insert(prims, {prim = t, char = modus})

        for i = 1, #modus - 1 do
            local pair = modus:sub(i, i+1)
            local t_pair = texts_prim.new(pair, {
                x = 0, y = 0,
                text = {
                    font = font_name,
                    size = size,
                    red = 255, green = 255, blue = 255, alpha = 255,
                },
                bg = {alpha = 0, visible = false},
            })
            t_pair:show()
            table.insert(prims, {prim = t_pair, char = pair, is_pair = true})
        end
    end
end

local all_tested = false

function test_metrics_render()
    if all_tested then return end

    -- wacht een paar frames zodat texts_prim.new + show() voldoende tijd hebben om te initialiseren
    if prims_ready_delay and prims_ready_delay > 0 then
        prims_ready_delay = prims_ready_delay - 1
        return
    end

    local all_ok = true
    local all_chars_tested = true
    local kerning_table = {}

    for _, entry in ipairs(prims) do
        local t = entry.prim
        local char = entry.char
        local width, height = t:extents()
        if width and width > 0 then
            tested[char] = true
            local expected = 0
            if entry.is_pair then
                local c1, c2 = char:sub(1,1), char:sub(2,2)
                expected = FONT_METRICS.char_width(metrics, c1, size) + FONT_METRICS.char_width(metrics, c2, size)
                local diff = width - expected
                kerning_table[char] = diff
                if math.abs(diff) > 0.5 then
                    -- print(string.format("Kerning '%s': measured=%.2f x %.2f, sum=%.2f, diff=%.2f", char, width, height or 0, expected, diff))
                end
            elseif #char > 1 then
                expected = FONT_METRICS.text_width(metrics, char, size)
                if math.abs(width - expected) > 0.5 then
                    -- print(string.format("Word '%s': measured=%.2f x %.2f, table=%.2f, diff=%.2f", char, width, height or 0, expected, width - expected))
                    all_ok = false
                end
            else
                expected = FONT_METRICS.char_width(metrics, char, size)
                if math.abs(width - expected) > 0.5 then
                    -- print(string.format("Char '%s': measured=%.2f x %.2f, table=%.2f, diff=%.2f", char, width, height or 0, expected, width - expected))
                    all_ok = false
                end
            end
        else
            all_chars_tested = false
        end
    end

    if all_chars_tested then
        if (save_info == true) then
            local f = io.open('c:/windower4/addons/actor/font_metrics_result.lua', 'w')
            f:write("return {\n   base_metrics = {\n")

            local function escape_literal(s)
                if not s then return s end
                local out = ""
                for i = 1, #s do
                    local ch = s:sub(i, i)
                    local b = string.byte(ch)
                    if b == 92 or b == 34 or b == 39 then
                        out = out .. '\\' .. ch
                    else
                        out = out .. ch
                    end
                end
                return out
            end

            -- write metrics with width and height
            for _, entry in ipairs(prims) do
                local t = entry.prim
                local char = entry.char
                local width, height = t:extents()
                if width and width > 0 and not entry.is_pair then
                    f:write(string.format("    [\"%s\"] = { w = %.2f, h = %.2f },\n", escape_literal(char), width, height or 0))
                end
            end

            -- compute paddings by measuring "Wy" and "Wy\nWy" and asc/desc examples
            local _, single_h = p_single:extents()
            local _, two_h    = p_two:extents()
            local _, three_h  = p_three:extents()
            local _, asc_h    = p_asc:extents()
            local _, desc_h   = p_desc:extents()

            -- bepaal baseline-step (oploop) tussen regels via p_single, p_two en p_three
            -- delta1 = two_h - single_h, delta2 = three_h - two_h
            local delta1 = math.max(0, two_h - single_h)
            local delta2 = math.max(0, three_h - two_h)

            -- als beide deltas vergelijkbaar zijn, neem hun gemiddelde als interline_total
            -- anders neem de kleinste (conservatieve) waarde om overschatting te voorkomen
            local interline_total
            if math.abs(delta1 - delta2) <= 1.0 then
                interline_total = (delta1 + delta2) / 2
            else
                interline_total = math.min(delta1, delta2)
            end

            -- afleiding pad_top / letterhoogte (optioneel)
            local letter_height = asc_h or 0
            local pad_top = math.max(0, single_h - letter_height)
            local pad_bottom = math.max(0, single_h - pad_top - letter_height)

            print('Heights: single='..tostring(single_h).." two="..tostring(two_h).." three="..tostring(three_h).." asc="..tostring(asc_h).." desc="..tostring(desc_h))
            print('Paddings: top='..tostring(pad_top).." bottom="..tostring(pad_bottom).." between="..tostring(interline_total))
            print('Letter height (asc): '..tostring(letter_height))
            print('Interline total: '..tostring(interline_total))


            f:write("},\n   kerning_table = {\n")
            for pair, diff in pairs(kerning_table) do
                if math.abs(diff) > 0.5 then
                    f:write(string.format("    [\"%s\"] = %.2f,\n", escape_literal(pair), diff))
                end
            end

            f:write("},\n   base_size = " .. tostring(size) .. ",\n")
            f:write(string.format("   paddings = { single_h = %.2f, two_h = %.2f, pad_top = %.2f, pad_between = %.2f, pad_bottom = %.2f },\n",
                single_h or 0, two_h or 0, pad_top, interline_total, pad_bottom))
            f:write("}\n\n\ndifferences = {\n")

            for _, entry in ipairs(prims) do
                local t = entry.prim
                local char = entry.char
                local width, height = t:extents()
                local expected = 0
                if entry.is_pair then
                    local c1, c2 = char:sub(1,1), char:sub(2,2)
                    expected = FONT_METRICS.char_width(metrics, c1, size) + FONT_METRICS.char_width(metrics, c2, size)
                    if width and width > 0 and math.abs(width - expected) > 0.5 then
                        f:write(string.format("    {pair = \"%s\", measured_w = %.2f, measured_h = %.2f, sum = %.2f, diff = %.2f},\n",
                            escape_literal(char), width, height or 0, expected, width - expected))
                    end
                elseif #char > 1 then
                    expected = FONT_METRICS.text_width(metrics, char, size)
                    if width and width > 0 and math.abs(width - expected) > 0.5 then
                        f:write(string.format("    {word = \"%s\", measured_w = %.2f, measured_h = %.2f, table = %.2f, diff = %.2f},\n",
                            escape_literal(char), width, height or 0, expected, width - expected))
                    end
                else
                    expected = FONT_METRICS.char_width(metrics, char, size)
                    if width and width > 0 and math.abs(width - expected) > 0.5 then
                        f:write(string.format("    {char = \"%s\", measured_w = %.2f, measured_h = %.2f, table = %.2f, diff = %.2f},\n",
                            escape_literal(char), width, height or 0, expected, width - expected))
                    end
                end
            end

            f:write("}\n\nreturn {\n    metrics = new_metrics,\n    kerning = kerning_table,\n    differences = differences,\n}\n")
            f:close()
        end

        if all_ok then
            print("Alle karakters getest en metrics komen overeen. Wij zijn klaar!")
        else
            print("Alle karakters getest, verschillen zijn opgeslagen in font_metrics_result.lua.")
        end
        all_tested = true
    end
end

-- Roep test_metrics_render() aan in je render/update loop.