-- ===============================================================
-- MAP DISPLAY FUNCTIONS
-- ===============================================================
function landUseMap(cellSpace, landUses, select)
    local values, colors, labels = {}, {}, {}

    for _, landUse in pairs(landUses) do
        table.insert(values, landUse.value)
        table.insert(colors, landUse.color)
        table.insert(labels, landUse.name)
    end

    return Map {
        target = cellSpace,
        select = select,
        value = values,
        color = colors,
        label = labels
    }
end



function soilMap(cellSpace, soil_classes, select)
    local values = {}
    local colors = {}
    local names = {}

    for _, soil in pairs(soil_classes) do
        table.insert(values, soil.value)
        table.insert(colors, soil.color)
        table.insert(names, soil.name)
    end

    return Map {
        target = cellSpace,
        select = select,
        value = values,
        color = colors,
        label = names
    }
end



function altitudeMap(cellSpace,select)
    return Map {
        target = cellSpace,
        select = select,
        color = "RdYlGn",
        slices = 10,
        size = 1
    }
end
