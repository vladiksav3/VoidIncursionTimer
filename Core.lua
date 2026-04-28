local addonName, addon = ...

addon.id = addonName
addon.name = "VoidIncursionTimer"
addon.frame = CreateFrame("Frame")
addon.defaults = {
    displayMode = "static",
    displayModeVersion = 1,
    minimapAngle = 225,
}

local locale = GetLocale()
local defaultStrings = {
    targetTitle = "Impending Void Incursion",
    loaded = "loaded.",
    displayModeStatic = "display mode: static.",
    displayModeEstimated = "display mode: estimated time.",
    minimapTooltipTitle = "Void Incursion Timer",
    minimapTooltipStatusStatic = "Mode: Static",
    minimapTooltipStatusEstimated = "Mode: Estimated Time",
    minimapTooltipToggle = "Left-click to switch display mode.",
    minimapTooltipDrag = "Drag to move this button.",
    minimapTooltipReset = "Right-click to reset position.",
}
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

addon.L = setmetatable(stringsByLocale[locale] or {}, {
    __index = defaultStrings,
})

function addon:Print(message)
    print(self.name .. ": " .. message)
end

function addon:InitializeSavedVariables()
    VoidIncursionTimerDB = VoidIncursionTimerDB or {}
    self.db = VoidIncursionTimerDB

    if self.db.showEstimatedTime ~= nil then
        self.db.showEstimatedTime = nil
    end

    if self.db.displayMode == "current" then
        self.db.displayMode = "static"
    end

    if self.db.displayModeVersion == nil then
        self.db.displayMode = "static"
        self.db.displayModeVersion = self.defaults.displayModeVersion
    end

    for key, value in pairs(self.defaults) do
        if self.db[key] == nil then
            self.db[key] = value
        end
    end
end

function addon:GetDisplayMode()
    return (self.db and self.db.displayMode) or self.defaults.displayMode
end

function addon:SetDisplayMode(mode)
    if mode == "current" then
        mode = "static"
    end

    if mode ~= "static" and mode ~= "estimated" then
        mode = self.defaults.displayMode
    end

    self.db.displayMode = mode
end

function addon:IsEstimatedTimeEnabled()
    return self:GetDisplayMode() == "estimated"
end

function addon:ToggleDisplayMode()
    local mode = self:GetDisplayMode() == "estimated" and "static" or "estimated"
    self:SetDisplayMode(mode)
    self:Print(mode == "estimated" and self.L.displayModeEstimated or self.L.displayModeStatic)

    if self.RefreshVisibleTooltips then
        self:RefreshVisibleTooltips()
    end

    return mode
end

function addon:GetMinimapAngle()
    return (self.db and self.db.minimapAngle) or self.defaults.minimapAngle
end

function addon:SetMinimapAngle(angle)
    self.db.minimapAngle = angle
end

function addon:ResetMinimapAngle()
    self:SetMinimapAngle(self.defaults.minimapAngle)
end

function addon:ToggleEstimatedTime()
    return self:ToggleDisplayMode()
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
