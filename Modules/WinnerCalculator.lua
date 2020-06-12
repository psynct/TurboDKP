local TDKP_WinnerCalculator =  {}
_G["TDKP_WinnerCalculator"] = TDKP_WinnerCalculator

local L = LibStub("AceLocale-3.0"):GetLocale("TurboDKP")

function TDKP_WinnerCalculator:ApplyBiddingCaps(bid1, bid2, rankCap1, rankCap2, specCap1, specCap2)
    -- don't have to worry about -1 cap values this way
    if rankCap1 < 0 then
        rankCap1 = 1e12
    end
    if rankCap2 < 0 then
        rankCap2 = 1e12
    end
    if specCap1 < 0 then
        specCap1 = 1e12
    end
    if specCap2 < 0 then
        specCap2 = 1e12
    end

    if rankCap1 ~= rankCap2 or specCap1 ~= specCap2 then -- some of caps are different
        if specCap1 == specCap2 then -- only rank caps are different
            if rankCap1 < rankCap2 then
                local bid1capped = min(bid1["bidAmount"], rankCap1)
                return bid1capped, bid2["bidAmount"]
            else
                local bid2capped = min(bid2["bidAmount"], rankCap2)
                return bid1["bidAmount"], bid2capped
            end
        elseif rankCap1 == rankCap2 then -- only spec caps are different
            if specCap1 < specCap2 then
                local bid1capped = min(bid1["bidAmount"], specCap1)
                return bid1capped, bid2["bidAmount"]
            else
                local bid2capped = min(bid2["bidAmount"], specCap2)
                return bid1["bidAmount"], bid2capped
            end
        else -- both caps are different
            if rankCap1 < rankCap2 and specCap1 < specCap2 then -- constrain bid1 by min of both caps
                local bid1capped = min(bid1["bidAmount"], min(rankCap1, specCap1))
                return bid1capped, bid2["bidAmount"]
            elseif rankCap1 < rankCap2 and specCap1 > specCap2 then
                if rankCap1 == specCap2 then -- min of cap for each bid is the same
                    return bid1["bidAmount"], bid2["bidAmount"]
                elseif rankCap1 < specCap2 then -- constrain bid1 because cap is lower
                    local bid1capped = min(bid1["bidAmount"], rankCap1)
                    return bid1capped, bid2["bidAmount"]
                elseif rankCap1 > specCap2 then -- constrain bid2 because cap is lower
                    local bid2capped = min(bid2["bidAmount"], specCap2)
                    return bid1["bidAmount"], bid2capped
                end
            elseif rankCap1 > rankCap2 and specCap1 < specCap2 then
                if rankCap2 == specCap1 then -- min of cap for each bid is the same
                    return bid1["bidAmount"], bid2["bidAmount"]
                elseif rankCap2 < specCap1 then -- constrain bid2 because cap is lower
                    local bid2capped = min(bid2["bidAmount"], rankCap2)
                    return bid1["bidAmount"], bid2capped
                elseif rankCap2 > specCap1 then -- constrain bid1 because cap is lower
                    local bid1capped = min(bid1["bidAmount"], specCap1)
                    return bid1capped, bid2["bidAmount"]
                end
            elseif rankCap1 > rankCap2 and specCap1 > specCap2 then -- constrain bid2 by min of both caps
                local bid2capped = min(bid2["bidAmount"], min(rankCap2, specCap2))
                return bid1["bidAmount"], bid2capped
            end
        end
    else -- caps are the same, no need to cap either bid
        return bid1["bidAmount"], bid2["bidAmount"]
    end
end

