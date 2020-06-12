local TDKP_Parser =  {}
_G["TDKP_Parser"] = TDKP_Parser

local L = LibStub("AceLocale-3.0"):GetLocale("TurboDKP")

function TDKP_Parser:ParseInputIntoTokensAndItems(input)
    local items = {}
    for itemLink in string.gmatch(input, ITEM_LINK_REGEX) do
        local itemId = GetItemInfoInstant(itemLink)
        local itemName = GetItemInfo(itemId)
        if itemId ~= nil and itemName ~= nil then
            table.insert(items, {
                ["itemId"] = itemId,
                ["itemName"] = itemName,
                ["itemLink"] = itemLink,
            })
        end
    end
    local inputWithoutItems = RemoveItemsAndTrim(input)
    local tokens = splitString(inputWithoutItems, "%s")
    if #tokens >= 1 then
        tokens[1] = string.lower(tokens[1])
    end
    return tokens, items
end

function TDKP_Parser:ShouldReadWhisper(msg, sender)
    local playerName = strsplit( "-", sender)
    if playerName == nil or not IsInRaid() or not UnitInRaid(playerName) then
        return false
    end

    msg = string.lower(RemoveItemsAndTrim(msg))

    if strfind(msg, "^!cancel") then
        return true
    end

    for _, spec in pairs(TDKP.ValidSpecs) do
        if strfind(msg, "^" .. spec .. "%s+[0-9]+") or strfind(msg, "^[0-9]+%s+" .. spec) then
            return true
        end
    end

    return false
end

function TDKP_Parser:ShouldHideSentWhisper(msg)
    return strfind(msg, "^%[" .. L["TurboDKP"] .. "%]") == 1
end

