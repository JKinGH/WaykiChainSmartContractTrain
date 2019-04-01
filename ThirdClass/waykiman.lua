mylib = require ("mylib")

-------------------------------------------- common function ---------------------------------------------
LOG_TYPE =
{
    ENUM_STRING = 0,
    ENUM_NUMBER = 1
}

ADDR_TYPE = {
    REGID  = 1,
    BASE58 = 2
}
OP_TYPE = {
    ADD_FREE = 1,
    SUB_FREE = 2
}

APP_OPERATE_TYPE=
{
    setOwner  = 0x01,
    setMinMax = 0x02,
    setPercentages = 0x03,
    joinGame     = 0x05, 
    claimWin     = 0x06, 
    withdraw     = 0x07,  
    withdrawPot = 0x08, 
    withdrawAffiliateBalance = 0x09,
    withdrawHighscorePot = 0x0a,
    stopContract = 0x0b,
    setScore = 0x0c
}

POT_TYPE = {
    developer = 0x01,
    charity = 0x02,
    surprise = 0x03
}

--print log to vm.log if config 'debug=vm' in WaykiChain.conf
LogMsg = function (msg)
    local logTable = {
        key = 0,
        length = string.len(msg),
        value = msg
    }
    mylib.LogPrint(logTable)
end

--Get all of element in the table
Unpack = function (t,i)
    i = i or 1
    if t[i] then
        return t[i], Unpack(t,i+1)
    end
end

--Determine if the data is non-empty
TableIsNotEmpty = function (t)
    return _G.next(t) ~= nil
end

