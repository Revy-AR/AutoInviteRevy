local addonName = "AutoInviteRevy"

local enabled
local keywords

-- Úticél kulcsszavak
local destinationKeywords = {
    tb = "Thunder Bluff",
    ["thunder bluff"] = "Thunder Bluff",
    thunderbluff = "Thunder Bluff",

    og = "Orgrimmar",
    orgrimmar = "Orgrimmar",

    sm = "Silvermoon",
    silvermoon = "Silvermoon",

    st = "Stonard",
    stonard = "Stonard",

    uc = "Undercity",
    undercity = "Undercity"
}

-- Betöltés
local function LoadSettings()
    if not AutoInviteRevyDB then
        AutoInviteRevyDB = {}
    end

    enabled = AutoInviteRevyDB.enabled
    if enabled == nil then
        enabled = false
    end

    keywords = AutoInviteRevyDB.keywords or { "portal", "port" }
end

-- Mentés
local function SaveSettings()
    AutoInviteRevyDB.enabled = enabled
    AutoInviteRevyDB.keywords = keywords
end

local function cleanName(name)
    if string.find(name, "-") then
        return string.match(name, "([^%-]+)")
    else
        return name
    end
end

local function checkMessage(msg, sender)
    if not enabled then return end

    sender = cleanName(sender)
    msg = string.lower(msg)

    for _, word in ipairs(keywords) do
        if string.find(msg, word) then

            -- Úticél felismerése
            local destinationFound = nil
            for key, city in pairs(destinationKeywords) do
                if string.find(msg, key) then
                    destinationFound = city
                    break
                end
            end

            if destinationFound then
                print("|cffffff00[AutoInvite] " .. sender .. " → " .. destinationFound .. " portot kér.|r")
            end

            -- GUID lekérése
            local guid = UnitGUID(sender)
            local _, class

            if guid then
                _, class = GetPlayerInfoByGUID(guid)
            end

            -- Mage szűrés (csendben)
            if class then
                class = string.upper(class)
                if class == "MAGE" then
                    return -- nem invitáljuk, nem írunk ki semmit
                end
            end

            print("|cff00ff00[AutoInvite] Találat kulcsszóra:|r " .. word .. " → próbálkozás meghívással.")

            if C_PartyInfo and C_PartyInfo.InviteUnit then
                C_PartyInfo.InviteUnit(sender)
            end

            break
        end
    end
end

-------------------------------------------------
-- Eseménykezelő frame
-------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:RegisterEvent("CHAT_MSG_SAY")
frame:RegisterEvent("CHAT_MSG_YELL")
frame:RegisterEvent("CHAT_MSG_GUILD")
frame:RegisterEvent("CHAT_MSG_PARTY")
frame:RegisterEvent("CHAT_MSG_RAID")

frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == addonName then
        LoadSettings()
        return
    end

    if arg1 and arg2 then
        checkMessage(arg1, arg2)
    end
end)

-------------------------------------------------
-- Slash parancsok
-------------------------------------------------

-- Enable
SLASH_AIENABLE1 = "/aienable"
SlashCmdList["AIENABLE"] = function()
    enabled = true
    SaveSettings()
    print("|cff00ff00AutoInvite engedélyezve.|r")
end

-- Disable
SLASH_AIDISABLE1 = "/aidisable"
SlashCmdList["AIDISABLE"] = function()
    enabled = false
    SaveSettings()
    print("|cffff0000AutoInvite letiltva.|r")
end

-- Keyword setter (/aikw)
SLASH_AIKEYWORD1 = "/aikw"
SlashCmdList["AIKEYWORD"] = function(msg)
    keywords = {}
    local seen = {}
    for word in string.gmatch(msg, "%S+") do
        word = string.lower(word)
        if not seen[word] then
            table.insert(keywords, word)
            seen[word] = true
        end
    end
    SaveSettings()
    print("|cffffff00Kulcsszavak frissítve:|r " .. table.concat(keywords, ", "))
end

-- Add keyword (/addkw)
SLASH_ADDKW1 = "/addkw"
SlashCmdList["ADDKW"] = function(msg)
    local newWord = string.lower(msg)
    if newWord == "" then
        print("|cffff0000Nem adtál meg kulcsszót.|r")
        return
    end
    for _, word in ipairs(keywords) do
        if word == newWord then
            print("|cffff0000A megadott kulcsszó már szerepel:|r " .. newWord)
            return
        end
    end
    table.insert(keywords, newWord)
    SaveSettings()
    print("|cff00ff00Hozzáadva:|r " .. newWord)
