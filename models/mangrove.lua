-- ===============================================================
-- SOIL MIGRATION
-- ===============================================================
-- Updates the soil type of the neighbouring cells with fixed, simple
-- migration rules, without parameters or auxiliary tables.
function migrateSoils(cell, attribute_names, soil_classes, influenceZone)
    -- Shapefile fields
    local soilAttr     = attribute_names.soil
    local landUseAttr  = attribute_names.land_use
    local altitudeAttr = attribute_names.altitude

    local currentSoil = cell.past[soilAttr]

    -- Can the current soil start a migration? (source soils)
    if currentSoil == soil_classes.MANGROVE.value
        or currentSoil == soil_classes.MIGRATED_MANGROVE.value
        or currentSoil == soil_classes.RIVER_CHANNEL.value then

        -- Visit the neighbours of the current cell
        forEachNeighbor(cell, function(neighbor)
            local neighborUse  = neighbor.past[landUseAttr]
            local neighborSoil = neighbor.past[soilAttr]
            local neighborAlt  = neighbor.past[altitudeAttr]

            -- Conditions that allow the soil to migrate
            if (neighborUse == land_use_classes.TERRESTRIAL_VEGETATION.value
                or neighborUse == land_use_classes.BARE_SOIL.value)
                and neighborSoil ~= soil_classes.MIGRATED_MANGROVE.value
                and neighborAlt <= influenceZone then

                -- The neighbour's soil becomes "migrated mangrove"
                neighbor[soilAttr] = soil_classes.MIGRATED_MANGROVE.value
            end
        end)
    end
end



-- ===============================================================
-- LAND-USE MIGRATION
-- ===============================================================
-- Updates the land use of the neighbouring cells with fixed rules,
-- without external parameters or auxiliary tables.
function migrateLandUses(cell, attribute_names, land_use_classes, soil_classes, influenceZone)
    -- Shapefile fields
    local soilAttr     = attribute_names.soil
    local landUseAttr  = attribute_names.land_use
    local altitudeAttr = attribute_names.altitude

    local currentUse = cell.past[landUseAttr]

    -- Can the current land use start a migration?
    if currentUse == land_use_classes.MANGROVE.value
        or currentUse == land_use_classes.MIGRATED_MANGROVE.value then

        -- Visit the neighbours and apply the migration conditions
        forEachNeighbor(cell, function(neighbor)
            local neighborUse  = neighbor.past[landUseAttr]
            local neighborSoil = neighbor.past[soilAttr]
            local neighborAlt  = neighbor.past[altitudeAttr]

            -- Conditions for the land use to migrate
            if (neighborUse == land_use_classes.TERRESTRIAL_VEGETATION.value
                or neighborUse == land_use_classes.BARE_SOIL.value)
                and (neighborSoil == soil_classes.MANGROVE.value
                     or neighborSoil == soil_classes.MIGRATED_MANGROVE.value)
                and neighborAlt <= influenceZone then

                -- The neighbour's land use becomes "migrated mangrove"
                neighbor[landUseAttr] = land_use_classes.MIGRATED_MANGROVE.value
            end
        end)
    end
end



-- ===============================================================
-- VERTICAL MUD ACCRETION
-- ===============================================================
-- Simulates the vertical build-up of sediment (accretion) in mangrove
-- cells. Elevation rises only on suitable soils and land uses.
function applyAccretion(cell, attribute_names, land_use_classes, soil_classes, accretionRate_m)
    -- Shapefile fields
    local soilAttr     = attribute_names.soil
    local landUseAttr  = attribute_names.land_use
    local altitudeAttr = attribute_names.altitude

    local currentSoil = cell.past[soilAttr]
    local currentUse  = cell.past[landUseAttr]

    -- Accretion is allowed only on mangrove and migrated-mangrove soils
    local soilAllowed = (
        currentSoil == soil_classes.MANGROVE.value or
        currentSoil == soil_classes.MIGRATED_MANGROVE.value
    )

    -- Land uses on which accretion is not allowed
    local useForbidden = (
        currentUse == land_use_classes.SEA.value or
        currentUse == land_use_classes.FLOODED_SOIL.value or
        currentUse == land_use_classes.FLOODED_ANTHROPIZED_AREA.value or
        currentUse == land_use_classes.FLOODED_MANGROVE.value or
        currentUse == land_use_classes.FLOODED_TERRESTRIAL_VEGETATION.value
    )

    -- Apply vertical accretion only when the soil is allowed and the use is not forbidden
    if soilAllowed and not useForbidden then
        cell[altitudeAttr] = cell[altitudeAttr] + accretionRate_m
    end
end



-- ===============================================================
-- MANGROVE DYNAMICS MODEL (Mangrove)
-- ===============================================================
-- Python twin: brmangue.models.*.mangrove_model.MangroveModel (brmangue-dissmodel).
-- Combines soil migration, land-use migration and vertical accretion
-- to simulate the response of the mangrove to sea-level rise.
function Mangrove(cellSpace, soil_classes, land_use_classes, attribute_names)
    return Model {
        -- Simulation time
        start = 1,
        finalTime = 100,

        -- General model parameters
        cellArea = 0.09,            -- cell area (hectares)
        tideHeight = 6,             -- mean tide height (m)
        seaLevelRiseRate = 0.5,     -- sea-level rise rate (m/year)

        -- Coefficients of the Alongi (2008) equation
        coefficientA = 1.693,       -- intercept
        coefficientB = 0.939,       -- slope

        -- Executed at every time step
        execute = function(model, event)
            local time = event:getTime()

            -- Sea level and accretion rate (in metres)
            local seaLevel = time * model.seaLevelRiseRate
            local accretionRate_m = model.coefficientA / 1000 + (model.coefficientB * seaLevel)

            -- Tidal influence zone, shifted by sea-level rise
            local influenceZone = model.tideHeight + seaLevel

            -- Apply the processes to every cell of the space
            forEachCell(cellSpace, function(cell)
                migrateSoils(cell, attribute_names, soil_classes, influenceZone)
                migrateLandUses(cell, attribute_names, land_use_classes, soil_classes, influenceZone)
                --applyAccretion(cell, attribute_names, land_use_classes, soil_classes, accretionRate_m)
            end)
        end,

        -- Model initialisation
        init = function(model)
            model.timer = Timer { Event { action = model } }
        end
    }
end
