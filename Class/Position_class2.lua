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
--                                  отступ от цены входа для того чтобы не покупать по худшим ценам в шагах цены
--									price_offset = 2, number
--									--время после которого нужно проверять наличие ордеров в словаре ордеров
--									begin_check_self_open = 4, number --открывающая сторона
--									begin_check_self_close = 4 number --закрывающая сторона
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
		--отступ от цены входа для того чтобы не покупать по худшим ценам в шагах цены
		private.price_offset = tonumber(positionTable.price_offset) or ""

		--property to on/off position - activate in method of activation
		private.is_active = false

		--флаг принудительного закрытия позиции
		private.flag_turn_off = false

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

		private.list_reply_of_transaction = {} --table of transaction one
		private.list_reply_of_orders = {}
		private.list_reply_of_deals = {}  --table of tables
		private.open_side_is_active = false


		private.list_reply_of_transaction_to_close = {} --table of transaction one
		private.list_reply_of_orders_to_close = {}
		private.list_reply_of_deals_to_close = {}    --table of tables
		private.close_side_is_active = false

		--life time begin count where was check first transaction
		private.life_time_open = 0
		private.begin_check_self_open = tonumber(positionTable.begin_check_self_open) or 4
		private.transaction_sended_open = false
		private.open_side_was_closed = false

		private.life_time_close = 0
		private.begin_check_self_close = tonumber(positionTable.begin_check_self_close) or 4
		private.transaction_sended_close = false
		private.close_side_was_closed = false

		--переменная включается в блоке закрытия позиции и не дает набирать новую позицию
		private.was_started_closed_position = false

		private.is_full = false

		--absolute values in price numbers
		private.stop_loss_absolute = tonumber(private.stop_loss) or 0
		private.take_profit_absolute = tonumber(private.take_profit) or 0

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

	function private_func:fill_data_from_get_param_ex()
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

	function private_func:check_stop_take_by_limits()
		-- check price of profit or stoploss for max limit or min limit
		-- data types {stop = 20, take = 40 , enter_price = 54000, side="b"}
		private_func.CheckSidePosition()
		local step = private.security_info.min_price_step
		local enter_price = private.enter_price
		local min_planc = tonumber(private.pricemin)
		local max_planc = tonumber(private.pricemax)

		--message("type = "..tostring(type(enter_price))..";\n value = "..tostring(enter_price)..";\n type max_planc = "..tostring(type(max_planc)).."value = "..tostring(max_planc))

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
			take = enter_price - (private.take_profit * step)
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

		--make absolute count of stop and take
		if (string.lower(private.side) == "b") then
			private.stop_loss_absolute = private_func.RoundToSecurityStep(private.enter_price - (private.stop_loss * step))
			private.take_profit_absolute = private_func.RoundToSecurityStep(private.enter_price + (private.take_profit * step))

		elseif (string.lower(private.side) == "s") then
			private.stop_loss_absolute = private_func.RoundToSecurityStep(private.enter_price + (private.stop_loss * step))
			private.take_profit_absolute = private_func.RoundToSecurityStep(private.enter_price - (private.take_profit * step))
		else
			message("check_stop_take_by_limits(): ERRORside not S or not B")
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

	--функция возвращает результат от таблицы в виде текстовой строки
	function public:get_result_of_position()
		local result = ""

		local middle_price_open_side = 0
		local count_open_side = 0
		local price_open_side = 0
		local date_open_side = ""
		local trade_num_open_side = ""
		local order_num_open_side = ""
		local trans_id_open_side = ""
		local brokerref_open_side = ""
		--считаю среднюю цену входа
		for key, value in pairs(private.list_reply_of_deals) do
			local v = tonumber(value.qty)
			local p = tonumber(value.price)
			if v == nil then message("qty is nil in list_reply_of_deals!!! (317 position_class2)") end
			if p == nil then message("price is nil in list_reply_of_deals!!! (317 position_class2)") end
			count_open_side = count_open_side + v
			price_open_side = price_open_side + p
			date_open_side = tostring(value.datetime.year) .. "-" .. tostring(value.datetime.month) .. "-" .. tostring(value.datetime.day).." "..
							tostring(value.datetime.hour) .. ":" .. tostring(value.datetime.min) .. ":" .. tostring(value.datetime.sec)
			trade_num_open_side = tostring(value.tradenum)
			order_num_open_side = tostring(value.ordernum)
			trans_id_open_side = tostring(value.trans_id)
			brokerref_open_side = tostring(value.brokerref)
		end

		middle_price_open_side = price_open_side / count_open_side

		local middle_price_close_side = 0
		local count_close_side = 0
		local price_close_side = 0
		local date_close_side = ""
		local trade_num_close_side = ""
		local order_num_close_side = ""
		local trans_id_close_side = ""
		local brokerref_close_side = ""

		--считаю среднюю цену входа
		for key, value in pairs(private.list_reply_of_deals_to_close) do
			local v = tonumber(value.qty)
			local p = tonumber(value.price)
			if v == nil then message("qty is nil in list_reply_of_deals!!! (333 position_class2)") end
			if p == nil then message("price is nil in list_reply_of_deals!!! (333 position_class2)") end
			count_close_side = count_close_side + v
			price_close_side = price_close_side + p
			date_close_side = tostring(value.datetime.year) .. "-" .. tostring(value.datetime.month) .. "-" .. tostring(value.datetime.day).." "..
							tostring(value.datetime.hour) .. ":" .. tostring(value.datetime.min) .. ":" .. tostring(value.datetime.sec)
			trade_num_close_side = tostring(value.tradenum)
			order_num_close_side = tostring(value.ordernum)
			trans_id_close_side = tostring(value.trans_id)
			brokerref_close_side = tostring(value.brokerref)
		end

		middle_price_close_side = price_close_side / count_close_side
		local profit = 0

		if (private.side == "B" or private.side == "b") then
			profit = middle_price_close_side - middle_price_open_side
		else
			profit = middle_price_open_side - middle_price_close_side
		end

		result = 
		date_open_side..';'..private.side..';'..tostring(profit)..";"..
		tostring(count_open_side)..';'..tostring(middle_price_open_side)..';'..trade_num_open_side..';'..order_num_open_side..';'..trans_id_open_side..';'..brokerref_open_side..';'..
		tostring(count_close_side)..';'..tostring(middle_price_close_side)..';'..trade_num_close_side..';'..order_num_close_side..';'..trans_id_close_side..';'..brokerref_close_side..';\n'

		return result
	end

	function public:copy_dictionary_value() --format {from_dic=table, to_dic=table}
		local from_dic_table = private_func.IsTable({table=self.from_dic, mes="copy_dictionary_value(): from_dic"})
		local to_dic_table = private_func.IsTable({table=self.to_dic, mes="copy_dictionary_value(): to_dic"})

		if from_dic_table.result == false then return from_dic_table end
		if to_dic_table.result == false then return to_dic_table end

		for key, value in pairs(self.from_dic) do
			self.to_dic[key] = value
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

		local table_of_self = private_func.IsTable({table=self, mes="kill_order_of_position(): self is table"})
		if table_of_self.result == false then return table_of_self end

		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't find order to cancel, because no self.kind='open' or self.kind='close'"}) end

		local _key = nil --id position or close position
		local _list = {} --list of order
		local result_ = false
		local _mes = ""
		local current_lots_of_position = nil
		local _order_num = nil
		local _delta = nil

		--in this list storage all sended to kill orders
		--_list_to_kill["order_num"] = {order_num = number, result = true, mes = ""}
		local _list_to_kill = {}

		if self.kind == 'open' then
			_key = private.id_position
			public.copy_dictionary_value({from_dic =  private.list_reply_of_orders, to_dic = _list})

			current_lots_of_position = private_func.get_current_lot_of_position_open()
			--_delta = private.lot - current_lots_of_position
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
			public.copy_dictionary_value({from_dic =  private.list_reply_of_orders_to_close, to_dic = _list})

			current_lots_of_position = private_func.get_current_lot_of_position_close()
			--_delta = private_func.get_current_lot_of_position_open() - private_func.get_current_lot_of_position_close()
		end

		--для каждого активного ордера в листе ордеров посылаю отмену
		for key, value in pairs(_list) do
			if(value.ordernum ~= nil and value.ordernum ~= 0) then
				_order_num = tostring(value.ordernum)
			elseif(value.order_num ~= nil and value.order_num ~= 0) then
				_order_num = tostring(value.order_num)
			end

			if (_order_num ~= nil) then

				if (value.flags ~= nil and bit.band(value.flags, 1) == 0) then
					--order no active
					_mes = "We can't send kill transaction, because order not active or flags == nil"
				elseif (value.flags ~= nil and bit.band(value.flags, 1) > 0) then
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
						--MainWriter.WriteToEndOfFile({mes="Order N: "..tostring(_order_num)..". ".._mes})
					else
						_mes = 'kill_order_of_position(): Transaction Kill sended successful: private.life_time_close = 0'
						--MainWriter.WriteToEndOfFile({mes="Order N: "..tostring(_order_num)..". ".._mes})
						--message('TransOpenPos(): Transaction Kill sended')
					end
				end
			end
		end
	end

	function private_func:check_self_transaction_in_crude_dic() --format {crude_dictionary = table, executed_dictionary = table, kind = "open", kind = "close"}
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
		local _list_trans = {}

		--copy dictionary to local variable
		if self.kind == 'open' then
			_key = private.id_position
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
		end

		for key, value in pairs(self.crude_dictionary) do

			if (tostring(value.trans_id) == _key)then
				if       value.status == 0    then
					_mes = 'OnTransReply(): Transaction sended to server'
				elseif   value.status == 1    then
					_mes = 'OnTransReply(): Transaction take by server from QUIK client'
				elseif   value.status == 2    then
					_mes = 'OnTransReply(): Error with sending transaction to market system. As Quik is not connected to Moscow exchange. Second transaction wilnt send.'
				elseif   value.status == 3    then
				--success reply from server register to this position
					_mes = 'OnTransReply(): Transaction success sended!!!'
					if (self.kind == 'open') then

						if (private.list_reply_of_transaction[tostring(value.order_num)] == nil) then
							private.list_reply_of_transaction[tostring(value.order_num)] = value
						else
							if (private.list_reply_of_transaction[tostring(value.order_num)].quantity > 0 and
								value.quantity == 0) then
								private.list_reply_of_transaction[tostring(value.order_num)] = value
							end
						end
					elseif (self.kind == 'close') then
						if (private.list_reply_of_transaction_to_close[tostring(value.order_num)] == nil) then
							private.list_reply_of_transaction_to_close[tostring(value.order_num)] = value
						else
							if (private.list_reply_of_transaction_to_close[tostring(value.order_num)].quantity > 0 and
								value.quantity == 0) then
								private.list_reply_of_transaction_to_close[tostring(value.order_num)] = value
							end
						end
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

	function private_func:check_self_orders_in_crude_dic()
		local _is_active = private_func.IsActivePosition({mes="check_self_orders_in_crude_dic()"})
		if _is_active.result == false then return _is_active end

		local crude_dic_table = private_func.IsTable({table=self.crude_dictionary_orders, mes="check_self_orders_in_crude_dic(): Crude Table"})
		local execu_dic_table = private_func.IsTable({table=self.executed_dictionary_orders, mes="check_self_orders_in_crude_dic(): Executed Table"})

		if crude_dic_table.result == false then return crude_dic_table end
		if execu_dic_table.result == false then return execu_dic_table end
		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't check crude orders, because no self.kind='open' or self.kind='close'"}) end

		local list_to_delete = {}

		local _key = nil
		local _list = {}

		if self.kind == 'open' then
			_key = private.id_position
			public.copy_dictionary_value({from_dic=private.list_reply_of_orders, to_dic=_list}) --format
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
			public.copy_dictionary_value({from_dic=private.list_reply_of_orders_to_close, to_dic=_list}) --format
		end

		for key, value in pairs(self.crude_dictionary_orders) do
			local _order_num = nil
			if (value.ordernum ~= nil and value.ordernum ~= 0) then
				_order_num = value.ordernum
			elseif (value.order_num ~= nil and value.order_num ~= 0) then
				_order_num = value.order_num
			end

			if (_order_num ~= nil) then
				--message("tostring(value.brokerref): "..tostring(value.brokerref).."_key: "..tostring(_key))
				if (tostring(value.brokerref) == _key)then
				--find self order reply
					--1)Adding name order to list for delete
					list_to_delete[key] = key
					--2)Adding name order to list executed orders of transaction manager
					self.executed_dictionary_orders[key] = value

					if (_list[tostring(_order_num)] == nil) then
						_list[tostring(_order_num)] = value
					end

					if(_list[tostring(_order_num)].trans_id == 0 and value.trans_id ~=0) then
						_list[tostring(_order_num)] = value
					end

					if (bit.band(value.flags, 2) > 0) then
						--если заявка снята кем-то
						_list[tostring(_order_num)] = value
					elseif(bit.band(value.flags, 1) == 0 and bit.band(value.flags, 2) == 0) then
						--если ордер исполнен
						_list[tostring(_order_num)] = value
					end
				end
			else
				message("ERROR _order_num = null")
			end
		end

		--copy all _list values to self dictionary orders
		if self.kind == 'open' then
			public.copy_dictionary_value({from_dic=_list, to_dic= private.list_reply_of_orders}) --format
		elseif self.kind == 'close' then
			public.copy_dictionary_value({from_dic=_list, to_dic= private.list_reply_of_orders_to_close}) --format
		end

		--clear dictionary of crude if it was moved to executed dictionary
		for key, value in pairs(list_to_delete) do
			self.crude_dictionary_orders[value] = nil
		end
	end

	function private_func:check_self_deals_in_crude_dic() -- format {crude_dictionary_deals = table, executed_dictionary_deals = table, kind = "open"}
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
		local _list = {}

		--fill local list of self list deals data
		if self.kind == 'open' then
			_key = private.id_position
			public.copy_dictionary_value({from_dic=private.list_reply_of_deals, to_dic=_list}) --format
		elseif self.kind == 'close' then
			_key = private.id_position_to_close
			public.copy_dictionary_value({from_dic=private.list_reply_of_deals_to_close, to_dic=_list}) --format
		end

		for key, value in pairs(self.crude_dictionary_deals) do
			if (tostring(value.brokerref) == _key)then
				local not_finded_deal = true
				for inner_key, inner_value in pairs(_list) do
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
				--if private dictionary of deals not contains this deal write it to self list of deals
				if not_finded_deal == true then
						_list[key] = value
				end
			end
		end

		--fill self list of deals of newest data
		if self.kind == 'open' then
			public.copy_dictionary_value({from_dic=_list, to_dic=private.list_reply_of_deals}) --format
		elseif self.kind == 'close' then
			public.copy_dictionary_value({from_dic=_list, to_dic=private.list_reply_of_deals_to_close}) --format
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

	--public functions
	function public:ActivatePosition()
		--take security info to saving
		private.securityinfo = getSecurityInfo(private.class, private.security)

		--take param current session
		private_func.fill_data_from_get_param_ex()

		--check side position for correct char
		private_func.CheckSidePosition()

		--if all properties filled is_activate = true
		local _res = private_func.IsNilPropertyOfTable(private)
		private.is_active = _res.result
		message("ActivatePosition()	: ".._res.mes)
		--fill stoploss and takeprofits with limits of market max-min price
		private_func.check_stop_take_by_limits()

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


		if self.kind == nil or (self.kind ~= 'open' and self.kind ~= 'close') then return private_func.IsNotValidate({mes="Can't sending new order, because no self.kind='open' or self.kind='close'"}) end
		local _side = nil
		local _price = nil
		local _lot = nil
		local _id_pos = nil
		local _slip = nil

		if (self.kind == "open") then
			_side = private.side

			--_price = tostring(private.enter_price)
			local last = tonumber(getParamEx(private.class, private.security, "LAST").param_value)
			local step = private.security_info.min_price_step

			if private.side == "B" then
				--_price = tostring( last + private_func.RoundToSecurityStep(private.slippage*step))
				--_price = tostring( last + private.slippage)
				_price = tostring( private_func.RoundToSecurityStep(last - (private.price_offset * step)))
			elseif private.side == "S" then
				--_price = tostring( last - private_func.RoundToSecurityStep(private.slippage*step))
				--_price = tostring( last - private.slippage)
				_price = tostring( private_func.RoundToSecurityStep(last + (private.price_offset * step)))
			end


			--needed delta of has positions and needed positions
			_lot = tostring(private.lot - private_func.get_current_lot_of_position_open())
			_id_pos = private.id_position
			_slip = private.slippage

		elseif (self.kind == "close") then
			_side = private_func.ReverseSidePosition()
			local last = tonumber(getParamEx(private.class, private.security, "LAST").param_value)
			local step = private.security_info.min_price_step

			if private_func.ReverseSidePosition() == "B" then
				--_price = tostring( last + private_func.RoundToSecurityStep(private.slippage*step))
				--_price = tostring( last + private.slippage)
				_price = tostring( private_func.RoundToSecurityStep(last - (private.price_offset * step)))
			elseif private_func.ReverseSidePosition() == "S" then
				--_price = tostring( last - private_func.RoundToSecurityStep(private.slippage*step))
				--_price = tostring( last - private.slippage)
				_price = tostring( private_func.RoundToSecurityStep(last + (private.price_offset * step)))
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
				--message(_mes)
				--MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() BAD RESULT".."\n"})
				if (self.kind == "open") then
					private.transaction_sended_open = false
					private.open_side_is_active = false
					--MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() BAD RESULT ACTIVATED".."\n"})
				elseif (self.kind == "close") then
					private.transaction_sended_close = false
					private.close_side_is_active = false
				end
				return private_func.IsNotValidate({mes=_mes})
			end
			_mes = 'send_first_transaction(): Transaction sended'
			--message(_mes)
			--MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() GOOD RESULT".."\n"})
			--start new loop of life side's position
			if (self.kind == "open") then
				private.transaction_sended_open = true
				private.open_side_is_active = true
				private.life_time_open = 0
				--MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() GOOD RESULT ACTIVATED".."\n"})
			elseif (self.kind == "close") then
				private.transaction_sended_close = true
				private.close_side_is_active = true
				private.life_time_close = 0
				--MainWriter.WriteToEndOfFile({mes="\nSEND TRANS() GOOD RESULT ACTIVATED CLOSE".."\n"})
			end
		end

		return private_func.IsValidate({mes=_mes})
	end

	function public:full_check_manager()
	--format data{crude_dictionary = table,
	--			executed_dictionary = table,
	--			crude_dictionary_orders = table,
	--			executed_dictionary_orders = table,
	--			crude_dictionary_deals = table,
	--			executed_dictionary_deals = table }
		local _is_active = private_func.IsActivePosition({mes="check_self_transaction_in_crude_dic()"})
		if _is_active.result == false then return _is_active end

		local crude_dic_trans_table = private_func.IsTable({table=self.crude_dictionary, mes="full_check_manager(): Crude Table Transaction"})
		local execu_dic_trans_table = private_func.IsTable({table=self.executed_dictionary, mes="full_check_manager(): Executed Table Transaction"})
		local crude_dic_orders_table = private_func.IsTable({table=self.crude_dictionary_orders, mes="full_check_manager(): Crude Table Orders"})
		local execu_dic_orders_table = private_func.IsTable({table=self.executed_dictionary_orders, mes="full_check_manager(): Executed Table Orders"})
		local crude_dic_deals_table = private_func.IsTable({table=self.crude_dictionary_deals, mes="full_check_manager(): Crude Table Deals"})
		local execu_dic_deals_table = private_func.IsTable({table=self.executed_dictionary_deals, mes="full_check_manager(): Executed Table Deals"})

		if crude_dic_trans_table.result == false then return crude_dic_trans_table end
		if execu_dic_trans_table.result == false then return execu_dic_trans_table end
		if crude_dic_orders_table.result == false then return crude_dic_orders_table end
		if execu_dic_orders_table.result == false then return execu_dic_orders_table end
		if crude_dic_deals_table.result == false then return crude_dic_deals_table end
		if execu_dic_deals_table.result == false then return execu_dic_deals_table end

		private_func.check_self_transaction_in_crude_dic({
									crude_dictionary = self.crude_dictionary,
									executed_dictionary = self.executed_dictionary,
									kind = "open"})
		private_func.check_self_transaction_in_crude_dic({
									crude_dictionary = self.crude_dictionary,
									executed_dictionary = self.executed_dictionary,
									kind = "close"})

		private_func.check_self_orders_in_crude_dic({
									crude_dictionary_orders = self.crude_dictionary_orders,
									executed_dictionary_orders = self.executed_dictionary_orders,
									kind = "open"})

		private_func.check_self_orders_in_crude_dic({
									crude_dictionary_orders = self.crude_dictionary_orders,
									executed_dictionary_orders = self.executed_dictionary_orders,
									kind = "close"})

		private_func.check_self_deals_in_crude_dic({
									crude_dictionary_deals = self.crude_dictionary_deals,
									executed_dictionary_deals = self.executed_dictionary_deals,
									kind = "open"})

		private_func.check_self_deals_in_crude_dic({
									crude_dictionary_deals = self.crude_dictionary_deals,
									executed_dictionary_deals = self.executed_dictionary_deals,
									kind = "close"})

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

		local _list_order = nil
		local _table_name = "None Name Of Table"
		local _id_position = "None ID Position"
		if (self.kind == 'open') then
			_list_order = private.list_reply_of_orders
			_table_name = 'OPEN SIDE ORDER TABLE'
			_id_position = private.id_position
		elseif (self.kind == 'close') then
			_list_order = private.list_reply_of_orders_to_close
			_table_name = 'CLOSE SIDE ORDER TABLE'
			_id_position = private.id_position_to_close
		end

		--проверяю есть ли активные ордера в словаре ордеров - есть значит возвращаю true
		for key, value in pairs(_list_order) do
			if (bit.band(value.flags, 1) == 0) then
				--order no active
				_result = false
				_mes = _table_name..": All orders not active"

			else
				--order is active
				_result = true
				_mes = _table_name..": One order is ACTIVE."

				break
			end
		end
		message(_mes)
		return {
				result = _result,
				mes = _mes,
				id_position = _id_position
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
			--MainWriter.WriteToEndOfFile({mes="\ndeactivate_open_step() CAN CLOSE".."\n"})
			private.open_side_is_active = false
			private.open_side_was_closed = true
			_result = true
			_mes = "All orders of open side position was closed. Open side is deactivated. open_side_was_closed = true"
		else
			--MainWriter.WriteToEndOfFile({mes="\ndeactivate_open_step() CAN'T CLOSE".."\n"})
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
			--MainWriter.WriteToEndOfFile({mes="\nINCOME TO deactivate_open_step 'OPEN'\n"..
			--						"private.open_side_is_active = "..tostring(private.open_side_is_active).."\n"})

			local open_pos_deactivated = public.deactivate_open_step()

			--MainWriter.WriteToEndOfFile({mes="\nOUT FROM deactivate_open_step 'OPEN'\n"..
			--							"open_pos_deactivated.RESULT = "..tostring(open_pos_deactivated.result).."\n"..
			--							"private.open_side_is_active = "..tostring(private.open_side_is_active).."\n"
			--							})

			--if I can't deactivate open-side position return to block deactivate open side position
			if (open_pos_deactivated.result == false) then
				--MainWriter.WriteToEndOfFile({mes="\ndeactivate_close_step() CAN'T CLOSE BECAUSE OPEN CANT BE CLOSE".."\n"})
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

	function public:take_best_position()
		local _is_active = private_func.IsActivePosition({mes="take_best_position()"})
		if _is_active.result == false then return _is_active end

		--если вкючено закрытие позиции набирать позицию нельзя
		if (private.was_started_closed_position == true) then
			return private_func.IsNotValidate({mes="Can't opening position, because was started closing position"})
		end

		--включаю открывающую сторону позиции
		private.open_side_is_active = true

		local _result = false
		local _mes = "take_best_position(): No message."
		--3)Check delta of current volume open-side position and needed lots
		local delta = private.lot - private_func.get_current_lot_of_position_open()


		if (delta == 0) then
			--4)All open-positions volume was opened
			private.open_side_is_active = false
			private.open_side_was_closed = true
			--позиция набрана в полном объеме и теперь ее можно только закрывать
			private.was_started_closed_position = true
			_result = true
			_mes = "All open-side volume = "..tostring(private_func.get_current_lot_of_position_open()).." was taked successful"
		elseif (delta > 0) then
			--3)Has volume of positions to open
			if (private.transaction_sended_open == false) then
				--3a)Has flag that transaction was sended, turn on transaction_sended_open = true
				--3a)Set new time life of opening side position: private.life_time_open = 0
				local result_send_order = public.send_first_transaction({kind = "open"})
				_result = false
				_mes = "Open side of position sended transaction to open volume of position. Result sending= "..tostring(result_send_order.result)
			else
				if (private.life_time_open <= private.begin_check_self_open) then
				--if time not come to check result of transaction return false result
					_result = false
					_mes = "take_best_position(): not yet time to check order status for open side position\n"
				else
				--if time to check position come - checking for active order of opening side position
					local _order_is_active = public.check_is_order_active({kind="open"})
					if (_order_is_active.result == false) then
						--turn off flag that transaction was sended
						private.transaction_sended_open = false
						_result = false
						_mes = "take_best_position(): No active orders of opening side\n"
					else
						--send transaction for cancel order of opening side position
						local result_send_order = private_func.kill_order_of_position({kind="open"})
						_result = false
						_mes = "take_best_position(): Exist active orders of opening side, send transaction to cancel it\n"
					end

				end
			end

		else
			--error we take more posiitions that we need
			_result = true
			_mes = "ERROR \ntake_best_position() ERROR delta of positions < 0 ".."\n"
			MainWriter.WriteToEndOfFile({mes=_mes})

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

		--включаю флаг что набирать позицию нельзя
		private.was_started_closed_position = true

		if (private.open_side_was_closed == true and private.close_side_was_closed == true) then
			_result = true
			_mes = "close_position(): Position successful closed as full"
			private.is_active = false
			message(_mes)
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

	function public:main_loop_position()
	--функция основного жизненного цикла конкретной позиции
		local _is_active = private_func.IsActivePosition({mes="main_loop_position()"})
		if _is_active.result == false then return _is_active end

		--MainWriter.WriteToEndOfFile({mes="\nCome to: public:main_loop_position()\n_____\n"})
		if (private.flag_turn_off == true) then
			--нужно принудительно закрыть позицию
			--MainWriter.WriteToEndOfFile({mes="Come to: if (private.flag_turn_off == true)\n"})
			private.was_started_closed_position = true
			return public.close_position()
		end
		--нет принудительного закрытия позиции

		if (string.lower(private.use_stop) == 'true') then
			--проверяюдостигли стопа или нет
			--MainWriter.WriteToEndOfFile({mes="Come to: if (private.use_stop == true)\n"})
			local _last = tonumber(getParamEx(private.class, private.security, "LAST").param_value)
			if (string.lower(private.side) == "b" and _last <= private.stop_loss_absolute) or
			(string.lower(private.side) == "s" and _last >= private.stop_loss_absolute) then
				MainWriter.WriteToEndOfFile({mes="Come to: block take stoploss\n"})
				--включаю принудительное закрытие позиции
				private.flag_turn_off = true
				private.was_started_closed_position = true
				return public.close_position()
			end
		end

		if (string.lower(private.use_take) == 'true') then
			--проверяю достигли тейка или нет
			--MainWriter.WriteToEndOfFile({mes="Come to: if (private.use_take == true)\n"})
			local _last = tonumber(getParamEx(private.class, private.security, "LAST").param_value)
			if (string.lower(private.side) == "b" and _last >= private.take_profit_absolute) or
			(string.lower(private.side) == "s" and _last <= private.take_profit_absolute) then
				--включаю принудительное закрытие позиции
				--MainWriter.WriteToEndOfFile({mes="Come to: block take takeprofit\n"})
				private.flag_turn_off = true
				private.was_started_closed_position = true
				return public.close_position()
			end
		end

		if (private.was_started_closed_position == false) then
			--если позиция не набрана в полном объеме
			--MainWriter.WriteToEndOfFile({mes="Come to: if (private.was_started_closed_position == false)\n"})
			return public.take_best_position()
		end
		--если пришло сюда значит позиция на пути к стопу или тейку или ждет сигнал на закрытие
		local _result = true
		local _mes = "Main_loop of position continue..."
		--MainWriter.WriteToEndOfFile({mes="Exit from: public:main_loop_position(). Main_loop of position continue...\n"})
		return {
				result = _result,
				mes = _mes,
				id_position = private.id_position,
				open_side_volume = private_func.get_current_lot_of_position_open(),
				close_side_volume = private_func.get_current_lot_of_position_close()
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

	function public:get_stoploss_price()
		return private.stop_loss_absolute
	end

	function public:get_takeprofit_price()
		return private.take_profit_absolute
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
		return private.list_reply_of_transaction
	end

	function public:get_table_reply_of_orders()
		return private.list_reply_of_orders
	end

	function public:get_list_reply_of_deals()
		return private.list_reply_of_deals
	end

	function public:get_table_reply_of_transaction_to_close()
		return private.list_reply_of_transaction_to_close
	end

	function public:get_table_reply_of_orders_to_close()
		return private.list_reply_of_orders_to_close
	end

	function public:get_list_reply_of_deals_to_close()
		return private.list_reply_of_deals_to_close
	end

	function public:get_is_full_position()
		return private.is_full
	end

	function public:count_open_side_transactions()
		local c = 0
		for key, value in pairs(private.list_reply_of_transaction) do
			c = c + 1
		end
		return tonumber(c)
	end

	function public:count_open_side_orders()
		local c = 0
		for key, value in pairs(private.list_reply_of_orders) do
			c = c + 1
		end
		return tonumber(c)
	end

	function public:count_open_side_deals()
		local c = 0
		for key, value in pairs(private.list_reply_of_deals) do
			c = c + 1
		end
		return tonumber(c)
	end

	function public:count_close_side_transactions()
		local c = 0
		for key, value in pairs(private.list_reply_of_transaction_to_close) do
			c = c + 1
		end
		return tonumber(c)
	end

	function public:count_close_side_orders()
		local c = 0
		for key, value in pairs(private.list_reply_of_orders_to_close) do
			c = c + 1
		end
		return tonumber(c)
	end

	function public:count_close_side_deals()
		local c = 0
		for key, value in pairs(private.list_reply_of_deals_to_close) do
			c = c + 1
		end
		return tonumber(c)
	end

	function public:is_was_started_closed_position()
		return private.was_started_closed_position
	end

	function public:make_new_stop()--format number
		local stop = tonumber(self)
		local min_planc = tonumber(private.pricemin)
		local max_planc = tonumber(private.pricemax)
		local step = private.security_info.min_price_step

		if (stop==nil) then
			message ("Can't init new stop because: \nlocal stop = tonumber(self); (stop==nil)")
			return
		end

		if (private.side == "B") then
			private.stop_loss_absolute = private_func.RoundToSecurityStep(stop - step)
		elseif (private.side == "S") then
			private.stop_loss_absolute = private_func.RoundToSecurityStep(stop + step)
		end

		--если стоп меньше минимальной планки или больше максимальной делаем его на обин шаг выше или ниже соответственно
		if (private.stop_loss_absolute < min_planc) then
			private.stop_loss_absolute = private_func.RoundToSecurityStep(min_planc + (2 * step))
		elseif (private.stop_loss_absolute > max_planc) then
			private.stop_loss_absolute = private_func.RoundToSecurityStep(max_planc - (2 * step))
		end

		--устанавливаю вновь полученное значение стопа в шагах цены - чтобы синхронизировать
		if (private.side == "B") then
			private.stop_loss = math.floor((private.enter_price - private.stop_loss_absolute)/step)
		elseif (private.side == "S") then
			private.stop_loss = math.floor((private.enter_price + private.stop_loss_absolute)/step)
		end
	end

	function public:make_new_take()--format number
		local take = tonumber(self)
		local min_planc = tonumber(private.pricemin)
		local max_planc = tonumber(private.pricemax)
		local step = private.security_info.min_price_step

		if (take==nil) then
			message ("Can't init new take because: \nlocal take = tonumber(self); (take==nil)")
			return
		end

		private.take_profit_absolute = private_func.RoundToSecurityStep(take)

		--если стоп меньше минимальной планки или больше максимальной делаем его на обин шаг выше или ниже соответственно
		if (private.take_profit_absolute < min_planc) then
			private.take_profit_absolute = private_func.RoundToSecurityStep(min_planc + step)
		elseif (private.take_profit_absolute > max_planc) then
			private.take_profit_absolute = private_func.RoundToSecurityStep(max_planc - step)
		end
		--устанавливаю вновь полученное значение take в шагах цены - чтобы синхронизировать
		if (private.side == "B") then
			private.stop_loss = math.floor((private.enter_price + private.stop_loss_absolute)/step)
		elseif (private.side == "S") then
			private.stop_loss = math.floor((private.enter_price - private.stop_loss_absolute)/step)
		end
	end

	function public:get_delta_lot_of_position()
	--return actual information about open count lots
		return private_func.get_current_lot_of_position_open() - private_func.get_current_lot_of_position_close()
	end

	function public:get_info_dic_positions()
		return
		"\n----------------------------------------\n"..
		"Info about dictionaries Position № '"..tostring(private.id_position).."':\n"..
		"----------------------------------------"..
		"Reply Transaction items count = "..tostring(public.count_open_side_transactions()).."\n"..
		"Reply Order items count = "..tostring(public.count_open_side_orders()).."\n"..
		"Count deals in pos = "..tostring(public.count_open_side_deals()).."\n"..
		"Reply Transaction items count close = "..tostring(public.count_close_side_transactions()).."\n"..
		"Reply Order items count close= "..tostring(public.count_close_side_orders()).."\n"..
		"Count deals in pos close = "..tostring(public.count_close_side_deals()).."\n"..
		"----------------------------------------\n"
	end

	function public:turn_off_position()
		--флаг принудительного закрытия позиции
		private.flag_turn_off = true
	end

	setmetatable(public,self)
    self.__index = self; return public

end