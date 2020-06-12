local L = LibStub("AceLocale-3.0"):NewLocale("TurboDKP", "enUS", true, true)
L = L or {}
L["Turbo DKP"] = true
L["TurboDKP"] = true
L["optionsDesc"] = "Turbo DKP Config (You can type /%s %s to open this)."
L["Minimap Button"] = true
L["minimapDesc"] = "Enable minimap button. Will require a /reload if hiding the button."
L["bidCapDesc"] = [=[A bid cap means that a player cannot outbid another player with a higher cap beyond their own bid cap.
Ex. If player1 (no cap) bids 60 and player2 (cap of 50) bids 75 then player1 will win the item for 51.
(-1 indicates no cap)]=]
L["classPriorityDesc"] = "When players bid on these items, they will be forced to bid OS if they are not the priority class."
L["lootCouncilDesc"] = "TurboDKP will not allow bidding to occur on any item set as loot council."
L["The bid cap for guild rank: %s."] = true
L["The bid cap for spec: %s."] = true

-- Chat Messages
L["minimapShown"] = "Minimap button shown."
L["minimapHidden"] = "Minimap button hidden. (you will need to type /reload to show changes)"

-- Console
L["tdkp"] = true
L["dkp"] = true
L["config"] = true
L["bid"] = true
L["award"] = true
L["unaward"] = true
L["import"] = true
L["export"] = true
L["clear"] = true
L["mmb"] = true
L["configConsole"] = "Open/close configuration window."
L["bidConsole"] = "Start bidding for given items."
L["awardConsole"] = "Award player the given item for dkp."
L["unawardConsole"] = "Unaward player the given item."
L["importConsole"] = "Import player dkp data from csv."
L["exportConsole"] = "Export dkp items awarded as csv."
L["clearConsole"] = "Clear player dkp data, awarded items, and loot log."
L["toggleMinimapConsole"] = "Toggle minimap button."
L["item"] = true
L["cost"] = true
L["items"] = true
L["player"] = true

-- Minimap Icon Text
L["minimapLeftClickAction"] = "Left click to display dkp items awarded."
L["minimapRightClickAction"] = "Right click to open/close Turbo DKP configuration window."

-- Dialog
L["Paste data below (csv):"] = true
L["Import Player DKP Data"] = true
L["DKP History Data"] = true

-- Bosses
L["Trash"] = true
L["Azuregos"] = true
L["Lord Kazzak"] = true
L["Emeriss"] = true
L["Lethon"] = true
L["Taerar"] = true
L["Ysondre"] = true
L["Onyxia"] = true
L["Lucifron"] = true
L["Magmadar"] = true
L["Gehennas"] = true
L["Garr"] = true
L["Shazzrah"] = true
L["Baron Geddon"] = true
L["Golemagg"] = true
L["Sulfuron Harbinger"] = true
L["Majordomo Executus"] = true
L["Ragnaros"] = true
L["Razorgore the Untamed"] = true
L["Vaelastrasz the Corrupt"] = true
L["Broodlord Lashlayer"] = true
L["Firemaw"] = true
L["Ebonroc"] = true
L["Flamegor"] = true
L["Chromaggus"] = true
L["Nefarian"] = true
L["High Priestess Jeklik"] = true
L["High Priest Venoxis"] = true
L["High Priestess Mar'li"] = true
L["High Priest Thekal"] = true
L["High Priestess Arlokk"] = true
L["Bloodlord Mandokir"] = true
L["Jin'do the Hexxer"] = true
L["Gahz'ranka"] = true
L["Gri'lek"] = true
L["Renataki"] = true
L["Hazza'rah"] = true
L["Wushoolay"] = true
L["Hakkar"] = true
L["Kurinnaxx"] = true
L["General Rajaxx"] = true
L["Moam"] = true
L["Buru the Gorger"] = true
L["Ayamiss the Hunter"] = true
L["Ossirian the Unscarred"] = true
L["The Prophet Skeram"] = true
L["Princess Yauj"] = true
L["Vem"] = true
L["Lord Kri"] = true
L["Battleguard Sartura"] = true
L["Fankriss the Unyielding"] = true
L["Princess Huhuran"] = true
L["Emperor Vek'lor"] = true
L["Emperor Vek'nilash"] = true
L["Viscidus"] = true
L["Ouro"] = true
L["C'Thun"] = true
L["Anub'Rekhan"] = true
L["Grand Widow Faerlina"] = true
L["Maexxna"] = true
L["Instructor Razuvious"] = true
L["Gothik the Harvester"] = true
L["Highlord Mograine"] = true
L["Thane Korth'azz"] = true
L["Lady Blaumeux"] = true
L["Sir Zeliek"] = true
L["Noth the Plaguebringer"] = true
L["Heigan the Unclean"] = true
L["Loatheb"] = true
L["Patchwerk"] = true
L["Grobbulus"] = true
L["Gluth"] = true
L["Thaddius"] = true
L["Sapphiron"] = true
L["Kel'Thuzad"] = true
