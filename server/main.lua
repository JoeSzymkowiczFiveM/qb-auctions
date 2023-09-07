local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    local epoch = os.time()*1000
    --print(epoch)
    --MongoDB.Sync.delete( { collection = 'auctions',query = {} } )
    --local result = MongoDB.Sync.find({collection = 'auctions', query = { ["enddate"] = { ["$lte"] = epoch } } })
    MongoDB.Sync.delete({collection = 'auctions', query = { ["enddate"] = { ["$lte"] = epoch } } })
end)

lib.callback.register('qb-auctions:server:GetAuctions', function(source)
    local Auctions = {}
    local result = MongoDB.Sync.find({collection = 'auctions', query = { active = true} })
    if result[1] ~= nil then
        Auctions = result
    end
    return Auctions
end)

RegisterServerEvent('qb-auctions:server:serverEvent', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    TriggerClientEvent('qb-auctions:client:clientEvent', src)
end)

RegisterServerEvent('qb-auctions:server:putItemsOnAuction', function(data)
    local src = source
    if data == nil then return end
    local Player = QBCore.Functions.GetPlayer(src)
    local slot = tonumber(data[1])
    local initialBidPrice = tonumber(data[2])
    local increment = tonumber(data[3])
    local buyItNowPrice = tonumber(data[4])
    local toItemData = Player.Functions.GetItemBySlot(slot)
    if toItemData ~= nil then
        toItemData.created = {[1] = toItemData.created[1]}
        if Player.Functions.RemoveItem(toItemData.name:lower(), 1, slot) then
            local insertResult = MongoDB.Sync.insertOne({
                collection = "auctions",
                document = {
                    item = toItemData.name:lower(), buyItNowPrice = buyItNowPrice, active = true, increment = increment, highBidder = Player.PlayerData.citizenid,
                    currentBidPrice = initialBidPrice, degrade = toItemData.degrade, info = toItemData.info, label = toItemData.label, citizenid = nil,
                    seller = Player.PlayerData.citizenid, itemcreated = toItemData.created,
                    startdate = os.time()*1000, enddate = (os.time()*1000)+2592000
                }
            })
            local findResult = MongoDB.Sync.findOne({collection = 'auctions', query = { _id = insertResult.insertedIds[1]} })
            TriggerClientEvent('qb-phone:client:addAuctionItem', -1, findResult[1])
            TriggerClientEvent('qb-phone:client:AuctionNotification', -1, { message = "A new item is up for auction!" })
            Wait(1500)
            TriggerClientEvent('inventory:client:CheckDroppedItem', src, toItemData.name:lower(), slot)
        end
    end
end)

RegisterServerEvent('qb-auctions:server:buyItNowAuction', function(data)
    local src = source
    if data == nil then return end
    local id = data
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local result = MongoDB.Sync.findOne({collection = 'auctions', query = { _id = id, active = true } })
    if Player.Functions.RemoveMoney('bank', result[1].buyItNowPrice, 'auction-purchase') then
        MongoDB.Sync.updateOne({collection = 'auctions', query = { _id = id, active = true }, update = { ["$set"] = { active = false, citizenid = citizenid } }})
        TriggerClientEvent('qb-phone:client:removeAuctionItem', -1, id)
        TriggerClientEvent('qb-phone:client:postBuyItNowClose', src)
        QBCore.Functions.CreatePaycheck(result[1]['seller'], 'Auction Sale', result[1].buyItNowPrice, "You sold an item on auction for $"..tonumber(result[1].buyItNowPrice))
    else
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money for that..', 'error')
    end
end)

RegisterServerEvent('qb-auctions:server:bidAuction', function(data)
    local src = source
    if data == nil then return end
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local id = data
    local result = MongoDB.Sync.findOne({collection = 'auctions', query = { _id = id, active = true } })
    if result[1]['highBidder'] ~= citizenid then
        MongoDB.Sync.updateOne({collection = 'auctions', query = { _id = id, active = true }, update = { ["$set"] = { highBidder = citizenid }, ["$inc"] = { currentBidPrice = result[1]['increment'] } }})
        TriggerClientEvent('qb-phone:client:updateAuctionItem', -1, id, result[1]['increment'] + result[1]['currentBidPrice'], citizenid)
        TriggerClientEvent('qb-phone:client:postBuyItNowClose', src)
        TriggerClientEvent('QBCore:Notify', src, 'Bid accepted..', "success")
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are currently the high bidder..', 'error')
    end
end)

lib.callback.register('qb-auctions:server:getWonItems', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local result = MongoDB.Sync.find({collection = 'auctions', query = { active = false, citizenid = citizenid } })
    if result[1] ~= nil then
        return result
    else
        return nil
    end
end)

RegisterServerEvent('qb-auctions:server:recieveWonItems', function(data, securityToken)
    if not exports['salty_tokenizer']:secureServerEvent(GetCurrentResourceName(), source, securityToken) then
		return false
	end

    local src = source
    if data == nil then return end
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local result = MongoDB.Sync.findOne({collection = 'auctions', query = { _id = data, active = false, citizenid = citizenid } })
    if result[1] ~= nil then
        if Player.Functions.AddItem(result[1]['item'], 1, nil, result[1]['info'], result[1]['itemCreated']) then
            MongoDB.Sync.deleteOne({collection = 'auctions', query = {_id = result[1]['_id']}})
        end
    end
end)