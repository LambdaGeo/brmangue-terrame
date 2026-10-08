-- Headless driver: runs BR-MANGUE (hidro + mangue) on the Maranhão Island cut-out and
-- writes uso/solo/alt of every cell: step_01.csv is the INITIAL state, step_02.csv the
-- state after the first step, and so on (the convention of the golden files used by
-- brmangue-dissmodel).
--
-- Parameters (environment variables):  TAXA (m/step, default 0.05)  FINAL (steps, default 19)
--   MARE (tide height, default 6)  OUT (output dir, default out)  SHP (shapefile)
-- Use `make golden` (Docker) rather than calling this file directly.
import("gis")
require("models/mangue")
require("models/hidro")
require("models/utils")

local TAXA   = tonumber(os.getenv("TAXA"))   or 0.05
local FINAL  = tonumber(os.getenv("FINAL"))  or 19
local MARE   = tonumber(os.getenv("MARE"))   or 6
local OUT    = os.getenv("OUT") or "out"
local SHP    = os.getenv("SHP") or "data/ilha/elevacao_pol.shp"

local nomes_atributos = { uso = "uso", solo = "solo", alt = "alt" }

tabela_usos = {
    MANGUE = {valor=1,cor={0,100,0},nome="Mangue"}, VEGETACAO_TERRESTRE={valor=2,cor={128,128,0},nome="Vegetação Terrestre"},
    MAR={valor=3,cor={0,0,139},nome="Mar"}, AREA_ANTROPIZADA={valor=4,cor={255,215,0},nome="Área Antropizada"},
    SOLO_DESCOBERTO={valor=5,cor={255,222,173},nome="Solo Descoberto"}, SOLO_INUNDADO={valor=6,cor={0,0,0},nome="Solo Inundado"},
    AREA_ANTROPIZADA_INUNDADA={valor=7,cor={50,50,50},nome="Área Antropizada Inundada"}, MANGUE_MIGRADO={valor=8,cor={0,255,0},nome="Mangue Migrado"},
    MANGUE_INUNDADO={valor=9,cor={255,0,0},nome="Mangue Inundado"}, VEGETACAO_TERRESTRE_INUNDADA={valor=10,cor={0,0,0},nome="Vegetação Terrestre Inundada"}
}
tabela_solos = {
    CANAL_FLUVIAL={valor=0,cor={0,0,255},nome="Canal Fluvial"}, MANGUE={valor=3,cor={0,100,0},nome="Mangue"},
    MANGUE_MIGRADO={valor=9,cor={34,139,34},nome="Mangue Migrado"}, OUTROS={valor=4,cor={0,0,0},nome="Outros"}
}

local projeto = Project { file = "recorte.qgs", cell_usos = SHP, clean = true }
local cs = CellularSpace { project = projeto, layer = "cell_usos", xy = { "col", "row" }, select = nomes_atributos }
cs:createNeighborhood { strategy = "moore", self = false }
cs:synchronize()

local hidro_model  = Hidro(cs, tabela_usos, nomes_atributos)
local mangue_model = Mangue(cs, tabela_solos, tabela_usos, nomes_atributos)

local function dump(n)
    local f = io.open(string.format("%s/step_%02d.csv", OUT, n), "w")
    f:write("col,row,uso,solo,alt\n")
    forEachCell(cs, function(c)
        f:write(string.format("%.1f,%.1f,%.1f,%.1f,%.17g\n", c.col, c.row, c[nomes_atributos.uso], c[nomes_atributos.solo], c[nomes_atributos.alt]))
    end)
    f:close()
end

os.execute("mkdir -p " .. OUT)
-- In every cycle the dump runs BEFORE the models step, so cycle 1 captures the initial
-- state (step_01) and cycle n the state after n-1 steps. The models therefore run
-- FINAL+1 cycles so that step_(FINAL+1).csv is the state after FINAL steps.
local k = 0
local env = Environment {
    hidro  = hidro_model{ finalTime = FINAL + 1, taxaElevacaoMar = TAXA },
    mangue = mangue_model{ finalTime = FINAL + 1, taxaElevacaoMar = TAXA, alturaMare = MARE },
}
env:add(Event { action = function() cs:synchronize() end })
env:add(Event { action = function() k = k + 1; dump(k) end })
env:run()
print("files written:", k)
