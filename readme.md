# BR-MANGUE

## Overview
**BR-MANGUE** is a spatially explicit cellular automata model designed to simulate the impacts of sea-level rise (SLR) on mangrove ecosystems. Developed as a virtual laboratory, it helps to understand the patterns of resistance, migration, and decline of mangrove forests facing climate change scenarios, particularly in coastal zones with complex anthropic occupation.

## Conceptual Model
The model stratifies the relevant aspects for mangrove persistence into four main components:
* **Sea-Level Rise (NMRM):** Simulates the advance of the water column over the continent and its impacts, such as permanent inundation and erosion.
* **Land Use and Occupation:** Considers different land cover types as potential areas for mangrove colonization or as anthropic/natural barriers that prevent migration.
* **Environmental Restrictions:** Evaluates the suitability of the substrate, considering factors like soil type (e.g., indiscriminate mangrove soils) and sediment accretion processes.
* **Mangrove Dynamics:** Integrates the interactions between SLR, tidal influence area (AIM), land cover, and environmental constraints to determine if the mangrove will resist, migrate, or decline.

## Technologies
* **TerraME:** A programming environment for spatial dynamical modeling, supporting cellular automata and integrated with 2D cellular spaces.
* **Lua:** The model's source code is implemented using Lua, an open-source, lightweight, and robust programming language.
* **TerraView / GIS:** Used for geographic database organization and cellular space creation.

## Input Data Requirements
To run simulations, the model requires a cellular space containing the following attributes for each cell:
* **Land Cover / Use:** Initial state of the cell (e.g., mangrove, water, anthropic area, terrestrial vegetation).
* **Altimetry:** Minimum altitude values, often derived from Digital Elevation Models (DEM).
* **Soil Classes:** To determine if the soil is suitable for mangrove colonization.
* **Tidal Influence Area (AIM):** Defined by the local tide height.

## Key Mechanisms
The model's transition rules incorporate complex biophysical interactions:
* **Water Flux:** Determined by the water column height relative to adjacent cells.
* **Vertical & Longitudinal Accretion:** Simulates the formation of new mud banks and increases in sediment height, which can counteract sea-level rise.
* **Migration:** Mangroves can colonize new areas if the tidal influence shifts and no anthropic or natural barriers exist.

## Case Studies
The model has been successfully applied to simulate sea-level rise impacts in vulnerable Brazilian coastal zones, such as **Maranhão Island** and the **Baixada Maranhense** (a Ramsar site).

## References
* Bezerra, D. S. (2014). *Modelagem da dinâmica do manguezal frente à elevação do nível do mar*. INPE.
* Bezerra, D. S. et al. (2014). *Simulating Sea-Level Rise Impacts on Mangrove Ecosystem adjacent to Anthropic Areas: the case of Maranhão Island, Brazilian Northeast*. Pan-American Journal of Aquatic Sciences.
* Bezerra, D. S., Costa, S. S., Mochel, F. R., Santos, F. A. S., Barros, K. A. L., Sousa, F. M., Bezerra, J. S. (2025). *Spatially Explicit Modeling for Impacts of Sea-Level Rise in the Baixada Maranhense, Brazilian Legal Amazon*. In: *Dynamics of the Oceans - Variability, Hydrological Cycles, and Sea Level Change*. IntechOpen. https://doi.org/10.5772/intechopen.1012210

## Code layout and naming

| File | Content |
|------|---------|
| `manguebr.lua` | interactive run with maps (TerraME GUI) |
| `golden.lua` | headless run that writes the reference CSVs (see below) |
| `models/flood.lua` | flood (hydrology) model: sea-level rise, flux diffusion, flooding |
| `models/mangrove.lua` | mangrove model: soil and land-use migration, vertical accretion |
| `models/utils.lua` | mean altitude and a sea-level test model |
| `visualization/maps.lua` | land-use, soil and altitude maps |

