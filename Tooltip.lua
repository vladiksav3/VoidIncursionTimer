local _, addon = ...

local TARGET_TITLE = addon.L.targetTitle
local UPDATE_INTERVAL = 0.25
local SECONDS_PER_PERCENT = 90
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
local timerStartPercent
local lastSeenPercent
local elapsedTrackedTime = 0
local RECALIBRATION_INTERVAL = 180
local RECALIBRATION_THRESHOLD_PERCENT = 95

local function GetPercentFromText(text)
    if not text then
        return nil
    end

    local value = text:match("(%d+[%.,]?%d*)%%")
    if not value then
        return nil
    end

    value = value:gsub(",", ".")
    return tonumber(value)
end

local function GetSecondsRemaining(percent)
    if not percent then
        return nil
    end

    if not timerStartPercent then
        timerStartPercent = percent
        elapsedTrackedTime = 0
    elseif lastSeenPercent and percent < lastSeenPercent then
        timerStartPercent = percent
        elapsedTrackedTime = 0
    elseif percent >= 100 then
        timerStartPercent = percent
        elapsedTrackedTime = 0
    elseif percent <= RECALIBRATION_THRESHOLD_PERCENT and elapsedTrackedTime >= RECALIBRATION_INTERVAL then
        timerStartPercent = percent
        elapsedTrackedTime = 0
    end

    lastSeenPercent = percent

    local initialRemainingSeconds = (100 - timerStartPercent) * SECONDS_PER_PERCENT
    return math.max(0, initialRemainingSeconds - elapsedTrackedTime)
end

local function ShouldAdvanceTrackedTime()
    return WorldMapFrame and WorldMapFrame:IsShown()
end

local function GetChild(frame, index)
    return select(index, frame:GetChildren())
end

local function GetRegion(frame, index)
    return select(index, frame:GetRegions())
end

local function FrameTextContains(frame, targetText)
    if not frame then
        return false
    end

    local regionCount = frame:GetNumRegions() or 0
    for index = 1, regionCount do
        local region = GetRegion(frame, index)
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and text:find(targetText, 1, true) then
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
        if leftText and leftText:find(TARGET_TITLE, 1, true) then
            return true
        end

        local rightText = addon:GetTooltipText(tooltip, "Right", index)
        if rightText and rightText:find(TARGET_TITLE, 1, true) then
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
    local overlay = EnsureBarOverlay(statusBar)
    HideOriginalStatusBarText(statusBar, overlay)

    local displayText = string.format("%.2f%% (%s)", percent, addon:FormatTimeEstimate(GetSecondsRemaining(percent)))
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
        HideWidgetOverlays(tooltip.widgetContainer)
        return
    end

    if UpdateWidgetStatusBar(tooltip) then
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

    local displayText = string.format("%.2f%% (%s)", percent, addon:FormatTimeEstimate(GetSecondsRemaining(percent)))

    local line = addon:GetTooltipLine(tooltip, lineSide, lineIndex)
    if line and line:GetText() ~= displayText then
        line:SetText(displayText)
        tooltip:Show()
    end
end

function addon:StartTooltipWatcher()
    tooltipFrame:SetScript("OnUpdate", function(_, elapsed)
        if ShouldAdvanceTrackedTime() then
            elapsedTrackedTime = elapsedTrackedTime + elapsed
        end

        elapsedSinceUpdate = elapsedSinceUpdate + elapsed
        if elapsedSinceUpdate < UPDATE_INTERVAL then
            return
        end

        elapsedSinceUpdate = 0
        for _, tooltipName in ipairs(TOOLTIP_NAMES) do
            local tooltip = _G[tooltipName]
            if tooltip and tooltip:IsShown() then
                addon:UpdateTrackedTooltip(tooltip)
            elseif tooltip and tooltip.widgetContainer then
                HideWidgetOverlays(tooltip.widgetContainer)
            end
        end
    end)

    tooltipFrame:Show()
end
