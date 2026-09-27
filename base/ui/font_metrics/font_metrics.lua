FONT_METRICS = {}

-- Haal de breedte van een karakter op voor een bepaalde fontsize (pixels)
function FONT_METRICS.char_width(font, char, size)
    local w = font.base_metrics[char] or 7
    if not size or size == font.base_size then
        return w
    end
    return w * (size / font.base_size)
end

-- Haal de breedte van een string op voor een bepaalde fontsize (pixels), met kerning
function FONT_METRICS.text_width(font, text, size)
    local width = 0
    local prev = nil
    text = tostring(text)
    for i = 1, #text do
        local c = text:sub(i, i)
        width = width + FONT_METRICS.char_width(font,c, size)
        if prev then
            local pair = prev .. c
            local kern = font.kerning_table[pair]
            if kern then
                -- Schaal kerning indien nodig
                if size and size ~= font.base_size then
                    kern = kern * (size / font.base_size)
                end
                width = width + kern
            end
        end
        prev = c
    end
    return width
end

-- Retourneer de hele metrics-tabel geschaald naar een bepaalde fontsize (inclusief kerning)
function FONT_METRICS.metrics_for_size(font, size)
    if not size or size == font.base_size then
        return font.base_metrics, font.kerning_table
    end
    local scaled_metrics = {}
    for k, v in pairs(font.base_metrics) do
        scaled_metrics[k] = v * (size / font.base_size)
    end
    local scaled_kerning = {}
    for k, v in pairs(font.kerning_table) do
        scaled_kerning[k] = v * (size / font.base_size)
    end
    return scaled_metrics, scaled_kerning
end

function FONT_METRICS.get_baseline(font, size)
    size = size or font.base_size
    -- 0.8 * fontsize is een redelijke schatting voor Arial
    return math.floor(size * 0.8)
end

function FONT_METRICS.get_line_spacing(font, size)
    size = size or font.base_size
    local line_spacing = font.line_spacing or 7
    -- 0.8 * fontsize is een redelijke schatting voor Arial
    return mathFunctions.round_nearest(line_spacing*(size / font.base_size))
end
