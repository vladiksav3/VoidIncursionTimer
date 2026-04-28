local addonName, addon = ...

addon.id = addonName
addon.name = "VoidIncursion"
addon.frame = CreateFrame("Frame")

local locale = GetLocale()
local stringsByLocale = {
    enUS = {
        targetTitle = "Impending Void Incursion",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Void Assault",
        voidAssaultPlural = "Void Assaults",
        assaultsLeft = "%d %s left",
        loaded = "loaded.",
    },
    enGB = {
        targetTitle = "Impending Void Incursion",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Void Assault",
        voidAssaultPlural = "Void Assaults",
        assaultsLeft = "%d %s left",
        loaded = "loaded.",
    },
    deDE = {
        targetTitle = "Drohender Leereneinbruch",
        incursionActive = "Invasion aktiv",
        voidAssaultSingular = "Leerenangriff",
        voidAssaultPlural = "Leerenangriffe",
        assaultsLeft = "Noch %d %s",
        loaded = "geladen.",
    },
    esES = {
        targetTitle = "Impending Void Incursion",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Void Assault",
        voidAssaultPlural = "Void Assaults",
        assaultsLeft = "%d %s left",
        loaded = "loaded.",
    },
    esMX = {
        targetTitle = "Impending Void Incursion",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Void Assault",
        voidAssaultPlural = "Void Assaults",
        assaultsLeft = "%d %s left",
        loaded = "loaded.",
    },
    frFR = {
        targetTitle = "Incursion du Vide imminente",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Assaut du Vide",
        voidAssaultPlural = "Assauts du Vide",
        assaultsLeft = "Il reste %d %s",
        loaded = "loaded.",
    },
    itIT = {
        targetTitle = "Incursione del Vuoto imminente",
        incursionActive = "Incursione attiva",
        voidAssaultSingular = "Assalto del Vuoto",
        voidAssaultPlural = "Assalti del Vuoto",
        assaultsLeft = "Restano %d %s",
        loaded = "caricato.",
    },
    koKR = {
        targetTitle = "Impending Void Incursion",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Void Assault",
        voidAssaultPlural = "Void Assaults",
        assaultsLeft = "%d %s left",
        loaded = "loaded.",
    },
    ptBR = {
        targetTitle = "Incursao do Caos Iminente",
        incursionActive = "Incursao ativa",
        voidAssaultSingular = "Investida do Caos",
        voidAssaultPlural = "Investidas do Caos",
        assaultsLeft = "Restam %d %s",
        loaded = "carregado.",
    },
    ruRU = {
        targetTitle = "Impending Void Incursion",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Void Assault",
        voidAssaultPlural = "Void Assaults",
        assaultsLeft = "%d %s left",
        loaded = "loaded.",
    },
    zhCN = {
        targetTitle = "Impending Void Incursion",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Void Assault",
        voidAssaultPlural = "Void Assaults",
        assaultsLeft = "%d %s left",
        loaded = "loaded.",
    },
    zhTW = {
        targetTitle = "Impending Void Incursion",
        incursionActive = "Incursion active",
        voidAssaultSingular = "Void Assault",
        voidAssaultPlural = "Void Assaults",
        assaultsLeft = "%d %s left",
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

    return line:GetText()
end

function addon:FormatAssaultsRemaining(percent)
    if not percent or percent >= 100 then
        return self.L.incursionActive
    end
 
    local remainingAssaults = math.ceil((100 - percent) / 5)
    local label = remainingAssaults == 1 and self.L.voidAssaultSingular or self.L.voidAssaultPlural
    return string.format(self.L.assaultsLeft, remainingAssaults, label)
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
