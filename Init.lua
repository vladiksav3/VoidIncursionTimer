local _, addon = ...

addon.frame:RegisterEvent("PLAYER_LOGIN")
addon.frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        addon:InitializeSavedVariables()
        addon:CreateMinimapButton()
        addon:StartTooltipWatcher()
    end
end)
