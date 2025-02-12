-- GuildLottery Addon for WoW Classic with UI, Minimap Icon, and Saved Data

local GuildLottery = CreateFrame("Frame", "GuildLotteryFrame")
GuildLottery:RegisterEvent("MAIL_SHOW")
GuildLottery:RegisterEvent("MAIL_CLOSED")
GuildLottery:RegisterEvent("ADDON_LOADED")

-- Saved Variables
GuildLotteryDB = GuildLotteryDB or {tickets = {}, totalTickets = 0, history = {}}

-- Function to check mail and track gold received
local function ScanMail()
    for i = 1, GetInboxNumItems() do
        local _, _, sender, subject, money = GetInboxHeaderInfo(i)
        if money and money > 0 then
            local goldAmount = floor(money / 10000) -- Convert copper to gold
            if goldAmount > 0 then
                local startTicket = GuildLotteryDB.totalTickets + 1
                local endTicket = startTicket + goldAmount - 1
                GuildLotteryDB.tickets[#GuildLotteryDB.tickets + 1] = {sender = sender, start = startTicket, finish = endTicket}
                GuildLotteryDB.totalTickets = endTicket
            end
        end
    end
end

-- UI Panel
local uiFrame = CreateFrame("Frame", "GuildLotteryUI", UIParent, "BasicFrameTemplateWithInset")
uiFrame:SetSize(300, 400)
uiFrame:SetPoint("CENTER")
uiFrame:SetMovable(true)
uiFrame:EnableMouse(true)
uiFrame:RegisterForDrag("LeftButton")
uiFrame:SetScript("OnDragStart", uiFrame.StartMoving)
uiFrame:SetScript("OnDragStop", uiFrame.StopMovingOrSizing)
uiFrame:Hide()

uiFrame.title = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
uiFrame.title:SetPoint("TOP", uiFrame, "TOP", 0, -10)
uiFrame.title:SetText("Guild Lottery")

-- UI Buttons
local announceButton = CreateFrame("Button", nil, uiFrame, "GameMenuButtonTemplate")
announceButton:SetSize(120, 30)
announceButton:SetPoint("TOP", uiFrame, "TOP", 0, -40)
announceButton:SetText("Announce Tickets")
announceButton:SetScript("OnClick", function() AnnounceTickets() end)

local rollButton = CreateFrame("Button", nil, uiFrame, "GameMenuButtonTemplate")
rollButton:SetSize(120, 30)
rollButton:SetPoint("TOP", announceButton, "BOTTOM", 0, -10)
rollButton:SetText("Roll Winner")
rollButton:SetScript("OnClick", function() RollWinner() end)

local resetButton = CreateFrame("Button", nil, uiFrame, "GameMenuButtonTemplate")
resetButton:SetSize(120, 30)
resetButton:SetPoint("TOP", rollButton, "BOTTOM", 0, -10)
resetButton:SetText("Reset Lottery")
resetButton:SetScript("OnClick", function() ResetLottery() end)

-- Minimap Button
local minimapButton = CreateFrame("Button", "GuildLotteryMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetNormalTexture("Interface\AddOns\GuildLottery\icon.tga")
minimapButton:SetHighlightTexture("Interface\Minimap\UI-Minimap-ZoomButton-Highlight")
minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
minimapButton:SetScript("OnClick", function()
    if uiFrame:IsShown() then
        uiFrame:Hide()
    else
        uiFrame:Show()
    end
end)

-- Announce tickets
local function AnnounceTickets()
    SendChatMessage("Guild Lottery Ticket Assignments:", "GUILD")
    for _, ticket in ipairs(GuildLotteryDB.tickets) do
        SendChatMessage(ticket.sender .. " has tickets " .. ticket.start .. " to " .. ticket.finish, "GUILD")
    end
end

-- Roll a winner
local function RollWinner()
    if GuildLotteryDB.totalTickets > 0 then
        local winningTicket = math.random(1, GuildLotteryDB.totalTickets)
        for _, ticket in ipairs(GuildLotteryDB.tickets) do
            if winningTicket >= ticket.start and winningTicket <= ticket.finish then
                SendChatMessage("The lottery winner is: " .. ticket.sender .. " with ticket #" .. winningTicket, "GUILD")
                table.insert(GuildLotteryDB.history, {winner = ticket.sender, ticket = winningTicket, date = date("%Y-%m-%d")})
                return
            end
        end
    else
        SendChatMessage("No tickets sold for this lottery round.", "GUILD")
    end
end

-- Reset lottery data
local function ResetLottery()
    GuildLotteryDB.tickets = {}
    GuildLotteryDB.totalTickets = 0
    SendChatMessage("Guild Lottery has been reset for the next round!", "GUILD")
end

-- Slash Commands
SLASH_GUILDLOTTERY1 = "/lottery"
SlashCmdList["GUILDLOTTERY"] = function(msg)
    if msg == "announce" then
        AnnounceTickets()
    elseif msg == "roll" then
        RollWinner()
    elseif msg == "reset" then
        ResetLottery()
    elseif msg == "show" then
        uiFrame:Show()
    else
        print("Guild Lottery Commands: \n/lottery announce - Announce ticket assignments\n/lottery roll - Roll for a winner\n/lottery reset - Reset the lottery\n/lottery show - Open the UI")
    end
end