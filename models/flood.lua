-- ===============================================================
-- HELPER FUNCTIONS
-- ===============================================================

-- Tells whether a land-use value is sea or one of the flooded uses,
-- i.e. whether the cell is already under the influence of the tide
-- or of flooding.
--
-- @param landUse : current land-use value of the cell
-- @return true if the land use is sea or a flooded class, false otherwise
function isSeaOrFlooded(landUse)
    -- Land uses regarded as flooded
    local floodedUses = {
        [land_use_classes.SEA.value]                            = true,
        [land_use_classes.FLOODED_SOIL.value]                   = true,
        [land_use_classes.FLOODED_ANTHROPIZED_AREA.value]       = true,
        [land_use_classes.FLOODED_MANGROVE.value]               = true,
        [land_use_classes.FLOODED_TERRESTRIAL_VEGETATION.value] = true
    }

    return floodedUses[landUse] == true
end



-- Applies the flooding rule to a cell, if there is one for its land use:
-- turns the current land use into the matching "flooded" class.
--
-- @param cell        : cell of the cellular space
-- @param landUseAttr : name of the land-use attribute of the cell (e.g. "uso")
function applyFlooding(cell, landUseAttr)
    local currentUse = cell.past[landUseAttr]

    -- Conversion rules: dry land use -> flooded land use
    local rules = {
        [land_use_classes.MANGROVE.value]               = land_use_classes.FLOODED_MANGROVE.value,
        [land_use_classes.MIGRATED_MANGROVE.value]      = land_use_classes.FLOODED_MANGROVE.value,
        [land_use_classes.TERRESTRIAL_VEGETATION.value] = land_use_classes.FLOODED_TERRESTRIAL_VEGETATION.value,
        [land_use_classes.ANTHROPIZED_AREA.value]       = land_use_classes.FLOODED_ANTHROPIZED_AREA.value,
        [land_use_classes.BARE_SOIL.value]              = land_use_classes.FLOODED_SOIL.value
    }

    -- If there is a rule for the current land use, apply it
    if rules[currentUse] then
        cell[landUseAttr] = rules[currentUse]
    end
end



-- ===============================================================
-- FLOOD MODEL (Flood) — hydrology
-- ===============================================================
-- Python twin: brmangue.models.*.flood_model.FloodModel (brmangue-dissmodel).
-- Simulates the effect of sea-level rise on elevation and land use.
-- Spreads the sea-level increment among flooded cells and their
-- neighbours, so that flooding advances gradually over time.
--
-- @param cs               : cellular space (CellularSpace)
-- @param land_use_classes : table with the land-use codes
-- @param attribute_names  : names of the cell attributes (e.g. { land_use = "uso", altitude = "alt" })
function Flood(cs, land_use_classes, attribute_names)
    return Model {
        start = 1,
        finalTime = 100,
        seaLevelRiseRate = 0.011,

        execute = function(model, event)
            local landUseAttr  = attribute_names.land_use
            local altitudeAttr = attribute_names.altitude
            local seaLevel     = event:getTime() * model.seaLevelRiseRate

            forEachCell(cs, function(cell)
                local currentUse = cell.past[landUseAttr]
                local currentAlt = cell.past[altitudeAttr]

                if isSeaOrFlooded(currentUse) and currentAlt >= 0 then
                    local lowerNeighbors = 1

                    forEachNeighbor(cell, function(neighbor)
                        if neighbor.past[altitudeAttr] <= currentAlt then
                            lowerNeighbors = lowerNeighbors + 1
                        end
                    end)

                    local flux = model.seaLevelRiseRate / lowerNeighbors

                    -- elevation: relative condition (flux diffusion)
                    cell[altitudeAttr] = cell[altitudeAttr] + flux

                    forEachNeighbor(cell, function(neighbor)
                        if neighbor.past[altitudeAttr] <= currentAlt then
                            neighbor[altitudeAttr] = neighbor[altitudeAttr] + flux
                        end

                        -- flooding: absolute level (BR-MANGUE, Bezerra 2014)
                        if neighbor.past[altitudeAttr] <= seaLevel then
                            if not isSeaOrFlooded(neighbor.past[landUseAttr]) then
                                applyFlooding(neighbor, landUseAttr)
                            end
                        end
                    end)
                end
            end)
        end,

        init = function(model)
            model.timer = Timer { Event { action = model } }
        end
    }
end