end

-- Delete keyword (/delkw)
SLASH_DELKW1 = "/delkw"
SlashCmdList["DELKW"] = function(msg)
    local target = string.lower(msg)
    if target == "" then
        print("|cffff0000Nem adtál meg törlendő kulcsszót.|r")
        return
    end
    for i, word in ipairs(keywords) do
        if word == target then
            table.remove(keywords, i)
            SaveSettings()
            print("|cffff0000Törölve:|r " .. target)
            return
        end
    end
    print("|cffffff00Nem találtam ilyen kulcsszót:|r " .. target)
end

-- Show keywords (/showkw)
SLASH_SHOWKW1 = "/showkw"
SlashCmdList["SHOWKW"] = function()
    print("|cffffff00Jelenlegi kulcsszavak:|r " .. table.concat(keywords, ", "))
end

-- Show commands (/parancsok)
SLASH_PARANCSOK1 = "/parancsok"
SlashCmdList["PARANCSOK"] = function()
    print("|cffffff00Elérhető parancsok:|r")
    print("/aienable - bekapcsolás")
    print("/aidisable - kikapcsolás")
    print("/aikw <szavak> - kulcsszavak beállítása")
    print("/addkw <szó> - kulcsszó hozzáadása")
    print("/delkw <szó> - kulcsszó törlése")
    print("/showkw - kulcsszavak listázása")
    print("/parancsok - parancsok listája")
    print("/aioptions - beállítópanel megnyitása")
end

-------------------------------------------------
-- Beállítópanel (Interface Options)
-------------------------------------------------

local optionsPanel = CreateFrame("Frame", addonName .. "OptionsPanel", InterfaceOptionsFramePanelContainer)
optionsPanel.name = "AutoInviteRevy"

local function RefreshKeywordsList()
    if not optionsPanel.keywordList then return end

    local text = ""
    if keywords and #keywords > 0 then
        for i, word in ipairs(keywords) do
            text = text .. word
            if i < #keywords then
                text = text .. "\n"
            end
        end
    else
        text = "(nincsenek kulcsszavak)"
    end

    optionsPanel.keywordList:SetText(text)
end

