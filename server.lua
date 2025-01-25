local Config = {
    frameWork = "ESX", -- or "QBCORE"
    getSharedObject = "esx:getSharedObject", -- or QBCore:getObject
    webHook = "https://discord.com/api/webhooks/xxx/xxx", -- replace webhook

    jobLockedEvents = {
        {eventName = "esx_policejob:handcuff", authorizedJobs = {"police","sheriff"}},
        {eventName = "esx_jail:sendToJail", authorizedJobs = {"police","sheriff"}},
    }
}

local function logToDiscord(source, eventName, currentJob)
    local embedContent = {
        ["color"] = 3447003,
        ["type"] = "rich",
        ["fields"] = {
            {
                ["name"] = "**A player tried to trigger a job locked event:**",
                ["value"] = "```".. 
                    "Player Name: ".. GetPlayerName(source) .."\n".. 
                    "Server ID: ".. tostring(source) .."\n".. 
                    "Event Name: ".. eventName.."\n".. 
                    "Player Job: ".. currentJob.."\n".. 
                    "Date: ".. os.date("%A, %d %B %Y - %X") .."\n"
                .."```",
                ["inline"] = false,
            }
        },
    }

    PerformHttpRequest(Config.webHook, function(err, text, headers)
        if err ~= 200 then
            print("[Discord Webhook] Error sending log: "..err)
        end
    end, "POST", json.encode({embeds = {embedContent}}), {["Content-Type"] = "application/json"})
end

local function getPlayerJob(source)
    if Config.frameWork == "ESX" then
        local player = ESX.GetPlayerFromId(source)
        return player and player.job.name or "Unknown"
    elseif Config.frameWork == "QBCORE" then
        local player = QBCore.Functions.GetPlayer(source)
        return player and player.PlayerData.job.name or "Unknown"
    end
    return "Unknown"
end

CreateThread(function()
    if Config.frameWork == "ESX" then
        while ESX == nil do
            TriggerEvent(Config.getSharedObject, function(obj)
                ESX = obj
            end)
            Wait(10)
        end
    elseif Config.frameWork == "QBCORE" then
        while QBCore == nil do
            TriggerEvent(Config.getSharedObject, function(obj)
                QBCore = obj
            end)
            Wait(10)
        end
    end

    for _, eventConfig in ipairs(Config.jobLockedEvents) do
        AddEventHandler(eventConfig.eventName, function()
            local source = source
            local playerJob = getPlayerJob(source)

            local isAuthorized = false
            for _, authorizedJob in ipairs(eventConfig.authorizedJobs) do
                if playerJob == authorizedJob then
                    isAuthorized = true
                    break
                end
            end

            if not isAuthorized then
                logToDiscord(source, eventConfig.eventName, playerJob)
            end
        end)
    end
end)
