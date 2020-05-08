dofile(getScriptPath().."\\robot_reverse_body.lua")
dofile(getScriptPath().."\\Helper\\Helper_validator.lua")
dofile(getScriptPath().."\\Helper\\Helper_time.lua")
dofile(getScriptPath().."\\Helper\\Helper_reduce_message.lua")
dofile(getScriptPath().."\\Class\\Table_class.lua")
dofile(getScriptPath().."\\Class\\Writer_class.lua")
dofile(getScriptPath().."\\Class\\TransManager_class.lua")
dofile(getScriptPath().."\\Class\\Strategy_reverse_class.lua")
dofile(getScriptPath().."\\Class\\Position_class2.lua")
dofile(getScriptPath().."\\Class\\Position_info_class.lua")

function OnInit()
	is_run = true;
	is_push_stop = false
	FileLog = getScriptPath().."\\log.txt"
	Timer = 3;
	Class="SPBFUT"  --"TQBR" "SBER"	 "SPBOPT" "RI162500BM0E"
	--Emit="BRG0"
	Emit="SiM0"
	SECURITY_TABLE_1 = getSecurityInfo(Class, Emit)
	MyAccount = "41026II"
    Slip = 30
	Lot = 1
    --id indicators in quik
	IdSAR= "SAR_REVERSE"
	IdMA200= "MA200_REVERSE"
	IdPriceSAR = "PRICE_REVERSE"
	COUNT=0

	MainStrategy = Startegy_reverse:new({
											id_strategy = "ReverseSi",
											account = MyAccount,
											class = Class,
											security = Emit,
											security_info = SECURITY_TABLE_1,
											id_indicator = IdSAR,
											id_indicator_MA200 = IdMA200,
											id_price = IdPriceSAR,
											market_type = "reverse", --string may be "long","short", "reverse"
											})


	--create table of robot
	TableSar = RobotTable:new("TableID2",MainStrategy.get_id_strategy(), 25)
	TableSar.initColumnTable({"Parametrs", "Values", "Comments", "Control_OP", "Control_CP", "Stop_ctr", "Take_ctr", "Ext"})
	TableSar.putMainData({"qwerty", "second"})

	--set main writer to robot
    MainWriter = WriterRobot:new("Writer1","Writer1", "SecondLog.txt", TableSar)
	--set second writer to robot
	Writer_second = WriterRobot:new("Writer2","Writer2", "ThirdLog.txt", TableSar)

	MainWriter.WriteToEndOfFile({mes="Writer activated"})
	MainWriter.WriteToConsole({mes="Writer activated", row=6, column=2})

	----читаю файл
	--local ggg = MainWriter.JsonDecode({file_name = getScriptPath().."\\user.json"})
	--
	--message(type(ggg))
--
	----записываю файл
	--local ggg2 = MainWriter.JsonEncode({table = ggg, file_name = getScriptPath().."\\new_file.json", record_kind = "rewrite"})
	--message(ggg2.mes)

	MainTransManager = TransManager:new({
											sIdTransactionManager="Main_transaction_manager",
											sIdStrategy = MainStrategy.get_id_strategy(),
											nSecTimeToKill = 15
											--there is a problem, because time to kill count by order start
											--if order or transaction come very later it may by delete by now
										})

	MainStrategy.set_transaction_manager(MainTransManager)
	MainStrategy.set_table_manager(TableSar)
	MainStrategy.set_main_writer(MainWriter)
	MainStrategy.strategy_start()
	MainTransManager.activateTransManager()

end;

function main()
	while is_run do     -- is_run==true  (is_run==true)
		Body()
	end;
end;

function OnTrade(TradeX)
	MainTransManager.putCrudeDeals(TradeX)
end

function OnOrder(OrderX)
	--action whith apear Order
	--MainWriter.WriteToEndOfFile({mes="New order come!"})
	local o = MainTransManager.putCrudeOrders(OrderX)
	--MainWriter.WriteToEndOfFile({mes=o.mes})
	--Writer_second.WriteToEndOfFile({mes="Order "..GetRecurseMesssageHelper(OrderX)})
end

function OnStopOrder()
	--action if new stop order
end

function OnTransReply(trans_reply)
    --if new reply
	MainTransManager.putCrudeTransaction(trans_reply)
	--Writer_second.WriteToEndOfFile({mes="TransAction "..GetRecurseMesssageHelper(trans_reply)})
end

function OnStop()
	is_run = false;
	DestroyTable(TableSar.getAllocTable())
	MainWriter.WriteToEndOfFile({mes="Robot stoped!"})

end
