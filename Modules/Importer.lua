local TDKP_Importer =  {}
_G["TDKP_Importer"] = TDKP_Importer

local L = LibStub("AceLocale-3.0"):GetLocale("TurboDKP")

function TDKP_Importer:ParsePlayerDKP_CSV(data)
    local lines = splitString(data, "\n")
    local headerColNames = pack(strsplit(",", lines[1]))
    local headerPairs = {}
    local current = {}
    for i, colName in pairs(headerColNames) do
        if string.lower(colName) == "dkp" then
            if #current < 2 then
                table.insert(current, i)
            end
        elseif string.lower(colName) == "player" then
            if #current < 2 then
                table.insert(current, 1, i)
            end
        end
        if #current == 2 then
            table.insert(headerPairs, current)
            current = {}
        end
    end

    if #headerPairs == 0 then
        error("INVALID IMPORT DATA! Header data is malformed (must contain columns \"dkp\" and \"player\")")
    end

    local playerDKP = {}
    local numImported = 0
    for i, line in pairs(lines) do
        if i > 1 then
            local vals = pack(strsplit(",", line))
            for _, headerPair in pairs(headerPairs) do
                local player = vals[headerPair[1]]
                local dkp = tonumber(vals[headerPair[2]])
                if player ~= nil and player ~= "" and dkp ~= nil then
                    playerDKP[player] = dkp
                    numImported = numImported + 1
                end
            end
        end
    end
    return playerDKP, numImported
end

function TDKP_Importer:ImportPlayerData(data)
    local status, playerDKPOrErr, numImported = pcall(TDKP_Importer.ParsePlayerDKP_CSV, TDKP_Importer, data)
    if not status then
        print(TDKP.CHAT_PREFIX_COLORED .. playerDKPOrErr)
        return
    end

    TDKP.db.factionrealm.playerDKP = playerDKPOrErr

    for _, itemAwarded in pairs(TDKP.db.factionrealm.itemsAwarded) do
        if TDKP.db.factionrealm.playerDKP[itemAwarded["player"]] ~= nil then
            TDKP.db.factionrealm.playerDKP[itemAwarded["player"]] = TDKP.db.factionrealm.playerDKP[itemAwarded["player"]] - itemAwarded["cost"]
        end
    end

    print(TDKP.CHAT_PREFIX_COLORED .. "Imported " .. numImported .. " player dkp values!")
end
