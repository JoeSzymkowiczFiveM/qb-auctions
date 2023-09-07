local QBCore = exports['qb-core']:GetCoreObject()

-- AddEventHandler('onClientResourceStart', function(resourceName)
--     if GetCurrentResourceName() ~= resourceName then return end
--     while QBCore == nil do
--         Wait(200)
--     end
-- end)

-- RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
-- AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
--     PlayerJob = QBCore.Functions.GetPlayerData().job
-- end)

-- RegisterNetEvent('QBCore:Client:OnPlayerUnload')
-- AddEventHandler('QBCore:Client:OnPlayerUnload', function()
-- end)

-- RegisterNetEvent('QBCore:Client:OnJobUpdate')
-- AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
--     PlayerJob = JobInfo

--     if PlayerJob.name == 'job' then
--         TriggerServerEvent('qb-carboost:server:removeBooster')
--     end
-- end)

RegisterNetEvent('qb-auctions:client:putItemsOnAuction', function()
    local options = {}
    for _, v in pairs(QBCore.Functions.GetPlayerData().items) do
        local label = v.label
        options[#options+1] = {
            value = v.slot,
            label = label,
        }
    end

    local input = lib.inputDialog('Sell Items For Auction', {
        { type = 'select', label = 'Choose Item', options = options},
        { type = "input", label = "Starting Bid Price", placeholder = "100", icon = 'dollar-sign' },
        { type = "input", label = "Bid Increment", placeholder = "20", icon = 'dollar-sign' },
        { type = "input", label = "Buy It Now Price", placeholder = "200", icon = 'dollar-sign' },
    })
    if input == nil then return
    elseif input[1] == nil then
        QBCore.Functions.Notify('You didn\'t select an item..', 'error', 3000)
        return
    elseif tonumber(input[2]) == nil and tonumber(input[2]) > 0 then
        QBCore.Functions.Notify('You didn\'t enter a Starting Bid price..', 'error', 3000)
        return
    elseif tonumber(input[4]) == nil and tonumber(input[4]) > 0 then
        QBCore.Functions.Notify('You didn\'t enter a Buy It Now price..', 'error', 3000)
        return
    elseif tonumber(input[3]) == nil and tonumber(input[3]) > 0 then
        QBCore.Functions.Notify('You didn\'t enter a Bid Increment price..', 'error', 3000)
        return
    end
    TriggerServerEvent('qb-auctions:server:putItemsOnAuction', input)
end)

RegisterNetEvent('qb-auctions:client:getWonItems')
AddEventHandler('qb-auctions:client:getWonItems', function()
    local result = lib.callback.await('qb-auctions:server:getWonItems', false)
    local options = {}
    if result ~= nil then
        for k, v in pairs(result) do
            options[#options+1] = {
                value = v._id,
                label = v.label,
            }
        end
    else
        options[#options+1] = {
            value = 0,
            label = 'No items available',
        }
    end

    local input = lib.inputDialog('Pickup Won Auction Items', {
        { type = 'select', label = 'Choose Item', options = options},
    })
    if input ~= nil then
        TriggerServerEvent('qb-auctions:server:recieveWonItems', input[1], securityToken)
    end
end)