-- Topological sorting is needed for this problem. The ApplyBiddingCaps function has different comparison results
-- depending on which two bids are being compared. This will insert all of the bids into a graph with
-- "equals", "decreasing", and "increasing" costs form each bid to every other bid. It then figures out the top bid by
-- finding the bids with no "increasing" costs. Of those it finds the bid with the most "equals" costs (if any exist).
function TDKP_WinnerCalculator:DetermineWinningBid(itemId)
    local item = TDKP.itemsCurrentlyBidding[itemId]

    -- Print out all bids and the player whispers (just in case something goes wrong and you want to see the summary of bids)
    print("--------------------")
    print(TDKP.CHAT_PREFIX_COLORED .. item["itemLink"])
    for _, bid in pairs(item["bids"]) do
        print(TDKP.CHAT_PREFIX_COLORED .. string.join(" ", GetPlayerNameWithColor(bid["player"]), bid["rankName"], bid["spec"], bid["bidAmount"]))
    end

    local bidGraph = {}
    local numBids = 0
    -- Bulid graph of all bids
    for player1, bidData1 in pairs(item["bids"]) do
        if not bidGraph[player1] then
            bidGraph[player1] = {bid = bidData1, equals = {}, decreasing = {}, increasing = {}}
        end
        numBids = numBids + 1
        for player2, bidData2 in pairs(item["bids"]) do
            if not bidGraph[player2] then
                bidGraph[player2] = {bid = bidData2, equals = {}, decreasing = {}, increasing = {}}
            end
            if player1 ~= player2 then
                local rankCap1 = TDKP.db.factionrealm.guildRankBidCaps[bidData1["rank"]]
                local rankCap2 = TDKP.db.factionrealm.guildRankBidCaps[bidData2["rank"]]
                local specCap1 = TDKP.db.factionrealm.specBidCaps[bidData1["spec"]]
                local specCap2 = TDKP.db.factionrealm.specBidCaps[bidData2["spec"]]
                local bid1capped, bid2capped = TDKP_WinnerCalculator:ApplyBiddingCaps(bidData1, bidData2, rankCap1, rankCap2, specCap1, specCap2)
                local costs12 = { bid1capped, bid2capped }
                local costs21 = { bid2capped, bid1capped }
                if bid1capped == bid2capped then
                    bidGraph[player1]["equals"][player2] = costs12
                    bidGraph[player2]["equals"][player1] = costs21
                elseif bid1capped < bid2capped then
                    bidGraph[player1]["increasing"][player2] = costs12
                    bidGraph[player2]["decreasing"][player1] = costs21
                elseif bid1capped > bid2capped then
                    bidGraph[player1]["decreasing"][player2] = costs12
                    bidGraph[player2]["increasing"][player1] = costs21
                end
            end
        end
    end

    -- return early if there are no bids
    if numBids == 0 then
        print("--------------------")
        SendChatMessage(TDKP.CHAT_PREFIX .. "No bids on " .. item["itemLink"], "RAID_WARNING")
        return
    end

    -- get top nodes and calculate num of costs for each type
    local numTopNodes = 0
    local topNodes = {}
    local hasEqualsInTopNodes = false
    for player, node in pairs(bidGraph) do
        local numDecreasing = 0
        for _, _ in pairs(node["decreasing"]) do
            numDecreasing = numDecreasing + 1
        end
        node["numDecreasing"] = numDecreasing

        local numIncreasing = 0
        for _, _ in pairs(node["increasing"]) do
            numIncreasing = numIncreasing + 1
        end
        node["numIncreasing"] = numIncreasing

        local numEquals = 0
        for _, _ in pairs(node["equals"]) do
            numEquals = numEquals + 1
        end
        node["numEquals"] = numEquals

        if numIncreasing == 0 then
            topNodes[player] = node
            numTopNodes = numTopNodes + 1
            if numEquals > 0 then
                hasEqualsInTopNodes = true
            end
        end
    end

    -- Something has gone horribly wrong and no top nodes were found
    if numTopNodes == 0 then
        error("Found no top nodes, cannot determine winner")
    end

    -- Get the top node (either node with most "equals" costs or the only node in top nodes table)
    local bestTopNode
    if hasEqualsInTopNodes then
        local bestEqualsNum = 0
        for _, node in pairs(topNodes) do
            if node["numEquals"] > bestEqualsNum then
                bestEqualsNum = node["numEquals"]
                bestTopNode = node
            end
        end
    else
        if numTopNodes == 1 then
            for _, node in pairs(topNodes) do
                bestTopNode = node
                break
            end
        else
            error("Found more than 1 top node when there should only be 1")
        end
    end

    -- Something has gone horribly wrong and could not find a best top node
    if bestTopNode == nil then
        error("Could not find a best top node")
    end

    -- If top node has "equals" costs then we need to get all bids that are equal and tell all those players to roll
    if bestTopNode["numEquals"] > 0 then
        local cost = 1e12
        local playersTied = { bestTopNode["bid"]["player"] }
        for player, costs in pairs(bestTopNode["equals"]) do
            table.insert(playersTied, player)
            if costs[2] < cost then
                cost = costs[2]
            end
        end
        print(TDKP.CHAT_PREFIX_COLORED .. "Tied: " .. table.concat(map(function (_, player)
            return GetPlayerNameWithColor(player)
        end, playersTied, true), ", ") .. " for " .. cost .. " dkp.")
        print("--------------------")
        SendChatMessage(TDKP.CHAT_PREFIX .. "Bids tied. Roll " .. table.concat(playersTied, ", ") .. " on " .. item["itemLink"] .. " for " .. cost .. " dkp.", "RAID_WARNING")
        for _, player in pairs(playersTied) do
            SendChatMessage(TDKP.CHAT_PREFIX .. "You tied with another bid. Roll on " .. item["itemLink"] .. " for " .. cost .. " dkp.", "WHISPER", nil, player)
        end
    else -- This is the winning bid, but need to calculate the greatest "decreasing" node compared to bid and add one for cost
        local cost
        if bestTopNode["numDecreasing"] > 0 then
            cost = 0
            for player, costs in pairs(bestTopNode["decreasing"]) do
                if costs[2] > cost then
                    cost = costs[2]
                end
            end
            cost = cost + 1
        else -- If no "less" bids, that means it is the only bid and the cost is the minimum
            cost = TDKP.db.factionrealm.minBid
        end
        local winningPlayer = bestTopNode["bid"]["player"]
        print(TDKP.CHAT_PREFIX_COLORED .. "|cFF00FF00Winner|r: " .. GetPlayerNameWithColor(winningPlayer) .. " for " .. cost .. " dkp.")
        print("--------------------")
        TDKP_UI:ShowAwardWinningBidDialog(winningPlayer, cost, item)
        --SendChatMessage(TDKP.CHAT_PREFIX .. "Congrats " .. bestTopNode["bid"]["player"] .. " on " .. item["itemLink"] .. " for " .. cost .. " dkp!", "RAID_WARNING")
    end
end
