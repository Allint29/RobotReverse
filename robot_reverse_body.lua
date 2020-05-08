function Body()
	if (Timer > 0) then
		Timer=Timer - 1
		TableSar.putDangerToTable({row=4,column=3,mes="Starting..", danger=true})
		sleep(1000)
		return
	end

	local SessionStatus = tonumber(getParamEx(Class, Emit, "STATUS").param_value)
	--если нет связи с сервером, то робот дальше не идет, если его убрать
	--то при обрыве связи и новом ее восстановлении позиции закрываются
	if(SessionStatus~=1)then
        TableSar.putDangerToTable({row=4,column=3,mes="Starting..", danger=true})
		Timer=3		
		return
	end
	----------------------------------------------------------------------
	
	local ServerTime = getInfoParam("SERVERTIME")
	local ServerDateTime = getInfoParam("TRADEDATE").." "..getInfoParam("SERVERTIME")

	--get server time in format of date table
	local _server_time = GetServerTimeTable()

	if(ServerTime == nil or ServerTime == "") then
		TableSar.putDangerToTable({row=4,column=3,mes="No connection", danger=true})
		Timer=3
		return
	else

	end;

	local check_market = MainStrategy.check_market()



	--checking data of dictionaries for clean deals, orders, and transactions if it time is over
	MainTransManager.major_checking_for_clean({server_time=_server_time})

	TableSar.putActiveTime()
	TableSar.putDangerToTable({row=2,column=2,mes=tostring(os.time()), danger=false})
	TableSar.putDangerToTable({row=4,column=3,mes="Robot is working", danger=false})

	TableSar.windowAlwaysUp({nonClosed=true})
	-------------------------------

	--if push on stop - stopping robot

	--is_run = TableSar.actionOnTable()

	sleep(2000)
end;