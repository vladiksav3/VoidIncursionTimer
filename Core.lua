local addonName, addon = ...

addon.name = addonName
addon.frame = CreateFrame("Frame")

function addon:Print(message)
    print(self.name .. ": " .. message)
end
