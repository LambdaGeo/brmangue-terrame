-- ===============================================================
-- IMPACTS OF SEA-LEVEL RISE ON MANGROVE ECOSYSTEMS (BR-MANGUE)
-- ORIGINAL AUTHOR: Denilson da Silva Bezerra
-- REVISED AND RESTRUCTURED BY: Sergio Souza Costa
-- ===============================================================


-- ===============================================================
-- LIBRARIES
-- ===============================================================
import("gis")                 -- Main library for spatial (GIS) operations
require("models/mangrove")    -- Mangrove dynamics model
require("models/flood")       -- Flood (hydrology) model
require("models/utils")       -- Utility functions
require("visualization/maps") -- Map display




-- ===============================================================
-- ATTRIBUTE NAMES
-- ===============================================================
-- Names of the shapefile fields used by the model, written only here: the
-- models receive this table. The values are the field names of the data
-- (in Portuguese).
local attribute_names = {
    land_use = "Uso",
    soil     = "Solo",
    altitude = "Altitude"
}


-- ===============================================================
-- LAND-USE CLASSES
-- ===============================================================
-- Each class is a land cover or land use; the codes are those of the data.
land_use_classes = {
    MANGROVE                        = { value = 1,  color = {0, 100, 0},      name = "Mangrove" },
    TERRESTRIAL_VEGETATION          = { value = 2,  color = {128, 128, 0},    name = "Terrestrial vegetation" },
    SEA                             = { value = 3,  color = {0, 0, 139},      name = "Sea" },
    ANTHROPIZED_AREA                = { value = 4,  color = {255, 215, 0},    name = "Anthropized area" },
    BARE_SOIL                       = { value = 5,  color = {255, 222, 173},  name = "Bare soil" },
    FLOODED_SOIL                    = { value = 6,  color = {0, 0, 0},        name = "Flooded soil" },
    FLOODED_ANTHROPIZED_AREA        = { value = 7,  color = {50, 50, 50},     name = "Flooded anthropized area" },
    MIGRATED_MANGROVE               = { value = 8,  color = {0, 255, 0},      name = "Migrated mangrove" },
    FLOODED_MANGROVE                = { value = 9,  color = {255, 0, 0},      name = "Flooded mangrove" },
    FLOODED_TERRESTRIAL_VEGETATION  = { value = 10, color = {0, 0, 0},        name = "Flooded terrestrial vegetation" }
}


-- ===============================================================
-- SOIL CLASSES
-- ===============================================================
-- Soil or substrate types of the study area
soil_classes = {
    RIVER_CHANNEL     = { value = 0, color = {0, 0, 255},     name = "River channel" },
    RIVERBED          = { value = 1, color = {102, 153, 204}, name = "Riverbed" },      -- no transition rule
    PODZOLIC          = { value = 2, color = {170, 170, 170}, name = "Podzolic" },      -- no transition rule
    MANGROVE          = { value = 3, color = {0, 100, 0},     name = "Mangrove mud" },
    MIGRATED_MANGROVE = { value = 9, color = {34, 139, 34},   name = "Migrated mangrove mud" },
    OTHER             = { value = 4, color = {0, 0, 0},       name = "Other" }
}


-- ===============================================================
-- PROJECT AND CELLULAR SPACE
-- ===============================================================
-- Load the QGIS project and build the cellular space from the shapefile
local project = Project {
    file = "recorte.qgs",
    cell_usos = "data/teste_dinamica/Recorte_Teste.shp",
    clean = true
}

-- Cellular space with the selected attributes
local cellSpace = CellularSpace {
    project = project,
    layer   = "cell_usos",
    xy      = { "Col", "Lin" },
    select  = attribute_names
}

-- Moore neighbourhood (8 neighbours) and initial state
cellSpace:createNeighborhood { strategy = "moore", self = false }
cellSpace:synchronize()

local flood_model = Flood(cellSpace, land_use_classes, attribute_names)
local mangrove_model = Mangrove(cellSpace, soil_classes, land_use_classes, attribute_names)


-- ===============================================================
-- MODEL CONSTANTS
-- ===============================================================
-- Sea-level rise rate (metres per time step)
local SEA_LEVEL_RISE_RATE = 0.5
local TIDE_HEIGHT = 6
local FINAL_TIME = 11

-- ===============================================================
-- SIMULATION ENVIRONMENT
-- ===============================================================
-- The keys "hidro" and "mangue" are kept on purpose: TerraME visits the
-- Environment table with pairs(), so the key names decide the order in
-- which the two models run in each step, and that order changes the results.
local env = Environment {

    -- Dynamic models
    hidro  =  flood_model{
            finalTime = FINAL_TIME,
            seaLevelRiseRate = SEA_LEVEL_RISE_RATE
    },
    mangue =  mangrove_model{
            finalTime = FINAL_TIME,
            seaLevelRiseRate = SEA_LEVEL_RISE_RATE, tideHeight = TIDE_HEIGHT
    },

    -- Mean altitude per step,
    -- used to check that sea-level rise is working
    --MeanAltitude(cellSpace, attribute_names) {}
}


-- ===============================================================
-- MAPS
-- ===============================================================
-- Thematic maps of land use, soil and altitude

env:add(Event { action = landUseMap(cellSpace, land_use_classes, attribute_names.land_use) })
env:add(Event { action = soilMap(cellSpace, soil_classes, attribute_names.soil) })
env:add(Event { action = altitudeMap(cellSpace, attribute_names.altitude) })

-- Synchronise the cellular space at every step
env:add(Event { action = function() cellSpace:synchronize() end })


-- ===============================================================
-- RUN
-- ===============================================================
-- Run the whole simulation
-- (for step-by-step mode, uncomment the line below)
--env:add(Event { action = function() print("Press ENTER to continue...") io.read() end })

env:run()
