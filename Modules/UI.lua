local TDKP_UI =  {}
_G["TDKP_UI"] = TDKP_UI

local L = LibStub("AceLocale-3.0"):GetLocale("TurboDKP")

local AceGUI = LibStub("AceGUI-3.0")

function TDKP_UI:GetDefaultsDB()
    local guildRankCapDefaults = {}
    for i = 1, GuildControlGetNumRanks() do
        guildRankCapDefaults[i] = -1
    end

    local specCapDefaults = {}
    for _, spec in pairs(TDKP.ValidSpecs) do
        specCapDefaults[spec] = -1
    end

    return {
        profile = {
            minimap = {
                hide = false,
            },
            bidTime = 60,
            bidWarningTime = 15,
        },
        factionrealm = {
            minBid = 5,
            specBidCaps = specCapDefaults,
            guildRankBidCaps = guildRankCapDefaults,
            playerDKP = {},
            itemsAwarded = {},
            lootLog = {},
            classPriorityItems = {},
            lootCouncilItems = {},
        },
    }
end

function TDKP_UI:GetOptionsUI()
    return {
        name = format("|T%s:24:24:0:5|t ", TDKP.ICON) .. L["Turbo DKP"] .. " " .. GetVersionString(TDKP.VERSION),
        handler = TDKP,
        type = 'group',
        args = {
            desc = {
                type = "description",
                name = "|CffDEDE42" .. format(L["optionsDesc"], L["tdkp"], L["config"]),
                fontSize = "medium",
                order = 1,
            },
            minimap = {
                type = "toggle",
                name = L["Minimap Button"],
                desc = L["minimapDesc"],
                order = 2,
                get = function()
                    return not TDKP.db.profile.minimap.hide
                end,
                set = function (info, value)
                    TDKP.db.profile.minimap.hide = not value
                    if TDKP.db.profile.minimap.hide then
                        TDKP.icon:Hide("TurboDKP")
                    else
                        TDKP.icon:Show("TurboDKP")
                    end
                end,
            },
            bidTimers = {
                type = "group",
                name = "Bid Timers",
                order = 3,
                args = {
                    bidTime = {
                        type = "range",
                        name = "Bidding Time",
                        desc = "The allotted time to accept bids in seconds.",
                        min = 15,
                        max = 120,
                        step = 5,
                        order = 1,
                        get = function()
                            return TDKP.db.profile.bidTime
                        end,
                        set = function (info, value)
                            TDKP.db.profile.bidTime = value
                        end,
                    },
                    bidWarningTime = {
                        type = "range",
                        name = "Bid Warning Time",
                        desc = "Will warn the raid that bidding is almost done when this many seconds remain for bidding.",
                        min = 5,
                        max = 30,
                        step = 1,
                        order = 2,
                        get = function()
                            return TDKP.db.profile.bidWarningTime
                        end,
                        set = function (info, value)
                            TDKP.db.profile.bidWarningTime = value
                        end,
                    },
                }
            },
            specCaps = TDKP_UI:GetSpecCapsOptions(4),
            guildRankCaps = TDKP_UI:GetGuildRankCapsOptions(5),
            bidLimits = {
                type = "group",
                name = "Bid Limits",
                order = 6,
                args = {
                    minBid = {
                        type = "input",
                        name = "Minimum Bid",
                        desc = "The minimum bid",
                        order = 1,
                        get = function()
                            return tostring(TDKP.db.factionrealm.minBid)
                        end,
                        set = function (info, value)
                            local v = tonumber(value)
                            if v == nil then
                                v = -1
                            end
                            v = floor(v)
                            TDKP.db.factionrealm.minBid = v
                        end,
                    },
                }
            },
            classPriority = TDKP_UI:GetClassPriorityOptions(7),
            lootCouncil = TDKP_UI:GetLootCouncilOptions(8),
        }
    }
end

