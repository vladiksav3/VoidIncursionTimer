local _, addon = ...

local TARGET_TITLE = addon.L.targetTitle
local UPDATE_INTERVAL = 0.25
local SECONDS_PER_PERCENT = 60
local TOOLTIP_NAMES = {
    "GameTooltip",
    "WorldMapTooltip",
}
local TOOLTIP_SIDES = {
    "Left",
    "Right",
}

local tooltipFrame = CreateFrame("Frame")
local elapsedSinceUpdate = 0
local progressState = {
    anchorPercent = nil,
    anchorTime = nil,
    secPerPercent = nil,
}

local function GetPercentFromText(text)
    if not text then
        return nil
    end

    local value = string.match(text, "(%d+[%.,]?%d*)%%")
    if not value then
        return nil
    end

    value = string.gsub(value, ",", ".")
    return tonumber(value)
end

local function ObserveProgress(percent)
    if not percent then
        return
    end

    local now = GetTime()
    local anchorPercent = progressState.anchorPercent
    local anchorTime = progressState.anchorTime

    if anchorPercent and anchorTime then
        local deltaPercent = percent - anchorPercent
        local deltaTime = now - anchorTime

        if deltaPercent > 0 and deltaTime > 0 then
            local measuredSecondsPerPercent = deltaTime / deltaPercent
            if progressState.secPerPercent then
                progressState.secPerPercent = (progressState.secPerPercent * 0.7) + (measuredSecondsPerPercent * 0.3)
            else
                progressState.secPerPercent = measuredSecondsPerPercent
            end
            progressState.anchorPercent = percent
            progressState.anchorTime = now
            return
        elseif deltaPercent < 0 then
            progressState.secPerPercent = nil
            progressState.anchorPercent = percent
            progressState.anchorTime = now
            return
        end
    end

    if not anchorPercent then
        progressState.anchorPercent = percent
        progressState.anchorTime = now
    end
end

local function GetSecondsPerPercent()
    if addon:IsEstimatedTimeEnabled() then
        return progressState.secPerPercent
    end

    return SECONDS_PER_PERCENT
end

local function GetSecondsRemaining(percent)
    if not percent then
        return nil
    end

    local secondsPerPercent = GetSecondsPerPercent()
    if not secondsPerPercent or secondsPerPercent <= 0 then
        return nil
    end

    return math.max(0, (100 - percent) * secondsPerPercent)
end

local function FormatSecondsPerPercent(secondsPerPercent)
    if not secondsPerPercent or secondsPerPercent <= 0 then
        return nil
    end

    return string.format("1%%=%s", addon:FormatTimeEstimate(secondsPerPercent))
end

local function GetChild(frame, index)
    return select(index, frame:GetChildren())
end

local function GetRegion(frame, index)
    return select(index, frame:GetRegions())
end

local function FormatDisplayText(percent)
    local etaText = addon:FormatTimeEstimate(GetSecondsRemaining(percent))
    if addon:IsEstimatedTimeEnabled() then
        local rateText = FormatSecondsPerPercent(GetSecondsPerPercent())
        if rateText then
            return string.format("%.2f%% (%s, %s)", percent, etaText, rateText)
        end
    end

    return string.format("%.2f%% (%s)", percent, etaText)
end

local function TextContains(text, targetText)
    if not text or not targetText then
        return false
    end

    local ok, found = pcall(string.find, text, targetText, 1, true)
    return ok and found ~= nil
end

local function FrameTextContains(frame, targetText)
    if not frame then
        return false
    end

    local regionCount = frame:GetNumRegions() or 0
    for index = 1, regionCount do
        local region = GetRegion(frame, index)
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local ok, text = pcall(region.GetText, region)
            if ok and TextContains(text, targetText) then
                return true
            end
        end
    end

    local childCount = frame:GetNumChildren() or 0
    for index = 1, childCount do
        local child = GetChild(frame, index)
        if FrameTextContains(child, targetText) then
            return true
        end
    end

    return false
end

local function TooltipContainsTarget(tooltip)
    local lineCount = tooltip:NumLines()
    for index = 1, lineCount do
        local leftText = addon:GetTooltipText(tooltip, "Left", index)
        if TextContains(leftText, TARGET_TITLE) then
            return true
        end

        local rightText = addon:GetTooltipText(tooltip, "Right", index)
        if TextContains(rightText, TARGET_TITLE) then
            return true
        end
    end

    if tooltip.widgetContainer and FrameTextContains(tooltip.widgetContainer, TARGET_TITLE) then
        return true
    end

    return false
end

local function FindWidgetStatusBar(frame)
    if not frame then
        return nil
    end

    if frame:IsShown() and frame.GetObjectType and frame:GetObjectType() == "StatusBar" then
        return frame
    end

    local childCount = frame:GetNumChildren() or 0
    for index = 1, childCount do
        local child = GetChild(frame, index)
        local statusBar = FindWidgetStatusBar(child)
        if statusBar then
            return statusBar
        end
    end

    return nil
end

