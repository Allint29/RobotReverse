--Class of strategy. It search signal of indicators
--and create and deactivate positions
--it have dictionary of active position and dictionary of deactivated positions
--it have a triger of on/off strategy
--format of data positionTable = {
--								  id_strategy = "name" string

--								  account="", string
--								  class="", string
--								  security="", string
--								  security_info=SECURITY_TABLE_1,

--								  id_indicator = "name_indicator" string
--								  id_price = "name_price" string
--								  market_type = "reverse", string may be "long","short", "reverse"
--								  transaction_manager = transactionmanager
--								}


--Entity of strategy position format:
--  {name="",
--   time_signal_bar="",
--   t_open_position=new:Position,
--	 sec_to_open = 60
--	 sec_to_close = 60
--   t_close_position = new:Position,
--   is_active=true
--   stage = "opening"  ,  may be "opening", "active", "closing", "closed"
--   }

Startegy_reverse = {}
function Startegy_reverse:new(strategyTable)
	local private = {}
	local private_func = {}
	local public = {}

	private.id_strategy = tostring(strategyTable.id_strategy) or "default_parabolic_strategy"
	private.account = tostring(strategyTable.account) or ""
	private.class = tostring(strategyTable.class) or ""
	private.security = tostring(strategyTable.security) or ""
	private.security_info = strategyTable.security_info or ""
	private.id_indicator = tostring(strategyTable.id_indicator) or ""
	private.id_indicator_MA200 = tostring(strategyTable.id_indicator_MA200) or ""
	private.id_price = tostring(strategyTable.id_price) or ""
	private.market_type = "reverse" -- may be "long","short", "reverse"
	private.transaction_manager = strategyTable.transaction_manager or ""

	--table ob visualization of data - it need that have a access to table button
	private.strategy_table = strategyTable.strategy_table or ""

	--table of writer to file to console
	private.main_writer = strategyTable.main_writer or ""


	--
	private.active_positions = {}

	private.not_active_positions = {}

	--dict save all signal-bar name
	private.signal_bars = {}


	--property to on/off strategy - activate in method of activation
	private.is_active = false

	private.cash_maximum = {}
	private.cash_minimum = {}

	private.cash_names_of_positions = {}

	private.take_new_position_manualy = false


	--Элементы контроля таблицей
	--цена входа в первую лонговую позицию
	private.pos_info_table = {}
	private.pos_info_table["long_1"] = PositionInfo:new({id_position_info = "long_1", side = "long", row = 9})
	private.pos_info_table["long_2"] = PositionInfo:new({id_position_info = "long_2", side = "long", row = 11})
	private.pos_info_table["long_3"] = PositionInfo:new({id_position_info = "long_3", side = "long", row = 13})
	private.pos_info_table["short_1"] = PositionInfo:new({id_position_info = "short_1", side = "short", row = 15})
	private.pos_info_table["short_2"] = PositionInfo:new({id_position_info = "short_2", side = "short", row = 17})
	private.pos_info_table["short_3"] = PositionInfo:new({id_position_info = "short_3", side = "short", row = 19})

	--расчитываемый в блоке open_position_algo размер тейка в зависимости от размера предыдущего бара
	private.delta_for_2_tp_position  = 50
	----------------------------


	function private_func:IsValidate()
		--function return true with message
		--data format - string
		----format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "IsValidate(): None message" end
		return {result=true,
			mes="IsValidate(): "..tostring(self.mes).." "..tostring(private.id_strategy),
			id_strategy = tostring(private.id_strategy)
		}
	end

	function private_func:IsNotValidate()
		--function return true with message
		--data format - string
		----format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "IsNotValidate(): None message" end
		return {result=false,
				mes="IsNotValidate(): "..tostring(self.mes).." "..tostring(private.id_strategy),
				id_strategy = tostring(private.id_strategy)
		}
	end

	function private_func:IsActiveStrategy()
		--data format - string-message if manager is active transcend
		--format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = private.id_strategy.." None message" end
        if (private.is_active == false)then
            return {result=false,
                    mes=tostring(self.mes)..": "..private.id_strategy.." not active!",
                    id_strategy = tostring(private.id_strategy)}
        end

		return {result=true,
            mes=tostring(self.mes)..": Position is active!",
            id_strategy = tostring(private.id_strategy)}
    end

	--private functions
	function private_func:IsTable()
		--data format - data - if table transcend
		--format {table=obj, mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = private.id_strategy.."None message" end
		if (string.lower(type(self.table)) ~= string.lower("table"))then
			local _mes = tostring(self.mes).." : "..private.id_strategy.." take not valid data - not table! "..tostring(private.id_strategy)
			return {result=false,
					mes=_mes,
					id_strategy = tostring(private.id_strategy)
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
						id_strategy = tostring(private.id_strategy)
						}
			end
		end

		return private_func.IsValidate({mes="All properties not nil!"})
	end

	function private_func:generate_new_name_of_position() -- format {begin_num=number, end_num=number }
		--функция нужна для генерации названия позиций и чтобы они не повторялись
		local _begin = 100000
		local _end = 200000

		if (tonumber(self.begin_num) ~= nil) then _begin = tonumber(self.begin_num) end
		if (tonumber(self.end_num) ~= nil) then _end = tonumber(self.end_num) end

		local g_str = "1"..tostring(math.random(_begin,_end)).."9"
		local finded = false

		for key, value in pairs(private.cash_names_of_positions) do
			if (key == g_str) then
				finded = true
				break
			end
		end

		if (finded == true) then g_str = generate() end

		private.cash_names_of_positions[g_str] = g_str

		return g_str
	end

	function private_func:TableCount()-- format {dictionary=dictionary}
		--private.main_writer.WriteToEndOfFile({mes="dictionary: "..tostring(self.dictionary).."\n"})
		if (string.lower(type(self)) ~= string.lower("table") )then return 0 end
		--if (string.lower(type(self)) ~= string.lower("table"))then return 0 end

		local count = 0
		for key, value in pairs(self) do
			count = count + 1
			--private.main_writer.WriteToEndOfFile({mes="key: "..tostring(key).."value: "..tostring(value).."\n"})
		end
		return count
	end
	-----------------------------------------------------------------------
	function private_func:create_long_reverse_position()
		local last2 = tonumber(getParamEx(private.class, private.security, "LAST").param_value)
		--r = os.time()^-string.len(tostring(os.time()))
		return Position:new({
								id_position=tostring(private_func.generate_new_name_of_position({begin_num=10000, end_num=20000})),
								account=private.account,
								class=private.class,
								security=private.security,
								security_info=private.security_info,
								lot=1,
								side="b",
								enter_price= last2,
								slippage=3,
								stop_loss=50,
								take_profit=350,
								use_stop=true,
								use_take=true,
								market_type="reverse",
								--отступ от цены входа для того чтобы не покупать по худшим ценам в шагах цены
								price_offset = -2,
								--время после которого нужно проверять наличие ордеров в словаре ордеров
								begin_check_self_open = 4, --открывающая сторона
								begin_check_self_close = 4 --закрывающая сторона

								})
	end

	function private_func:create_short_reverse_position()
		local last2 = tonumber(getParamEx(private.class, private.security, "LAST").param_value)

		return Position:new({
								id_position=tostring(private_func.generate_new_name_of_position({begin_num=10000, end_num=20000})),
								account=private.account,
								class=private.class,
								security=private.security,
								security_info=private.security_info,
								lot=1,
								side="s",
								enter_price= last2,
								slippage=3,
								stop_loss=50,
								take_profit=350,
								use_stop=true,
								use_take=true,
								market_type="reverse",
								--отступ от цены входа для того чтобы не покупать по худшим ценам в шагах цены
								price_offset = -2,
								--время после которого нужно проверять наличие ордеров в словаре ордеров
								begin_check_self_open = 4, --открывающая сторона
								begin_check_self_close = 4 --закрывающая сторона

								})
	end

	function private_func:max_time_in_signal_bars()
	--function take dict with field bar_time and return signal bar with prev bar time and prev indicator price

		--local signal_bars_is_table = private_func.IsTable({table=self, mes="rivate_func:max_time_number(): "})
		--
		--if (signal_bars_is_table.result == false or self.bar_time == nil) then
		--	return nil
		--end

		local res_num = 0
		local signal_bar = nil

		for key, value in pairs(private.signal_bars) do
			if (value.bar_time > res_num) then
				res_num = tonumber(value.bar_time)
				signal_bar = value

			end
		end

		return signal_bar

	end

	function private_func:signal_check()
	--function of generate signal to trade
	--должен вернуть является ли данный бар сигнальным - то есть разворотным
	--последняя цена выше хая предыдущегобара
	--позапрошлый хай больше или равен предыдущему
		local _is_active = private_func.IsActiveStrategy({mes="signal_check()"})

		local _signal_for_1_long = false
		local _signal_for_1_short = false

		local _signal_for_2_long = false
		local _signal_for_2_short = false

		local _signal_bar = nil
		local _current_bar = nil
		local _bar_2 = nil
		local _bar_3 = nil
		local _indicator = nil
		local _indicator_MA200 = nil
		local _last_price = nil
		local _mes = ""

		if _is_active.result == false then
			return {
					signal_for_1_long = _signal_for_1_long,
					signal_for_1_short = _signal_for_1_short,
					signal_for_2_long = _signal_for_2_long,
					signal_for_2_short = _signal_for_2_short,
					signal_bar = _signal_bar,
					current_bar = _current_bar,
					bar = _bar_2,
					bar_3 = _bar_3,
					indicator = _indicator,
					indicator_MA200 = _indicator_MA200,
					last_price = _last_price,
					mes = _mes,
					id_strategy = private.id_strategy
					}
		end

		
		--last price of security
		_last_price = tonumber(getParamEx(private.class, private.security, "LAST").param_value)
		--count of candles of indicator
		local count_candles_indicator = getNumCandles(private.id_indicator)
		local count_candles_indicator_MA200 = getNumCandles(private.id_indicator_MA200)
		local count_candles_price = getNumCandles(private.id_price)

		--TABLE t, NUMBER n, STRING l getCandlesByIndex (STRING tag, NUMBER line, NUMBER first_candle, NUMBER count)
		--take three candles from chart
		local t_c_indicator, c_n_indicator, _ = getCandlesByIndex (private.id_indicator, 0, count_candles_indicator-4, 4)
		local t_c_indicator_MA200, c_n_indicator_MA200, _ = getCandlesByIndex (private.id_indicator_MA200, 0, count_candles_indicator_MA200-4, 4)
		local t_c_price, c_n_price, _ = getCandlesByIndex (private.id_price, 0, count_candles_price-4, 4)

		--текущий бар - если взято 3 бара то текущий - это t_c_indicator[3]
		--предыдущий - t_c_indicator[2]
		--предыдущий - t_c_indicator[1]
		--самый левый - t_c_indicator[0]

		if (c_n_indicator~=4 or c_n_price~=4)then
			_signal_bar = nil
			_long_side_MA200 = nil			
			_bar_2 = nil
			_bar_3 = nil
			_indicator = nil
			_indicator_MA200 = nil
			_mes = "Count candles of price or indicator ~= 3"
		else
			_signal_bar = false

			if(
				t_c_indicator[0] ~=nil and t_c_indicator_MA200[0] ~=nil and t_c_price[0] ~=nil and
				t_c_indicator[1] ~=nil and t_c_indicator_MA200[1] ~=nil and t_c_price[1] ~=nil and
				t_c_indicator[2] ~=nil and t_c_indicator_MA200[2] ~=nil and t_c_price[2] ~=nil and
				t_c_indicator[3] ~=nil and t_c_indicator_MA200[3] ~=nil and t_c_price[3] ~=nil
				)then
				
				local _signal_to_long = false
				_mes = "no signal bars"
				--если текущая цена выше предыдущего хая		
				if (t_c_price[3].high > t_c_price[2].high) then
					local i = 2
					while i >= 0 do			
						--ели нашелся бар который выше		
						if (t_c_price[2].high < t_c_price[i].high and i > 0) then
							_signal_to_long = true
							break
						elseif(t_c_price[2].high <= t_c_price[i].high and i == 0) then
							_signal_to_long = true
							break
						end
						i = i - 1
					end
				end

				local _signal_to_short = false

				--если текущая цена выше предыдущего хая		
				if (t_c_price[3].low < t_c_price[2].low) then
					local i = 2
					while i >= 0 do			
						--ели нашелся бар который выше		
						if (t_c_price[2].low > t_c_price[i].low and i > 0) then
							_signal_to_short = true
							break
						elseif(t_c_price[2].low >= t_c_price[i].low and i == 0) then
							_signal_to_short = true
							break
						end
						i = i - 1
					end
				end

				if (_signal_to_long == true or _signal_to_short == true) then
					private.signal_bars[os.date("%x %X", os.time(t_c_price[3].datetime))] = {signal_long=_signal_to_long, signal_short = _signal_to_short, bar_time=os.time(t_c_price[3].datetime)}
					_mes = "yes signal bar: long - "..tostring(_signal_to_long).."; short - "..tostring(_signal_to_short)

				end

				private.main_writer.WriteToConsole({mes="signal_long", row=2, column=4})
				private.main_writer.WriteToConsole({mes="", row=2, column=5})
				private.main_writer.WriteToConsole({mes="signal_short", row=3, column=4})
				private.main_writer.WriteToConsole({mes="", row=3, column=5})

				private.main_writer.WriteToConsole({mes="bar_in_dict", row=4, column=4})
				for k, v in pairs(private.signal_bars) do
					if (k == os.date("%x %X", os.time(t_c_price[3].datetime))) then
						private.main_writer.WriteToConsole({mes=tostring(v.signal_long), row=2, column=5})
						private.main_writer.WriteToConsole({mes=tostring(v.signal_short), row=3, column=5})
						private.main_writer.WriteToConsole({mes=tostring(true), row=4, column=5})
						_signal_bar = true
					else
						private.main_writer.WriteToConsole({mes=tostring(false), row=4, column=5})
					end
				end


				--возвращаю текущий бар
				_current_bar = t_c_price[3]
				--_current_bar.high = _current_bar.high + 2
				--_current_bar.low = _current_bar.low - 2
				--возвращаем предыдущий бар
				--TODO перевести в шаги цены
				_bar_2 = t_c_price[2]
				_bar_2.high = _bar_2.high + 2
				_bar_2.low = _bar_2.low - 2
				--возвращаем третий бар справа
				_bar_3 = t_c_price[1]
				_bar_3.high = _bar_3.high + 2
				_bar_3.low = _bar_3.low - 2

				_indicator = t_c_indicator[2]
				_indicator_MA200 = t_c_indicator_MA200[2]

				

				--расчет размера предыдущего бара
				local body_2_bar_size = _bar_2.high - _bar_2.low
				local part_of_bar = ((_bar_2.high - _bar_2.low)/2)
				private.delta_for_2_tp_position = 60

				if (body_2_bar_size < 60) then
					--part_of_bar = ((_bar_2.high - _bar_2.low)/4)
					private.delta_for_2_tp_position = 50
				elseif (body_2_bar_size > 120) then
					--part_of_bar = ((_bar_2.high - _bar_2.low)/2)
					private.delta_for_2_tp_position = 100
				end

				private.main_writer.WriteToConsole({mes="up_line_2", row=6, column=6})
				private.main_writer.WriteToConsole({mes=tostring(_bar_2.high - part_of_bar), row=6, column=7})
				private.main_writer.WriteToConsole({mes="down_line", row=7, column=6})
				private.main_writer.WriteToConsole({mes=tostring(_bar_2.low + part_of_bar), row=7, column=7})				

				--логика захода в первую позицию при сигнале
				if (_signal_bar == true) then

					if (
						--если при сигнальном баре и лой и хай предыдущего бара ниже текущего
						(_bar_2.high < _current_bar.high and
						_bar_2.low < _current_bar.low)
						or
						--если при сигнальном баре лой текущего ниже предыдущего, но текущая цена выше хая предыдущего бара
						(_bar_2.high < _last_price and
						_bar_2.low > _current_bar.low )
						) then
						--первый заход в лонг
						--1)проверяю если нет первой позиции создаю ее
						--если нет первой позиции открываю ее
						_signal_for_1_long = true
					elseif (
							--если при сигнальном баре и лой и хай предыдущего бара выше текущего
							(_bar_2.high > _current_bar.high and
							_bar_2.low > _current_bar.low)
							or
							--если при сигнальном баре хай текущего выше предыдущего, но текущая цена ниже лоя предыдущего бара
							(_bar_2.low > _last_price and
							_bar_2.high < _current_bar.high)
							) then
						--первый заход в шорт
						--если нет первой позиции открываю ее
						_signal_for_1_short = true
					end
				end

				if (
					(
						--набор второй позиции посередине предыдущего бара, если хай текущего уже выше предыдущего и лой тоже
						(_bar_2.high < _current_bar.high and _bar_2.low < _current_bar.low)
						or
						--набор второй позиции посередине предыдущего бара, если хай прошлого выше хая позапрошлого и лой прошлого выше лоя позапрошлого и бар не сигнальный
						(_bar_3.high < _bar_2.high and _bar_3.low < _bar_2.low and _signal_bar == false)
					)
					and
					_last_price <= (_bar_2.low + part_of_bar)
					) then
					--если нет первой позиции открываю ее
					_signal_for_2_long = true
				elseif (
						(
							--набор второй позиции посередине предыдущего бара, если хай текущего уже ниже предыдущего и лой тоже
							(_bar_2.high > _current_bar.high and _bar_2.low > _current_bar.low)
							or
							--набор второй позиции посередине предыдущего бара, если хай прошлого ниже хая позапрошлого и лой прошлого ниже лоя позапрошлого и бар не сигнальный
							(_bar_3.high > _bar_2.high and _bar_3.low > _bar_2.low and _signal_bar == false)
						)
						and
						_last_price >= (_bar_2.high - part_of_bar)
						) then
					--если нет первой позиции открываю ее
					_signal_for_2_short = true
				end


				private.main_writer.WriteToConsole({mes="_signal_for_1_long", row=2, column=6})
				private.main_writer.WriteToConsole({mes=tostring(_signal_for_1_long), row=2, column=7})
				private.main_writer.WriteToConsole({mes="_signal_for_2_long", row=3, column=6})
				private.main_writer.WriteToConsole({mes=tostring(_signal_for_2_long), row=3, column=7})
				private.main_writer.WriteToConsole({mes="_signal_for_1_short", row=4, column=6})
				private.main_writer.WriteToConsole({mes=tostring(_signal_for_1_short), row=4, column=7})
				private.main_writer.WriteToConsole({mes="_signal_for_2_short", row=5, column=6})
				private.main_writer.WriteToConsole({mes=tostring(_signal_for_2_short), row=5, column=7})
			else
				_mes = "Last indicator bar is nil"
			end
		end

		return {
				signal_for_1_long = _signal_for_1_long,
				signal_for_1_short = _signal_for_1_short,
				signal_for_2_long = _signal_for_2_long,
				signal_for_2_short = _signal_for_2_short,
				signal_bar = _signal_bar,
				current_bar = _current_bar,
				bar = _bar_2,
				bar_3 = _bar_3,
				indicator = _indicator,
				indicator_MA200 = _indicator_MA200,
				last_price = _last_price,
				mes = _mes,
				id_strategy = private.id_strategy
				}
	end

	function public:set_transaction_manager()
		local trans_manager_is_table = private_func.IsTable({table=self, mes="set_transaction_manager(): "})
		if (trans_manager_is_table.result == false or self.getIdTransactionManager() == nil) then
			return private_func.IsNotValidate({mes="Not success of added transaction manager"})
		end

		private.transaction_manager = self

		return private_func.IsValidate({mes="Success added transaction manager"})
	end

	function public:set_table_manager()
		local table_manager_is_table = private_func.IsTable({table=self, mes="set_table_manager(): "})
		if (table_manager_is_table.result == false or self.getIdTable() == nil) then
			return private_func.IsNotValidate({mes="Not success of added table-startegy manager"})
		end

		private.strategy_table = self
		--message("EEE:" .. tostring(self.getAllocTable()))

		return private_func.IsValidate({mes="Success added table-strategy manager"})
	end

	function public:set_main_writer()
		local main_writer_is_table = private_func.IsTable({table=self, mes="set_main_writer(): "})
		if (main_writer_is_table.result == false or self.getIdWriter() == nil) then
			return private_func.IsNotValidate({mes="Not success of added main_writer manager"})
		end

		private.main_writer = self

		return private_func.IsValidate({mes="Success added main-writer manager"})
	end

	function public:set_visual_table_property()



	end

	function private_func:take_json_position_info()--take name of position by string and find it in json file
		local tab_json = private.main_writer.JsonDecode({file_name = getScriptPath().."\\Positions\\".."all_positions"..".json"})
		local name_pos = self
		local mes = ""

		--в таблице зарегистрированных позиций перебираю и ищу нужную
		for k_p_i, v_p_i in pairs(private.pos_info_table) do
			if k_p_i == name_pos then
				for key, value in pairs(tab_json) do
					for key1, value1 in pairs(value) do
						--в файле ищу нужный узел - который равен названию позиции
						if key1 == name_pos then
							--find name of position
							--mes = mes..key1..":\n"
							local ent_price = 0
							local st_loss = 0
							local t_profit = 0
							local h_line = 0
							local l_line = 0

							for key2, value2 in pairs(value1) do
								--decode all parametrs of position


								if (key2 == "auto_trade") then
								--	v_p_i.set_auto_trade(tostring(value2))
								elseif (key2 == "enter_price") then
									ent_price = tonumber(value2)
									--v_p_i.set_enter_price(tonumber(value2))						
								elseif (key2 == "stop_loss") then
									st_loss = tonumber(value2) or 0
									--v_p_i.set_stop_loss(tonumber(value2))
								elseif (key2 == "take_profit") then
									t_profit = tonumber(value2) or 0
									--v_p_i.set_take_profit(tonumber(value2))
								elseif (key2 == "hight_line_to_take_position") then
									h_line = tonumber(value2) or 0
									--v_p_i.set_hight_line_to_take_position(tonumber(value2))
								elseif (key2 == "low_line_to_take_position") then
									l_line = tonumber(value2) or 0
									--v_p_i.set_low_line_to_take_position(tonumber(value2))
								end	
							end

							--ищу активную позицию
							local is_position_active = false

							for key, value in pairs(private.active_positions) do
								if (key == name_pos) then is_position_active = true end
							end

							if (is_position_active == false) then
							--	if(ent_price ~= 0) then
							--		--если есть цена входа то коридор набора позиции обнуляю и проверяю чтобы тейк, стоп и цена входа соответствовали
							--		if (v_p_i.get_side() == "long") then
							--			if (ent_price > st_loss and ent_price < t_profit) then
							--				v_p_i.set_enter_price(ent_price)
							--				v_p_i.set_stop_loss(st_loss)
							--				v_p_i.set_take_profit(t_profit)
							--				v_p_i.set_hight_line_to_take_position(0)
							--				v_p_i.set_low_line_to_take_position(0)
							--			else
							--				--ошибка пришли неверные данные
							--				message(k_p_i..': enter_price, st_loss or t_profit wrong for long without position.(508)')
							--			end
							--		else
							--			if (ent_price < st_loss and ent_price > t_profit) then
							--				v_p_i.set_enter_price(ent_price)
							--				v_p_i.set_stop_loss(st_loss)
							--				v_p_i.set_take_profit(t_profit)
							--				v_p_i.set_hight_line_to_take_position(0)
							--				v_p_i.set_low_line_to_take_position(0)
							--			else
							--				--ошибка пришли неверные данные
							--				message(k_p_i..': enter_price, st_loss or t_profit wrong for short without position.(519)')
							--			end
							--		end
