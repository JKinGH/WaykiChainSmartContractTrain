mylib = require ("mylib")

-- the lottery itemname
ITEMNAME_KEY = "numguess"
--the addr_curcount key
BETCOUNT_KEY = "betcount"
--the odds
ODDS_VALUE = 7
-- myself bet5 key
MYSELFBET5_KEY = "myselfbet5"
-- recent won5 key
RECENTWON5_KEY = "recentwon5"
--parameter len
ADDR_LEN = 34
HASH_LEN = 32
BETDATA_LEN = 3
ISOPENED_LEN = 1
ISWON_LEN = 1
ISPAY_LEN = 1
BETCOUNT_LEN = 4
AMOUNT_LEN = 8
PAY_LEN = 8
ODDS_LEN = 4
OPENDATA_LEN = 3
--ALLCOUNTVALUE_LEN = 99 bytes
ALLCOUNTVALUE_LEN = ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN+PAY_LEN+ODDS_LEN+OPENDATA_LEN

--WICC单位精度
DECIMAL = 100000000
--最小投注金额
MIN_AMOUNT = 0.001
--最大投注金额
MAX_AMOUNT = 1000

--慈善捐献地址
charityAddress = "wXFjaTsUBtcVz2AjRyJHAUA8HYBG8xaMH5"
--慈善捐献比例
CHARITY_VALUE = 0.5

--开奖记录标识
OPENED_FLAG = "openedflag"

LOG_TYPE =
{
    ENUM_STRING = 0,
    ENUM_NUMBER = 1
}

APP_OPERATE_TYPE=
{
    USER_BET     = 0x01,  --用户投注
    TEST         = 0x11
}

------------------------------------------引用自开发者中心-----------------------------------------------------

ADDR_TYPE = {
    REGID  = 1,
    BASE58 = 2
}
OP_TYPE = {
    ADD_FREE = 1,
    SUB_FREE = 2
}

LogMsg = function (msg)
    local logTable = {
        key = 0,
        length = string.len(msg),
        value = msg
    }
    mylib.LogPrint(logTable)
end

--获取当前发起交易的账号
GetCurrTxAccountAddress = function ()
    return {mylib.GetBase58Addr(mylib.GetCurTxAccount())}
end

--遍历并输出table数组所有元素
Unpack = function (t,i)
    i = i or 1
    if t[i] then
        return t[i], Unpack(t,i+1)
    end
end

--判断传入的table是否为非空
TableIsNotEmpty = function (t)
    return _G.next(t) ~= nil
end

--获取链上该合约中key对应的value值
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

--写/改数据
WriteOrModify = function (isConfig, writeTbl)
    if not isConfig then
        if not mylib.WriteData(writeTbl) then    error("FuncSetAdmin: Write error") end
    else
        if not mylib.ModifyData(writeTbl) then error("FuncSetAdmin: Modify error") end
    end
end

--获取合约内容
--参数startIndex为起始索引， 参数length为获取字段的长度， 另外contract为全局变量。
--返回contract 以startIndex为起始索引，length为长度获取的contract部分字段
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

--获取字符串的byte table数组
--传入的参数param是字符串
--返回值为 字符串param转换成的byte table数组
GetByte = function(param)
    return {string.byte(param,1,string.len(param))}
end

--字符转换拼接
--将table类型的数据，拼接成字符串，传入参数obj必须为table类型
--传入参数 hex 为bool值，是否为hex类型
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
        error("can not Serialize a " .. t .. " type.")
    end

    return lua
end

--获取当前发起交易时转账给合约的WICC金额
--返回值为WICC*10^8
GetCurTxPayAmount = function ()
    local payMoney = mylib.ByteToInteger(mylib.GetCurTxPayAmount())
    assert(payMoney > 0,"GetCurrTxPayAmount: payMoney <= 0")
    return payMoney
end

--比较t1和t2是否相等
--参数t1和t2均为table类型
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

--新建指定长度的table空间
function NewArray(size)
    local t = {}
    for i = 1, size do
        t[i] = 0
    end
    return t
end
------------------------------------------引用自开发者中心-----------------------------------------------------

