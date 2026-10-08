# BR-MANGUE

## Overview
**BR-MANGUE** is a spatially explicit cellular automata model designed to simulate the impacts of sea-level rise (SLR) on mangrove ecosystems [1, 2]. Developed as a virtual laboratory, it helps to understand the patterns of resistance, migration, and decline of mangrove forests facing climate change scenarios, particularly in coastal zones with complex anthropic occupation [1, 3, 4].

## Conceptual Model
The model stratifies the relevant aspects for mangrove persistence into four main components [5, 6]:
* **Sea-Level Rise (NMRM):** Simulates the advance of the water column over the continent and its impacts, such as permanent inundation and erosion [7, 8].
* **Land Use and Occupation:** Considers different land cover types as potential areas for mangrove colonization or as anthropic/natural barriers that prevent migration [9-11].
* **Environmental Restrictions:** Evaluates the suitability of the substrate, considering factors like soil type (e.g., indiscriminate mangrove soils) and sediment accretion processes [12, 13].
* **Mangrove Dynamics:** Integrates the interactions between SLR, tidal influence area (AIM), land cover, and environmental constraints to determine if the mangrove will resist, migrate, or decline [14, 15].

## Technologies
* **TerraME:** A programming environment for spatial dynamical modeling, supporting cellular automata and integrated with 2D cellular spaces [16, 17].
* **Lua:** The model's source code is implemented using Lua, an open-source, lightweight, and robust programming language [18].
* **TerraView / GIS:** Used for geographic database organization and cellular space creation [19].

## Input Data Requirements
To run simulations, the model requires a cellular space containing the following attributes for each cell:
* **Land Cover / Use:** Initial state of the cell (e.g., mangrove, water, anthropic area, terrestrial vegetation) [20].
* **Altimetry:** Minimum altitude values, often derived from Digital Elevation Models (DEM) [21, 22].
* **Soil Classes:** To determine if the soil is suitable for mangrove colonization [23].
* **Tidal Influence Area (AIM):** Defined by the local tide height [21].

## Key Mechanisms
The model's transition rules incorporate complex biophysical interactions [24-28]:
* **Water Flux:** Determined by the water column height relative to adjacent cells [24, 29].
* **Vertical & Longitudinal Accretion:** Simulates the formation of new mud banks and increases in sediment height, which can counteract sea-level rise [30-32].
* **Migration:** Mangroves can colonize new areas if the tidal influence shifts and no anthropic or natural barriers exist [26, 27].

## Case Studies
The model has been successfully applied to simulate sea-level rise impacts in vulnerable Brazilian coastal zones, such as **Maranhão Island** [1, 3, 33] and the **Baixada Maranhense** (a Ramsar site) [34, 35].

## References
* Bezerra, D. S. (2014). *Modelagem da dinâmica do manguezal frente à elevação do nível do mar*. INPE [36, 37].
* Bezerra, D. S. et al. (2014). *Simulating Sea-Level Rise Impacts on Mangrove Ecosystem adjacent to Anthropic Areas: the case of Maranhão Island, Brazilian Northeast*. Pan-American Journal of Aquatic Sciences [33, 38].
* Bezerra, D. S. et al. (2025). *Spatially Explicit Modeling for Impacts of Sea-Leve

## Running headless with Docker (golden files)

`golden.lua` runs `hidro` + `mangue` without a graphical interface and writes the
`uso`, `solo` and `alt` of every cell, the initial state first (`step_01.csv` is the
state before the first step). These files are the reference used to validate
[`brmangue-dissmodel`](https://github.com/DisSModel/brmangue-dissmodel).

```bash
make golden TAXA=0.05 FINAL=18                         # baseline  -> golden/
make golden TAXA=0.5 FINAL=11 OUT=golden_flood         # flooding  -> golden_flood/
make golden IMAGE=profsergiocosta/terrame-luccme:0.4.2 # pin the image
```

It uses the [`terrame-docker`](https://github.com/LambdaGeo/terrame-docker) image
(TerraME 2.0.1) and downloads the Maranhão Island cells once (`make data`).

> **Note.** This code is an *adaptation* to TerraME 2.0 of the BR-MANGUE model
> (Bezerra, 2014); it is not the original published script. See
> `docs/model-fidelity.md` in `brmangue-dissmodel` for how the rules relate to
> the thesis.
