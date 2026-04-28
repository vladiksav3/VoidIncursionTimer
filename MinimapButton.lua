local _, addon = ...

local BUTTON_NAME = "VoidIncursionTimerMinimapButton"
local BUTTON_SIZE = 31
local RADIUS = 80
local ICON_PATH = "Interface\\AddOns\\VoidIncursionTimer\\Media\\curseforge-logo.png"

local function GetAngleFromCursor()
    local scale = Minimap:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    local centerX = Minimap:GetLeft() + (Minimap:GetWidth() / 2)
    local centerY = Minimap:GetBottom() + (Minimap:GetHeight() / 2)
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

local function UpdateButtonTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(addon.L.minimapTooltipTitle)
    GameTooltip:AddLine(addon:IsEstimatedTimeEnabled() and addon.L.minimapTooltipStatusEstimated or addon.L.minimapTooltipStatusStatic, 1, 1, 1)
    GameTooltip:AddLine(addon.L.minimapTooltipToggle, 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine(addon.L.minimapTooltipDrag, 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine(addon.L.minimapTooltipReset, 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end

function addon:CreateMinimapButton()
    if self.minimapButton then
        self:UpdateMinimapButtonPosition()
        return
    end

    local button = CreateFrame("Button", BUTTON_NAME, Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetAllPoints()
    background:SetVertexColor(0, 0, 0, 0.6)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON_PATH)
    icon:SetPoint("TOPLEFT", 7, -7)
    icon:SetPoint("BOTTOMRIGHT", -7, 7)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints()

    button:SetScript("OnEnter", UpdateButtonTooltip)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function(_, mouseButton)
        if button.wasDragged then
            button.wasDragged = nil
            return
        end

        if mouseButton == "RightButton" then
            addon:ResetMinimapAngle()
            addon:UpdateMinimapButtonPosition()
            return
        end

        addon:ToggleDisplayMode()
        if GameTooltip:IsOwned(button) then
            UpdateButtonTooltip(button)
        end
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