optionsPanel:SetScript("OnShow", function(self)
    if not self.initialized then
        self.initialized = true

        -- Cím
        local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("AutoInvite – Beállítások")

        -- Engedélyezés checkbox
        local enableCheck = CreateFrame("CheckButton", nil, self, "InterfaceOptionsCheckButtonTemplate")
        enableCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
        enableCheck.Text:SetText("AutoInvite engedélyezése")
        enableCheck:SetScript("OnClick", function(btn)
            enabled = btn:GetChecked() and true or false
            SaveSettings()
        end)
        self.enableCheck = enableCheck

        -- Kulcsszavak címke
        local keywordsLabel = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        keywordsLabel:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -16)
        keywordsLabel:SetText("Kulcsszavak:")

        -- Kulcsszó lista (scroll nélküli egyszerű szöveg)
        local keywordListBG = CreateFrame("Frame", nil, self, "TooltipBackdropTemplate")
        keywordListBG:SetPoint("TOPLEFT", keywordsLabel, "BOTTOMLEFT", 0, -8)
        keywordListBG:SetSize(200, 120)

        local keywordList = keywordListBG:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        keywordList:SetPoint("TOPLEFT", 8, -8)
        keywordList:SetJustifyH("LEFT")
        keywordList:SetJustifyV("TOP")
        keywordList:SetWidth(184)
        self.keywordList = keywordList

        -- Új kulcsszó címke
        local addLabel = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        addLabel:SetPoint("TOPLEFT", keywordListBG, "TOPRIGHT", 16, 0)
        addLabel:SetText("Új kulcsszó:")

        -- Input mező
        local input = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
        input:SetSize(160, 20)
        input:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -4)
        input:SetAutoFocus(false)
        self.keywordInput = input

        -- Hozzáadás gomb
        local addButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        addButton:SetSize(80, 22)
        addButton:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -4)
        addButton:SetText("Hozzáadás")
        addButton:SetScript("OnClick", function()
            local text = input:GetText() or ""
            text = string.lower(strtrim(text))
            if text == "" then return end

            for _, word in ipairs(keywords) do
                if word == text then
                    print("|cffff0000A megadott kulcsszó már szerepel:|r " .. text)
                    return
                end
            end

            table.insert(keywords, text)
            SaveSettings()
            RefreshKeywordsList()
            input:SetText("")
        end)

        -- Eltávolítás gomb (utolsó kulcsszó törlése)
        local removeButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        removeButton:SetSize(80, 22)
        removeButton:SetPoint("LEFT", addButton, "RIGHT", 8, 0)
        removeButton:SetText("Eltávolítás")
        removeButton:SetScript("OnClick", function()
            local text = input:GetText() or ""
            text = string.lower(strtrim(text))

            if text == "" then
                -- ha nincs megadva, az utolsó kulcsszót töröljük
                if #keywords > 0 then
                    local removed = table.remove(keywords)
                    print("|cffff0000Törölve:|r " .. removed)
                end
            else
                local found = false
                for i, word in ipairs(keywords) do
                    if word == text then
                        table.remove(keywords, i)
                        print("|cffff0000Törölve:|r " .. text)
                        found = true
                        break
                    end
                end
                if not found then
                    print("|cffffff00Nem találtam ilyen kulcsszót:|r " .. text)
                end
            end

            SaveSettings()
            RefreshKeywordsList()
            input:SetText("")
        end)

        -- Reset gomb
        local resetButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        resetButton:SetSize(200, 22)
        resetButton:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 0, -8)
        resetButton:SetText("Alapértelmezett kulcsszavak visszaállítása")
        resetButton:SetScript("OnClick", function()
            keywords = { "portal", "port" }
            SaveSettings()
            RefreshKeywordsList()
            print("|cffffff00Kulcsszavak visszaállítva alapértelmezettre.|r")
        end)
    end

    -- Frissítés megnyitáskor
    self.enableCheck:SetChecked(enabled and true or false)
    RefreshKeywordsList()
end)

-- InterfaceOptions_AddCategory(optionsPanel)

-- Slash parancs a panel megnyitásához
SLASH_AIOPTIONS1 = "/aioptions"
SlashCmdList["AIOPTIONS"] = function()
    InterfaceOptionsFrame_OpenToCategory(optionsPanel)
    InterfaceOptionsFrame_OpenToCategory(optionsPanel) -- kétszer kell, Blizzard bug miatt
end

-------------------------------------------------
-- Minimap ikon
-------------------------------------------------

-- Minimap gomb TBC Classic kompatibilis módon
local minimapButton = CreateFrame("Button", "AutoInviteRevyMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

-- 🔥 TBC-ben ez KRITIKUS
minimapButton:SetFrameStrata("HIGH")
minimapButton:SetFrameLevel(10)

minimapButton:EnableMouse(true)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:Show()

-- Ikon
local icon = minimapButton:CreateTexture(nil, "ARTWORK")
icon:SetTexture("Interface\\AddOns\\AutoInviteRevy\\AutoInviteIcon")
icon:SetAllPoints()

-- Border
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetWidth(54)
border:SetHeight(54)
border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)

-- Highlight
local highlight = minimapButton:CreateTexture(nil, "HIGHLIGHT")
highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

-- Tooltip
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("AutoInviteRevy", 1, 1, 1)
    GameTooltip:AddLine("Bal klikk: Beállítások", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Jobb klikk: Be/Ki kapcsolás", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Kattintás
minimapButton:SetScript("OnClick", function(self, button)

    -- Jobb klikk: be/ki kapcsolás
    if button == "RightButton" then
        enabled = not enabled
        SaveSettings()
        if enabled then
            print("|cff00ff00AutoInvite engedélyezve.|r")
        else
            print("|cffff0000AutoInvite letiltva.|r")
        end
        return
    end

    -- Bal klikk: beállítások panel (ha létezik)
    if button == "LeftButton" then
        if optionsPanel and optionsPanel:IsShown() then
            optionsPanel:Hide()
        elseif optionsPanel then
            optionsPanel:Show()
        else
            print("|cffffff00Nincs beállítási panel definiálva az addonban.|r")
        end
        return
    end

end)


