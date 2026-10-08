function computeMeanAltitude(cellSpace, attribute_names)
    local count = 0
    local altitudeSum = 0
    local altitudeAttr = attribute_names.altitude



    forEachCell(cellSpace, function(cell)
        if cell[altitudeAttr] then
            altitudeSum = altitudeSum + cell[altitudeAttr]
            count = count + 1
        end
    end)

    if count == 0 then
        return 0
    end

    return altitudeSum / count
end


function MeanAltitude(cellSpace, attribute_names)
    return Model {
        start = 1,
        finalTime = 100,

        -- Pass the arguments through
        mean_altitude = computeMeanAltitude(cellSpace, attribute_names),

        execute = function(model, event)
            local time = event:getTime()
            model.mean_altitude = computeMeanAltitude(cellSpace, attribute_names)
            print("Mean altitude:", time, model.mean_altitude)
        end,

        init = function(model)


            forEachCell(cellSpace, function(cell)
                --cell["Uso"] = 3
                --cell["Altitude"] = 0
            end)

            model.timer = Timer { Event { action = model } }
        end
    }
end


-- for testing only

SeaLevelRise = Model{
	seaLevelRiseRate = 0.011,
	tideHeight       =  6, -- tide height (Ferreira, 1988)
	finalTime        = 88,

    coefficientA    = 1.693,  -- intercept of the Alongi equation
    coefficientB    = 0.939,  -- slope of the Alongi equation
    seaLevel = 0,
    accretionRate_m = 0,

	execute = function(model, event)
        local time = event:getTime()


        model.seaLevel = time * model.seaLevelRiseRate
        -- Equation proposed by Alongi (2008) with R2 = 0,704 and p < 0,001
        model.accretionRate_m = model.coefficientA/1000 + (model.coefficientB * model.seaLevel) -- 1.693 + 0.939 * seaLevel_mm / 1000

        model.influenceZone = model.tideHeight + model.seaLevel
        print (time+2012, string.format("%.2f", model.seaLevel ),  string.format("%.2f", model.accretionRate_m), string.format("%.2f", model.influenceZone))
	end,
	init = function(model)



		model.timer = Timer{
			Event{action = model},
		}
	end
}
