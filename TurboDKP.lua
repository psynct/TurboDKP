TDKP = LibStub("AceAddon-3.0"):NewAddon("TurboDKP", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
TDKP.Dialog = LibStub("AceConfigDialog-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("TurboDKP")

TDKP.VERSION = 100
TDKP.ICON = "Interface/Icons/inv_misc_ticket_tarot_stack_01"

TDKP.BossIdsToNames = {
	["0"] = L["Trash"],
	["6109"] = L["Azuregos"],
	["12397"] = L["Lord Kazzak"],
	["14889"] = L["Emeriss"],
	["14888"] = L["Lethon"],
	["14890"] = L["Taerar"],
	["14887"] = L["Ysondre"],
	["10184"] = L["Onyxia"],
	["12118"] = L["Lucifron"],
	["11982"] = L["Magmadar"],
	["12259"] = L["Gehennas"],
	["12057"] = L["Garr"],
	["12264"] = L["Shazzrah"],
	["12056"] = L["Baron Geddon"],
	["11988"] = L["Golemagg"],
	["12098"] = L["Sulfuron Harbinger"],
	["179703"] = L["Majordomo Executus"], -- special case since it is looted from Cache of the Firelord
	["11502"] = L["Ragnaros"],
	["12435"] = L["Razorgore the Untamed"],
	["13020"] = L["Vaelastrasz the Corrupt"],
	["12017"] = L["Broodlord Lashlayer"],
	["11983"] = L["Firemaw"],
	["14601"] = L["Ebonroc"],
	["11981"] = L["Flamegor"],
	["14020"] = L["Chromaggus"],
	["11583"] = L["Nefarian"],
	["14517"] = L["High Priestess Jeklik"],
	["14507"] = L["High Priest Venoxis"],
	["14510"] = L["High Priestess Mar'li"],
	["14509"] = L["High Priest Thekal"],
	["14515"] = L["High Priestess Arlokk"],
	["11382"] = L["Bloodlord Mandokir"],
	["11380"] = L["Jin'do the Hexxer"],
	["15114"] = L["Gahz'ranka"],
	["15082"] = L["Gri'lek"],
	["15084"] = L["Renataki"],
	["15083"] = L["Hazza'rah"],
	["15085"] = L["Wushoolay"],
	["14834"] = L["Hakkar"],
	["15348"] = L["Kurinnaxx"],
	["15341"] = L["General Rajaxx"],
	["15340"] = L["Moam"],
	["15370"] = L["Buru the Gorger"],
	["15369"] = L["Ayamiss the Hunter"],
	["15339"] = L["Ossirian the Unscarred"],
	["15263"] = L["The Prophet Skeram"],
	["15543"] = L["Princess Yauj"],
	["15544"] = L["Vem"],
	["15511"] = L["Lord Kri"],
	["15516"] = L["Battleguard Sartura"],
	["15510"] = L["Fankriss the Unyielding"],
	["15509"] = L["Princess Huhuran"],
	["15276"] = L["Emperor Vek'lor"],
	["15275"] = L["Emperor Vek'nilash"],
	["15299"] = L["Viscidus"],
	["15517"] = L["Ouro"],
	["15727"] = L["C'Thun"],
	["15956"] = L["Anub'Rekhan"],
	["15953"] = L["Grand Widow Faerlina"],
	["15952"] = L["Maexxna"],
	["16061"] = L["Instructor Razuvious"],
	["16060"] = L["Gothik the Harvester"],
	["16062"] = L["Highlord Mograine"],
	["16064"] = L["Thane Korth'azz"],
	["16065"] = L["Lady Blaumeux"],
	["16063"] = L["Sir Zeliek"],
	["15954"] = L["Noth the Plaguebringer"],
	["15936"] = L["Heigan the Unclean"],
	["16011"] = L["Loatheb"],
	["16028"] = L["Patchwerk"],
	["15931"] = L["Grobbulus"],
	["15932"] = L["Gluth"],
	["15928"] = L["Thaddius"],
	["15989"] = L["Sapphiron"],
	["15990"] = L["Kel'Thuzad"],
}

TDKP.MAIN_SPEC = "ms"
TDKP.OFF_SPEC = "os"
TDKP.ValidSpecs = {TDKP.MAIN_SPEC, TDKP.OFF_SPEC}
TDKP.CHAT_PREFIX = format("[%s] ", L["TurboDKP"])
TDKP.CHAT_PREFIX_COLORED = format("|cffff5ccd%s|r", TDKP.CHAT_PREFIX)
TDKP.BidExample = "Bid Format: spec(" .. table.concat(TDKP.ValidSpecs, "/") .. ") dkp [item]  --  Ex: " .. TDKP.ValidSpecs[1] .. " 45 "
TDKP.BidExampleItemLink = nil
TDKP.itemsCurrentlyBidding = {}

-- fetch example item
local exampleItem = Item:CreateFromItemID(22799)
exampleItem:ContinueOnItemLoad(function()
	TDKP.BidExampleItemLink = exampleItem:GetItemLink()
end)

local initTime = GetTime()
function TDKP:OnInitialize()
	if GuildControlGetNumRanks() > 0 then
		TDKP:InitializeDelayed()
	elseif GetTime() - initTime < 30 then -- don't try to init for more than 30s (probably not in guild in that case)
		TDKP:ScheduleTimer("OnInitialize", 1)
	end
end

function TDKP:InitializeDelayed()
	TDKP:RegisterChatCommand(L["tdkp"], "ChatCommand")
	TDKP:RegisterChatCommand(L["dkp"], "ChatCommand")

	TDKP.TurboDKPLauncher = LibStub("LibDataBroker-1.1"):NewDataObject("TurboDKP", {
		type = "launcher",
		text = L["Turbo DKP"],
		icon = TDKP.ICON,
		OnClick = function(self, button)
			if button == "LeftButton" then
				TDKP_UI:ShowBidItemsWindow()
			elseif button == "RightButton" then
				TDKP:ToggleConfigWindow()
			end
		end,
		OnEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:AddDoubleLine(format("|cFFFFFFFF%s|r", L["Turbo DKP"]), format("|cFF777777%s|r", GetVersionString(TDKP.VERSION)))
			GameTooltip:AddLine(L["minimapLeftClickAction"])
			GameTooltip:AddLine(L["minimapRightClickAction"])
			GameTooltip:Show()
		end,
		OnLeave = function(self)
			GameTooltip:Hide()
		end
	})

	TDKP.optionDefaults = TDKP_UI:GetDefaultsDB()
	TDKP.db = LibStub("AceDB-3.0"):New("TurboDKPDB", TDKP.optionDefaults, "Default")

	TDKP.options = TDKP_UI:GetOptionsUI()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("TurboDKP", TDKP.options)
	TDKP.TurboDKPOptions = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TurboDKP", L["Turbo DKP"])

	TDKP.icon = LibStub("LibDBIcon-1.0")
	TDKP.icon:Register("TurboDKP", TDKP.TurboDKPLauncher, TDKP.db.profile.minimap)

	TDKP:RegisterEvent("LOOT_READY")
	TDKP:RegisterEvent("CHAT_MSG_WHISPER")
	TDKP:RegisterEvent("TRADE_SHOW")
	TDKP:RegisterEvent("TRADE_ACCEPT_UPDATE")
	TDKP:RegisterEvent("TRADE_CLOSED")
	TDKP:RegisterEvent("UI_INFO_MESSAGE")
	TDKP:RegisterEvent("CHAT_MSG_LOOT")

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(frame, event, msg, sender, ...)
		return TDKP_Parser:ShouldReadWhisper(msg, sender)
	end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(frame, event, msg, sender, ...)
		return TDKP_Parser:ShouldHideSentWhisper(msg)
	end)

	TDKP:ScheduleRepeatingTimer("CheckItemBidTimers", 1, true, true)

	GameTooltip:HookScript("OnTooltipSetItem", function (tooltip)
		TDKP_UI:GameTooltip_OnTooltipSetItem(tooltip)
	end)

	TDKP_Tests:RunTests()
end

function TDKP:GetBidExample(itemLink)
	if itemLink then
		return TDKP.BidExample .. itemLink
	else
		return TDKP.BidExample .. TDKP.BidExampleItemLink
	end
end

function TDKP:TRADE_SHOW()
	local playerTradingWith = GetUnitName("NPC")
	if not IsInRaid() or not UnitInRaid(playerTradingWith) then
		return
	end
	local itemsAwarded = {}
	for _, item in pairs(TDKP.db.factionrealm.itemsAwarded) do
		if item["player"] == playerTradingWith and not item["traded"] and GetItemCount(item["itemId"]) > 0 and not IsEquippedItem(item["itemId"]) then
			table.insert(itemsAwarded, item)
		end
	end
	TDKP_UI:ShowTradeWindowAttachment(playerTradingWith, itemsAwarded)
end

local tradeInfo = nil
function TDKP:TRADE_ACCEPT_UPDATE(_, acceptPlayer, acceptTarget)
	if (acceptPlayer == 1 or acceptTarget == 1) and not (GetTradePlayerItemLink(7) or GetTradeTargetItemLink(7)) then
		-- update tradeInfo
		tradeInfo = {
			["playerItemIds"] = {},
			["target"] = GetUnitName("NPC")
		}

		for i = 1, 6 do
			local itemLink = GetTradePlayerItemLink(i)
			if itemLink then
				local itemId = GetItemInfoInstant(itemLink)
				if itemId then
					table.insert(tradeInfo["playerItemIds"], itemId)
				end
			end
		end
	else
		tradeInfo = nil
	end
end

function TDKP:UI_INFO_MESSAGE(_, msg)
	if msg == LE_GAME_ERR_TRADE_COMPLETE and tradeInfo then
		if not IsInRaid() or not UnitInRaid(tradeInfo["target"]) then
			return
		end
		for _, itemId in pairs(tradeInfo["playerItemIds"]) do
			for _, itemAwarded in pairs(TDKP.db.factionrealm.itemsAwarded) do
				if itemAwarded["itemId"] == itemId and itemAwarded["player"] == tradeInfo["target"] and not itemAwarded["traded"] then
					itemAwarded["traded"] = true
					break
				end
			end
		end
	end
end

function TDKP:TRADE_CLOSED()
	TDKP_UI:HideTradeWindowAttachment()
end

function TDKP:CHAT_MSG_LOOT(_, msg, _, _, _, player)
	if IsInRaid() and msg and player and UnitName("player") ~= player then
		local itemLink = string.match(msg, ITEM_LINK_REGEX)
		if itemLink then
			local itemId = GetItemInfoInstant(itemLink)
			if itemId then
				for _, itemAwarded in pairs(TDKP.db.factionrealm.itemsAwarded) do
					if itemAwarded["itemId"] == itemId and itemAwarded["player"] == player and not itemAwarded["traded"] then
						itemAwarded["traded"] = true
						break
					end
				end
			end
		end
	end
end

-- Log items looted to loot log so that the boss that the item dropped from can be set when awarding items
function TDKP:LOOT_READY()
	if not IsInRaid() then
		return
	end

	local n = GetNumLootItems()
	for i = 1, n do
		local item = GetLootSlotLink(i)
		if item then
			local itemId = GetItemInfoInstant(item)
			if itemId then
				local _, _, itemRarity = GetItemInfo(item)
				local unitGUID = GetLootSourceInfo(i)

				local bossId = "0"
				if unitGUID then
					local npcId = select(6, strsplit("-", unitGUID))
					if TDKP.BossIdsToNames[npcId] then
						bossId = npcId
					end
				end
				local bossName = TDKP.BossIdsToNames[bossId]

				-- Only log at least green or better items
				if itemRarity >= 2 then
					TDKP.db.factionrealm.lootLog[itemId] = {
						["bossId"] = bossId,
						["bossName"] = bossName,
					}
				end
			end
		end
	end
end

function TDKP:CheckItemBidTimers()
	if not IsInRaid() then
		return
	end

	local bidsWarning = {}
	local bidsClosing = {}
	local itemIdsToDetermineWinner = {}
	for itemId, bidData in pairs(TDKP.itemsCurrentlyBidding) do
		local timeLeft = (bidData["start"] + TDKP.db.profile.bidTime) - GetServerTime()
		if not bidData["closed"] and timeLeft <= 0 then
			table.insert(bidsClosing, bidData["itemLink"])
			bidData["closed"] = true
			table.insert(itemIdsToDetermineWinner, itemId)
		elseif not bidData["warned"] and timeLeft <= TDKP.db.profile.bidWarningTime then
			table.insert(bidsWarning, bidData["itemLink"])
			bidData["warned"] = true
		end
	end
	if #bidsWarning > 0 then
		SendChatMessage(TDKP.CHAT_PREFIX .. "Bidding closing for " .. table.concat(bidsWarning, " ") .. " in " .. TDKP.db.profile.bidWarningTime .. "s", "RAID_WARNING");
	end
	if #bidsClosing > 0 then
		SendChatMessage(TDKP.CHAT_PREFIX .. "Bidding closed for " .. table.concat(bidsClosing, " ") .. "!", "RAID_WARNING");
	end
	for _, itemId in pairs(itemIdsToDetermineWinner) do
		TDKP_WinnerCalculator:DetermineWinningBid(itemId)
	end
end

function TDKP:CHAT_MSG_WHISPER(event, msg, sender)
	if not TDKP_Parser:ShouldReadWhisper(msg, sender) then
		return
	end

	local valid, data = TDKP_Parser:ParseWhisper(msg, sender)
	if not valid then
		SendChatMessage(TDKP.CHAT_PREFIX .. data, "WHISPER",nil, sender)
		return
	end

	if type(data) == "string" then
		SendChatMessage(TDKP.CHAT_PREFIX .. data, "WHISPER",nil, sender)
	elseif type(data) == "table" then
		local bidItem = TDKP.itemsCurrentlyBidding[data["itemId"]]
		bidItem["bids"][data["player"]] = data
		local rankNameWithCap = data["rankName"]
		local rankCap = TDKP.db.factionrealm.guildRankBidCaps[data["rank"]]
		if rankCap > 0 then
			rankNameWithCap = rankNameWithCap .. " (cap:" .. rankCap .. ")"
		else
			rankNameWithCap = rankNameWithCap .. " (no cap)"
		end
		SendChatMessage(TDKP.CHAT_PREFIX .. "Bid of " .. data["bidAmount"] .. " " .. string.upper(data["spec"]) .. " for " .. bidItem["itemLink"] .. " as " .. rankNameWithCap .. " accepted! (\"!cancel " .. bidItem["itemLink"] .. "\" to cancel bid)", "WHISPER",nil, sender)

		-- convert bids to OS when they are not the class priority
		if TDKP.db.factionrealm.classPriorityItems[data["itemId"]] then
			local priorityClasses = TDKP.db.factionrealm.classPriorityItems[data["itemId"]].classes
			if not priorityClasses[data["class"]] and data["spec"] ~= TDKP.OFF_SPEC then
				local prioClassBidExists = false
				for _, bid in pairs(bidItem["bids"]) do
					if priorityClasses[bid["class"]] then
						prioClassBidExists = true
						break
					end
				end
				if prioClassBidExists then
					data["spec"] = TDKP.OFF_SPEC
				end
				local prioClassesString = ConvertClassFlagsToString(priorityClasses)
				SendChatMessage(TDKP.CHAT_PREFIX .. "You are bidding on an item that is " .. prioClassesString .. " prio. Your bid will be converted to off-spec automatically if a " .. prioClassesString .. " submits a bid.", "WHISPER",nil, sender)
			elseif priorityClasses[data["class"]] then -- change all non class priority bids to off-spec when priority class bids
				for _, bid in pairs(bidItem["bids"]) do
					if not priorityClasses[bid["class"]] then
						bid["spec"] = TDKP.OFF_SPEC
					end
				end
			end
		end
	end
end

function TDKP:AwardPlayerItem(player, cost, item)
	if player ~= nil and cost ~= nil and item ~= nil then
		local bossId, bossName
		local lootLogItem = TDKP.db.factionrealm.lootLog[item["itemId"]]
		if lootLogItem then
			bossId = lootLogItem["bossId"]
			bossName = lootLogItem["bossName"]
		else
			bossId = "0"
			bossName = TDKP.BossIdsToNames[bossId]
		end
		table.insert(TDKP.db.factionrealm.itemsAwarded, {
			["player"] = player,
			["cost"] = cost,
			["itemId"] = item["itemId"],
			["itemName"] = item["itemName"],
			["itemLink"] = item["itemLink"],
			["bossId"] = bossId,
			["bossName"] = bossName,
			["time"] = GetServerTime(),
			["traded"] = (player == UnitName("player")),
		})
		if TDKP.db.factionrealm.playerDKP[player] ~= nil then
			TDKP.db.factionrealm.playerDKP[player] = TDKP.db.factionrealm.playerDKP[player] - cost
		end
		SendChatMessage(TDKP.CHAT_PREFIX .. item["itemLink"] .. " awarded to " .. player .. " for " .. cost .. " dkp!", "RAID_WARNING")
	end
end

function TDKP:UnawardPlayerItem(player, item)
	if player ~= nil and item ~= nil then
		local indexToRemove
		for i, itemAwarded in pairs(TDKP.db.factionrealm.itemsAwarded) do
			if item["itemId"] == itemAwarded["itemId"] and player == itemAwarded["player"] then
				indexToRemove = i
			end
		end
		if indexToRemove then
			local removedItemAwarded = table.remove(TDKP.db.factionrealm.itemsAwarded, indexToRemove)
			if removedItemAwarded then
				if TDKP.db.factionrealm.playerDKP[player] ~= nil then
					TDKP.db.factionrealm.playerDKP[player] = TDKP.db.factionrealm.playerDKP[player] + removedItemAwarded["cost"]
				end
				print(TDKP.CHAT_PREFIX_COLORED .. "Removed awarded " .. removedItemAwarded["itemLink"] .. " from " .. removedItemAwarded["player"] .. ".")
			else
				print(TDKP.CHAT_PREFIX_COLORED .. player .. " doesn't have " .. item["itemLink"] .. " awarded to them to remove.")
			end
		else
			print(TDKP.CHAT_PREFIX_COLORED .. player .. " doesn't have " .. item["itemLink"] .. " awarded to them to remove.")
		end
	end
end

function TDKP:ChatCommand(input)
	local tokens, items = TDKP_Parser:ParseInputIntoTokensAndItems(input)
	if tokens[1] == L["config"] then
		TDKP:ToggleConfigWindow()
	elseif tokens[1] == L["bid"] then
		if not IsInRaid() or not CanIssueRaidWarning() then
			print(TDKP.CHAT_PREFIX_COLORED .. "Must be in raid group and raid lead/assist to start item bidding.")
			return
		end
		if #items > 0 then
			local itemLinksToBid = {}
			local itemLinksWithPrio = {}
			for _, item in pairs(items) do
				if TDKP.db.factionrealm.lootCouncilItems[item["itemId"]] then
					print(TDKP.CHAT_PREFIX_COLORED .. "Cannot start bidding on " .. item["itemLink"] .. ". It is specified as a loot council item.")
				else
					TDKP.itemsCurrentlyBidding[item["itemId"]] = {
						["start"] = GetServerTime(),
						["itemId"] = item["itemId"],
						["itemName"] = item["itemName"],
						["itemLink"] = item["itemLink"],
						["closed"] = false,
						["warned"] = false,
						["bids"] = {},
					}
					local classPrioItem = TDKP.db.factionrealm.classPriorityItems[item["itemId"]]
					if classPrioItem then
						table.insert(itemLinksWithPrio, item["itemLink"] .. "(" .. ConvertClassFlagsToString(classPrioItem.classes) .. " prio)")
					else
						table.insert(itemLinksWithPrio, item["itemLink"])
					end
					table.insert(itemLinksToBid, item["itemLink"])
				end
			end
			if #itemLinksToBid > 0 then
				SendChatMessage(TDKP.CHAT_PREFIX .. "Bidding started for " .. table.concat(itemLinksWithPrio, " ") .. ". Whisper " .. UnitName("player") .. " to bid.", "RAID_WARNING")
				SendChatMessage(TDKP:GetBidExample(itemLinksToBid[1]), "RAID")
			end
		end
	elseif tokens[1] == L["award"] then
		if #tokens == 3 and #items == 1 then
			local player = tokens[2]
			local cost = tonumber(tokens[3])
			TDKP:AwardPlayerItem(player, cost, items[1])
		end
	elseif tokens[1] == L["unaward"] then
		if #tokens == 2 and #items == 1 then
			local player = tokens[2]
			TDKP:UnawardPlayerItem(player, items[1])
		end
	elseif tokens[1] == L["import"] then
		TDKP:ShowImportDialog()
	elseif tokens[1] == L["export"] then
		TDKP:ShowDKPAwardsDialog()
	elseif tokens[1] == L["clear"] then
		TDKP.db.factionrealm.playerDKP = {}
		TDKP.db.factionrealm.itemsAwarded = {}
		TDKP.db.factionrealm.lootLog = {}
		TDKP.itemsCurrentlyBidding = {}
		print(TDKP.CHAT_PREFIX_COLORED .. "Cleared player dkp values, items awarded, and loot log!")
	elseif tokens[1] == L["mmb"] then
		local minimap = not TDKP:getMinimap()
		TDKP:setMinimap(nil, minimap)
		if minimap then
			print(TDKP.CHAT_PREFIX_COLORED .. L["minimapShown"])
		else
			print(TDKP.CHAT_PREFIX_COLORED .. L["minimapHidden"])
		end
	else
		print(TDKP:GetExampleInputBlock({
			{ L["config"], L["configConsole"] },
			{ L["bid"], format("[%s]", L["items"]), L["bidConsole"] },
			{ L["award"], L["player"], L["cost"], format("[%s]", L["item"]), L["awardConsole"] },
			{ L["unaward"], L["player"], format("[%s]", L["item"]), L["unawardConsole"] },
			{ L["import"], L["importConsole"] },
			{ L["export"],L["exportConsole"] },
			{ L["clear"], L["clearConsole"] },
			{ L["mmb"], L["toggleMinimapConsole"] },
		}))
	end
end

function TDKP:GetExampleInputBlock(lines)
	local lineStrings = {}
	for _, line in pairs(lines) do
		local lineStr = "/%s"
		for i = 1, #line - 1 do
			lineStr = lineStr .. " %s"
		end
		lineStr = lineStr .. " - %s"
		lineStr = format(lineStr, L["tdkp"], unpack(line))
		table.insert(lineStrings, lineStr)
	end
	return table.concat(lineStrings, "\n")
end

function TDKP:ShowImportDialog()
	local dialog = TDKP_UI:GetImportDialog();
	dialog.editBox:SetText("")
	dialog:Show()
	dialog.frame:Raise()
	dialog.editBox:SetFocus()
end

function TDKP:ShowDKPAwardsDialog()
	local lines = {"player,cost,itemName,itemId,bossName,bossId,date,timestamp,traded"}
	for _, itemAwarded in pairs(TDKP.db.factionrealm.itemsAwarded) do
		table.insert(lines, table.concat({
			tostring(itemAwarded["player"]),
			tostring(itemAwarded["cost"]),
			tostring(itemAwarded["itemName"]):gsub(",", ""), -- need to remove commas so that it is valid csv
			tostring(itemAwarded["itemId"]),
			tostring(itemAwarded["bossName"]):gsub(",", ""), -- need to remove commas so that it is valid csv
			tostring(itemAwarded["bossId"]),
			tostring(date("%Y/%m/%d", itemAwarded["time"])),
			tostring(itemAwarded["time"]),
			tostring(itemAwarded["traded"]),
		}, ","))
	end
	local dialog = TDKP_UI:GetExportDialog();
	dialog.editBox:SetText(table.concat(lines, "\n"))
	dialog:Show()
	dialog.frame:Raise()
	dialog.editBox:SetFocus()
	dialog.editBox:HighlightText()
end

function TDKP:ToggleConfigWindow()
	if TDKP.Dialog.OpenFrames["TurboDKP"] then
		TDKP.Dialog:Close("TurboDKP")
	else
		TDKP.Dialog:Open("TurboDKP")
	end
end