The code is in English. The **attribute names of the data stay in Portuguese**:
`uso`, `solo`, `alt` (and `col`, `row`) in the Maranhão Island cells, and
`Uso`, `Solo`, `Altitude`, `Col`, `Lin` in `data/teste_*`. They are written in
one place per script, the `attribute_names` table (plus `cell_xy` for the
coordinates in `golden.lua`); the models and the header of the CSV files
(`col,row,uso,solo,alt`) use that table, so renaming the data means changing
only those lines. Class codes are the codes of
the data:

| Code | Land-use class | Original name |
|-----:|----------------|---------------|
| 1 | `MANGROVE` | Mangue |
| 2 | `TERRESTRIAL_VEGETATION` | Vegetação terrestre |
| 3 | `SEA` | Mar |
| 4 | `ANTHROPIZED_AREA` | Área antropizada |
| 5 | `BARE_SOIL` | Solo descoberto |
| 6 | `FLOODED_SOIL` | Solo inundado |
| 7 | `FLOODED_ANTHROPIZED_AREA` | Área antropizada inundada |
| 8 | `MIGRATED_MANGROVE` | Mangue migrado |
| 9 | `FLOODED_MANGROVE` | Mangue inundado |
| 10 | `FLOODED_TERRESTRIAL_VEGETATION` | Vegetação terrestre inundada |

| Code | Soil class | Original name |
|-----:|------------|---------------|
| 0 | `RIVER_CHANNEL` | Canal fluvial |
| 1 | `RIVERBED` (no transition rule) | Leito de rio |
| 2 | `PODZOLIC` (no transition rule) | Podzólico |
| 3 | `MANGROVE` (mangrove mud) | Mangue |
| 4 | `OTHER` | Outros |
| 9 | `MIGRATED_MANGROVE` (migrated mangrove mud) | Mangue migrado |

The names are shared with the Python re-implementation
[`brmangue-dissmodel`](https://github.com/DisSModel/brmangue-dissmodel) (0.5.0 or
later), so the two codes can be compared side by side; Lua uses `camelCase`,
Python `snake_case`:

| Concept | Lua (this repository) | Python (brmangue-dissmodel) |
|---|---|---|
| models | `Flood` (`models/flood.lua`), `Mangrove` (`models/mangrove.lua`) | `FloodModel`, `MangroveModel` |
| sea-level rise per step (m) | `seaLevelRiseRate` | `sea_level_rise_rate` |
| tide height (m) | `tideHeight` | `tide_height` |
| sea level, tidal influence zone | `seaLevel`, `influenceZone` | `sea_level`, `influence_zone` |
| land-use classes | `land_use_classes.MIGRATED_MANGROVE`… | `MIGRATED_MANGROVE`… |
| soil classes | `soil_classes.MIGRATED_MANGROVE`… | `SOIL_MIGRATED_MANGROVE`… |

In `Environment{...}` the two models keep the keys `hidro` and `mangue`.
TerraME visits that table with `pairs()`, so the key names decide the order in
which the models run in each step, and that order changes the results;
renaming them could change the reference outputs.

## Running headless with Docker (golden files)

`golden.lua` runs `hidro` + `mangue` without a graphical interface and writes the
`uso`, `solo` and `alt` of every cell, the initial state first (`step_01.csv` is the
initial state and `step_NN.csv` the state after NN-1 steps, so `FINAL=19` writes 20 files). These files are the reference used to validate
[`brmangue-dissmodel`](https://github.com/DisSModel/brmangue-dissmodel).

```bash
make golden TAXA=0.05 FINAL=19                         # baseline  -> golden/
make golden TAXA=0.5 FINAL=11 OUT=golden_flood         # flooding  -> golden_flood/
make golden IMAGE=profsergiocosta/terrame-luccme:0.4.2 # pin the image
```

It uses the [`terrame-docker`](https://github.com/LambdaGeo/terrame-docker) image
(TerraME 2.0.1) and downloads the Maranhão Island cells once (`make data`).

> **Note.** This code is an *adaptation* to TerraME 2.0 of the BR-MANGUE model
> (Bezerra, 2014); it is not the original published script. See
> `docs/model-fidelity.md` in `brmangue-dissmodel` for how the rules relate to
> the thesis.