--内存拷贝
--本合约用于table拼接
MemCpy = function(tDest,start0,tSrc,start1,length)
    assert(tDest ~= nil,"tDest is empty")
    assert(TableIsNotEmpty(tSrc),"tSrc is empty")
    assert(start0 > 0,"start0 err")
    assert(start1 > 0,"start1 err")
    assert(length > 0,"length err")
    local i
    for i = 1,length do
        tDest[start0 + i -1] = tSrc[start1 + i - 1]
    end
end

--根据项目名称作为key值查询数据库中对应的value_int值
-- 存在：返回 value值
-- 不存在： 返回 0
GetKeyIntValue = function(Key)

    --如果key-value存在，返回value值
    local exist,NumTable = GetContractValue(Key)
    if exist == true then
        return  mylib.ByteToInteger(Unpack(NumTable))
    else
        return 0
    end
end


--[[
  功能: 增加key-value对至链数据库
  参数：
    Strkey:    key：string
    ValueTbl:  value : table
  返回值：
    无
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
  功能: 查询当前交易hash
  参数：
        无
  返回值：
        当前交易hash，table类型
--]]
GetCurTxHash = function()
    local result = {mylib.GetCurTxHash()}
    assert(#result == 32,"GetCurTxHash err")
    return result
end


--[[
  功能: 将区块hash最后一位(0-255)进行运算判断为单/双数

  参数：
        blockhash_table：区块hash(Table)
  返回值：
        双数: "0"
        单数: "1"
--]]
CheckBlockHash = function(blockhash_table)

    assert(type(blockhash_table) == "table", "CheckBlockHash err!" )

    local num = blockhash_table[#blockhash_table]
    local num1,num2=math.modf(num/2) --返回整数和小数部分
    if(num2==0)then --双数
        return "0"
    else
        return "1" --单数
    end
end

GetPrizePoolBalance = function()

    local regidTbl = {mylib.GetScriptID()}
    assert(#regidTbl > 0," GetScriptID err")

    local balanceTbl = {mylib.QueryAccountBalance(Unpack(regidTbl))}
    assert(#balanceTbl == 8,"QueryAccountBalance err");

    return mylib.ByteToInteger(Unpack(balanceTbl))
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
    local appRegId = {mylib.GetScriptID()}
    WriteAccountData(OP_TYPE.SUB_FREE, ADDR_TYPE.REGID, appRegId, moneyTbl)
    return true
end

--获取Table内容
--参数startIndex为起始索引， 参数length为获取字段的长度。
--src 以startIndex为起始索引，length为长度获取的src部分字段
GetParamtblFromTbl = function (src,startIndex, length)
    assert(type(src)=="table","GetParamtblFromTbl type error.")
    assert(startIndex > 0, "GetParamtblFromTbl start error(<=0).")
    assert(length > 0, "GetParamtblFromTbl length error(<=0).")
    assert(startIndex+length-1 <= #src, "GetParamtblFromTbl length ".. length .." exceeds limit: " .. #src)

    local newTbl = {}
    local i = 1
    for i = 1,length do
        newTbl[i] = src[startIndex+i-1]
    end
    return newTbl
end

--修改更新 isopened，iswon，ispay，pay,opendata值
ModifyParameter = function(allcountvalueTbl,data,len_start)

    local t = type(data)
    --修改number类型参数
    if t == "number" then
        --修改pay

        MemCpy(allcountvalueTbl,len_start,{mylib.IntegerToByte8(data)},1,PAY_LEN)
    elseif t == "string" then --修改 isopened，iswon，ispay,opendata

        MemCpy(allcountvalueTbl,len_start,GetByte(data),1,#data)
    end
end

DebugGetMyselfBet5 = function(myselfbet5Tbl)
    for i = 0,4 do
        --从自己的投注记录中取出每天记录
        local ereryrecordTbl =  GetParamtblFromTbl(myselfbet5Tbl,ALLCOUNTVALUE_LEN*i+1,ALLCOUNTVALUE_LEN)
        --有数据的记录
        if  ereryrecordTbl[1] ~= 0x00 then

            local betTbl = GetParamtblFromAllCountValue(ereryrecordTbl)
            local addr = Serialize(betTbl.addrTbl,false)
            local hash = Serialize(betTbl.hashTbl,true)
            local betdata = Serialize(betTbl.betdataTbl,false)
            local isopened = Serialize(betTbl.isopenedTbl,false)
            local iswon = Serialize(betTbl.iswonTbl,false)
            local ispay = Serialize(betTbl.ispayTbl,false)
            local betcount = mylib.ByteToInteger(Unpack(betTbl.betcountTbl))
            local amount = mylib.ByteToInteger(Unpack(betTbl.amountTbl))
            local pay = mylib.ByteToInteger(Unpack(betTbl.payTbl))
            local odds = mylib.ByteToInteger(Unpack(betTbl.oddsTbl))
            local opendata = Serialize(betTbl.opendataTbl,false)

            LogMsg("[DebugGetMyselfBet5]:".."["..addr.."]-["..betcount.."]= hash:" ..
                    Serialize(betTbl.hashTbl,true)..",betdata:"..betdata.. ",isopened："..isopened..",iswon:"..iswon..",ispay:"..ispay.. ",betcount:"..betcount..",amount:"..amount..",pay:"..pay..",odds:"..odds..",opendata:"..opendata)

        end
    end

end

--查找当前所要开奖的投注是否在自己最近的5次投注中，用于更新最近5次投注信息
ModifyCurallcountvalueTomyselfbet5 = function (addr,betcount,allcountvalueTbl)

    local exist,old_myselfbet5Tbl = GetContractValue(addr..MYSELFBET5_KEY)
    LogMsg("#allcountvalueTbl="..#allcountvalueTbl)

    --如果存在本地址最近5期的的投注详情，
    if exist == true then

        --debug
        DebugGetMyselfBet5(old_myselfbet5Tbl)
        --从最近的一个投注开始，往后解析自己最近5次投注详情，将其中betcount = 本次开奖的betcount的投注详情进行数据更新
        for i = 0 ,4 do
            --根据betcount查找最近5次投注中是否有本次开奖的投注
            local betcount_indbTbl = GetParamtblFromTbl(old_myselfbet5Tbl,ALLCOUNTVALUE_LEN*i+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+1,BETCOUNT_LEN)
            --如有，替换掉
            if mylib.ByteToInteger(Unpack(betcount_indbTbl)) == betcount then

                LogMsg("find the num is "..i+1)

                MemCpy(old_myselfbet5Tbl,ALLCOUNTVALUE_LEN*i+1,allcountvalueTbl,1,#allcountvalueTbl)

                local myselfbet5Tbl_modifyed = old_myselfbet5Tbl

                LogMsg("#myselfbet5Tbl_modifyed="..#myselfbet5Tbl_modifyed)

                WriteStrkeyValueToDb(addr..MYSELFBET5_KEY,myselfbet5Tbl_modifyed)

                return
            --如找不到，则此开奖的投注不在最近5次投注中,不做处理
            else
                --do nothing
            end
        end
    --如果不存在,说明bet的时候没有写对应的key-value
    else
        LogMsg("Don't write Myselfbet5 to DB when bet Bet,error!")

    end
end


UpdateValueInOpenBet = function(check_allcount,addr,betcount,allcountvalueTbl_modifyed)

    assert(#allcountvalueTbl_modifyed == ALLCOUNTVALUE_LEN,"UpdateValueInOpenBet,len of allcountvalueTbl_modifyed ="..#allcountvalueTbl_modifyed.. " error.")
    --每次更新都必须更新3个键值对 "allcount" - "allcount_value"、"addr_betcount" - "allcount_value"、"addr..MYSELFBET5_KEY" - "addr..MYSELFBET5_KEY_value"
    WriteStrkeyValueToDb(check_allcount,allcountvalueTbl_modifyed)
    WriteStrkeyValueToDb(addr..betcount,allcountvalueTbl_modifyed)
    LogMsg("1234567")
    --开奖时更新最近5次投注记录
    ModifyCurallcountvalueTomyselfbet5(addr,betcount,allcountvalueTbl_modifyed)
end

--更新最近5次中奖列表
UpdateRecentWon5List =function(allcountvalueTbl)
    assert(#allcountvalueTbl == ALLCOUNTVALUE_LEN,"UpdateRecentWon5List,len of allcountvalueTbl ="..#allcountvalueTbl.." error.")

    local exist,recentwon5listTbl = GetContractValue(RECENTWON5_KEY)
    --如果存在最近5期的的中奖详情，更新详情
    if exist == true then
        --更新规则:取出原来value中后4个ALLCOUNTVALUE_LEN个bytes数据，后面拼接新的1个新的allcountvalueTbl构成新的recentwon5listTbl
        local lod_recentwon4listTbl = GetParamtblFromTbl(recentwon5listTbl,ALLCOUNTVALUE_LEN+1,ALLCOUNTVALUE_LEN*4)
        MemCpy(lod_recentwon4listTbl,#lod_recentwon4listTbl+1,allcountvalueTbl,1,#allcountvalueTbl)
        --更新最新5期的投注情况
        WriteStrkeyValueToDb(RECENTWON5_KEY,lod_recentwon4listTbl)

    --如果不存在最近5期的的中奖详情，增加详情:默认设置长度为 ALLCOUNTVALUE_LEN * 5,新来的中奖纪录放在第五条
    else
        --增加 "RECENTWON5_KEY" - allcountvalueTbl + ALLCOUNTVALUE_LEN*4 空白
        local recentwon5listTbl_new = NewArray(ALLCOUNTVALUE_LEN*5)
        MemCpy(recentwon5listTbl_new,ALLCOUNTVALUE_LEN*4+1,allcountvalueTbl,1,#allcountvalueTbl)
        WriteStrkeyValueToDb(RECENTWON5_KEY,recentwon5listTbl_new)
    end
end

GetParamtblFromAllCountValue = function(allcountvalueTbl)

    local betTbl = {
        addrTbl       = GetParamtblFromTbl(allcountvalueTbl,1,ADDR_LEN),
        hashTbl       = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN,HASH_LEN),
        betdataTbl    = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN,BETDATA_LEN) ,  --str
        isopenedTbl   = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN,ISOPENED_LEN) ,  --str
        iswonTbl      = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN,ISWON_LEN) , --str
        ispayTbl      = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN,ISPAY_LEN) , --str
        betcountTbl   = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN,BETCOUNT_LEN), --int
        amountTbl     = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN,AMOUNT_LEN), --int
        payTbl        = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN,PAY_LEN), --int
        oddsTbl       = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN+PAY_LEN,ODDS_LEN) ,--int
        opendataTbl   = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN+PAY_LEN+ODDS_LEN,OPENDATA_LEN) --str
    }

    return betTbl
end

DebugUpdateParam = function (check_allcount,allcountvalueTbl)
    local betTbl = GetParamtblFromAllCountValue(allcountvalueTbl)
    local addr = Serialize(betTbl.addrTbl,false)
    local hash = Serialize(betTbl.hashTbl,true)
    local betdata = Serialize(betTbl.betdataTbl,false)
    local isopened = Serialize(betTbl.isopenedTbl,false)
    local iswon = Serialize(betTbl.iswonTbl,false)
    local ispay = Serialize(betTbl.ispayTbl,false)
    local betcount = mylib.ByteToInteger(Unpack(betTbl.betcountTbl))
    local amount = mylib.ByteToInteger(Unpack(betTbl.amountTbl))
    local pay = mylib.ByteToInteger(Unpack(betTbl.payTbl))
    local odds = mylib.ByteToInteger(Unpack(betTbl.oddsTbl))
    local opendata = Serialize(betTbl.opendataTbl,false)

    LogMsg("[Debug bet]["..check_allcount.."]:".."["..addr.."]-["..betcount.."]= hash:" ..
            Serialize(betTbl.hashTbl,true)..",betdata:"..betdata.. ",isopened："..isopened..",iswon:"..iswon..",ispay:"..ispay.. ",betcount:"..betcount..",amount:"..amount..",pay:"..pay..",odds:"..odds..",opendata:"..opendata)
end



--为老的投注开奖
OpenLodBet = function(opened_flag,allcount_int)

    LogMsg("---------------------------------------------------------------OpenLodBet-----------------------------------------------------------------------------")
    -- 开奖,根据opened_flag记录的条目，往下继续开奖
    for i = opened_flag+1 ,allcount_int do

        --避免合约一直循环消耗内存等资源
        if i - opened_flag > 100 then
            return
        end

        local open_num = "" --存放开奖的号码
        local check_allcount = string.format("%d",i)

        -- "allcount" - {addr+hsah+betdata+isopened+iswon+ispay+betcount+amount+pay+odds}
        local allcount_exist,allcountvalueTbl = GetContractValue(check_allcount)

        assert(allcount_exist == true, "check_allcount "..check_allcount.." Error!")
        local betTbl = GetParamtblFromAllCountValue(allcountvalueTbl)
--[[
        local addrTbl       = GetParamtblFromTbl(allcountvalueTbl,1,ADDR_LEN)
        local hashTbl       = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN,HASH_LEN)
        local betdataTbl    = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN,BETDATA_LEN)   --str
        local isopenedTbl   = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN,ISOPENED_LEN)   --str
        local iswonTbl      = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN,ISWON_LEN)  --str
        local ispayTbl      = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN,ISPAY_LEN)  --str
        local betcountTbl   = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN,BETCOUNT_LEN) --int
        local amountTbl     = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN,AMOUNT_LEN) --int
        local payTbl        = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN,PAY_LEN) --int
        local oddsTbl       = GetParamtblFromTbl(allcountvalueTbl,1+ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN+PAY_LEN,ODDS_LEN) --int

        local addr = Serialize(addrTbl,false)
        local hash = Serialize(hashTbl,true)
        local betdata = Serialize(betdataTbl,false)
        local isopened = Serialize(isopenedTbl,false)
        local iswon = Serialize(iswonTbl,false)
        local ispay = Serialize(ispayTbl,false)
        local betcount = mylib.ByteToInteger(Unpack(betcountTbl))
        local amount = mylib.ByteToInteger(Unpack(amountTbl))
        local pay = mylib.ByteToInteger(Unpack(payTbl))
        local odds = mylib.ByteToInteger(Unpack(oddsTbl))