local function HideWidgetOverlays(frame)
    if not frame then
        return
    end

    if frame.overlayText then
        frame.overlayText:Hide()
    end

    if frame.hiddenTextRegions then
        for region in pairs(frame.hiddenTextRegions) do
            if region and region.SetAlpha and region.originalAlpha ~= nil then
                region:SetAlpha(region.originalAlpha)
            end
        end
        frame.hiddenTextRegions = nil
    end

    local childCount = frame:GetNumChildren() or 0
    for index = 1, childCount do
        local child = GetChild(frame, index)
        HideWidgetOverlays(child)
    end
end

local function RestoreTooltipLines(tooltip)
    local lineCount = tooltip and tooltip:NumLines() or 0
    for index = 1, lineCount do
        for _, side in ipairs(TOOLTIP_SIDES) do
            local line = addon:GetTooltipLine(tooltip, side, index)
            if line and line.vitOriginalText then
                line:SetText(line.vitOriginalText)
                line.vitOriginalText = nil
            end
        end
    end
end

local function HideOriginalStatusBarText(frame, overlay)
    if not frame then
        return
    end

    frame.hiddenTextRegions = frame.hiddenTextRegions or {}

    local regionCount = frame:GetNumRegions() or 0
    for index = 1, regionCount do
        local region = GetRegion(frame, index)
        if region and region ~= overlay and region.GetObjectType and region:GetObjectType() == "FontString" then
            if region:IsShown() then
                if region.originalAlpha == nil then
                    region.originalAlpha = region:GetAlpha()
                end
                region:SetAlpha(0)
                frame.hiddenTextRegions[region] = true
            end
        end
    end

    local childCount = frame:GetNumChildren() or 0
    for index = 1, childCount do
        local child = GetChild(frame, index)
        HideOriginalStatusBarText(child, overlay)
    end
end

local function EnsureBarOverlay(statusBar)
    if statusBar.overlayText then
        return statusBar.overlayText
    end

    local text = statusBar:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    text:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetTextColor(1, 1, 1)
    statusBar.overlayText = text

    return text
end

local function UpdateWidgetStatusBar(tooltip)
    local container = tooltip.widgetContainer
    local statusBar = container and FindWidgetStatusBar(container)
    if not statusBar or not statusBar.GetValue or not statusBar.GetMinMaxValues then
        return false
    end

    local minValue, maxValue = statusBar:GetMinMaxValues()
    local currentValue = statusBar:GetValue()
    if not currentValue or not maxValue or maxValue <= minValue then
        return false
    end

    local percent = ((currentValue - minValue) / (maxValue - minValue)) * 100
    ObserveProgress(percent)
    local overlay = EnsureBarOverlay(statusBar)
    HideOriginalStatusBarText(statusBar, overlay)

    local displayText = FormatDisplayText(percent)
    overlay:SetText(displayText)
    overlay:Show()
    return true
end

local function FindPercentLine(tooltip)
    local lineCount = tooltip:NumLines()
    for index = 2, lineCount do
        for _, side in ipairs(TOOLTIP_SIDES) do
            local text = addon:GetTooltipText(tooltip, side, index)
            if GetPercentFromText(text) then
                return side, index, text
            end
        end
    end

    return nil, nil, nil
end

function addon:UpdateTrackedTooltip(tooltip)
    if not tooltip or not tooltip:IsShown() then
        return
    end

    if not TooltipContainsTarget(tooltip) then
        RestoreTooltipLines(tooltip)
        HideWidgetOverlays(tooltip.widgetContainer)
        return
    end

    if UpdateWidgetStatusBar(tooltip) then
        RestoreTooltipLines(tooltip)
        return
    end

    local lineSide, lineIndex, lineText = FindPercentLine(tooltip)
    if not lineSide or not lineIndex or not lineText then
        return
    end

    local percent = GetPercentFromText(lineText)
    if not percent then
        return
    end

    ObserveProgress(percent)
    local displayText = FormatDisplayText(percent)

    local line = addon:GetTooltipLine(tooltip, lineSide, lineIndex)
    local shouldUpdate = true
    local currentText = nil
    if line then
        local ok, existingText = pcall(line.GetText, line)
        currentText = ok and existingText or nil
        shouldUpdate = not ok or currentText ~= displayText
    end

    if line and shouldUpdate then
        if line.vitOriginalText == nil then
            line.vitOriginalText = currentText or lineText
        end
        line:SetText(displayText)
        tooltip:Show()
    end
end

function addon:RefreshVisibleTooltips()
    for _, tooltipName in ipairs(TOOLTIP_NAMES) do
        local tooltip = _G[tooltipName]
        if tooltip and tooltip:IsShown() then
            self:UpdateTrackedTooltip(tooltip)
        elseif tooltip then
            RestoreTooltipLines(tooltip)
            HideWidgetOverlays(tooltip.widgetContainer)
        end
    end
end

function addon:StartTooltipWatcher()
    tooltipFrame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed
        if elapsedSinceUpdate < UPDATE_INTERVAL then
            return
        end

        elapsedSinceUpdate = 0
        addon:RefreshVisibleTooltips()
    end)

    tooltipFrame:Show()
end