--
							--	elseif(ent_price == 0 and h_line ~= 0 and l_line ~= 0) then
							--		--если цена входа 0 и есть диапазон цен для набора то цену входа обнуляю и проверяю диапазон на соответствие
							--		if (v_p_i.get_side() == "long") then
							--			if (l_line > st_loss and h_line < t_profit) then										
							--				v_p_i.set_enter_price(0)
							--				v_p_i.set_stop_loss(st_loss)
							--				v_p_i.set_take_profit(t_profit)
							--				v_p_i.set_hight_line_to_take_position(h_line)
							--				v_p_i.set_low_line_to_take_position(l_line)
							--			else
							--				--ошибка пришли неверные данные
							--				message(k_p_i..': h_line, l_line, st_loss or t_profit wrong for long chanel without position.(534)')
							--			end
							--		else
							--			if (h_line < st_loss and l_line > t_profit) then
							--				v_p_i.set_enter_price(0)
							--				v_p_i.set_stop_loss(st_loss)
							--				v_p_i.set_take_profit(t_profit)
							--				v_p_i.set_hight_line_to_take_position(h_line)
							--				v_p_i.set_low_line_to_take_position(l_line)
							--			else
							--				--ошибка пришли неверные данные
							--				message(k_p_i..': h_line, l_line, st_loss or t_profit wrong for short chanel without position.(545)')
							--			end
							--		end
							--	else
							--		--если нет цены входа и диапазон цен неправелен то ошибка
							--		message(k_p_i..': h_line, l_line, ent_price wrong for without position.(550)')
							--	end
							else
								--есть активная позиция - загружаю только тейкпрофиты и стоплоссы не смотря на enter_price и канал
								if (v_p_i.get_side() == "long") then
									if (st_loss < t_profit) then
										v_p_i.set_stop_loss(st_loss)
										v_p_i.set_take_profit(t_profit)
										v_p_i.set_hight_line_to_take_position(0)
										v_p_i.set_low_line_to_take_position(0)
									else
										--ошибка тейк меньше стопа
										message(k_p_i..': st_loss, t_profit wrong for with position.(562)')
									end
								else
									if (st_loss > t_profit) then
										v_p_i.set_stop_loss(st_loss)
										v_p_i.set_take_profit(t_profit)
										v_p_i.set_hight_line_to_take_position(0)
										v_p_i.set_low_line_to_take_position(0)
									else
										--ошибка тейк больше стопа
										message(k_p_i..': st_loss, t_profit wrong for with position.(572)')
									end
								end						
							end
						end
					end
				end
				break
			end
		end
		--message(mes)
	end

	function private_func:create_new_json_file_of_position()
	----читаю файл
	--local ggg = MainWriter.JsonDecode({file_name = getScriptPath().."\\user.json"})
	--
		local fn_pos = getScriptPath().."\\Positions\\".."all_positions"..".json"
		local table_to_write = {positions = {}}

		for k_p_i, v_p_i in pairs(private.pos_info_table) do
			table_to_write["positions"][v_p_i.get_id_position_info()] = {
				name = v_p_i.get_id_position_info(),
				side = v_p_i.get_side(),
				auto_trade = tostring(v_p_i.get_auto_trade()),
				enter_price = tostring(v_p_i.get_enter_price()),
				stop_loss = tostring(v_p_i.get_stop_loss()),
				take_profit = tostring(v_p_i.get_take_profit()),
				hight_line_to_take_position = tostring(v_p_i.get_hight_line_to_take_position()),
				low_line_to_take_position = tostring(v_p_i.get_low_line_to_take_position()),
				row = tostring(v_p_i.get_row())
			}
		end
		--message(file_name)
		private.main_writer.JsonEncode({table = table_to_write, file_name = fn_pos, record_kind = "rewrite"})

	end

	function public:strategy_start()
	--activate strategy
		--if all properties filled is_activate = true
		local _res = private_func.IsNilPropertyOfTable(private)
		private.is_active = _res.result

		--set table property of visualization




		if (_res.result == false) then return _res end

		return _res
	end

	function private_func:fill_startegy_table() --format self{signal_check = table}
		--count open volume in position			
		for k_p_i, v_p_i in pairs(private.pos_info_table) do
			
			local pos = v_p_i.get_id_position_info()
			local target = "S:0;T;0"
			
			for key, value in pairs (private.active_positions) do
				if (key == pos) then
					pos = tostring(value.get_delta_lot_of_position()).."L_1:"..tostring(value.get_enter_price())
					target = "S:"..tostring(value.get_stoploss_price())..";T:"..tostring(value.get_takeprofit_price())
				end
			end

			private.main_writer.WriteToConsole({mes=pos, row=v_p_i.get_row(), column=1})
			private.main_writer.WriteToConsole({mes=target, row=v_p_i.get_row(), column=2})			

			private.main_writer.WriteToConsole({mes=v_p_i.get_side().."; e="..tostring(v_p_i.get_enter_price()) , row = v_p_i.get_row()+1, column=1})
			private.main_writer.WriteToConsole({mes="s="..tostring(v_p_i.get_stop_loss())..";", row=v_p_i.get_row()+1, column=2})
			private.main_writer.WriteToConsole({mes="t_p="..tostring(v_p_i.get_take_profit())..";", row=v_p_i.get_row()+1, column=3})
			private.main_writer.WriteToConsole({mes="ch_low="..tostring(v_p_i.get_low_line_to_take_position()), row=v_p_i.get_row()+1, column=4})
			private.main_writer.WriteToConsole({mes="ch_hi="..tostring(v_p_i.get_hight_line_to_take_position()), row=v_p_i.get_row()+1, column=5})
			private.main_writer.WriteToConsole({mes="auto="..tostring(v_p_i.get_auto_trade()) , row = v_p_i.get_row()+1, column=6})
		end

		--Элементы контрола выставлением цены


		--Info to visual table
		private.main_writer.WriteToConsole({mes="market_side", row=7, column=1})
		private.main_writer.WriteToConsole({mes=self.signal_check.mes, row=7, column=2})
		private.main_writer.WriteToConsole({mes="signal bar", row=8, column=1})
		private.main_writer.WriteToConsole({mes=tostring(self.signal_check.signal_bar), row=8, column=2})

		--------------------------
	end

	function public:open_position_algo() --self - name of position
		for k_p_i, v_p_i in pairs(private.pos_info_table) do
			--если переданое название позиции найдено
			if (k_p_i == self) then
				--Position one take 60steps-----------------------
				local is_position_active = false
				local is_position_anti_side = false
				for key, value in pairs(private.active_positions) do
					if (key == self) then is_position_active = true end
				--	if ((string.lower(value.get_side()) == 'b' and string.lower(v_p_i.get_side()) == "short") or 
				--		(string.lower(value.get_side()) == 's' and string.lower(v_p_i.get_side()) == "long")) then is_position_anti_side = true end
				end

				if (is_position_active == false and is_position_anti_side == false) then
					--if not active long position open it
					private.main_writer.WriteToEndOfFile({mes=self.." by MANUALY position not in active dictionary. Set it."})
					--------------------------------------------
					--в зависимости от направления позиции открываю соответствующую
					if (v_p_i.get_side() == "long") then
						private.active_positions[self] = private_func.create_long_reverse_position()
					else
						private.active_positions[self] = private_func.create_short_reverse_position()
					end
					private.main_writer.WriteToEndOfFile({mes="Create "..self.. "by MANUALY position N: "..tostring(private.active_positions[self].get_id_position()).."\n"})
					private.active_positions[self].ActivatePosition()

					--insert new stop and takeprofit
					if (v_p_i.get_stop_loss() ~= 0 ) then
						private.active_positions[self].make_new_stop(v_p_i.get_stop_loss())
					else
						v_p_i.set_stop_loss(private.active_positions[self].get_stoploss_price())
					end
					if (v_p_i.get_take_profit() ~= 0 ) then
						private.active_positions[self].make_new_take(v_p_i.get_take_profit())
					else
						v_p_i.set_take_profit(private.active_positions[self].get_takeprofit_price())
					end

					--TODO Изменить единицы на шаг инструмента
					--если нужно открыть вторую позицию - то тейк беру по входу первой - чтобы только улучшить вход
					if (self == "long_2") then --and private.active_positions["long_1"] ~= nil
						private.active_positions[self].make_new_take(private.active_positions[self].get_enter_price() + private.delta_for_2_tp_position)--private.active_positions["long_1"].get_enter_price() + 15)
					elseif (self == "short_2") then -- and private.active_positions["short_1"] ~= nil
						private.active_positions[self].make_new_take(private.active_positions[self].get_enter_price() - private.delta_for_2_tp_position)--private.active_positions["short_1"].get_enter_price() - 15)
					end

					if (self == "long_3") then --and private.active_positions["long_1"] ~= nil
						private.active_positions[self].make_new_take(private.active_positions[self].get_enter_price() + private.delta_for_2_tp_position)--private.active_positions["long_1"].get_enter_price() + 15)
					elseif (self == "short_3") then -- and private.active_positions["short_1"] ~= nil
						private.active_positions[self].make_new_take(private.active_positions[self].get_enter_price() - private.delta_for_2_tp_position)--private.active_positions["short_1"].get_enter_price() - 15)
					end

					--записываем вход в позицию в json файл при входе в позицию
					private.pos_info_table[self].set_auto_trade("false")
					private.pos_info_table[self].set_enter_price(private.active_positions[self].get_enter_price())
					private.pos_info_table[self].set_stop_loss(private.active_positions[self].get_stoploss_price())
					private.pos_info_table[self].set_take_profit(private.active_positions[self].get_takeprofit_price())
					private.pos_info_table[self].set_hight_line_to_take_position(0)
					private.pos_info_table[self].set_low_line_to_take_position(0)

					private_func.create_new_json_file_of_position()
					------------------------------------------------------------
					
					private.main_writer.WriteToEndOfFile({mes=self.." by MANUALY Enter price = "..tostring(private.active_positions[self].get_enter_price())..
							"; Stop = "..tostring(private.active_positions[self].get_stoploss_price()).."; "..
							"; Take = "..tostring(private.active_positions[self].get_takeprofit_price())})
					-------------------------------------------
				else
					if (is_position_active == true) then
						message("Can not open "..self..", because it was opened!")
					end
					if (is_position_anti_side == true) then
						message("Can not open "..self..", because there is anti side position! Close it before.")
					end
				end
				break
			end
		end
	end

	function private_func:set_auto_trade() --принимает название позиции
		if (private.active_positions[self] == nil) then
			if (private.pos_info_table[self].get_auto_trade() == false) then
				private.pos_info_table[self].set_auto_trade("true")
			else
				private.pos_info_table[self].set_auto_trade("false")
			end
		else
			message(self.." is active and can`t be auto-trade.")
		end
	end

	function public:check_market()
		local _is_active = private_func.IsActiveStrategy({mes="check_market()"})
		if _is_active.result == false then return _is_active end

		--generate signal bars
		local signal_check = private_func.signal_check()

		if (signal_check == nil or 
			signal_check.bar == nil or
			signal_check.signal_for_1_long == nil or
			signal_check.signal_for_1_short == nil or 
			signal_check.signal_for_2_long == nil or 
			signal_check.signal_for_2_short == nil or 
			signal_check.signal_bar == nil or 
			signal_check.current_bar == nil or 
			signal_check.bar == nil or 
			signal_check.bar_3 == nil or 
			signal_check.indicator == nil or 
			signal_check.indicator_MA200 == nil or 
			signal_check.last_price == nil or
			signal_check.mes == nil or
			signal_check.id_strategy == nil) then
				message("Some field from signal check return nil value! (check_market 892)")
				return {result = false,
				mes = "Some field from signal check return nil value! (check_market 892)",
				id_strategy = private.id_strategy
		}
		end

		local is_anti_market_position = false
		local position_is_changed = false
		local list_to_delete = {}
		--private.main_writer.WriteToEndOfFile({mes="Long side = "..tostring(signal_check.long_side).."; Signal bar = "..tostring(signal_check.signal_bar).."\n"})
		local write_pos_info_to_journal = ''
		for key, value in pairs (private.active_positions) do
			--1)check in dictionary of active position for antimarket position
			local is_table = private_func.IsTable({table=value, mes="check_market()"})
			--private.main_writer.WriteToEndOfFile({mes="Type of VALUE =  "..is_table.mes.."   type = "..tostring(type(value)).."\n"})
			if (is_table.result == true) then
				--if we have position in active dictionary as table
				--private.main_writer.WriteToEndOfFile({mes="We have position in active dictionary ".."\n"})

				--Если позиция открыта или действующая ее нужно убрать из авторежима - так как она уже активна
				for k_p_i, v_p_i in pairs(private.pos_info_table) do
					if (k_p_i == key) then 
						--message("make false")
						v_p_i.set_auto_trade("false") 
					end
				end

				--если позиция стала неактивна по какой-либо причине (например стоплосс, тейкпрофит, вышло время и т.д.)
				if (value.get_is_active() == false) then
					--if position is not active
					--private.main_writer.WriteToEndOfFile({mes="position is not active ".."\n"})
					private.not_active_positions[key..value.get_id_position()] = value
					list_to_delete[key] = key
					write_pos_info_to_journal = write_pos_info_to_journal..value.get_result_of_position()				
				else
					--pass
				end

				--закрываю позицию, если это позиция против рынка
				--если стою в шорт. а цена выше хая предыдущего бара
				if (
						(string.lower(value.get_side()) == 'b' and signal_check.bar.low > signal_check.last_price) or
						(string.lower(value.get_side()) == 's' and signal_check.bar.high < signal_check.last_price)
					) then
						value.turn_off_position()
				end
				
			else
				message("check_market(): ERROR come not table of position!!!\n"..is_table.mes)
				return
			end
		end

		if (write_pos_info_to_journal ~= '') then
			private.main_writer.WriteToEndOfFile({mes=write_pos_info_to_journal, file_name=getScriptPath().."\\Logs\\juornal.txt", with_time=false})
		end

		--clear dictionary of crude if it was moved to executed dictionary
		for key, value in pairs(list_to_delete) do
			--Говорю роботу что позиция изменилась и нужно перезаписать json с позициями
			position_is_changed = true
			--Нужно обнулять все pos_info_... если позиция стала неактивна обнуляю ее и после записывать в json file
			for k_p_i, v_p_i in pairs(private.pos_info_table) do				
				if (k_p_i == key) then		
						
					v_p_i.set_auto_trade("false")
					v_p_i.set_enter_price(0)
					v_p_i.set_stop_loss(0)
					v_p_i.set_take_profit(0)
					v_p_i.set_hight_line_to_take_position(0)
					v_p_i.set_low_line_to_take_position(0)
					--message("key="..key.."; k_p_i="..k_p_i)		
				end
			end
			private.active_positions[value] = nil
			private.main_writer.WriteToEndOfFile({mes="Delete position from active dictionary position: "..tostring(value)})

		end

		--если позиция изменилась, то перезаписываем json с новыми данными
		if (position_is_changed == true) then
			private_func.create_new_json_file_of_position()
		end

		--make new stop, takeprofit
		for key, value in pairs(private.active_positions) do
			--private.main_writer.WriteToEndOfFile({mes="Make new stop: "..tostring(signal_check.indicator.close).."\n"})
			--для покупок стоп лоу предыдущего бара
			if (string.lower(value.get_side()) == 'b') then
				value.make_new_stop(signal_check.bar.low)
			elseif (string.lower(value.get_side()) == 's') then
				value.make_new_stop(signal_check.bar.high)
			end
			for k_p_i, v_p_i in pairs(private.pos_info_table) do
				if(key == k_p_i) then
					value.make_new_take(v_p_i.get_take_profit())
				end
			end
			
		end

		--------------------------------Открытие позиций---------------------------------------
		local is_long_1_active = false
		local is_long_2_active = false	
		local is_short_1_active = false
		local is_short_2_active = false	

		
		for key, value in pairs(private.active_positions) do
			if (key == "long_1") then is_long_1_active = true end
			if (key == "long_2") then is_long_2_active = true end
			if (key == "short_1") then is_short_1_active = true end
			if (key == "short_2") then is_short_2_active = true end
		end

		if (signal_check.signal_for_1_long == true and is_long_1_active == false) then --and is_short_1_active == false and is_short_2_active == false) then
			public.open_position_algo("long_1")				
		elseif (signal_check.signal_for_1_short == true and is_short_1_active == false) then-- and is_long_1_active == false and is_long_2_active == false) then
			--message("position short 1 signal")
			public.open_position_algo("short_1")
		end		

		if (signal_check.signal_for_2_long == true and is_long_2_active == false) then --is_long_1_active == true and 
			public.open_position_algo("long_2")
		elseif (signal_check.signal_for_2_short == true and is_short_2_active == false) then --is_short_1_active == true and
			public.open_position_algo("short_2")
		end	
		---------------------------------------------------------------------------------------
