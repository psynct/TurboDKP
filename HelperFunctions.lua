_G["ITEM_LINK_REGEX"] = "|c%x+|Hitem[0-9:]+|h.-|h|r"
_G["ALL_CLASSES"] = FillLocalizedClassList({})

function GetVersionString(ver)
    if ver >= 10 then
        return GetVersionString(floor(ver/10)) .. "." .. tostring(ver % 10)
    else
        return "v" .. tostring(ver)
    end
end

local playerNameToClassCache = {}
function GetPlayerClass(player)
    if playerNameToClassCache[player] then
        return playerNameToClassCache[player]
    else
        for i = 1, MAX_RAID_MEMBERS do
            local tempPlayerName, _, _, _, _, englishClass = GetRaidRosterInfo(i)
            if tempPlayerName ~= nil and englishClass ~= nil then
                local playerName, _ = UnitName(tempPlayerName)
                playerNameToClassCache[playerName] = englishClass
                if playerName == player then
                    return englishClass
                end
            end
        end
    end
    return nil
end

function GetPlayerNameWithColor(player)
    local playerClass = "PRIEST"
    if playerNameToClassCache[player] then
        playerClass = playerNameToClassCache[player]
    else
        local tempClass = GetPlayerClass(player)
        if tempClass then
            playerClass = tempClass
        end
    end
    return "|c" .. RAID_CLASS_COLORS[playerClass].colorStr .. player .. "|r"
end

function GetClassWithColor(englishClass)
    local color = RAID_CLASS_COLORS["PRIEST"].colorStr
    if RAID_CLASS_COLORS[englishClass] then
        color = RAID_CLASS_COLORS[englishClass].colorStr
    end
    return format("|c%s%s|r", color, ALL_CLASSES[englishClass] or englishClass)
end

function ConvertClassFlagsToString(classes, withClassColor)
    return table.concat(map(function (class, flag)
        if flag then
            if withClassColor then
                return GetClassWithColor(class)
            else
                return ALL_CLASSES[class]
            end
        end
    end, classes, true), ", ")
end

function CanIssueRaidWarning()
    return IsInRaid() and (UnitIsGroupLeader("player") == true or UnitIsGroupAssistant("player") == true)
end

function RemoveItemsAndTrim(msg)
    if not msg then
        return msg
    end
    return msg:gsub(ITEM_LINK_REGEX, " "):gsub("^%s*", ""):gsub("%s*$", "")
end

function splitString(inputstr, sep)
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function pack(...)
    return {n = select("#", ...), ...}
end

function tcount(tbl)
    local count = 0
    for _, v in pairs(tbl) do
        count = count + 1
    end
    return count
end

function map(func, tbl, convertToArray)
    local newtbl = {}
    if convertToArray then
        for i, v in pairs(tbl) do
            table.insert(newtbl, func(i, v))
        end
    else
        for i, v in pairs(tbl) do
            newtbl[i] = func(i, v)
        end
    end
    return newtbl
end

function filter(func, tbl, convertToArray)
    local newtbl = {}
    if convertToArray then
        for i, v in pairs(tbl) do
            if func(i, v) then
                table.insert(newtbl, v)
            end
        end
    else
        for i, v in pairs(tbl) do
            if func(i, v) then
                newtbl[i] = v
            end
        end
    end
    return newtbl
end
