--Class of position - It manadge to send transaction for open position,
--take and save info about transaction, orders, deals of open volume position
--It manadge to send transaction for close position,
--take and save info about transaction, orders, deals of closed volume position
--format of data positionTable = {
--									id_position="", string there need take system time in seconds
--									account="", string
--									class="", string
--									security="", string
--       							security_info=SECURITY_TABLE_1,
--									lot=1,   number
--									side="B", string
--									enter_price=23453, number
--									slippage = 3, number
--									stop_loss=20, number steps
--									take_profit=40, number steps
--									use_stop="true", string
--									use_take="true", string
--									market_type="reverse", string may be "long","short", "reverse"
--									}
Position = {}
function Position:new(positionTable)
	local private = {}
	local private_func = {}
	local public = {}

		--Private properties
		private.id_position = tostring(positionTable.id_position) or ""
		private.id_position_to_close = string.sub(string.reverse(private.id_position), 0, 9) or ""
		private.account = tostring(positionTable.account) or ""
		private.class = tostring(positionTable.class) or ""
		private.security = tostring(positionTable.security) or ""
		private.security_info = positionTable.security_info or ""
		private.lot = tonumber(positionTable.lot) or ""
		private.side =  tostring(positionTable.side) or ""
		private.enter_price = tonumber(positionTable.enter_price) or ""
		private.slippage = tonumber(positionTable.slippage) or ""
		private.use_stop = tostring(positionTable.use_stop) or ""
		private.use_take = tostring(positionTable.use_take) or ""
		private.stop_loss = tonumber(positionTable.stop_loss) or ""
		private.take_profit = tonumber(positionTable.take_profit) or ""
		private.market_type = positionTable.market_type or ""

		--property to on/off position - activate in method of activation
		private.is_active = false
		
		--info from table getSecurityInfo
		
		--info from table current market GetParamEx
		private.tradingstatus = "" --string
		private.pricemax = "" --numeric
		private.pricemin = "" --numeric
		private.starttime = "" --string
		private.endtime = "" --string
		private.evnstarttime = "" --string
		private.evnendtime = "" --string
		private.monstarttime = "" --string
		private.monendtime = "" --string
	
		private.table_reply_of_transaction = "none_reply" --table of transaction one
		
		private.list_reply_of_orders = {}
		private.table_reply_of_order = "none_reply"		 --table of active ordersof position		
		private.list_reply_of_deals = {}         --table of tables
		private.open_side_is_active = false
		
		
		private.table_reply_of_transaction_to_close = "none_reply" --table of transaction one
		
		private.list_reply_of_orders_to_close = {}
		private.table_reply_of_order_to_close = "none_reply"		 --table of active ordersof position		
		private.list_reply_of_deals_to_close = {}         			 --table of tables		
		private.close_side_is_active = false
		
		--life time begin count where was check first transaction
		private.life_time_open = 0
		private.begin_check_self_open = 4
		private.transaction_sended_open = false
		private.open_side_was_closed = false
		
		private.life_time_close = 0
		private.begin_check_self_close = 4
		private.begin_reset_self_close = private.begin_check_self_close + private.begin_check_self_close
		private.transaction_sended_close = false
		private.close_side_was_closed = false
		
		private.is_full = false		
	
	function private_func:IsValidate()
		--function return true with message
		--data format - string
		----format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "IsValidate(): None message" end    
		return {result=true, 
			mes="IsValidate(): "..tostring(self.mes).." "..tostring(private.id_position),
			id_position = tostring(private.id_position)
		}
	end
	
	function private_func:IsNotValidate()
		--function return true with message
		--data format - string
		----format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "IsNotValidate(): None message" end    
		return {result = false, 
				mes = "IsNotValidate(): "..tostring(self.mes).." "..tostring(private.id_position),
				id_position = tostring(private.id_position)
		}		
	end
	
	function private_func:IsActivePosition()
		--data format - string-message if manager is active transcend
		--format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Position Manager None message" end
        if (private.is_active == false)then
            return {result=false,
                    mes=tostring(self.mes)..": Manager not active!",
                    id_position = tostring(private.id_position)}
        end
		
		
		return {result=true,
            mes=tostring(self.mes)..": Position is active!",
            id_position = tostring(private.id_position)}  
    end		
		
	--private functions	
	function private_func:IsTable()
		--data format - data - if table transcend
		--format {table=obj, mes=""}	
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "None message" end
		if (string.lower(type(self.table)) ~= string.lower("table"))then
			local _mes = tostring(self.mes).." : Position take not valid data - not table! "..tostring(private.id_position)
			return {result=false, 
					mes=_mes,
					id_position = tostring(private.id_position)
					}
		end
		return private_func.IsValidate({mes="Success check as table"})
	end
	
	function private_func:IsNilPropertyOfTable()
		local _is_table = private_func.IsTable({table=self,mes="IsNilPropertyOfTable()"})
		
		if _is_table.result == false then return _is_table end
		
		--local _mes = ""
		for key, value in pairs(self) do
			--_mes = _mes..key..": "..tostring(value).."\n"
			if (value == "") then			
				return {
						result=false,
						mes="Position.IsNilPropery 'private."..tostring(key).."' is ''. Position ",
						id_position = tostring(private.id_position)
						}
			end
		end

		return private_func.IsValidate({mes="All properties not nil!"})		
	end
	
	function private_func:RoundToSecurityStep()
		-- function round numeric to security step
		local num = tonumber(self)
		local step = tonumber(private.securityinfo.min_price_step)
		if (num == nil or step == nil)then return nil end
		if (num == 0)then return self end
		return math.floor(num/step)*step		
	end	
	
	function private_func:CheckSidePosition()
		-- check char of side position
		local side_long = "b"
		local side_short = "s"
		local fact_side = string.lower(private.side)
		if (fact_side ~= side_long and fact_side ~= side_short) then private.side = "" end
		if(fact_side == side_long) then private.side = "B" end
		if(fact_side == side_short) then private.side = "S"	end		
	end		

	function private_func:ReverseSidePosition()
		-- check char of side position
		local side_long = "b"
		local side_short = "s"
		local fact_side = string.lower(private.side)
		if (fact_side ~= side_long and fact_side ~= side_short) then private.side = "" end
		if(fact_side == side_long) then return "S" end
		if(fact_side == side_short) then return "B"	end		
	end		
	
	function private_func:TableCount()
		if (string.lower(type(self)) ~= string.lower("table"))then return 0 end
		local count = 0 
		for key, value in pairs(self) do
			count = count + 1
		end
		return count
	end
				
	function private_func:FillDataFromGetParamEx()		
		--local SessionStatus = tonumber(getParamEx(Class, Emit, "STATUS").param_value)
		--local SessionStatus2 = getParamEx(Class, Emit, "STATUS").param_image
		private.tradingstatus = getParamEx(private.class, private.security, "STATUS").param_image
		private.pricemax = private_func.RoundToSecurityStep(getParamEx(private.class, private.security, "PRICEMAX").param_value)
		private.pricemin = private_func.RoundToSecurityStep(getParamEx(private.class, private.security, "PRICEMIN").param_value)
		private.starttime = getParamEx(private.class, private.security, "STARTTIME").param_image
		private.endtime = getParamEx(private.class, private.security, "ENDTIME").param_image
		private.evnstarttime = getParamEx(private.class, private.security, "EVNSTARTTIME").param_image
		private.evnendtime = getParamEx(private.class, private.security, "EVNENDTIME").param_image
		private.monstarttime = getParamEx(private.class, private.security, "MONSTARTTIME").param_image
		private.monendtime = getParamEx(private.class, private.security, "MONENDTIME").param_image

	end		
		
	function private_func:CheckStopTakeForLimit()
		-- check price of profit or stoploss for max limit or min limit 
		-- data types {stop = 20, take = 40 , enter_price = 54000, side="b"}
		private_func.CheckSidePosition()
		local step = private.security_info.min_price_step
		local enter_price = private.enter_price		
		local min_planc = tonumber(private.pricemin)
		local max_planc = tonumber(private.pricemax)

		if (enter_price > max_planc) then
			private.enter_price = max_planc
			enter_price = max_planc 
		end
		if (enter_price < min_planc) then 
			private.enter_price = min_planc
			enter_price = min_planc 		
		end

		local stop = 0
		local take = 0
		if (private.side == "B") then
			--message(tostring(type(enter_price))..tostring(type(private.take_profit ))..tostring(type(step)))
			stop = enter_price - (private.stop_loss * step)
			take = enter_price + (private.take_profit * step)
		elseif (private.side == "S") then
			stop = enter_price + (private.stop_loss * step)
			elsetake = enter_price - (private.take_profit * step)	
		else
			return 
		end
		if (stop < min_planc) then
			private.stop_loss = math.ceil((enter_price - min_planc)/step)
		elseif (stop > max_planc) then
			private.stop_loss = math.floor((max_planc - enter_price)/step)
		end
		
		if (take > max_planc) then
			private.take_profit = math.floor((max_planc - enter_price)/step)
		elseif (take < min_planc) then
			private.take_profit = math.ceil((enter_price - min_planc)/step)
		end

	end		
	
	function private_func:get_current_lot_of_position_open()		
		local count = 0
		
		for key, value in pairs(private.list_reply_of_deals) do
			local v = tonumber(value.qty)
			if v == nil then message("Quantity is nil in list_reply_of_deals!!!") end
			count = count + v
		end
		return count
	end

	function private_func:get_current_lot_of_position_close()
		local count = 0
		
		for key, value in pairs(private.list_reply_of_deals_to_close) do
			local v = tonumber(value.qty)
			if v == nil then message("Quantity is nil in list_reply_of_deals!!!") end
			count = count + v
		end

		return count
	end	
	
	function private_func:kill_order_of_position2() --data format {kind="open"} {kind="close"}
		--function kill order from it position
		--data format {kind="open"} {kind="close"}
		--to do checking if not order reply find it in transaction or deals journals
		------CLASSCODE=TQBR; 		
		------SECCODE=RU0009024277; 
		------TRANS_ID=5; 
		------ACTION=KILL_ORDER; 
		------ORDER_KEY=503983;
		
		local _is_active = private_func.IsActivePosition({mes="KillOpenOrderOfPosition()"})		
		if _is_active.result == false then return _is_active end	
		
		local table_of_self = private_func.IsTable({table=self, mes="kill_order_of_position(): self is table"})		
		if table_of_self.result == false then return table_of_self end
		
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't find order to cancel, because no self.kind='open' or self.kind='close'"}) end
		
		local _key = nil --id position or close position
		local _id_trans = nil --list of transaction
		local _id_order = nil --list of order
		local _id_deal = nil --list of deals
		local result_ = false
		local _mes = ""
		local current_lots_of_position = nil
		local _order_num = nil
		local _delta = nil
		
		--in this list storage all sended to kill orders
		--_list_order_to_kill["order_num"] = {order_num = number, result = true, mes = ""}
		local _list_order_to_kill = {} 
		
		if self.kind == 'open' then
			_key = private.id_position
			_id_trans = private.table_reply_of_transaction
			_list_order = private.list_reply_of_order
			_id_deal = private.list_reply_of_deals
			
			current_lots_of_position = private_func.get_current_lot_of_position_open()
			_delta = private.lot - current_lots_of_position
			
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
			_id_trans = private.table_reply_of_transaction_to_close
			_list_order = private.list_reply_of_order_to_close
			_id_deal = private.list_reply_of_deals_to_close
			
			current_lots_of_position = private_func.get_current_lot_of_position_close()
			_delta = private_func.get_current_lot_of_position_open() - private_func.get_current_lot_of_position_close()
		end
				
		--для каждого активного ордера в листе ордеров посылаю отмену
		for key, value in pairs() do				
			if(value.ordernum ~= nil and value.ordernum ~= 0) then
				_order_num = tostring(value.ordernum)
			elseif(value.order_num ~= nil and value.order_num ~= 0) then
				_order_num = tostring(value.order_num)
			end		
			
			if (_order_num ~= nil) then 
		
				if (value.flags ~= nil and bit.band(value.flags, 1) == 0) then
					--order no active
					_mes = "We can't send kill transaction, because order not active or flags == nil"				
				else
					local transaction = {
									["ACTION"]="KILL_ORDER",
									["ORDER_KEY"] = _order_num,
									["TRANS_ID"]=_key,
									["SECCODE"]=private.security,
									["CLASSCODE"]=private.class
									}		
					
					local result = sendTransaction(transaction)
					
					if result ~= '' then 	
						_mes = 'kill_order_of_position(): Error with send Kill transaction: '..result
						--message('TransOpenPos(): Error with send Kill transaxtion: '..result)
						MainWriter.WriteToEndOfFile({mes="Order N: "..tostring(_order_num)..". ".._mes})
					else 
						_mes = 'kill_order_of_position(): Transaction Kill sended successful: private.life_time_close = 0'
						MainWriter.WriteToEndOfFile({mes="Order N: "..tostring(_order_num)..". ".._mes})
						--message('TransOpenPos(): Transaction Kill sended')
						--private.life_time_close = 0						
					end
				end
			end			
		end
	end
	
	function private_func:kill_order_of_position() --data format {kind="open"} {kind="close"}
		--function kill order from it position
		--data format {kind="open"} {kind="close"}
		--to do checking if not order reply find it in transaction or deals journals
		------CLASSCODE=TQBR; 		
		------SECCODE=RU0009024277; 
		------TRANS_ID=5; 
		------ACTION=KILL_ORDER; 
		------ORDER_KEY=503983;
		
		local _is_active = private_func.IsActivePosition({mes="KillOpenOrderOfPosition()"})		
		if _is_active.result == false then return _is_active end	
		
		local table_of_order = private_func.IsTable({table=private.table_reply_of_order, mes="KillOpenOrderOfPosition(): table_of order"})		
		if table_of_order.result == false then return table_of_order end
		
		local table_of_self = private_func.IsTable({table=self, mes="kill_order_of_position(): self is table"})		
		if table_of_self.result == false then return table_of_self end
		
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't find order to cancel, because no self.kind='open' or self.kind='close'"}) end
		
		local _key = nil --id position or close position
		local _id_trans = nil --table of transaction
		local _id_order = nil --table of order
		local _id_deal = nil --table of deals
		local result_ = false
		local _mes = ""
		local current_lots_of_position = nil
		local _order_num = nil
		local _delta = nil
		
		if self.kind == 'open' then
			_key = private.id_position
			_id_trans = private.table_reply_of_transaction
			_id_order = private.table_reply_of_order
			_id_deal = private.list_reply_of_deals
			
			current_lots_of_position = private_func.get_current_lot_of_position_open()
			_delta = private.lot - current_lots_of_position
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
			_id_trans = private.table_reply_of_transaction_to_close
			_id_order = private.table_reply_of_order_to_close
			_id_deal = private.list_reply_of_deals_to_close
			
			current_lots_of_position = private_func.get_current_lot_of_position_close()
			_delta = private_func.get_current_lot_of_position_open() - private_func.get_current_lot_of_position_close()
		end		
				
		if(_id_order.ordernum ~= nil and _id_order.ordernum ~= 0) then
			_order_num = tostring(_id_order.ordernum)
		elseif(_id_order.order_num ~= nil and _id_order.order_num ~= 0) then
			_order_num = tostring(_id_order.order_num)
		elseif(_id_trans.order_num ~=nil and _id_trans.order_num ~= 0) then
			_order_num = tostring(_id_trans.order_num)
			local order_of_position = getOrderByNumber(tostring(private.class), tostring(_order_num))
			if order_of_position ~= nil then
				_id_order = order_of_position
			end
		end
		
		if (_id_order.flags ~= nil and bit.band(_id_order.flags, 1) == 0) then
			--order no active
			_mes = "We can't send kill transaction, becouse order not active or flags == nil"
		else
			local transaction = {
							["ACTION"]="KILL_ORDER",
							["ORDER_KEY"] = _order_num,
							["TRANS_ID"]=_key,
							["SECCODE"]=private.security,
							["CLASSCODE"]=private.class
							}		
			
			local result = sendTransaction(transaction)
			
			if result ~= '' then 	
				_mes = 'kill_order_of_position(): Error with send Kill transaction: '..result
				--message('TransOpenPos(): Error with send Kill transaxtion: '..result)			
			else 
				_mes = 'kill_order_of_position(): Transaction Kill sended successful: private.life_time_close = 0'
				--message('TransOpenPos(): Transaction Kill sended')
				private.life_time_close = 0
				result_ = true
			end
		end
				
		return {result=result_, 
				mes=_mes,
				id_position = tostring(_key),
				needed_position = private.lot,
				current_position = current_lots_of_position,
				delta = _delta
		}
	end
	
	--public functions
	function public:ActivatePosition()		
		--take security info to saving
		private.securityinfo = getSecurityInfo(private.class, private.security)
		
		--take param current session
		private_func.FillDataFromGetParamEx()
		
		--check side position for correct char
		private_func.CheckSidePosition()
		
		--if all properties filled is_activate = true
		local _res = private_func.IsNilPropertyOfTable(private)
		private.is_active = _res.result
		message("ActivatePosition()	: ".._res.mes)
		--fill stoploss and takeprofits with limits of market max-min price
		private_func.CheckStopTakeForLimit()		

		return private_func.IsValidate({mes="Position is activated Ok"})	
	end
	
	function public:send_first_transaction() --format data {kind="open"}   {kind="close"}
		--format data {kind="open"}   {kind="close"}
		local _is_active = private_func.IsActivePosition({mes="send_first_transaction()"})
		if _is_active.result == false then return _is_active end
		--ACCOUNT=SPBFUT00009; 
		--CLIENT_CODE= SPBFUT00009; 
		--TYPE=M; 
		--TRANS_ID=8; 
		--CLASSCODE=SPBFUT; 
		--SECCODE=LKH0; 
		--ACTION=NEW_ORDER; 
		--OPERATION=S; 
		--PRICE=16231; 
		--QUANTITY=15;
		local kind_table = private_func.IsTable({table=self, mes="send_first_transaction(): kind of transaction"})
		if kind_table.result == false or self.kind == nil then return kind_table end
		
		local _side = nil
		local _price = nil
		local _lot = nil
		local _id_pos = nil
		local _slip = nil
		
		if (self.kind == "open") then
			_side = private.side
			_price = tostring(private.enter_price)
			_lot = tostring(private.lot)
			_id_pos = private.id_position
			_slip = private.slippage
			
		elseif (self.kind == "close") then
			_side = private_func.ReverseSidePosition()
			local last = tonumber(getParamEx(private.class, private.security, "LAST").param_value)
			local step = private.security_info.min_price_step
			
			if private_func.ReverseSidePosition() == "B" then
				--_price = tostring( last + private_func.RoundToSecurityStep(private.slippage*step))
				--_price = tostring( last + private.slippage)
				_price = tostring( last - 200)
			elseif private_func.ReverseSidePosition() == "S" then
				--_price = tostring( last - private_func.RoundToSecurityStep(private.slippage*step))
				--_price = tostring( last - private.slippage)
				_price = tostring( last + 200)
			end			
			_lot = tostring(private_func.get_current_lot_of_position_open()-private_func.get_current_lot_of_position_close())
			_id_pos = private.id_position_to_close
		end
		
		if (private.transaction_sended_open == false and self.kind == "open") or 
			(private.transaction_sended_close == false and self.kind == "close" and private.transaction_sended_open == true) then
		--we can send transaction once and closing transaction after opening, 
		--and if it will be success, later we can move this order
			local transaction = {
							["ACTION"]="NEW_ORDER",
							["SECCODE"]=private.security,
							["ACCOUNT"]=private.account,
							["CLASSCODE"]=private.class,
							["OPERATION"]=_side,
							["PRICE"]=_price,
							["QUANTITY"]=_lot,
							["TYPE"]="L",
							["TRANS_ID"]=_id_pos,
							["CLIENT_CODE"]=_id_pos    -- комментарий в квике
							}
					
			local result = sendTransaction(transaction)
			local _mes = ""
			if result ~= '' then
				_mes = 'send_first_transaction(): Error with send transaxtion: '..result
				message(_mes)
				MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() BAD RESULT".."\n"})
				if (self.kind == "open") then
					private.transaction_sended_open = false
					private.open_side_is_active = false
					MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() BAD RESULT ACTIVATED".."\n"})
				elseif (self.kind == "close") then
					private.transaction_sended_close = false
					private.close_side_is_active = false
				end				
				return private_func.IsNotValidate({mes=_mes})
			end
			_mes = 'send_first_transaction(): Transaction sended'
			--message(_mes)			
			MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() GOOD RESULT".."\n"})
			--start new loop of life side's position
			if (self.kind == "open") then
				private.transaction_sended_open = true
				private.open_side_is_active = true
				private.life_time_close = 0
				MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() GOOD RESULT ACTIVATED".."\n"})
			elseif (self.kind == "close") then
				private.transaction_sended_close = true
				private.close_side_is_active = true
				private.life_time_close = 0
				MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() GOOD RESULT ACTIVATED CLOSE".."\n"})
			end			
		end
		
		return private_func.IsValidate({mes=_mes})				
	end
			
	function public:check_self_transaction_in_crude_dic() --format {crude_dictionary = table, executed_dictionary = table, kind = "open", kind = "close"}
	--take two tables crude and executed dictionary {crude_dictionary = table, executed_dictionary = table, kind = "open", kind = "close"}
	--data type dic of table - crude transaction dictionari in transaction manager	
	--there if in crude dictionary finded key with number of name this transaction it take
	--for self property of transaction and move table of transaction from crude to executed transaction
	--and delete from crude transaction
		local _is_active = private_func.IsActivePosition({mes="check_self_transaction_in_crude_dic()"})
		
		if _is_active.result == false then return _is_active end
	
		local crude_dic_table = private_func.IsTable({table=self.crude_dictionary, mes="check_self_transaction_in_crude_dic(): Crude Table"})
		local execu_dic_table = private_func.IsTable({table=self.executed_dictionary, mes="check_self_transaction_in_crude_dic(): Executed Table"})
		
		if crude_dic_table.result == false then return crude_dic_table end
		if execu_dic_table.result == false then return execu_dic_table end
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't check crude transaction, because no self.kind='open' or self.kind='close'"}) end
		
		
		local list_to_delete = {}
		local key_of_list = 0
		local _mes = ""
		
		local _key = nil
		local _id_trans = nil
			
		if self.kind == 'open' then
			_key = private.id_position
			_id_trans = private.table_reply_of_transaction
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
			_id_trans = private.table_reply_of_transaction_to_close
		end
		
		
		for key, value in pairs(self.crude_dictionary) do
			
			if (key == _key)then				
				if       value.status == 0    then 
					_mes = 'OnTransReply(): Transaction sended to server' 				
				elseif   value.status == 1    then 
					_mes = 'OnTransReply(): Transaction take by server from QUIK client' 												    
				elseif   value.status == 2    then 
					_mes = 'OnTransReply(): Error with sending transaction to market system. As Quik is not connected to Moscow exchange. Second transaction wilnt send.' 
				elseif   value.status == 3    then 
				--success reply from server register to this position
					_mes = 'OnTransReply(): Transaction success sended!!!'
					if (_id_trans == "none_reply") then
						if self.kind == 'open' then							
							private.table_reply_of_transaction = value
						elseif self.kind == 'close' then							
							private.table_reply_of_transaction_to_close = value
						end		
					message("Trans_position id close= ".. tostring(private.table_reply_of_transaction_to_close).."\n"..
							"Trans_position id = ".. tostring(private.table_reply_of_transaction))						
					end													    
				elseif   value.status == 4    then 
					_mes = 'OnTransReply(): Transaction not sended, as error. Info in(trans_reply.result_msg)'
				elseif   value.status == 5    then 
					_mes = 'OnTransReply(): Transaction was not check by server Quik by some criteries. For example sender have not right for sending transaction of this type.' 				
				elseif   value.status == 6    then 
					_mes = 'OnTransReply(): Trnsaction not valid by limits server Quik' 
				elseif   value.status == 10   then 
					_mes = 'OnTransReply(): Transaction not support by market system' 
				elseif   value.status == 11   then 
					_mes = 'OnTransReply(): Transaction not valid by electronic signature.' 
				elseif   value.status == 12   then 
					_mes = 'OnTransReply(): Have not recive by transaction, time out of waiting. May be transaction from QPILE' 
				elseif   value.status == 13   then 
					_mes = 'OnTransReply(): Transaction not take by system? because may case cross-deals'
				end	
							
				self.executed_dictionary[key] = value
				list_to_delete[tostring(key_of_list)] = key	
				key_of_list = key_of_list + 1
			end
		end		
		--clear dictionary of crude if it was moved to executed dictionary
		for key, value in pairs(list_to_delete) do
			self.crude_dictionary[value] = nil		
		end
		
		return {mes = _mes}
	end
		
	function public:check_self_orders_in_crude_dic2()
		local _is_active = private_func.IsActivePosition({mes="check_self_orders_in_crude_dic()"})		
		if _is_active.result == false then return _is_active end

		local crude_dic_table = private_func.IsTable({table=self.crude_dictionary_orders, mes="check_self_orders_in_crude_dic(): Crude Table"})
		local execu_dic_table = private_func.IsTable({table=self.executed_dictionary_orders, mes="check_self_orders_in_crude_dic(): Executed Table"})	
		
		
		if crude_dic_table.result == false then return crude_dic_table end
		if execu_dic_table.result == false then return execu_dic_table end		
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't check crude orders, because no self.kind='open' or self.kind='close'"}) end
		
		local list_to_delete = {}

		local _key = nil
		local _list_order = nil
		
		if self.kind == 'open' then
			_key = private.id_position
			_list_order = private.list_reply_of_orders
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
			_list_order = private.list_reply_of_order_to_close
		end
		
		for key, value in pairs(self.crude_dictionary_orders) do	
			if (tostring(value.brokerref) == _key)then
				--1)Adding name order to list for delete
				list_to_delete[key] = key
				--2)Adding name order to list executed orders of transaction manager
				self.executed_dictionary_orders[key] = value
				
				local _order_finded = false
				for key_inner, value_inner in pairs(_list_order) do
					--find order in self list of order by numorder
					if (value.ordernum == value_inner.ordernum and value.ordernum ~= 0) or 
						(value.order_num == value_inner.order_num and value.order_num ~= 0)then
						--check canceled_uid = 0
						if (value.canceled_uid == 0) then
							--reply order not for cancel
							if (value.trans_id == value.brokerref) then
								--it more newest reply of order - write it to self list
								_list_order[key_inner] = value
							end						
						else
							--reply order for cancel
							if(value_inner.canceled_uid == 0) then
								--new order more newest that old order rewrite it
								_list_order[key_inner] = value
							else
								--if old order canceled reply too: check it for bit or withdraw_datetime
								if (bit.band(value.flags, 2) > 0) or
									(bit.band(value.flags, 1) == 0 and bit.band(value.flags, 2) == 0) or
									(os.time(value.withdraw_datetime) > os.time(value_inner.withdraw_datetime)) then
									--если заявка снята кем-то
									--если ордер исполнен
									--if time of withdraw_datetime of new reply > min it min order withdraw and 
									--it most newest reply rewrite old order
									_list_order[key_inner] = value		
								end
							end						
						end		
						--check that order was finded
						_order_finded = true
					end					
				end
				
				if  (_order_finded == false) then
					--if order from this position, but it not in list of orders this position write it
					--key is number of order
					if (value.ordernum ~=0) then
						_list_order[tostring(value.ordernum)] = value
					elseif (value.order_num ~=0) then
						_list_order[tostring(value.order_num)] = value
					end					
				end
			end			
		end
		
		--clear dictionary of crude if it was moved to executed dictionary
		for key, value in pairs(list_to_delete) do
			self.crude_dictionary_orders[value] = nil		
		end


	end	
				
	function public:check_self_orders_in_crude_dic() --format {crude_dictionary_orders = table, executed_dictionary_orders = table, kind = "open"}
		--take crude dictionary of orders and check it for self orders
		--if it contains self order, then it take to self orders dictionary and delete it from 		
		--transmanager order dictionary
		--take two tables crude and executed dictionary {crude_dictionary_orders = table, executed_dictionary_orders = table, kind = "open"}
		--this function check flags of order and if it active put it to active orders
		local _is_active = private_func.IsActivePosition({mes="check_self_orders_in_crude_dic()"})		
		if _is_active.result == false then return _is_active end		
		
		local crude_dic_table = private_func.IsTable({table=self.crude_dictionary_orders, mes="check_self_orders_in_crude_dic(): Crude Table"})
		local execu_dic_table = private_func.IsTable({table=self.executed_dictionary_orders, mes="check_self_orders_in_crude_dic(): Executed Table"})	
		
		
		if crude_dic_table.result == false then return crude_dic_table end
		if execu_dic_table.result == false then return execu_dic_table end		
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't check crude orders, because no self.kind='open' or self.kind='close'"}) end
		
		local list_to_delete = {}
		
		
		local _key = nil
		local _id_order = nil
			
		if self.kind == 'open' then
			_key = private.id_position
			_id_order = private.table_reply_of_order
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
			_id_order = private.table_reply_of_order_to_close
		end
				
		for key, value in pairs(self.crude_dictionary_orders) do		
		
			if (tostring(value.brokerref) == _key)then
				--	сначала установили сам ответ
				
				if (_id_order == "none_reply")  then
					--если это первый ордер из системы
					if self.kind == 'open' then
						private.table_reply_of_order = value
					elseif self.kind == 'close' then
						private.table_reply_of_order_to_close = value
					end
			
				elseif((_id_order.ordernum == value.ordernum and value.ordernum ~= 0) or
					(_id_order.order_num == value.order_num and value.order_num ~= 0)) then
					
					if(_id_order.trans_id == 0 and value.trans_id ~=0) then
						if self.kind == 'open' then
							private.table_reply_of_order = value
						elseif self.kind == 'close' then
							private.table_reply_of_order_to_close = value
						end
						
					elseif(os.time(value.datetime) > os.time(_id_order.datetime)) then
					--if date of new order more than self order replace it
						if self.kind == 'open' then						
							private.table_reply_of_order = value
						elseif self.kind == 'close' then						
							private.table_reply_of_order_to_close = value
							MainWriter.WriteToEndOfFile({mes="New close Order: "..tostring(private.table_reply_of_order_to_close.ordernum)})
						end
					end
				end
				
				if (bit.band(value.flags, 2) > 0) then
					--если заявка снята кем-то
						if self.kind == 'open' then						
							private.table_reply_of_order = value
						elseif self.kind == 'close' then						
							private.table_reply_of_order_to_close = value
						end
				elseif(bit.band(value.flags, 1) == 0 and bit.band(value.flags, 2) == 0) then
					--если ордер исполнен
						if self.kind == 'open' then						
							private.table_reply_of_order = value
						elseif self.kind == 'close' then						
							private.table_reply_of_order_to_close = value
						end
				end
				
				--to do oreder in transaction manager is executed dictionary
				self.executed_dictionary_orders[key] = value
				list_to_delete[key] = key
			end
		end				
		--clear dictionary of crude if it was moved to executed dictionary
		for key, value in pairs(list_to_delete) do
			self.crude_dictionary_orders[value] = nil		
		end
		
		return private_func.IsValidate({mes="Success check_self_orders_in_crude_dic"})
	end
		
	function public:check_self_deals_in_crude_dic() -- format {crude_dictionary_deals = table, executed_dictionary_deals = table, kind = "open"}
		--take crude dictionary of deals and check it for self deals
		--if it contains self deals, then it take to self deals dictionary and delete it from 		
		--transmanager deals dictionary
		--take two tables crude and executed dictionary {crude_dictionary_deals = table, executed_dictionary_deals = table, kind = "open"}
		--this function check flags of order and if it active put it to active orders
		local _is_active = private_func.IsActivePosition({mes="check_self_deals_in_crude_dic()"})		
		if _is_active.result == false then return _is_active end		
		
		local crude_dic_table = private_func.IsTable({table=self.crude_dictionary_deals, mes="check_self_deals_in_crude_dic(): Crude Table"})
		local execu_dic_table = private_func.IsTable({table=self.executed_dictionary_deals, mes="check_self_deals_in_crude_dic(): Executed Table"})	

		if crude_dic_table.result == false then return crude_dic_table end
		if execu_dic_table.result == false then return execu_dic_table end	
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't check crude deals, because no self.kind='open' or self.kind='close'"}) end

		local list_to_delete = {}
		
		local _key = nil		
		if self.kind == 'open' then
			_key = private.id_position
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
		end
		
		for key, value in pairs(self.crude_dictionary_deals) do			
		
			if (tostring(value.brokerref) == _key)then
				local not_finded_deal = true
				if self.kind == 'open' then
					for inner_key, inner_value in pairs(private.list_reply_of_deals) do
							local v_tradenum = tonumber(value.tradenum)
							local v_trade_num = tonumber(value.trade_num)					
							local v2_tradenum = tonumber(inner_value.tradenum)
							local v2_trade_num = tonumber(inner_value.trade_num)
							
							if (v_tradenum == nil or v_trade_num == nil or v2_tradenum == nil or v2_trade_num == nil) then
								message("v_tradenum is nil")
							end
							
							if (v_tradenum ~= nil and v2_tradenum ~= nil and v2_tradenum == v_tradenum and v2_tradenum ~= 0 and v_tradenum ~= 0) or
								(v_trade_num ~= nil and v2_trade_num ~= nil and v2_trade_num == v_trade_num and v2_trade_num ~= 0 and v_trade_num ~= 0) then
								--if find order in crude dictionary and it in deals already saved then remove this deals from crude 
								--dictionary to executed without adding to self dictionary of deals
							
								--adding to executed dealss of transmanager
								self.executed_dictionary_deals[key] = value
							
								--delete from crude dictionary deals of trans manager
								list_to_delete[key] = key
								not_finded_deal = false
							end								
					end
				elseif self.kind == 'close' then
					for inner_key, inner_value in pairs(private.table_reply_of_order_to_close) do
							local v_tradenum = tonumber(value.tradenum)
							local v_trade_num = tonumber(value.trade_num)					
							local v2_tradenum = tonumber(inner_value.tradenum)
							local v2_trade_num = tonumber(inner_value.trade_num)
							
							if (v_tradenum == nil or v_trade_num == nil or v2_tradenum == nil or v2_trade_num == nil) then
								message("v_tradenum is nil")
							end
							
							if (v_tradenum ~= nil and v2_tradenum ~= nil and v2_tradenum == v_tradenum and v2_tradenum ~= 0 and v_tradenum ~= 0) or
								(v_trade_num ~= nil and v2_trade_num ~= nil and v2_trade_num == v_trade_num and v2_trade_num ~= 0 and v_trade_num ~= 0) then
								--if find order in crude dictionary and it in deals already saved then remove this deals from crude 
								--dictionary to executed without adding to self dictionary of deals
							
								--adding to executed dealss of transmanager
								self.executed_dictionary_deals[key] = value
							
								--delete from crude dictionary deals of trans manager
								list_to_delete[key] = key
								not_finded_deal = false
							end								
					end				
				
				end
				--if private dictionary of deals not contains this deal write it to self list of deals
				if not_finded_deal == true then 
					private.list_reply_of_deals[key] = value 						
				end	
			end
		end				
		--clear dictionary of crude if it was moved to executed dictionary
		for key, value in pairs(list_to_delete) do
			self.crude_dictionary_deals[value] = nil		
		end	
		
		--count life time of position if was sended open transaction and it is alive
		if (private.transaction_sended_open == true and private.open_side_is_active == true) then
			private.life_time_open = private.life_time_open + 1
		end
		
		--count life time of position if was sended close transaction and it is alive
		if (private.transaction_sended_close == true and private.close_side_is_active == true) then
			private.life_time_close = private.life_time_close + 1
		end
		
		return private_func.IsValidate({mes="Success check_self_deals_in_crude_dic"})		
	end
	
	function public:GetStateFillingOfPosition() -- format ()
	--function check self position to answer of question is it position full or not full
	--it return result, mes, id_position, needed number of lot, current number of lot, delta to filling this position
	--if position is full it return true result and deactivate position
		local _is_active = private_func.IsActivePosition({mes="GetStateFillingOfPosition()"})		
		if _is_active.result == false then return _is_active end	
	
		local current_lots_of_position = private_func.get_current_lot_of_position_open()		
		
		local result_ = false
		local _mes = ""
		if current_lots_of_position == private.lot then
		--full position - close this position object
			_mes = "Current_lots = "..tostring(current_lots_of_position).."; \n Needed_lots: "..tostring(private.lot)
			message(_mes)
			private.is_full = true
			result_ = true
		elseif current_lots_of_position < private.lot then
		--not full position
			_mes = "Current_lots = "..tostring(current_lots_of_position).."; \n Needed_lots: "..tostring(private.lot)
			message(_mes)
			private.is_full = false
		elseif current_lots_of_position > private.lot then
		--error of position
			_mes = "Error: \nCurrent_lots = "..tostring(current_lots_of_position).."; \n Needed_lots: "..tostring(private.lot)
			message(_mes)
			private.is_full = true
		end
				
		return {result=result_, 
				mes=_mes,
				id_position = tostring(private.id_position),
				needed_position = private.lot,
				current_position = current_lots_of_position,
				delta = private.lot - current_lots_of_position				
		}	
	end
		
		
	function public:check_is_order_active() --format data {kind="open"} {kind="close"}
		local _is_active = private_func.IsActivePosition({mes="check_position_to_close()"})		
		if _is_active.result == false then return _is_active end
		
		local table_self = private_func.IsTable({table=self, mes="check_is_order_active(): table_of self"})
		if (table_self.result == false) then return table_self end
		
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then 
			return private_func.IsNotValidate({mes="Can't check_is_order_active, because no self.kind='open' or self.kind='close'"}) 
		end
		
		local _result = false
		local _mes = "None message from check_is_order_active()"
		
		local _table_order = nil
		local _table_transaction = nil
		local _table_name = "None Name Of Table"
		local _id_position = "None ID Position"
		if (self.kind == 'open') then
			_table_order = private.table_reply_of_order
			_table_transaction = private.table_reply_of_transaction
			_table_name = "OPEN ORDER SEARCH "
			_id_position = private.id_position
		elseif (self.kind == 'close') then
			_table_order = private.table_reply_of_order_to_close
			_table_transaction = private.table_reply_of_transaction_to_close
			_table_name = "CLOSE ORDER SEARCH "
			_id_position = private.id_position_to_close
		end		

		if (_table_order == "none_reply") then
			if (_table_transaction == "none_reply") then
				_result = false
				_mes = _table_name.."Order not finded, because not info in transaction and order table. Default not active."	
			
			elseif(_table_transaction.order_num ~= nil and _table_transaction.order_num ~= 0) then
				--find order in all orders table of terminal
				local _order = getOrderByNumber(tostring(private.class), tostring(_table_transaction.order_num))
				
				if (_order ~= nil)then
					--check finded order to state active or passive
					if (bit.band(_order.flags, 1) == 0) then
						--order no active
						_result = false
						_mes = _table_name.."Order finded by transaction's table's number and it is NOT ACTIVE."								
					else
						--order is active
						_result = true
						_mes = _table_name.."Order finded by transaction's table's number and it is ACTIVE."								
					end						
				else
					_result = false
					_mes = _table_name.."Error number of order is absent in ALL table of order terminal. Default order not active"
				end						
			else
				_result = false
				_mes = _table_name.."Error from taking numder order from TRANSACTION, because format is wrong. Check NAMES of table fields. Default order not active"
			end	
			
		elseif (_table_order.order_num ~= nil and _table_order.order_num ~= 0) or 
				(_table_order.ordernum ~= nil and _table_order.ordernum ~= 0) then
			--check finded order to state active or passive
			local _order = _table_order
			
			if (bit.band(_order.flags, 1) == 0) then
				--order no active
				_result = false
				_mes = _table_name.."Order finded by order's table's number and it is NOT ACTIVE."								
			else
				--order is active
				_result = true
				_mes = _table_name.."Order finded by orders's table's number and it is ACTIVE."								
			end	
		else
			--error format of data to find number order
			_result = false
			_mes = _table_name.."Error from taking numder order from ORDER table, because format is wrong. Check NAMES of table fields. Default order not active"
		end
		
		return {
				result = _result,
				mes = _mes,
				id_position = _id_position		
		}		
	end
		
		
	function public:check_position_to_deactivate() --format data {kind="open"} {kind="close"}
		--format data {kind="open"} {kind="close"}
		--function check that position's ordes not active 
		--if order not active return true
		local _is_active = private_func.IsActivePosition({mes="check_position_to_close()"})		
		if _is_active.result == false then return _is_active end
		
		local table_of_order = private_func.IsTable({table=private.table_reply_of_order, mes="check_position_to_close(): table_of order"})		
		local table_of_transaction = private_func.IsTable({table=private.table_reply_of_transaction, mes="check_position_to_close(): table_of transaction"})
			
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't check check_position_to_deactivate, because no self.kind='open' or self.kind='close'"}) end
		
		local result_ = false
		local _mes = ""
		local _key = nil
		local delta = nil
		local needed_position = nil
		local current_lots_of_position = nil
		
		MainWriter.WriteToEndOfFile({mes="\ncheck_position_to_deactivate() INCOME PARAM".. "\n"..
											"self.kind = "..self.kind.."\n"..
											"private.open_side_is_active = "..tostring(private.open_side_is_active).."\n"..
											"private.life_time_open = "..tostring(private.life_time_open).."\n"..
											"private.begin_check_self_open = "..tostring(private.begin_check_self_open).."\n"..
											"private.close_side_is_active = "..tostring(private.close_side_is_active).."\n"..
											"private.life_time_close = "..tostring(private.life_time_close).."\n"..
											"private.begin_check_self_close = "..tostring(private.begin_check_self_close).."\n"..											
											"---------------------------------------------------------------------------"
		
		})
		
		if (self.kind == "open" and private.open_side_is_active == true and private.life_time_open > private.begin_check_self_open ) or 
			(self.kind =="close" and private.close_side_is_active == true and private.life_time_close > private.begin_check_self_close )then 
						
			local trans_reply = nil
			local order_reply = nil
			local deals_reply = nil
		
			if (self.kind == 'open') then
				_key = private.id_position
				trans_reply = private.table_reply_of_transaction.status
			    order_reply = private.table_reply_of_order
			    deals_reply = private.list_reply_of_deals
				needed_position = private.lot
				current_lots_of_position = private_func.get_current_lot_of_position_open()
		        delta = private.lot - private_func.get_current_lot_of_position_open()
			elseif (self.kind == 'close') then
				_key = private.id_position_to_close
				trans_reply = private.table_reply_of_transaction_to_close.status
			    order_reply = private.table_reply_of_order_to_close
			    deals_reply = private.list_reply_of_deals_to_close	
				needed_position = private_func.get_current_lot_of_position_open()
				current_lots_of_position = private_func.get_current_lot_of_position_close()
		        delta = private_func.get_current_lot_of_position_open() - private_func.get_current_lot_of_position_close()											
			end			
			
			if (table_of_order.result == false) then
			--if no table of order's reply
				if (current_lots_of_position == 0) then
					--if no current positions
					if (table_of_transaction.result == false) then
						--if no table of trans's reply
						_mes = "ERROR from check_position_to_deactivate_open: None any info about this position"
						--message(_mes)
						result_ = true
					else
						if (tonumber(trans_reply) ~= nil) then
							if (state_ == 2 or state_ > 3) then
								_mes = "Transaction sending is bad reply: Transaction fail"
								result_ = true
							elseif (state_ == 3) then
								_mes = "Transaction sending is GOOD reply: Transaction sended"
								result_ = false
							else 
								_mes = "Transaction is sending status reply: Transaction sened and wait reply"
								result_ = false
							end
						else 
							_mes = "ERROR ! No transaction status"
							result_ = true						
						end
					end				
				else
					--if is lot of position - chek to fool position 				
					--there we must find order from trade table and if it active we can't close this position
					--мы должны найти ордер в таблице ордеров по номеру
					--TABLE order NUMBER indx getOrderByNumber(STRING class_code, NUMBER order_id)
					local order_num = ""
					for key, value in pairs(deals_reply) do
						if(value.ordernum ~= nil and value.ordernum ~= 0) then
							order_num = value.ordernum
						elseif (value.order_num ~= nil and value.order_num ~= 0) then
							order_num = value.order_num
						end
						break
					end	
					
					local order_of_position = getOrderByNumber(tostring(private.class), tostring(order_num))
					
					if order_of_position == nil then
						_mes = "ERROR We not have reply from order. We not have order of this position is system.\n But we have some position. We can close this position"
						result = true
					else
						local value = order_of_position
						if (bit.band(value.flags, 1) == 0) then
							--order no active
							_mes = "We not have reply from order, but order in terminal and order NO active. We can stop position"
							result_ = true	
						else
							--order is active
							_mes = "We not have reply from order, but order in terminal and order IS active. We can't stop position"
							result_ = false
						end						
					end
				end			
			else
			--if is order reply
			--we check order to active or passive if it active we can't close this position else we can close with curren result
				local value = order_reply
				if (bit.band(value.flags, 1) == 0) then
				--order no active
					_mes = "We have reply from order sending and order NO active. We can stop position"
					result_ = true	
				else
				--order is active
					_mes = "We have reply from order sending and order IS active. We can't stop position"
					result_ = false	
				end		
			end
		end
		
		----checking result of delta open position and close we need zero delta 
		--if (kind == "close" and delta ~= 0 ) then
		--	result_ = false
		--end
		MainWriter.WriteToEndOfFile({mes="\ncheck_position_to_deactivate() "..self.kind.. "\n"..
							"self.kind = "..self.kind.."\n"..
							"needed_position = "..tostring(needed_position).."\n"..
							"current_lots_of_position = "..tostring(current_lots_of_position).."\n"..
							"delta = "..tostring(delta).."\n"..
							"key = "..tostring(_key).."\n"..
							"result = "..tostring(result_).."\n"..
							"mes = ".._mes.."\n"..
							"-----------------------------------"
							})
		
		
		return {result=result_, 
				mes=_mes,
				id_position = tostring(_key) or tostring(private.id_position),
				needed_position = tonumber(needed_position),
				current_position = tonumber(current_lots_of_position),
				delta = tonumber(delta)
		}
	end
	
	function public:deactivate_open_step() -- format ()
	--I want to end of taking position and I must make open position non active
		local _is_active = private_func.IsActivePosition({mes="deactivate_open_step()"})		
		if _is_active.result == false then return _is_active end		
		
		--if time not come to check result of transaction return false result
		if (private.life_time_open <= private.begin_check_self_open) then		
			return private_func.IsNotValidate({mes="deactivate_open_step(): not yet time to check order status\n"})		
		end
		
		local _result = false
		local _mes = "deactivate_open_step(): No message."
		
		local _order_is_active = public.check_is_order_active({kind="open"})
		if (_order_is_active.result == false) then
			MainWriter.WriteToEndOfFile({mes="\ndeactivate_open_step() CAN CLOSE".."\n"})
			private.open_side_is_active = false
			private.open_side_was_closed = true
			_result = true
			_mes = "All orders of open side position was closed. Open side is deactivated. open_side_was_closed = true"
		else
			MainWriter.WriteToEndOfFile({mes="\ndeactivate_open_step() CAN'T CLOSE".."\n"})
			private.life_time_open = 0
			private_func.kill_order_of_position({kind="open"})
			_result = false
			_mes = "Open side has active orders. Open side can't be deactivated. Kill transaction was sended with kind = 'open'. Time life open side = 0"
		end
		
		return {
				result = _result,
				mes = _mes,
				id_position = private.id_position
		}
	end
	
	function private_func:deactivate_close_step() --format ()
		local _is_active = private_func.IsActivePosition({mes="deactivate_close_step()"})		
		if _is_active.result == false then return _is_active end
		
		if (private.open_side_was_closed == false) then	
			--1)Deactivate opening side of position
			MainWriter.WriteToEndOfFile({mes="\nINCOME TO deactivate_open_step 'OPEN'\n"..
									"private.open_side_is_active = "..tostring(private.open_side_is_active).."\n"})
			
			local open_pos_deactivated = public.deactivate_open_step()	
			
			MainWriter.WriteToEndOfFile({mes="\nOUT FROM deactivate_open_step 'OPEN'\n"..
										"open_pos_deactivated.RESULT = "..tostring(open_pos_deactivated.result).."\n"..
										"private.open_side_is_active = "..tostring(private.open_side_is_active).."\n"
										})
		
			--if I can't deactivate open-side position return to block deactivate open side position
			if (open_pos_deactivated.result == false) then 			
				MainWriter.WriteToEndOfFile({mes="\ndeactivate_close_step() CAN'T CLOSE BECAUSE OPEN CANT BE CLOSE".."\n"})
				return open_pos_deactivated 
			end				
		end 
		
		--2)Open-side position deactivated and now turn on close-side position
		private.close_side_is_active = true		
		
		local _result = false
		local _mes = "deactivate_close_step(): No message."
		
		--3)Check delta of current volume open-side position and current volume close-side position
		local delta = private_func.get_current_lot_of_position_open() - private_func.get_current_lot_of_position_close()
		if (delta == 0) then
			--4)All open-positions volume was closed
			private.close_side_is_active = false
			private.close_side_was_closed = true
			_result = true
			_mes = "All open-side volume = "..tostring(private_func.get_current_lot_of_position_open()).." of positions was closed successful"
		elseif (delta > 0) then
			--3)Has volume of positions to close
			if (private.transaction_sended_close == false) then
				--3a)Has flag that transaction was sended, turn on transaction_sended_close = true
				--3a)Set new time life of closing side position: private.life_time_close = 0				
				local result_send_order = public.send_first_transaction({kind = "close"})
				_result = false
				_mes = "Close side of position sended transaction to close volume of open position. Result sending= "..tostring(result_send_order.result)
			else				
				if (private.life_time_close <= private.begin_check_self_close) then
				--if time not come to check result of transaction return false result
					_result = false
					_mes = "deactivate_close_step(): not yet time to check order status\n"		
				else
				--if time to check position come - checking for active order
					local _order_is_active = public.check_is_order_active({kind="close"})
					if (_order_is_active.result == false) then
						--turn off flag that transaction was sended
						private.transaction_sended_close = false
						_result = false
						_mes = "deactivate_close_step(): No active orders of closing side\n"
					else
						--send transaction for cancel order of closing side position
						local result_send_order = private_func.kill_order_of_position({kind="close"})
						_result = false
						_mes = "deactivate_close_step(): Exist active orders of closing side, send transaction to cancel it\n"
					end				
				end			
			end		
		else
			MainWriter.WriteToEndOfFile({mes="\ndeactivate_close_step() ERROR delta of positions < 0 ".."\n"})
			_result = true
			_mes = "ERROR \ndeactivate_close_step() ERROR delta of positions < 0 ".."\n"
		end
		
		return {
				result = _result,
				mes = _mes,
				id_position = private.id_position,
				open_side_volume = private_func.get_current_lot_of_position_open(),
				close_side_volume = private_func.get_current_lot_of_position_close(),
				delta = delta
		}								
	end
	
	function public:close_position()	
		local _is_active = private_func.IsActivePosition({mes="deactivate_close_step()"})		
		if _is_active.result == false then return _is_active end
		
		local _result = false
		local _mes = "close_position(): None message "
		
		if (private.open_side_was_closed == true and private.close_side_was_closed == true) then
			_result = true
			_mes = "close_position(): Position successful closed as full"
			private.is_active = false
		else
			local result_deact_pos = private_func.deactivate_close_step()
			_result = result_deact_pos.result
			_mes = result_deact_pos.mes		
		end
		
		
		return {
				result = _result,
				mes = _mes,
				id_position = private.id_position
				}
	end
	
		
	function public:get_id_position()
		return private.id_position
	end
	
	function public:get_id_position_to_close()
		return private.id_position_to_close
	end	
	
	function public:get_account()
		return private.account
	end
	
	function public:get_class()
		return private.class
	end
	
	function public:get_security()
		return private.security
	end
	
	function public:get_security_info()
		return private.security_info
	end

	function public:get_lot()
		return private.lot
	end
	
	function public:get_side()
		return private.side
	end
	
	function public:get_enter_price()
		return private.enter_price
	end
	
	function public:get_slippage()
		return private.slippage
	end
	
	function public:get_stop_loss()
		return private.stop_loss
	end
	
	function public:get_take_profit()
		return private.take_profit
	end
	
	function public:get_market_type()
		return private.market_type
	end
	
	function public:get_is_active()
		return private.is_active
	end
	
	function public:get_securityinfo()
		return private.securityinfo
	end		
	
	function public:get_tradingstatus()
		return private.tradingstatus
	end
	
	function public:get_pricemax()
		return private.pricemax
	end
	
	function public:get_pricemin()
		return private.pricemin
	end
	
	function public:get_starttime()
		return private.starttime
	end
	
	function public:get_endtime()
		return private.endtime
	end
	
	function public:get_evnstarttime()
		return private.evnstarttime
	end
	
	function public:get_evnendtime()
		return private.evnendtime
	end
	
	function public:get_monstarttime()
		return private.get_monstarttime
	end
	
	function public:get_monendtime()
		return private.monendtime
	end
	
	function public:get_table_reply_of_transaction()
		return private.table_reply_of_transaction
	end

	function public:get_table_reply_of_orders()
		return private.table_reply_of_order
	end

	function public:get_list_reply_of_deals()
		return private.list_reply_of_deals
	end
	
	function public:get_is_full_position()
		return private.is_full
	end



	setmetatable(public,self)
    self.__index = self; return public
	
end