--
		----Открытие позиции руками, если есть позиция в противоположную сторону открыть нельзя в эту
		--if (private.strategy_table.get_open_first_long_position_pressed() == true)then
		--	public.open_position_algo(private.pos_info_table["long_1"].get_id_position_info())			
		--end
--
		--if (private.strategy_table.get_open_second_long_position_pressed() == true)then
		--	public.open_position_algo(private.pos_info_table["long_2"].get_id_position_info())					
		--end
--
		if (private.strategy_table.get_open_third_long_position_pressed() == true)then
			public.open_position_algo(private.pos_info_table["long_3"].get_id_position_info())				
		end
--
		--if (private.strategy_table.get_open_first_short_position_pressed() == true)then
		--	public.open_position_algo(private.pos_info_table["short_1"].get_id_position_info())			
		--end
--
		--if (private.strategy_table.get_open_second_short_position_pressed() == true)then
		--	public.open_position_algo(private.pos_info_table["short_2"].get_id_position_info())				
		--end
--
		if (private.strategy_table.get_open_third_short_position_pressed() == true)then
			public.open_position_algo(private.pos_info_table["short_3"].get_id_position_info())		
		end


		for key, value in pairs(private.active_positions) do

			--проверяю позицию на наличие нажатой клавиши
			if (key == private.pos_info_table["long_1"].get_id_position_info() and private.strategy_table.get_close_first_long_position_pressed() == true)then
				--message("Close first long position")
				--принудительно закрываю позицию
				value.turn_off_position()
			end

			if (key == private.pos_info_table["long_2"].get_id_position_info() and private.strategy_table.get_close_second_long_position_pressed() == true)then
				--message("Close second long position")
				--принудительно закрываю позицию
				value.turn_off_position()
			end

			if (key == private.pos_info_table["long_3"].get_id_position_info() and private.strategy_table.get_close_third_long_position_pressed() == true)then
				--message("Close third long position")
				--принудительно закрываю позицию
				value.turn_off_position()
			end

			if (key == private.pos_info_table["short_1"].get_id_position_info() and private.strategy_table.get_close_first_short_position_pressed() == true)then
				--message("Close first short position")

				--принудительно закрываю позицию
				value.turn_off_position()
			end

			if (key == private.pos_info_table["short_2"].get_id_position_info() and private.strategy_table.get_close_second_short_position_pressed() == true)then
				--message("Close second short position")
				--принудительно закрываю позицию
				value.turn_off_position()
			end

			if (key == private.pos_info_table["short_3"].get_id_position_info() and private.strategy_table.get_close_third_short_position_pressed() == true)then
				--message("Close third short position")
				--принудительно закрываю позицию
				value.turn_off_position()
			end
		end

		if (private.strategy_table.get_load_json_first_long_position_pressed() == true)then			
			private_func.take_json_position_info(private.pos_info_table["long_1"].get_id_position_info())
		end

		if (private.strategy_table.get_auto_first_long_position_pressed() == true)then
			--Если позиция открытая, то нельзя ставить авторежим, так как авторежим должен работать только на открытие позиции
			private_func.set_auto_trade(private.pos_info_table["long_1"].get_id_position_info())
		end
		----------------------------------------------------

		if (private.strategy_table.get_load_json_second_long_position_pressed() == true)then			
			private_func.take_json_position_info(private.pos_info_table["long_2"].get_id_position_info())
		end

		if (private.strategy_table.get_auto_second_long_position_pressed() == true)then			
			private_func.set_auto_trade(private.pos_info_table["long_2"].get_id_position_info())
		end

		----------------------------------------------------

		if (private.strategy_table.get_load_json_third_long_position_pressed() == true)then
			private_func.take_json_position_info(private.pos_info_table["long_3"].get_id_position_info())
		end

		if (private.strategy_table.get_auto_third_long_position_pressed() == true)then
			private_func.set_auto_trade(private.pos_info_table["long_3"].get_id_position_info())	
		end

		---------------------------------------------------------

		if (private.strategy_table.get_load_json_first_short_position_pressed() == true)then			
			private_func.take_json_position_info(private.pos_info_table["short_1"].get_id_position_info())
		end

		if (private.strategy_table.get_auto_first_short_position_pressed() == true)then
			private_func.set_auto_trade(private.pos_info_table["short_1"].get_id_position_info())	
		end

		---------------------------------------------------------

		if (private.strategy_table.get_load_json_second_short_position_pressed() == true)then			
			private_func.take_json_position_info(private.pos_info_table["short_2"].get_id_position_info())
		end

		if (private.strategy_table.get_auto_second_short_position_pressed() == true)then
			private_func.set_auto_trade(private.pos_info_table["short_2"].get_id_position_info())
		end

		---------------------------------------------------------

		if (private.strategy_table.get_load_json_third_short_position_pressed() == true)then			
			private_func.take_json_position_info(private.pos_info_table["short_3"].get_id_position_info())
		end

		if (private.strategy_table.get_auto_third_short_position_pressed() == true)then
			private_func.set_auto_trade(private.pos_info_table["short_3"].get_id_position_info())
		end		

		--клавиша создания json файла
		if (private.strategy_table.get_create_json_file_of_positions_pressed() == true)then
			private_func.create_new_json_file_of_position()
			message("Pressed create new json file of position")
		end		
		
		private.strategy_table.turn_off_open_first_long_position_pressed()
		private.strategy_table.turn_off_close_first_long_position_pressed()
		private.strategy_table.turn_off_load_json_first_long_position_pressed()
		private.strategy_table.turn_off_auto_first_long_position_pressed()
		----------------------------------------------------------------------------
		private.strategy_table.turn_off_open_second_long_position_pressed()
		private.strategy_table.turn_off_close_second_long_position_pressed()
		private.strategy_table.turn_off_load_json_second_long_position_pressed()
		private.strategy_table.turn_off_auto_second_long_position_pressed()
		----------------------------------------------------------------------------
		private.strategy_table.turn_off_open_third_long_position_pressed()
		private.strategy_table.turn_off_close_third_long_position_pressed()
		private.strategy_table.turn_off_load_json_third_long_position_pressed()
		private.strategy_table.turn_off_auto_third_long_position_pressed()
		----------------------------------------------------------------------------
		private.strategy_table.turn_off_open_first_short_position_pressed()
		private.strategy_table.turn_off_close_first_short_position_pressed()
		private.strategy_table.turn_off_load_json_first_short_position_pressed()
		private.strategy_table.turn_off_auto_first_short_position_pressed()
		----------------------------------------------------------------------------
		private.strategy_table.turn_off_open_second_short_position_pressed()
		private.strategy_table.turn_off_close_second_short_position_pressed()
		private.strategy_table.turn_off_load_json_second_short_position_pressed()
		private.strategy_table.turn_off_auto_second_short_position_pressed()
		----------------------------------------------------------------------------
		private.strategy_table.turn_off_open_third_short_position_pressed()
		private.strategy_table.turn_off_close_third_short_position_pressed()
		private.strategy_table.turn_off_load_json_third_short_position_pressed()
		private.strategy_table.turn_off_auto_third_short_position_pressed()				
		----------------------------------------------------------------------------
		private.strategy_table.turn_off_create_json_file_of_positions_pressed()

		--check response of transaction every position and start main loop of position
		for key, value in pairs(private.active_positions) do
			value.full_check_manager({
				crude_dictionary = MainTransManager.getDicCrudeTransactions(),
				executed_dictionary = MainTransManager.getDicExecutedTransactions(),
				crude_dictionary_orders = MainTransManager.getDicCrudeOrders(),
				executed_dictionary_orders = MainTransManager.getDicExecutedOrders(),
				crude_dictionary_deals = MainTransManager.getDicCrudeDeals(),
				executed_dictionary_deals = MainTransManager.getDicExecutedDeals()
			})

			value.main_loop_position()
			--private.main_writer.WriteToEndOfFile({mes="...".."\n"})
		end

		private_func.fill_startegy_table({signal_check = signal_check})

		is_run = private.strategy_table.actionOnTable()

		return {result = true,
				mes = signal_check.mes,
				id_strategy = private.id_strategy
		}

	end


	-----------------------------------------------------------------------
	function public:get_id_strategy()
		return private.id_strategy
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

	function public:get_id_indicator()
		return private.id_indicator
	end

	function public:get_id_indicator_MA200()
		return private.id_indicator_MA200
	end

	function public:get_id_price()
		return private.id_price
	end

	function public:get_market_type()
		return private.market_type
	end

	function public:get_transaction_manager()
		return private.transaction_manager
	end

	function public:get_name_position()
		return private.name_position
	end

	function public:get_active_positions()
		return private.active_positions
	end

	function public:get_not_active_positions()
		return private.not_active_positions
	end

	function public:get_is_active()
		return private.is_active
	end

	function public:take_new_position_manullaly()
		private.take_new_position_manualy = true
	end

	setmetatable(public,self)
    self.__index = self; return public

end