function TDKP_Parser:ParseWhisper(msg, sender)
    local playerName = strsplit("-", sender)
    local msgWithoutItemsLower = string.lower(RemoveItemsAndTrim(msg))

    -- Parse cancel bids
    if strfind(msgWithoutItemsLower, "^!cancel") then
        local itemLink = string.match(msg, ITEM_LINK_REGEX)
        if itemLink == nil then
            return false, "Must specify an item to cancel your bid for."
        end
        local cancelItemId = GetItemInfoInstant(itemLink)
        if cancelItemId == nil or TDKP.itemsCurrentlyBidding[cancelItemId] == nil then
            return false, "Cannot cancel bid! Unknown item or item not being bid on."
        end
        if TDKP.itemsCurrentlyBidding[cancelItemId]["closed"] then
            return false, "Cannot cancel bid! Bidding is closed for " .. TDKP.itemsCurrentlyBidding[cancelItemId]["itemLink"] .. "."
        end
        if TDKP.itemsCurrentlyBidding[cancelItemId]["bids"][playerName] == nil then
            return false, "Cannot cancel bid! You have no bids for " .. TDKP.itemsCurrentlyBidding[cancelItemId]["itemLink"] .. "."
        end
        TDKP.itemsCurrentlyBidding[cancelItemId]["bids"][playerName] = nil
        return true, "Bid cancelled! You have no bids for " .. TDKP.itemsCurrentlyBidding[cancelItemId]["itemLink"] .. "."
    end

    -- Get all items being bid on
    local itemsBeingBidOn = filter(function(_, bidData)
        return not bidData["closed"]
    end, TDKP.itemsCurrentlyBidding, true)

    if #itemsBeingBidOn == 0 then
        return false, "There are no items being bid on currently!"
    end

    -- Parse spec and bid amount
    local spec, bidAmount
    for _, validSpec in pairs(TDKP.ValidSpecs) do
        local tspec, tbidAmount = strmatch(msgWithoutItemsLower, "^(" .. validSpec .. ")%s+([0-9]+)")
        if tspec == nil or tbidAmount == nil then
            tbidAmount, tspec = strmatch(msgWithoutItemsLower, "^([0-9]+)%s+(" .. validSpec .. ")")
        end
        if tspec ~= nil and tbidAmount ~= nil then
            spec = tspec
            bidAmount = tonumber(tbidAmount)
        end
    end
    if spec == nil or bidAmount == nil then
        return false, "Invalid bid format! " .. TDKP:GetBidExample(itemsBeingBidOn[1]["itemLink"])
    end

    -- Can't bid below the min
    if bidAmount < TDKP.db.factionrealm.minBid then
        return false, "Invalid bid amount! Minimum bid is " .. TDKP.db.factionrealm.minBid
    end

    -- DKP for player check (but only if we know their DKP)
    if TDKP.db.factionrealm.playerDKP[playerName] ~= nil and TDKP.db.factionrealm.playerDKP[playerName] < bidAmount then
        return false, "Insufficient DKP! You have " .. TDKP.db.factionrealm.playerDKP[playerName] .. " DKP."
    end

    -- Get item id from whisper (or from TDKP.itemsCurrentlyBidding if there is only 1 item being bid on)
    local itemLink = strmatch(msg, ITEM_LINK_REGEX)
    local bidItemId
    if itemLink == nil then
        if #itemsBeingBidOn == 1 then
            bidItemId = itemsBeingBidOn[1]["itemId"]
        else
            return false, "Invalid bid format! Must specify an item to bid on. " .. TDKP:GetBidExample(itemsBeingBidOn[1]["itemLink"])
        end
    else
        bidItemId = GetItemInfoInstant(itemLink)
    end

    if bidItemId == nil then
        return false, "Invalid bid format! Must specify an item to bid on. " .. TDKP:GetBidExample(itemsBeingBidOn[1]["itemLink"])
    end

    -- Ensure bidding is not closed on the item
    if TDKP.itemsCurrentlyBidding[bidItemId] == nil or TDKP.itemsCurrentlyBidding[bidItemId]["closed"] then
        local errMsg = "That item is not currently being bid on! Items up for bidding: " ..
                table.concat(map(function(_, item) return item["itemLink"] end, itemsBeingBidOn), "")
        return false, errMsg
    end

    -- Get highest guild rank of character and all alts from GRM
    local senderRank
    if GRM_G and GRM_GuildMemberHistory_Save and
            GRM_GuildMemberHistory_Save[GRM_G.F] and
            GRM_GuildMemberHistory_Save[GRM_G.F][GRM_G.guildName] and
            GRM_GuildMemberHistory_Save[GRM_G.F][GRM_G.guildName][sender] then
        local playerAndAlts = { sender }
        local playerGRM = GRM_GuildMemberHistory_Save[GRM_G.F][GRM_G.guildName][sender]
        if playerGRM["alts"] then
            for _, alt in pairs(playerGRM["alts"]) do
                table.insert(playerAndAlts, alt[1])
            end
        end
        senderRank = GuildControlGetNumRanks()
        for _, char in pairs(playerAndAlts) do
            local charGRM = GRM_GuildMemberHistory_Save[GRM_G.F][GRM_G.guildName][char]
            if charGRM["rankIndex"] + 1 < senderRank then
                senderRank = charGRM["rankIndex"] + 1
            end
        end
    end

    -- Try to get rank the wow api way if it fails in GRM
    if senderRank == nil then
        for i = 1, GetNumGuildMembers() do
            local name, _, rank = GetGuildRosterInfo(i)
            if name == sender then
                senderRank = rank
                break
            end
        end
    end

    -- Player cannot be found in GRM or guild so they have no guild rank
    if senderRank == nil then
        return false, "Must be in guild to bid on items!"
    end

    return true, {
        ["player"] = playerName,
        ["spec"] = spec,
        ["bidAmount"] = bidAmount,
        ["itemId"] = bidItemId,
        ["rank"] = senderRank,
        ["rankName"] = GuildControlGetRankName(senderRank),
        ["class"] = GetPlayerClass(playerName),
        ["msg"] = msg,
    }
end
