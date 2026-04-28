local addonName, addon = ...

addon.id = addonName
addon.name = "VoidIncursionTimer"
addon.frame = CreateFrame("Frame")

local locale = GetLocale()
local stringsByLocale = {
    enUS = {
        targetTitle = "Impending Void Incursion",
        loaded = "loaded.",
    },
    enGB = {
        targetTitle = "Impending Void Incursion",
        loaded = "loaded.",
    },
    deDE = {
        targetTitle = "Drohender Leereneinbruch",
        loaded = "geladen.",
    },
    esES = {
        targetTitle = "Impending Void Incursion",
        loaded = "loaded.",
    },
    esMX = {
        targetTitle = "Impending Void Incursion",
        loaded = "loaded.",
    },
    frFR = {
        targetTitle = "Incursion du Vide imminente",
        loaded = "loaded.",
    },
    itIT = {
        targetTitle = "Incursione del Vuoto imminente",
        loaded = "caricato.",
    },
    koKR = {
        targetTitle = "Impending Void Incursion",
        loaded = "loaded.",
    },
    ptBR = {
        targetTitle = "Incursao do Caos Iminente",
        loaded = "carregado.",
    },
    ruRU = {
        targetTitle = "Impending Void Incursion",
        loaded = "loaded.",
    },
    zhCN = {
        targetTitle = "Impending Void Incursion",
        loaded = "loaded.",
    },
    zhTW = {
        targetTitle = "Impending Void Incursion",
        loaded = "loaded.",
    },
}

addon.L = stringsByLocale[locale] or stringsByLocale.enUS

function addon:Print(message)
    print(self.name .. ": " .. message)
end

function addon:GetTooltipLine(tooltip, side, index)
    local tooltipName = tooltip and tooltip:GetName()
    if not tooltipName then
        return nil
    end

    return _G[tooltipName .. "Text" .. side .. index]
end

function addon:GetTooltipText(tooltip, side, index)
    local line = self:GetTooltipLine(tooltip, side, index)
    if not line then
        return nil
    end

    local ok, text = pcall(line.GetText, line)
    if not ok then
        return nil
    end

    return text
end

function addon:FormatTimeEstimate(secondsRemaining)
    if not secondsRemaining or secondsRemaining <= 0 then
        return "calculating ETA"
    end

    local totalSeconds = math.max(0, math.floor(secondsRemaining + 0.5))
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60

    if hours > 0 then
        return string.format("%dh %02dm", hours, minutes)
    end

    if minutes > 0 then
        return string.format("%dm %02ds", minutes, seconds)
    end

    return string.format("%ds", seconds)
end