function TDKP_UI:GetSpecCapsOptions(order)
    local specCaps = {
        type = "group",
        name = "Bid Caps for Specs",
        order = order,
        args = {
            desc = {
                type = "description",
                name = L["bidCapDesc"],
                fontSize = "medium",
                order = 1,
            },
        },
    }

    for i, spec in pairs(TDKP.ValidSpecs) do
        specCaps.args[spec] = {
            type = "input",
            name = strupper(spec),
            desc = format(L["The bid cap for spec: %s."], strupper(spec)),
            order = i + 1,
            get = function()
                return tostring(TDKP.db.factionrealm.specBidCaps[spec])
            end,
            set = function (info, value)
                local v = tonumber(value)
                if v == nil then
                    v = -1
                end
                v = floor(v)
                TDKP.db.factionrealm.specBidCaps[spec] = v
            end,
        }
    end

    return specCaps
end

function TDKP_UI:GetGuildRankCapsOptions(order)
    local guildRankCaps = {
        type = "group",
        name = "Bid Caps for Guild Ranks",
        order = order,
        args = {
            desc = {
                type = "description",
                name = L["bidCapDesc"],
                fontSize = "medium",
                order = 1,
            },
        },
    }

    for i = 1, GuildControlGetNumRanks() do
        local guildRankName = GuildControlGetRankName(i)
        guildRankCaps.args[guildRankName .. i] = {
            type = "input",
            name = guildRankName,
            desc = format(L["The bid cap for guild rank: %s."], guildRankName),
            order = i + 1,
            get = function()
                return tostring(TDKP.db.factionrealm.guildRankBidCaps[i])
            end,
            set = function (info, value)
                local v = tonumber(value)
                if v == nil then
                    v = -1
                end
                v = floor(v)
                TDKP.db.factionrealm.guildRankBidCaps[i] = v
            end,
        }
    end

    return guildRankCaps
end

function TDKP_UI:BuildClassPriorityItemsList(args)
    wipe(args)
    local order = 1
    for itemId, classPriorityItem in pairs(TDKP.db.factionrealm.classPriorityItems) do
        args["classPriorityItem_" .. itemId] = {
            arg = itemId,
            name = (classPriorityItem.itemLink or itemId) .. " - " .. ConvertClassFlagsToString(classPriorityItem.classes, true),
            desc = "ID: " .. itemId,
            type = "toggle",
            width = "full",
            descStyle = "inline",
            order = order,
        }
        order = order + 1
    end
end

function TDKP_UI:BuildLootCouncilItemsList(args)
    wipe(args)
    local order = 1
    for itemId, lootCouncilItem in pairs(TDKP.db.factionrealm.lootCouncilItems) do
        args["lootCouncilItem_" .. itemId] = {
            arg = itemId,
            name = lootCouncilItem.itemLink or itemId,
            desc = "ID: " .. itemId,
            type = "toggle",
            width = "full",
            descStyle = "inline",
            order = order,
        }
        order = order + 1
    end
end