--Get the value of by key in the blockchain contract
GetContractValue = function (key)
    assert(#key > 0, "Key is empty")

    local tValue = { mylib.ReadData(key) }
    if TableIsNotEmpty(tValue) then
        return true,tValue
    else
        LogMsg("Key not exist")
        return false,nil
    end
end

--Write/modify date in the blockChain
WriteOrModify = function (isConfig, writeTbl)
    if not isConfig then
        if not mylib.WriteData(writeTbl) then    error(" Write error: Failed to write table with key "..writeTbl.key.." and length "..writeTbl.length.. " and value "..Serialize (writeTbl.value, true)) end
    else
        if not mylib.ModifyData(writeTbl) then error(" Modify error: Failed to modify table with key "..writeTbl.key.." and value "..Serialize (writeTbl.value, true)) end
    end
end

--Get smart contract content
GetContractTxParam = function (startIndex, length)
    assert(startIndex > 0, "GetContractTxParam start error(<=0).")
    assert(length > 0, "GetContractTxParam length error(<=0).")
    assert(startIndex+length-1 <= #contract, "GetContractTxParam length ".. length .." exceeds limit: " .. #contract)

    local newTbl = {}
    local i = 1
    for i = 1,length do
        newTbl[i] = contract[startIndex+i-1]
    end
    return newTbl
end

--Compare whether t1 and t2 are equal or not
MemIsEqual = function (t1,t2)
    assert(TableIsNotEmpty(t1), "t1 is empty")
    assert(TableIsNotEmpty(t2), "t2 is empty")

    if(#t1 ~= #t2) then
        return false
    end

    local i = 1
    for i = #t1,1,-1 do
        if t1[i] ~= t2[i] then
            return false
        end
    end
    return true
end

--Get the WICC amount transferred by the contract caller to the smart contract
GetCurTxPayAmount = function ()
    local payMoney = mylib.ByteToInteger(mylib.GetCurTxPayAmount())
    assert(payMoney >= 0,"GetCurrTxPayAmount: payMoney < 0")
    return payMoney
end

--Get msg.sender
GetCurrTxAccountAddress = function ()
    local accountTbl = {mylib.GetCurTxAccount()}
    return {mylib.GetBase58Addr(Unpack(accountTbl))}
end

--Convert a string to an byte table
GetByte = function(param)
    return {string.byte(param,1,string.len(param))}
end


--add key-value data to blockchain
AddStrkeyValueToDb = function (Strkey,Value)
    local t = type(Value)
    local value_table = {}
    if t == "table" then
        value_table = Value
    else
        value_table = GetByte(Value)
    end

    local writeTbl = {
        key = Strkey,
        length = #value_table,
        value = {}
    }
    writeTbl.value = value_table
    
    local exist,_ = GetContractValue (Strkey)
    if (exist == true) then
        WriteOrModify(true,writeTbl)
    else
        WriteOrModify(false,writeTbl)
    end 
    LogMsg(" WriteData right.")
end

--new a table which lenght is size ,content is {0x00,0x00...}
function NewArray(size)
    local t = {}
    for i = 1, size do
        t[i] = 0
    end
    return t
end

Serialize = function(obj, hex)
    local lua = ""
    local t = type(obj)

    if t == "table" then
        for i=1, #obj do
            if hex == false then
                lua = lua .. string.format("%c",obj[i])
            else
                lua = lua .. string.format("%02x",obj[i])
            end
        end
    elseif t == "nil" then
        return nil
    else
        error("can not serialize a " .. t .. " type.")
    end

    return lua
end
------------------------------------------common function end -----------------------------------------------------
--player keys
height_key = "height"
stake_key = "stake"
player1_key = "player1"
player2_key = "player2"
score_key = "score"
team_key = "key"
referrer_key = "referrer"

--pot keys
developerPot_key = "developerPot"
charityPot_key = "charityPot"
highscorePot_key = "highscorePot"
surprisePot_key = "surprisePot"

developerPercent_key = "developerPercent"
charityPercent_key = "charityPercent"
highscorePercent_key = "highscorePercent"
surprisePercent_key = "surprisePercent"
winnerPercent_key = "winnerPercent"

affiliateBalance_key = "affiliateBalance"
affiliatePercent_key = "affiliatePercent"

--highscore
highscoreHolder_key = "highscoreHolder"

--the minimum and maximum stake
minStake_key = "minStake"
maxStake_key = "maxStake"

--the owner of the contract
owner_key  = "owner"
--the address allowed to sign claim requests sent by users
authorized_key = "authorized"

senderIsOwner = function()
    local msg_senderTbl = GetCurrTxAccountAddress() -- 34bytes table
    local exist,ownerTbl =  GetContractValue(owner_key)-- 34bytes table
    if(exist == false) then
        return true
    else
        return MemIsEqual(msg_senderTbl,ownerTbl) == true
    end
end

senderIsAuthorized = function()
    local msg_senderTbl = GetCurrTxAccountAddress() -- 34bytes table
    local exist,authorizedTbl =  GetContractValue(authorized_key)-- 34bytes table
    if(exist == false) then
        return false
    else
        return MemIsEqual(msg_senderTbl,authorizedTbl) == true
    end
end

--set  minimum stake and maximum stake
--only callable by the owner
setMinMax = function(minTbl,maxTbl)
    assert(senderIsOwner() == true, "only the owner my call this function")
    --the minimum and maximum stake
    AddStrkeyValueToDb(minStake_key,minTbl)
    AddStrkeyValueToDb(maxStake_key,maxTbl)
end

setOwner = function(addressTbl)
    assert(senderIsOwner() == true, "only the owner my call this function")
    AddStrkeyValueToDb(owner_key, addressTbl)
end

setPercentages = function(dev, aff, cha, hig, sur)
    assert(senderIsOwner() == true, "only the owner my call this function")
    local sumPot = mylib.ByteToInteger(Unpack(dev)) + mylib.ByteToInteger(Unpack(aff)) + mylib.ByteToInteger(Unpack(cha)) + mylib.ByteToInteger(Unpack(hig)) + mylib.ByteToInteger(Unpack(sur))
    assert(sumPot < 100, "sum of the pot percentages cannot be larger than 100. the sum is "..sumPot)
    AddStrkeyValueToDb(developerPercent_key,dev)
    AddStrkeyValueToDb(affiliatePercent_key,aff)
    AddStrkeyValueToDb(charityPercent_key,cha)
    AddStrkeyValueToDb(highscorePercent_key,hig)
    AddStrkeyValueToDb(surprisePercent_key,sur)
    local winnerPercent = 100 - sumPot
    AddStrkeyValueToDb(winnerPercent_key,{mylib.IntegerToByte8(winnerPercent)})
end

addPlayerToTeam = function(team)
    local msg_sender = Serialize(GetCurrTxAccountAddress(), true)
    local exist,_ =  GetContractValue(msg_sender..team_key)
    if (exist == false) then
        AddStrkeyValueToDb (msg_sender..team_key, team)
    end 
end

addReferrerForPlayer = function(referrer)
    local msg_sender = Serialize(GetCurrTxAccountAddress(), true)
    local exist,_ =  GetContractValue(msg_sender..score_key)
    if(exist == false) then
        AddStrkeyValueToDb (msg_sender..referrer_key, referrer)
    end
end

--INTERNAL FUNCTION: initiate a new game
--gameId :string
_initGame = function(gameId)
    local msg_value = GetCurTxPayAmount() --unit is sawi,1 wicc = 10^8 sawi
    local msg_senderTbl = GetCurrTxAccountAddress() -- 34bytes table
    local exist,minStakeTbl =  GetContractValue(minStake_key)
    assert(exist == true, "get minStake error!")
    local exist,maxStakeTbl =  GetContractValue(maxStake_key)
    assert(exist == true, "get maxStake error!")
    local minStake = mylib.ByteToInteger(Unpack(minStakeTbl))
    local maxStake = mylib.ByteToInteger(Unpack(maxStakeTbl))

    --check the requirements
    assert(msg_value <= maxStake, "stake needs to be lower than or equal to the max stake")
    assert(msg_value >= minStake, "stake needs to be at least the min stake")
    --create a new game object and store it on the blockchain. The key is the 12-byte-game-identifier
    --because we do not know the second player adress yet, we set the second player to 34bytes 0x00

    --in wayki,store data on the blockchain,must use the API named "mylib.WriteData"
    --I use the function AddStrkeyValueToDb which structure from "mylib.WriteData" to write data to blockchain.
    --in wayki ,no way to get the current time.so get current block height to substitute the now time
    local cur_height = mylib.GetCurRunEnvHeight()
    AddStrkeyValueToDb(gameId..height_key,{mylib.IntegerToByte8(cur_height)})
    AddStrkeyValueToDb(gameId..stake_key,{mylib.IntegerToByte8(msg_value)})
    AddStrkeyValueToDb(gameId..player1_key,msg_senderTbl)
    AddStrkeyValueToDb(gameId..player2_key,NewArray(34))
end

--INTERNAL FUNCTION: join an existing game
--gameId :string
_joinGame = function(gameId)
    --load the game from the storage
    local exist,player1Tbl =  GetContractValue(gameId..player1_key)-- 34bytes table
    assert(exist == true, "get player1Tbl error!")
    local exist,player2Tbl =  GetContractValue(gameId..player2_key)
    assert(exist == true, "get player2Tbl error!")
    local exist,stakeTbl =  GetContractValue(gameId..stake_key)-- 8bytes table
    assert(exist == true, "get stakeTbl error!")
    local stake = mylib.ByteToInteger(Unpack(stakeTbl))--unit is sawi,1 wicc = 10^8 sawi

    local msg_senderTbl = GetCurrTxAccountAddress() -- 34bytes table
    local msg_value = GetCurTxPayAmount() --unit is sawi,1 wicc = 10^8 sawi

    --check the requirements
    assert(MemIsEqual(player1Tbl,msg_senderTbl) == false, "cannot play with one self because player one is "..Serialize(player1Tbl).." or seriazlized as hex "..Serialize(player1Tbl, true).."in game with id "..gameId);
    assert(msg_value >= stake, "value does not suffice to join the game");
    assert(MemIsEqual(player2Tbl,NewArray(34)) == true, "there is already a second player in this game")
    
    --modify the game object in the database. update the second player address and the block height
    AddStrkeyValueToDb(gameId..player2_key,msg_senderTbl)
    local cur_height = mylib.GetCurRunEnvHeight()
    AddStrkeyValueToDb(gameId..height_key,{mylib.IntegerToByte8(cur_height)})
end

--[[
INTERFACE FUNCTION
initiate a new game or join an existing game.
gameId :string
--]]
joinGame = function (gameId)
    --load the game from the storage
    local exist,_ =  GetContractValue(gameId..player1_key)
    --if the game does not yet exist (in this case all params are "nil"), then initiate a new game
    if exist == false then
        _initGame(gameId)
    --else join an existing game
    else
        _joinGame(gameId)
    end
end

delete_game = function(gameId)
    local result = mylib.DeleteData(gameId..height_key)
    assert(result == true, "delete height error.")
    local result = mylib.DeleteData(gameId..stake_key)
    assert(result == true, "delete stake error.")
    local result = mylib.DeleteData(gameId..player1_key)
    assert(result == true, "delete player1 error.")
    local result = mylib.DeleteData(gameId..player2_key)
    assert(result == true, "delete player2 error.")
end

-- update any of the pots: developer, highscore, charity or surprise pot
updatePot = function(value, pot_key, percent_key)
    local exist,percentTbl = GetContractValue (percent_key)
    assert(exist == true, "contract was not yet configured")
    local exist,potTbl = GetContractValue(pot_key)-- 8bytes table
    local pot = value * mylib.ByteToInteger(Unpack(percentTbl)) / 100
    local oldPot = 0
    if (exist == true) then
        oldPot = mylib.ByteToInteger(Unpack(potTbl))
        --assert(TableIsNotEmpty(potTbl) or exist,"table potTbl is empty and exist is false")
        --assert(TableIsNotEmpty(potTbl), "table potTbl is empty and exist is true")
        --assert(oldPot ~= nil, "old pot is nil. ")
        --assert(type(oldPot) == "number", "the value of the "..pot_key.." is not a number. potTbl is "..Serialize(potTbl))
        pot =  pot + oldPot
    end
    local pot_rm0 = math.floor(pot)
    --assert(pot_rm0 < 400000,"pot is "..pot.." old pot read from blockchain is "..oldPot)
    AddStrkeyValueToDb(pot_key,{mylib.IntegerToByte8(pot_rm0)})
    --local exist,potTbl = GetContractValue(pot_key)
    --local stored = mylib.ByteToInteger(Unpack(potTbl))
    --assert(stored < 0, "original pot is "..pot.." and stored pot is "..stored)
end

-- add the affiliate percentage of the value to the referrer's balance.
-- if there is no referrer, the value goes into the developer pot
updateAffiliateBalance = function(value)
    local exist,percentTbl = GetContractValue (affiliatePercent_key)
    assert(exist == true, "contract was not yet configured")
    local pot = value * mylib.ByteToInteger(Unpack(percentTbl)) / 100
    local msg_sender = Serialize(GetCurrTxAccountAddress(), true)
    local exist, referrerTbl = GetContractValue (msg_sender..referrer_key)
    
    if(exist == true) then
        local referrer = Serialize (referrerTbl, true)
        local exist, balanceTbl = GetContractValue (referrer..affiliateBalance_key)
        if(exist == true) then
            pot = pot + mylib.ByteToInteger(Unpack(balanceTbl))
        end
        AddStrkeyValueToDb (msg_sender..referrer_key, pot)
    else
        local exist, balanceTbl = GetContractValue (developerPot_key)
        if(exist == true) then
            pot = pot + mylib.ByteToInteger(Unpack(balanceTbl))
        end
        AddStrkeyValueToDb (developerPot_key, pot)
    end
end


WriteAccountData = function (opType, addrType, accountIdTbl, moneyTbl)
    local writeOutputTbl = {
        addrType = addrType,
        accountIdTbl = accountIdTbl,
        operatorType = opType,
        outHeight = 0,
        moneyTbl = moneyTbl
    }
    assert(mylib.WriteOutput(writeOutputTbl),"WriteAccountData" .. opType .. " err")
end

TransferToAddr = function (addrType, accTbl, moneyTbl)
    assert(TableIsNotEmpty(accTbl), "WriteWithdrawal accTbl empty")
    assert(TableIsNotEmpty(moneyTbl), "WriteWithdrawal moneyTbl empty")
    WriteAccountData(OP_TYPE.ADD_FREE, addrType, accTbl, moneyTbl)
    local contractRegid = {mylib.GetScriptID()}
    WriteAccountData(OP_TYPE.SUB_FREE, ADDR_TYPE.REGID, contractRegid, moneyTbl)
    return true
end


--[[
     INTERFACE FUCNTION
     The winner can claim his winnings, but only with a signature from the signing address set by the contract owner.
     usually, the pot would be distributed amongst the winner, the developers, the affiliate partner, a charity and the surprise pot
     but for simplicity, we will give all to the developer here, and we can add the distribution later
     gameId : string
--]]
claimWin = function(gameId)
    --load the game from the storage
    local exist,player2Tbl =  GetContractValue(gameId..player2_key)
    assert(exist == true, "get player2Tbl error!")
    local exist,player1Tbl =  GetContractValue(gameId..player1_key)
    assert(exist == true, "get player1Tbl error!")
    local exist,stakeTbl =  GetContractValue(gameId..stake_key)-- 8bytes table
    assert(exist == true, "get stakeTbl error!")
    local exist, winnerPercentTbl = GetContractValue(winnerPercent_key)
    assert(exist == true, "get winnerPercentTbl error!")
    local stake = mylib.ByteToInteger(Unpack(stakeTbl))--unit is sawi,1 wicc = 10^8 sawi
    local msg_senderTbl = GetCurrTxAccountAddress() -- 34bytes table
    local winnerPercent = mylib.ByteToInteger(Unpack(winnerPercentTbl))

    --check the requirements
    assert(MemIsEqual(player2Tbl,NewArray(34)) == false, "game has not started yet")
    assert(MemIsEqual(msg_senderTbl,player1Tbl) == true or
            MemIsEqual(msg_senderTbl,player2Tbl) == true , "sender is not a player in this game")
    
    --complete value of the game is the sum of the user bets (both paid the same, so 2x)
    local value = 2*stake
    --add to the player score
    local isWinnerTeam = addScore (stake)
    --delete the game from the storage, so the claim can not be processed a second time
    delete_game(gameId)
    --some percentage of the value goes to the the different pots. 
    updatePot(value, developerPot_key, developerPercent_key)
    updatePot(value, surprisePot_key, surprisePercent_key)
    updatePot(value, charityPot_key, charityPercent_key)
    updateAffiliateBalance(value)
    
    -- if the player belongs to the winning game, he does not have to pay tribute to the highscore holder
    if(isWinnerTeam == true) then
        local exist, highscorePercentTbl = GetContractValue (highscorePercent_key)
        assert(exist == true, "get highscorePercentTbl error")
        winnerPercent = winnerPercent + mylib.ByteToInteger(Unpack(highscorePercentTbl))
    else
        updatePot(value, highscorePot_key, highscorePercent_key)
    end
    
    local win = winnerPercent * value / 100
    local win_rm0 = tonumber(string.format('%d',win))
    local winTbl = {mylib.IntegerToByte8(win_rm0)}
    
    --transfer the win to the caller
    TransferToAddr(ADDR_TYPE.BASE58,msg_senderTbl,winTbl)
end

-- adds the score to the player and checks if there is a new highscore (holder)
-- returns the winning 
addScore = function(stake)
    local playerTbl = GetCurrTxAccountAddress ()
    local player = Serialize (playerTbl, true)
    local holderExists, highscoreHolderTbl = GetContractValue (highscoreHolder_key)
    local highscoreHolder = player
    if(holderExists == true) then
        highscoreHolder = Serialize (highscoreHolderTbl, true)
    else
        AddStrkeyValueToDb (highscoreHolder_key, playerTbl)
    end
    
    local x = stake / 10000000 --todo: take min bet
    local score = (61 * x + 100) / ( x + 100)
    local diffTeams = differentTeams(highscoreHolder, player)
    if(holderExists == false or diffTeams == true) then
        local extra = score * 25 / 100
        if(extra == 0) then
            extra = 1
        end
        score = score + extra
    end
    score = math.floor(score)
    local playerScoreKey = player..score_key
    local exist, playerScoreTbl = GetContractValue (playerScoreKey)
    if(exist == true) then
        score = score + mylib.ByteToInteger(Unpack(playerScoreTbl))
    end
    local scoreTbl = {mylib.IntegerToByte8(score)}
    assert(stake > 0, "stake is zero")
    assert(score > 0, "score is 0. stake was "..stake)
    assert(#scoreTbl > 0, "score table is empty. score was "..score)
    AddStrkeyValueToDb (playerScoreKey, scoreTbl)
    
    if(holderExists == true and MemIsEqual(playerTbl, highscoreHolderTbl) == false) then
        local exist, highscoreTbl = GetContractValue (highscoreHolder..score_key)
        local highscore = 0
        if(exist == true) then
            highscore = mylib.ByteToInteger(Unpack(highscoreTbl))
        end
        if(score > highscore) then
            local exist,highscorePotTbl = GetContractValue (highscorePot_key)
            if(exist == true)  then
                local highscorePot = mylib.ByteToInteger(Unpack(highscorePotTbl))
                if(highscorePot > 0) then
                    AddStrkeyValueToDb (highscorePot_key, {mylib.IntegerToByte8(0)})
                    TransferToAddr(ADDR_TYPE.BASE58,playerTbl,highscorePotTbl)
                end
            end
            AddStrkeyValueToDb (highscoreHolder_key, playerTbl)
        end
    end
    return diffTeams == false
end

differentTeams = function(player1, player2)
    local exist1, team1 = GetContractValue (player1..team_key)
    local exist2, team2 = GetContractValue (player2..team_key)
    if (exist1 == true and exist2 == true and MemIsEqual (team1, team2) == true) then
        return false
    else
        return true
    end
end

--[[
     INTERFACE FUNCTION
     allow the player to withdraw from the game stake in case no second player joined or the game was not ended within the
     minimum waiting time
     -- gameId :string
--]]
withdraw = function(gameId)
    --load the game from the storage
    local exist,player2Tbl =  GetContractValue(gameId..player2_key)
    assert(exist == true, "get player2Tbl error!")
    local exist,player1Tbl =  GetContractValue(gameId..player1_key)
    assert(exist == true, "get player1Tbl error!")
    local exist,stakeTbl =  GetContractValue(gameId..stake_key)-- 8bytes table
    assert(exist == true, "get stakeTbl error!")
    local stake = mylib.ByteToInteger(Unpack(stakeTbl))--unit is sawi,1 wicc = 10^8 sawi
    local exist,heightTbl =  GetContractValue(gameId..height_key)-- 8bytes table
    assert(exist == true, "get heightTbl error!")
    local height = mylib.ByteToInteger(Unpack(heightTbl))

    local msg_senderTbl = GetCurrTxAccountAddress() -- 34bytes table
    local cur_height = mylib.GetCurRunEnvHeight()

    --if the caller is player1
    if MemIsEqual(msg_senderTbl,player1Tbl) == true then
        --if no second player exists delete the game and transfer the stake to the caller
        if MemIsEqual(player2Tbl,NewArray(34)) == true then
            delete_game(gameId)
            TransferToAddr(ADDR_TYPE.BASE58,msg_senderTbl,stakeTbl)
        --[[
          if a second player exists, but nobody made a claim within one hour,
          transfer the stake to both players and delete the game
          in wayki,calculate time using block height difference, gen 1 block every 10s by DPOS.
          360 blocks means 3600 second = one hour
         --]]
        elseif cur_height - height > 360 then
            delete_game(gameId)
            TransferToAddr(ADDR_TYPE.BASE58,msg_senderTbl,stakeTbl)
            TransferToAddr(ADDR_TYPE.BASE58,player2Tbl,stakeTbl)
        else
            --error
            error("minimum waiting time has not yet passed. sender is player 1 and player to is "..Serialize(player2Tbl).." in game id "..gameId)
        end
    elseif MemIsEqual(msg_senderTbl,player2Tbl) == true then
        if cur_height - height > 360 then
            delete_game(gameId)
            TransferToAddr(ADDR_TYPE.BASE58,msg_senderTbl,stakeTbl)
            TransferToAddr(ADDR_TYPE.BASE58,player1Tbl,stakeTbl)
        else
            --error
            error("minimum waiting time has not yet passed")
        end
    else
        --error
        error("sender is not a player in this game")
    end
end


--[[
     INTERFACE FUNCTION
     withdraw from the developer pot
 --]]
withdrawPot = function(pot_key, receiverTbl)
    assert(senderIsOwner() == true, "only the owner my call this function")
    --copy the developer pot from storage into memory
    local exist,potTbl = GetContractValue(pot_key)-- 8bytes table
    assert(exist == true, "get potTbl error!")
    --set the developer pot to 0 before transfering the money
    AddStrkeyValueToDb(pot_key,{mylib.IntegerToByte8(0)})
    --transfer the money to the contract owner
    TransferToAddr(ADDR_TYPE.BASE58,receiverTbl,potTbl)
end

withdrawAffiliateBalance = function()
    local msgSender = GetCurrTxAccountAddress ()
    local key = Serialize(msgSender)..affiliateBalance_key
    local exist,affiliateBalanceTbl = GetContractValue (key)
    assert(exist == true, "sender has no affiliate balance")
    local balance = mylib.IntegerToByte8(affiliateBalanceTbl)
    assert(balance > 0, "affiliate balance is zero")
    AddStrkeyValueToDb(key,{mylib.IntegerToByte8(0)})
    TransferToAddr (ADDR_TYPE.BASE58,msgSender,affiliateBalanceTbl)
end

withdrawHighscorePot = function()
    local exist,highscoreHolderTbl =  GetContractValue(highscoreHolder_key)-- 34bytes table
    assert(exist == true, "there is no highscore holder")
    local exist,highscorePotTbl = GetContractValue (highscorePot_key)
    assert(exist == true, "there is no highscore pot")
    local pot = mylib.IntegerToByte8(highscorePotTbl)
    assert(pot > 0, "highscore pot is empty")
    AddStrkeyValueToDb(highscorePot_key,{mylib.IntegerToByte8(0)})
    TransferToAddr (ADDR_TYPE.BASE58,highscoreHolderTbl,highscorePotTbl)
end

stopContract = function()
    assert(senderIsOwner() == true, "only the owner my call this function")
    AddStrkeyValueToDb ("contractClosed",0x01)
    withdrawAll()
end

withdrawAll = function()
    local contractRegidTbl = {mylib.GetScriptID()}
    local contractAddressTbl = {mylib.GetBase58Addr(Unpack(contractRegidTbl))}
    local contractBalanceTbl = {mylib.QueryAccountBalance(Unpack(contractAddressTbl))}
    local exist, ownerTbl = GetContractValue (owner_key)
    assert(exist == true, "owner needs to exist in oder to withdraw everything")
    if(mylib.ByteToInteger(Unpack(ownerTbl)) > 0) then
        TransferToAddr (ADDR_TYPE.BASE58,ownerTbl,contractBalanceTbl)
    end
end

-- if there is a contract update, allow the owner to set the scores of the players on the new contract
setScore = function(playerTbl, scoreTbl, teamTbl)
    assert(senderIsOwner() == true, "only the owner my call this function")
    local player = Serialize (playerTbl)
    AddStrkeyValueToDb (player..score_key, scoreTbl)
    AddStrkeyValueToDb (player..team_key, teamTbl)
end 

--In waykichain smart contract , exist a Global variable named "contract"
--The variable means the calling parameter from caller
Main = function()

    assert(#contract >=2, "Param length error (<2): " ..#contract )
    assert(contract[1] == 0xf0, "Param MagicNo error (~=0xf0): " .. contract[1])
    
    local exist, contractClosed = GetContractValue ("contractClosed")
    assert(exist == false, "contract has been closed")

    if contract[2] == APP_OPERATE_TYPE.setMinMax then
        --[[
        If the calling parameter is
        f0017758466a61547355427463567a32416a52794a4841554138485942473878614d48351027000000000000204e000000000000
      ==f0(1byte) + 01(1byte) + 7758466a61547355427463567a32416a52794a4841554138485942473878614d4835(34bytes) +
        1027000000000000(8bytes) + 204e000000000000(8bytes)
        --]]

        --check the calling parameter length
        assert(#contract >= 1+1+8+8, "Param length error : " ..#contract )
        local minTbl = GetContractTxParam(2+1,8)
        local maxTbl = GetContractTxParam(2+8+1,8)
        setMinMax(minTbl,maxTbl)
    elseif contract[2] == APP_OPERATE_TYPE.setOwner then
        local ownerTbl = GetCurrTxAccountAddress() --34bytes table
        if(#contract >= 2+34) then
            ownerTbl = GetContractTxParam (2+1,34)
        end
        setOwner (ownerTbl)
    elseif contract[2] == APP_OPERATE_TYPE.setPercentages then
        assert(#contract >= 2+5*8, "Param length error : " ..#contract )
        local devTbl = GetContractTxParam(2+1,8)
        local affTbl = GetContractTxParam(2+8+1,8)
        local chaTbl = GetContractTxParam(2+2*8+1,8)
        local higTbl = GetContractTxParam(2+3*8+1,8)
        local surTbl = GetContractTxParam(2+4*8+1,8)
        setPercentages (devTbl, affTbl, chaTbl, higTbl, surTbl)
    elseif contract[2] == APP_OPERATE_TYPE.setAuthorizedWallet then
        assert(#contract >= 2+34, "Param length error : " ..#contract )
        local walletTbl = GetContractTxParam(2+1,34)
        setAuthorizedWallet (walletTbl)
    elseif contract[2] == APP_OPERATE_TYPE.joinGame then
        assert(#contract >= 2+12, "Param length error : " ..#contract )
        --if team specified
        if(#contract >= 2+12+1) then
            local teamId = contract[15]
            addPlayerToTeam(teamId)
        end
        if(#contract >= 2+12+1+34) then
            local referrer = GetContractTxParam(16,34)
            addReferrerForPlayer(referrer)
        end
        local gameId = GetContractTxParam (2+1,12)
        joinGame(Serialize (gameId, true))
    elseif contract[2] == APP_OPERATE_TYPE.claimWin then
        assert(#contract >= 2+12, "Param length error : " ..#contract )
        local gameId = GetContractTxParam (2+1,12)
        claimWin(Serialize (gameId, true))
    elseif contract[2] == APP_OPERATE_TYPE.withdraw then
        assert(#contract >= 2+12, "Param length error : " ..#contract )
        local gameId = GetContractTxParam (2+1,12)
        withdraw(Serialize (gameId, true))
    elseif contract[2] == APP_OPERATE_TYPE.withdrawPot then
        assert(#contract >= 2+35, "Param length error : " ..#contract )
        local pot = contract[3]
        local receiverTbl = GetContractTxParam(4,34)
        if(pot == POT_TYPE.developer) then
            withdrawPot (developerPot_key,receiverTbl) 
        elseif(pot == POT_TYPE.charity) then
            withdrawPot (charityPot_key,receiverTbl) 
        elseif(pot == POT_TYPE.surprise) then
            withdrawPot (surprisePot_key,receiverTbl) 
        else
            error('pot# '..string.format("%02x", contract[3])..' not found')
        end
    elseif contract[2] == APP_OPERATE_TYPE.withdrawHighscorePot then
        withdrawHighscorePot ()
    elseif contract[2] == APP_OPERATE_TYPE.withdrawAffiliateBalance then
        withdrawAffiliateBalance ()
    elseif contract[2] == APP_OPERATE_TYPE.stopContract then
        stopContract ()
    elseif contract[2] == APP_OPERATE_TYPE.setScore then
        assert(#contract >= 2+34+8+1, "Param length error : " ..#contract )
        local playerTbl = GetContractTxParam(2+1,34)
        local scoreTbl = GetContractTxParam (2+34+1, 8)
        local teamTbl = GetContractTxParam (2+34+8+1, 1)
        setScore (playerTbl, scoreTbl, teamTbl)
    else
        error('method# '..string.format("%02x", contract[2])..' not found')
    end
end

--contract = {0xf0, 0x0b,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01, 0x00, 0x00}
--8b ,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01
--4b ,0x00,0x00,0x00,0x01
--34b, ,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01, 0x00, 0x00
Main()