-- Headless driver: runs BR-MANGUE (flood + mangrove models) on the Maranhão Island cut-out and
-- writes uso/solo/alt of every cell: step_01.csv is the INITIAL state, step_02.csv the
-- state after the first step, and so on (the convention of the golden files used by
-- brmangue-dissmodel).
--
-- Parameters (environment variables):  TAXA (m/step, default 0.05)  FINAL (steps, default 19)
--   MARE (tide height, default 6)  OUT (output dir, default out)  SHP (shapefile)
-- Use `make golden` (Docker) rather than calling this file directly.
import("gis")
require("models/mangrove")
require("models/flood")
require("models/utils")

local TAXA   = tonumber(os.getenv("TAXA"))   or 0.05
local FINAL  = tonumber(os.getenv("FINAL"))  or 19
local MARE   = tonumber(os.getenv("MARE"))   or 6
local OUT    = os.getenv("OUT") or "out"
local SHP    = os.getenv("SHP") or "data/ilha/elevacao_pol.shp"

-- Field names of the data (Portuguese), written only here: the rest of the
-- script, the models and the CSV header use these tables.
local attribute_names = { land_use = "uso", soil = "solo", altitude = "alt" }
local cell_xy         = { x = "col", y = "row" }

land_use_classes = {
    MANGROVE={value=1,color={0,100,0},name="Mangrove"}, TERRESTRIAL_VEGETATION={value=2,color={128,128,0},name="Terrestrial vegetation"},
    SEA={value=3,color={0,0,139},name="Sea"}, ANTHROPIZED_AREA={value=4,color={255,215,0},name="Anthropized area"},
    BARE_SOIL={value=5,color={255,222,173},name="Bare soil"}, FLOODED_SOIL={value=6,color={0,0,0},name="Flooded soil"},
    FLOODED_ANTHROPIZED_AREA={value=7,color={50,50,50},name="Flooded anthropized area"}, MIGRATED_MANGROVE={value=8,color={0,255,0},name="Migrated mangrove"},
    FLOODED_MANGROVE={value=9,color={255,0,0},name="Flooded mangrove"}, FLOODED_TERRESTRIAL_VEGETATION={value=10,color={0,0,0},name="Flooded terrestrial vegetation"}
}
soil_classes = {
    RIVER_CHANNEL={value=0,color={0,0,255},name="River channel"}, RIVERBED={value=1,color={102,153,204},name="Riverbed"},
    PODZOLIC={value=2,color={170,170,170},name="Podzolic"}, MANGROVE={value=3,color={0,100,0},name="Mangrove mud"},
    MIGRATED_MANGROVE={value=9,color={34,139,34},name="Migrated mangrove mud"}, OTHER={value=4,color={0,0,0},name="Other"}
}

local project = Project { file = "recorte.qgs", cell_usos = SHP, clean = true }
local cs = CellularSpace { project = project, layer = "cell_usos", xy = { cell_xy.x, cell_xy.y }, select = attribute_names }
cs:createNeighborhood { strategy = "moore", self = false }
cs:synchronize()

local flood_model    = Flood(cs, land_use_classes, attribute_names)
local mangrove_model = Mangrove(cs, soil_classes, land_use_classes, attribute_names)

local function dump(n)
    local f = io.open(string.format("%s/step_%02d.csv", OUT, n), "w")
    f:write(string.format("%s,%s,%s,%s,%s\n", cell_xy.x, cell_xy.y,
        attribute_names.land_use, attribute_names.soil, attribute_names.altitude))
    forEachCell(cs, function(c)
        f:write(string.format("%.1f,%.1f,%.1f,%.1f,%.17g\n", c[cell_xy.x], c[cell_xy.y], c[attribute_names.land_use], c[attribute_names.soil], c[attribute_names.altitude]))
    end)
    f:close()
end

os.execute("mkdir -p " .. OUT)
-- In every cycle the dump runs BEFORE the models step, so cycle 1 captures the initial
-- state (step_01) and cycle n the state after n-1 steps. The models therefore run
-- FINAL+1 cycles so that step_(FINAL+1).csv is the state after FINAL steps.
local k = 0
-- The keys "hidro" and "mangue" are kept on purpose: TerraME visits the Environment
-- table with pairs(), so the key names decide the order in which the two models run
-- in each step, and that order changes the results.
local env = Environment {
    hidro  = flood_model{ finalTime = FINAL + 1, seaLevelRiseRate = TAXA },
    mangue = mangrove_model{ finalTime = FINAL + 1, seaLevelRiseRate = TAXA, tideHeight = MARE },
}
env:add(Event { action = function() cs:synchronize() end })
env:add(Event { action = function() k = k + 1; dump(k) end })
env:run()
print("files written:", k)
