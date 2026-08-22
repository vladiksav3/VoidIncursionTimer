local _, addon = ...

local BUTTON_NAME = "VoidIncursionTimerMinimapButton"
local BUTTON_SIZE = 31
local ICON_SIZE = 22
-- TrackingBorder artwork occupies only upper-left portion of its 53px canvas.
-- These values render its visible ring at about 31px around the 22px icon.
local BORDER_SIZE = 47
local BORDER_OFFSET = 0
local RADIUS = 80
local ICON_PATH = "Interface\\AddOns\\VoidIncursionTimer\\Media\\curseforge-logo.png"
local DATA_OBJECT_NAME = addon.id

local function GetAngleFromCursor()
    local scale = Minimap:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    local centerX, centerY = Minimap:GetCenter()
    local deltaX = (cursorX / scale) - centerX
    local deltaY = (cursorY / scale) - centerY

    local angle
    if math.atan2 then
        angle = math.deg(math.atan2(deltaY, deltaX))
    elseif deltaX == 0 then
        angle = deltaY >= 0 and 90 or 270
    else
        angle = math.deg(math.atan(deltaY / deltaX))
        if deltaX < 0 then
            angle = angle + 180
        elseif deltaY < 0 then
            angle = angle + 360
        end
    end

    return (angle + 360) % 360
end

function addon:UpdateMinimapButtonPosition()
    local button = self.minimapButton
    if not button then
        return
    end

    local angle = math.rad(self:GetMinimapAngle())
    local x = math.cos(angle) * RADIUS
    local y = math.sin(angle) * RADIUS

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function PopulateTooltip(tooltip)
    tooltip:SetText(addon.L.minimapTooltipTitle)
    tooltip:AddLine(addon:IsEstimatedTimeEnabled() and addon.L.minimapTooltipStatusEstimated or addon.L.minimapTooltipStatusStatic, 1, 1, 1)
    tooltip:AddLine(addon.L.minimapTooltipToggle, 0.8, 0.8, 0.8, true)
    tooltip:AddLine(addon.L.minimapTooltipDrag, 0.8, 0.8, 0.8, true)
end

local function UpdateButtonTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    PopulateTooltip(GameTooltip)
    GameTooltip:Show()
end

local function ToggleDisplayMode(button)
    addon:ToggleDisplayMode()
    if GameTooltip:IsOwned(button) then
        UpdateButtonTooltip(button)
    end
end

local function StyleLibDBIconButton(button)
    local background
    for _, region in ipairs({ button:GetRegions() }) do
        if region:GetDrawLayer() == "BACKGROUND" then
            background = region
            break
        end
    end
    if background then
        background:Hide()
    end

    local icon = button.icon
    icon:ClearAllPoints()
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER")

    local iconMask = button:CreateMaskTexture()
    iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    iconMask:SetAllPoints(icon)
    icon:AddMaskTexture(iconMask)

    for _, region in ipairs({ button:GetRegions() }) do
        if region:GetDrawLayer() == "OVERLAY" then
            region:ClearAllPoints()
            region:SetSize(BORDER_SIZE, BORDER_SIZE)
            region:SetPoint("TOPLEFT", BORDER_OFFSET, -BORDER_OFFSET)
            break
        end
    end

    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetAlpha(0)
    end
end

local function CreateLibDBIconButton()
    if not LibStub then
        return nil
    end

    local broker = LibStub("LibDataBroker-1.1", true)
    local iconLibrary = LibStub("LibDBIcon-1.0", true)
    if not broker or not iconLibrary then
        return nil
    end

    local dataObject = broker:NewDataObject(DATA_OBJECT_NAME, {
        type = "data source",
        icon = ICON_PATH,
        OnClick = function(button, mouseButton)
            if mouseButton == "LeftButton" then
                ToggleDisplayMode(button)
            end
        end,
        OnTooltipShow = PopulateTooltip,
    })
    iconLibrary:Register(DATA_OBJECT_NAME, dataObject, addon.db.minimap)

    local button = iconLibrary:GetMinimapButton(DATA_OBJECT_NAME)
    StyleLibDBIconButton(button)
    return button
end

function addon:CreateMinimapButton()
    if self.minimapButton then
        if not self.usesLibDBIcon then
            self:UpdateMinimapButtonPosition()
        end
        return
    end

    local managedButton = CreateLibDBIconButton()
    if managedButton then
        self.minimapButton = managedButton
        self.usesLibDBIcon = true
        return
    end

    local button = CreateFrame("Button", BUTTON_NAME, Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON_PATH)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER")

    local iconMask = button:CreateMaskTexture()
    iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    iconMask:SetAllPoints(icon)
    icon:AddMaskTexture(iconMask)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(BORDER_SIZE, BORDER_SIZE)
    border:SetPoint("TOPLEFT", BORDER_OFFSET, -BORDER_OFFSET)

    button:SetScript("OnEnter", UpdateButtonTooltip)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function()
        if button.wasDragged then
            button.wasDragged = nil
            return
        end

        ToggleDisplayMode(button)
    end)
    button:SetScript("OnDragStart", function(self)
        self.wasDragged = true
        self:SetScript("OnUpdate", function()
            addon:SetMinimapAngle(GetAngleFromCursor())
            addon:UpdateMinimapButtonPosition()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        addon:SetMinimapAngle(GetAngleFromCursor())
        addon:UpdateMinimapButtonPosition()
    end)

    self.minimapButton = button
    self:UpdateMinimapButtonPosition()
end