function TDKP_UI:GetClassPriorityOptions(order)
    local classes = {}
    for englishClass, _ in pairs(ALL_CLASSES) do
        classes[englishClass] = GetClassWithColor(englishClass)
    end

    local currentPrioClasses = {["SHAMAN"] = true}
    local classPriority
    classPriority = {
        type = "group",
        name = "Class Priority",
        desc = L["classPriorityDesc"],
        order = order,
        args = {
            desc = {
                type = "description",
                name = L["classPriorityDesc"],
                fontSize = "medium",
                order = 1,
            },
            classInput = {
                type = "multiselect",
                control = "Dropdown",
                name = "Class",
                desc = "Class to give priority for the given item.",
                values = classes,
                order = 2,
                get = function(info, key)
                    return currentPrioClasses[key]
                end,
                set = function (info, key, value)
                    currentPrioClasses[key] = value
                end,
            },
            classPriorityItemIdInput = {
                type = "input",
                name = "Item ID",
                desc = "Item ID to add class priority for.",
                pattern = "^[0-9]+$",
                usage = "Must be a number!",
                order = 3,
                get = function() return "" end,
                set = function (info, value)
                    local itemId = GetItemInfoInstant(value)
                    local prioClasses = filter(function (_, v) return v end, currentPrioClasses)
                    if itemId and tcount(prioClasses) > 0 then
                        local item = Item:CreateFromItemID(itemId)
                        item:ContinueOnItemLoad(function()
                            local itemName, itemLink = GetItemInfo(itemId)
                            TDKP.db.factionrealm.classPriorityItems[itemId] = {
                                itemId = itemId,
                                itemName = itemName,
                                itemLink = itemLink,
                                classes = prioClasses,
                            }
                            TDKP_UI:BuildClassPriorityItemsList(classPriority.args.classPriorityItemList.args)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("TurboDKP")
                        end)
                    end
                end,
            },
            classPriorityItemList = {
                type = "group",
                name = "Class Priority Items",
                order = 4,
                inline = true,
                get = function() return true end,
                set = function(info, value)
                    TDKP.db.factionrealm.classPriorityItems[info.arg] = nil
                    TDKP_UI:BuildClassPriorityItemsList(classPriority.args.classPriorityItemList.args)
                end,
                args = {},
            },
        }
    }

    TDKP_UI:BuildClassPriorityItemsList(classPriority.args.classPriorityItemList.args)

    return classPriority
end

function TDKP_UI:GetLootCouncilOptions(order)
    local lootCouncil
    lootCouncil = {
        type = "group",
        name = "Loot Council",
        desc = L["lootCouncilDesc"],
        order = order,
        args = {
            desc = {
                type = "description",
                name = L["lootCouncilDesc"],
                fontSize = "medium",
                order = 1,
            },
            lootCouncilItemIdInput = {
                type = "input",
                name = "Item ID",
                desc = "Item ID to add loot council requirement.",
                pattern = "^[0-9]+$",
                usage = "Must be a number!",
                order = 2,
                get = function() return "" end,
                set = function (info, value)
                    local itemId = GetItemInfoInstant(value)
                    if itemId then
                        local item = Item:CreateFromItemID(itemId)
                        item:ContinueOnItemLoad(function()
                            local itemName, itemLink = GetItemInfo(itemId)
                            TDKP.db.factionrealm.lootCouncilItems[itemId] = {
                                itemId = itemId,
                                itemName = itemName,
                                itemLink = itemLink,
                            }
                            TDKP_UI:BuildLootCouncilItemsList(lootCouncil.args.lootCouncilItemsList.args)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("TurboDKP")
                        end)
                    end
                end,
            },
            lootCouncilItemsList = {
                type = "group",
                name = "Loot Council Items",
                order = 3,
                inline = true,
                get = function() return true end,
                set = function(info, value)
                    TDKP.db.factionrealm.lootCouncilItems[info.arg] = nil
                    TDKP_UI:BuildLootCouncilItemsList(lootCouncil.args.lootCouncilItemsList.args)
                end,
                args = {},
            },
        }
    }

    TDKP_UI:BuildLootCouncilItemsList(lootCouncil.args.lootCouncilItemsList.args)

    return lootCouncil
end

function TDKP_UI:GetImportDialog()
    if importDialogFrame then
        return importDialogFrame
    end
    importDialogFrame = AceGUI:Create("Frame")
    importDialogFrame:SetWidth(500)
    importDialogFrame:SetHeight(550)
    importDialogFrame:SetTitle(L["Import Player DKP Data"])
    importDialogFrame:EnableResize(false)

    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel(L["Paste data below (csv):"])
    editBox:SetText("")
    editBox:SetFullWidth(true)
    editBox:SetNumLines(30)
    editBox:SetMaxLetters(0)
    editBox:DisableButton(true)

    importDialogFrame.editBox = editBox
    importDialogFrame:AddChild(editBox)

    local importBtn = AceGUI:Create("Button")
    importBtn:SetText(L["Import Player DKP Data"])
    importBtn:SetFullWidth(true)
    importBtn:SetCallback("OnClick", function()
        TDKP_Importer:ImportPlayerData(editBox:GetText())
        importDialogFrame:Hide()
    end)

    importDialogFrame:AddChild(importBtn)

    return importDialogFrame;