--]]
        local addr = Serialize(betTbl.addrTbl,false)
        local hash = Serialize(betTbl.hashTbl,true)
        local betdata = Serialize(betTbl.betdataTbl,false)
        local isopened = Serialize(betTbl.isopenedTbl,false)
        local iswon = Serialize(betTbl.iswonTbl,false)
        local ispay = Serialize(betTbl.ispayTbl,false)
        local betcount = mylib.ByteToInteger(Unpack(betTbl.betcountTbl))
        local amount = mylib.ByteToInteger(Unpack(betTbl.amountTbl))
        local pay = mylib.ByteToInteger(Unpack(betTbl.payTbl))
        local odds = mylib.ByteToInteger(Unpack(betTbl.oddsTbl))
        local opendata = Serialize(betTbl.opendataTbl,false)

        LogMsg("[Open Bet]["..check_allcount.."]:".."["..addr.."]-["..betcount.."]= hash:" ..
                Serialize(betTbl.hashTbl,true)..",betdata:"..betdata.. ",isopened："..isopened..",iswon:"..iswon..
                ",ispay:"..ispay.. ",betcount:"..betcount..",amount:"..amount..",pay:"..pay..",odds:"..odds..",opendata:"..opendata)

        --根据交易hash获得交易的确认高度: height - number :123456.0
        local confirm_height = mylib.GetTxConFirmHeight(Unpack(betTbl.hashTbl))

        -- 所要开奖的hash未确认,直接return
        if confirm_height == nil then
            LogMsg("[The Bet]["..check_allcount.."]'s hash: "..hash.." have been unconfirmed currently")
            LogMsg('\n'..'\n')
            return
        -- 所要开奖的hash已确认
        elseif confirm_height > 0 then --如hash已得到确认，查询确认高度的区块hash和往后的2个区块hash

            for j = 2,0,-1 do
                local height_num = math.floor(confirm_height + j)
                local blockhash_table = {mylib.GetBlockHash(height_num) }
                --如果往后第二个区块不存在
                if #blockhash_table ~= 32 then
                    LogMsg("The next 2 block don't have been gen!")
                    LogMsg('\n'..'\n')
                    return
                else
                    local lastone = CheckBlockHash(blockhash_table)
                    open_num = lastone..open_num
                end
            end

            if #open_num == 3 then
                --此处真正开奖

                --中奖
                --if (open_num == betdata) then
                if (betdata == betdata) then
                    LogMsg("[The Bet WIN]["..check_allcount.."]---["..addr.."]-["..betcount.."]'s open_num: "..open_num..",betnum: "..betdata)
                    local pay_amount = odds * amount  --赔付金额
                    local charity_amount = CHARITY_VALUE * amount  --捐献金额
                    --如奖池资金足够，赔7倍,0.5倍用于捐献慈善
                    if pay_amount + charity_amount <= GetPrizePoolBalance() then
                        --赔付赢家
                        local pay_amountTbl = {mylib.IntegerToByte8(pay_amount)}
                        assert(#pay_amountTbl == 8,"IntegerToByte8 error0")
                        TransferToAddr(ADDR_TYPE.BASE58,betTbl.addrTbl,pay_amountTbl)
                        --捐献慈善
                        local charity_amountTbl = {mylib.IntegerToByte8(math.floor(charity_amount))}
                        assert(#charity_amountTbl == 8,"IntegerToByte8 error1")
                        TransferToAddr(ADDR_TYPE.BASE58,GetByte(charityAddress),charity_amountTbl)

                        --更新开奖状态：isopened = "1"
                        ModifyParameter(allcountvalueTbl,"1",ADDR_LEN+HASH_LEN+BETDATA_LEN+1) --isopened
                        --更新 iswon = "1"、ispay = "1"
                        ModifyParameter(allcountvalueTbl,"1",ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+1) --iswon
                        ModifyParameter(allcountvalueTbl,"1",ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+1) -- ispay
                        --更新 pay = pay_amount
                        ModifyParameter(allcountvalueTbl,pay_amount,ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN+1) --pay
                        --更新 opendata = open_num
                        ModifyParameter(allcountvalueTbl,open_num,ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN+PAY_LEN+ODDS_LEN+1) --opendata

                        --中奖并成功赔付的，更新至最近5期中奖名单
                        UpdateRecentWon5List(allcountvalueTbl)

                    --如奖池资金不够，等待下次开奖时资金足够时再开
                    else
                        LogMsg("Balance not enougt to pay!")
                        LogMsg('\n'..'\n')
                        return
                    end

                --不中奖
                else
                    LogMsg("[The Bet not WIN]["..check_allcount.."]---["..addr.."]-["..betcount.."]'s open_num: "..open_num..",betnum: "..betdata)
                    --更新开奖状态：isopened = "1"
                    ModifyParameter(allcountvalueTbl,"1",ADDR_LEN+HASH_LEN+BETDATA_LEN+1) --isopened
                    --更新 iswon = "0"、ispay = "0"
                    ModifyParameter(allcountvalueTbl,"0",ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+1) --iswon
                    ModifyParameter(allcountvalueTbl,"0",ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+1) -- ispay
                    --更新 pay = 0
                    ModifyParameter(allcountvalueTbl,0,ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN+1) --pay
                    --更新 opendata = open_num
                    ModifyParameter(allcountvalueTbl,open_num,ADDR_LEN+HASH_LEN+BETDATA_LEN+ISOPENED_LEN+ISWON_LEN+ISPAY_LEN+BETCOUNT_LEN+AMOUNT_LEN+PAY_LEN+ODDS_LEN+1) --opendata
                end

                --增加开奖记录标记
                WriteStrkeyValueToDb(OPENED_FLAG,{mylib.IntegerToByte8(i)})
                DebugUpdateParam(check_allcount,allcountvalueTbl)
                UpdateValueInOpenBet(check_allcount,addr,betcount,allcountvalueTbl)
            end
        end
    end
end

--更新本地址最近五次投注列表
UpdateMyselfBet5List = function(addr,allcount_valueTbl)

    local exist,myselfbet5Tbl = GetContractValue(addr..MYSELFBET5_KEY)
    --如果存在本地址最近5期的的投注详情，更新详情
    if exist == true then
        --更新规则:取出原来value前4个96bytes数据，前面拼接新的1个新的allcount_valueTbl构成新的myselfbet5Tbl
        local lod_reventbet4Tbl = GetParamtblFromTbl(myselfbet5Tbl,1,ALLCOUNTVALUE_LEN*4)
        MemCpy(allcount_valueTbl,#allcount_valueTbl+1,lod_reventbet4Tbl,1,#lod_reventbet4Tbl)

        --更新最新5期的投注情况
        WriteStrkeyValueToDb(addr..MYSELFBET5_KEY,allcount_valueTbl)

    --如果不存在本地址最近5期的的投注详情，增加详情:默认设置长度为 ALLCOUNTVALUE_LEN * 5
    else
        --增加 "addr+myselfbet5" - allcount_valueTbl + ALLCOUNTVALUE_LEN*4 空白
        local myselfbet5Tbl_new = NewArray(ALLCOUNTVALUE_LEN*5)
        MemCpy(myselfbet5Tbl_new,1,allcount_valueTbl,1,#allcount_valueTbl)

        WriteStrkeyValueToDb(addr..MYSELFBET5_KEY,myselfbet5Tbl_new)
    end
end

--构造"addr+hsah+betdata+isopened+iswon+ispay+betcount+amount+pay+odds"value值
CreateAllCountValueTbl = function(betTbl)

    local allcount_valueTbl = betTbl.addrTbl
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,betTbl.hsahTbl,1,HASH_LEN)                -- addr+hash
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,GetByte(betTbl.betdata),1,BETDATA_LEN)    -- addr+hsah+betdata
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,GetByte(betTbl.isopened),1,ISOPENED_LEN)  -- addr+hsah+betdata+isopened
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,GetByte(betTbl.iswon),1,ISWON_LEN)        -- addr+hsah+betdata+isopened+iswon
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,GetByte(betTbl.ispay),1,ISPAY_LEN)        -- addr+hsah+betdata+isopened+iswon+ispay
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,betTbl.betcountTbl,1,BETCOUNT_LEN)        -- addr+hsah+betdata+isopened+iswon+ispay+betcount
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,betTbl.amountTbl,1,AMOUNT_LEN)            -- addr+hsah+betdata+isopened+iswon+ispay+betcount+amount
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,betTbl.payTbl,1,PAY_LEN)                  -- addr+hsah+betdata+isopened+iswon+ispay+betcount+amount+pay
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,betTbl.oddsTbl,1,ODDS_LEN)                -- addr+hsah+betdata+isopened+iswon+ispay+betcount+amount+pay+odds
    MemCpy(allcount_valueTbl,#allcount_valueTbl+1,GetByte(betTbl.opendata),1,OPENDATA_LEN)  -- addr+hsah+betdata+isopened+iswon+ispay+betcount+amount+pay+odds+opendata

    return allcount_valueTbl
end

--投注
Bet = function (allcount_int,base58_addrTbl,bet_hashTbl,bet_data,betcount_int,amount_int)

    if allcount_int >= 0 then

        --每次投注项目对应总数+1
        local allcount_value_int = allcount_int + 1
        local allcount_key_str   = string.format("%d",allcount_value_int)
        --每次投注用户本身的投注次数+1
        local betcount = betcount_int + 1
        local BETCOUNT_KEY_str   = string.format("%d",betcount )
        --地址hash转换
        local addr = Serialize(base58_addrTbl,false)
        local bet_hashhex = Serialize(bet_hashTbl,true)
        local betTbl = {
            addrTbl      = base58_addrTbl,
            hsahTbl      = bet_hashTbl,
            betdata      = bet_data,
            isopened     = "0",
            iswon        = "0",
            ispay        = "0",
            betcountTbl  = {mylib.IntegerToByte4(betcount)},
            amountTbl    = {mylib.IntegerToByte8(amount_int)},
            payTbl       = {mylib.IntegerToByte8(0)},
            oddsTbl      = {mylib.IntegerToByte4(ODDS_VALUE) },
            opendata     = "xxx"
        }
        local allcount_valueTbl = CreateAllCountValueTbl(betTbl)

        LogMsg("["..allcount_value_int.."]".."[Join Bet]: ".."["..addr.."]".."-".."["..betcount.."]".."= hash:"..
                bet_hashhex..",betdata:"..bet_data..",betcount:"..betcount..",amount:"..amount_int..",pay:".."0"..",odds:"..ODDS_VALUE)

        --1、增加"项目名称"-"总投注人次"(int)
        WriteStrkeyValueToDb(ITEMNAME_KEY,{mylib.IntegerToByte8(allcount_value_int)})
        --2、增加"具体人次"-"投注详细信息"(addr+hsah+betdata+isopened+iswon+ispay+betcount+amount+pay) --用于H5遍历查询显示所有投注详情
        WriteStrkeyValueToDb(allcount_key_str,allcount_valueTbl)
        --3、增加"地址+投注次数"-"投注详细信息"(addr+hsah+betdata+isopened+iswon+ispay+betcount+amount+pay) --用于H5查询显示自己所有投注详情
        WriteStrkeyValueToDb(addr..BETCOUNT_KEY_str,allcount_valueTbl)
        --4、增加"地址当前投注次数"-"次数" --用于再次投注时，记得投过多少次
        WriteStrkeyValueToDb(addr..BETCOUNT_KEY,{mylib.IntegerToByte8(betcount)})
        --5、更新本地址最近五次投注结果，用于H5查询显示自己最近5次投注详情
        UpdateMyselfBet5List(addr,allcount_valueTbl) 
    end
end

--获取用户投注的金额
GetBetAmount = function()

    local amount_int = GetCurTxPayAmount()
    --投注金额限制
    if  amount_int >=  MIN_AMOUNT * DECIMAL and amount_int <= MAX_AMOUNT * DECIMAL  then
        return true,amount_int
    else
        return false
    end
end

--获取用户投注的投注信息
--返回值:string: "101"
GetBetData = function()
    local BetDataTbl = GetContractTxParam(5,3)
    local BetData = Serialize(BetDataTbl,false)
    return BetData
end

--主函数
Main = function()
    assert(contract[1] == 0xf0, "Param MagicNo error (~=0xf0): " .. contract[1])
    assert(#contract ==7, "USER_BET Param length error (~=7): " ..#contract )

    --用户参与投注
    if contract[2] == APP_OPERATE_TYPE.USER_BET then

        --获取当前项目对应的已参与投注人次
        local allcount_int = GetKeyIntValue(ITEMNAME_KEY)
        --获取当前调用的hash
        local bet_hashTbl = GetCurTxHash()
        --获取参与者的投注号码
        local bet_data = GetBetData()
        assert(#bet_data == 3, "The User's bet_data Error !" )
        --获取合约调用者地址
        local base58_addrTbl = GetCurrTxAccountAddress()
        assert(#base58_addrTbl == 34, "Get The Caller Addr Errors!" )
        --获取"地址+curcount" 对应的value
        local betcount_int = GetKeyIntValue(Serialize(base58_addrTbl,false)..BETCOUNT_KEY)
        local success,amount_int = GetBetAmount()
        assert(success == true, "The User Don't Push enough WICC To Join The Bet!" )
        --参与投注
        Bet(allcount_int,base58_addrTbl,bet_hashTbl,bet_data,betcount_int,amount_int)

        --前面有人投注的情况下才尝试为别人开奖
        if allcount_int > 0 then
            local opened_flag = GetKeyIntValue(OPENED_FLAG)
            LogMsg("opened_flag="..opened_flag..",allcount_int="..allcount_int)
            OpenLodBet(opened_flag,allcount_int)
        end
    elseif contract[2] == APP_OPERATE_TYPE.TEST then
        --test


    else
        error('method# '..string.format("%02x", contract[2])..' not found')
    end
end

Main()



