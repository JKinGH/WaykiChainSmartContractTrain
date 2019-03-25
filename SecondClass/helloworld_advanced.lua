mylib = require "mylib"
--脚本中必须以`mylib = require "mylib"`开头，注意一定要放在第一行，第一行如果留空会报异常。

--定义合约调用事件
METHOD = {
    CHECK_HELLOWORLD  = 0x17,
    SEND_HELLOWORLD = 0x18,
    ADVANCED_HELLOWORLD = 0x20
}

Serialize = function(obj, hex)
    local lua = ""
    local t = type(obj)

    if t == "table" then
        for i=1, #obj do
            if hex == false then
                lua = lua .. string.format("%c",obj[i])
            elseif hex == true then
                lua = lua .. string.format("%02x",obj[i])
            else
                error("index type error.")
            end
        end
    elseif t == "nil" then
        return nil
    else
        error("can not Serialize a " .. t .. " type.")
    end

    return lua
end


LOG_TYPE =
{
    ENUM_STRING = 0,
    ENUM_NUMBER = 1
}

--用于输出log信息至文件
LogMsg = function(LogType,Value)
    local LogTable = {
        key = 0, --日志类型：字符串或数字
        length = 0, --value数据流的总长
        value = nil -- 字符串或数字流
    }
    --保存数据流
    LogTable.key = LogType
    LogTable.length = #Value
    LogTable.value = Value
    mylib.LogPrint(LogTable)
end

---------------------------------------------------

Check = function()
    LogMsg(LOG_TYPE.ENUM_STRING,"Run CHECK_HELLOWORLD Method")
end

Send = function()
    LogMsg(LOG_TYPE.ENUM_STRING,"Run SEND_HELLOWORLD Method")
end

--[[
 --获取当前交易地址
 --mylib.GetCurTxAccount
 --mylib.GetBase58Addr
 ]]
GetCurrTxAccountAddress = function ()
    return {mylib.GetBase58Addr(mylib.GetCurTxAccount())}
end


--[[
  功能: 增加key-value对至链数据库
  mylib.WriteData
--]]
WriteStrkeyValueToDb = function (Strkey,ValueTbl)
    local t = type(ValueTbl)
    assert(t == "table","the type of Value isn't table.")

    local writeTbl = {
        key = Strkey,
        length = #ValueTbl,
        value = {}
    }
    writeTbl.value = ValueTbl

    if not mylib.WriteData(writeTbl) then  error("WriteData error") end
end


--[[
    获取调用合约的参数内容
 ]]
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

--[[
 --LogMsg()
 --GetCurrTxAccountAddress()
 --Serialize()
 --WriteStrkeyValueToDb()
 ]]
ADVANCED = function(valueTbl)
    --通过合约打印日志
    LogMsg(LOG_TYPE.ENUM_STRING,"I am leraning WaykiChain smart contract development!")
    --获取当前交易地址
    local senderTbl =  GetCurrTxAccountAddress() --34 bytes table
    local sender_base58 = Serialize(senderTbl,false) --string
    local sender_hex = Serialize(senderTbl,true) --string==77664e68575441513335786e684634734d33356e3851567964327362317075466341
    LogMsg(LOG_TYPE.ENUM_STRING,"sender_base58 ="..sender_base58)
    LogMsg(LOG_TYPE.ENUM_STRING,"sender_hex ="..sender_hex)

    --将目标数据写到区块链
    WriteStrkeyValueToDb("my name is:",valueTbl)
    LogMsg(LOG_TYPE.ENUM_STRING,"wirte to blockchain successfully.")
end

--智能合约入口
--GetContractTxParam()
Main = function()
    assert(#contract >=4, "Param length error (<4): " ..#contract )
    assert(contract[1] == 0xf0, "Param MagicNo error (~=0xf0): " .. contract[1])

    if contract[2] == METHOD.CHECK_HELLOWORLD then
        Check()
    elseif contract[2] == METHOD.SEND_HELLOWORLD then
        Send()
    elseif contract[2] == METHOD.ADVANCED_HELLOWORLD then
        local valueTbl = GetContractTxParam(5,#contract - 4) -- 获取合约调用信息
        ADVANCED(valueTbl)
    else
        error('method# '..string.format("%02x", contract[2])..' not found')
    end
end

Main()