end

function TDKP_UI:GetExportDialog()
    if exportDialogFrame then
        return exportDialogFrame
    end
    exportDialogFrame = AceGUI:Create("Frame")
    exportDialogFrame:SetWidth(500)
    exportDialogFrame:SetHeight(550)
    exportDialogFrame:SetTitle(L["DKP History Data"])
    exportDialogFrame:EnableResize(false)

    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel("")
    editBox:SetText("")
    editBox:SetFullWidth(true)
    editBox:SetNumLines(30)
    editBox:SetMaxLetters(0)
    editBox:DisableButton(true)

    exportDialogFrame.editBox = editBox
    exportDialogFrame:AddChild(editBox)

    return exportDialogFrame;
end

function TDKP_UI:ShowAwardWinningBidDialog(player, cost, item)
    if StaticPopupDialogs["TDKP_AwardDialog"] and StaticPopup_Visible("TDKP_AwardDialog") then
        TDKP:ScheduleTimer(TDKP_UI.ShowAwardWinningBidDialog, random()*0.5+0.5, TDKP_UI, player, cost, item)
    else
        local bidLines = table.concat(
                map(function (_, bid)
                    return string.join(" ", GetPlayerNameWithColor(bid["player"]), bid["rankName"], bid["spec"], bid["bidAmount"])
                end, item["bids"], true),
                "\n")
        StaticPopupDialogs["TDKP_AwardDialog"] = {
            text = bidLines .. "\n\nAward " .. GetPlayerNameWithColor(player) .. " " .. item["itemLink"] .. " for " .. cost .. " dkp?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                TDKP:AwardPlayerItem(player, cost, item)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("TDKP_AwardDialog")
    end
end

function TDKP_UI:ShowTradeWindowAttachment(player, items)
    if #items == 0 or not TradeFrame:IsShown() then
        return
    end

    if tradeAttachmentFrame == nil then
        tradeAttachmentFrame = AceGUI:Create("Frame")
        tradeAttachmentFrame:SetWidth(300)
        tradeAttachmentFrame:SetHeight(200)
        tradeAttachmentFrame:SetLayout("List")
        tradeAttachmentFrame:EnableResize(false)
    end
    tradeAttachmentFrame:SetTitle("DKP Items Awarded to " .. player)
    tradeAttachmentFrame.frame:SetParent(TradeFrame)
    tradeAttachmentFrame.frame:SetPoint("TOPRIGHT", 300, 0)
    tradeAttachmentFrame.frame:Show()

    tradeAttachmentFrame:ReleaseChildren()

    for _, item in pairs(items) do
        local itemLabel = AceGUI:Create("InteractiveLabel")
        itemLabel:SetText(item["itemLink"])
        itemLabel:SetImage(GetItemIcon(item["itemId"]))
        itemLabel:SetImageSize(24, 24)
        itemLabel:SetFullWidth(true)
        itemLabel:SetHeight(24)
        itemLabel:SetCallback("OnClick", function()
            if TradeFrame:IsShown() then
                for i = 0, NUM_BAG_SLOTS do
                    local bag, slot
                    for j = 1, GetContainerNumSlots(i) do
                        if GetContainerItemID(i, j) == item["itemId"] then
                            UseContainerItem(i, j)
                            bag, slot = i, j
                            break
                        end
                    end
                    if bag and slot then break end
                end
            end
        end)
        itemLabel:SetCallback("OnEnter", function()
            if(tradeAttachmentItemTooltip == nil) then
                tradeAttachmentItemTooltip = CreateFrame("GameTooltip", "tradeAttachmentItemTooltip" , nil, "GameTooltipTemplate")
            end
            tradeAttachmentItemTooltip:SetOwner(itemLabel.frame, "ANCHOR_CURSOR")
            tradeAttachmentItemTooltip:SetItemByID(item["itemId"])
            tradeAttachmentItemTooltip:Show()
        end)
        itemLabel:SetCallback("OnLeave", function()
            if tradeAttachmentItemTooltip then
                tradeAttachmentItemTooltip:Hide()
            end
        end)
        tradeAttachmentFrame:AddChild(itemLabel)
    end

    tradeAttachmentFrame:Show()
end

function TDKP_UI:HideTradeWindowAttachment()
    if tradeAttachmentFrame then
        tradeAttachmentFrame:Hide()
    end
end

function TDKP_UI:GameTooltip_OnTooltipSetItem(tooltip)
    if not IsInRaid() then
        return
    end

    local _, itemLink = tooltip:GetItem()
    if not itemLink then return; end
    local itemId = GetItemInfoInstant(itemLink)

    if TDKP.db.factionrealm.lootCouncilItems[itemId] then
        tooltip:AddLine(" ") --blank line
        tooltip:AddLine(TDKP.CHAT_PREFIX_COLORED .. "Loot Council Item!")
    elseif TDKP.db.factionrealm.classPriorityItems[itemId] then
        tooltip:AddLine(" ") --blank line
        tooltip:AddLine(TDKP.CHAT_PREFIX_COLORED .. ConvertClassFlagsToString(TDKP.db.factionrealm.classPriorityItems[itemId].classes) .. " Priority.", true)
    end

    local awardedItemsFiltered = filter(function(_, itemAwarded)
        return itemAwarded["itemId"] == itemId and (not itemAwarded["traded"] or itemAwarded["player"] == UnitName("player"))
    end, TDKP.db.factionrealm.itemsAwarded, true)
    if #awardedItemsFiltered > 0 then
        tooltip:AddLine(" ") --blank line
        for _, awardedItem in pairs(awardedItemsFiltered) do
            tooltip:AddLine(TDKP.CHAT_PREFIX_COLORED .. "Awarded to " .. GetPlayerNameWithColor(awardedItem["player"]) .. " for " .. awardedItem["cost"] .. " dkp.")
        end
    elseif TDKP.itemsCurrentlyBidding[itemId] and TDKP.itemsCurrentlyBidding[itemId]["closed"] then
        tooltip:AddLine(" ") --blank line
        if tcount(TDKP.itemsCurrentlyBidding[itemId]["bids"]) > 0 then
            tooltip:AddLine(TDKP.CHAT_PREFIX_COLORED .. "Needs to be awarded! Bids:")
            local bidLines = map(function (_, bid)
                return string.join(" ", GetPlayerNameWithColor(bid["player"]), bid["rankName"], bid["spec"], bid["bidAmount"])
            end, TDKP.itemsCurrentlyBidding[itemId]["bids"], true)
            for _, bidLine in pairs(bidLines) do
                tooltip:AddLine(TDKP.CHAT_PREFIX_COLORED .. bidLine)
            end
        else
            tooltip:AddLine(TDKP.CHAT_PREFIX_COLORED .. "No bids!")
        end
    elseif TDKP.itemsCurrentlyBidding[itemId] and not TDKP.itemsCurrentlyBidding[itemId]["closed"] then
        tooltip:AddLine(" ") --blank line
        tooltip:AddLine(TDKP.CHAT_PREFIX_COLORED .. "Currently up for bidding.")
    end
end

function TDKP_UI:ShowBidItemsWindow()
    ShowUIPanel(TurboDKP_BidFrame, 1)
end
