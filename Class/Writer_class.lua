--Class writer to file, message


WriterRobot = {}
function WriterRobot:new(sIdWriter, sName, sLogFileName, IdTradeTable)
---
--idTradeTable - id of table to show message for client  D:\QUIK_OpenBroker\Lua_Script\RobotHandDirect\Class\json4lua-master\json
	local private = {}
		private.idWriter = sIdTable or "MainWriter"
		private.name = sName or "MainLogger"
		private.logFileName = getScriptPath().."\\Logs\\"..tostring(sLogFileName) or getScriptPath().."\\Logs\\mainLog.txt"
		private.messages = {}
		private.idTradeTable = IdTradeTable or nil

	function private:is_validate()
	--function return true with message
		--data format - string
		----format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Writer None message" end
		return {result=true,
				mes=tostring(self.mes).." "..tostring(private.idWriter),
				id_writer = tostring(private.idWriter)
				}
	end

	function private:is_table()
		--data format - data - if table transcend
        --format {table=obj, mes=""}
        if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Writer None message" end
		if (string.lower(type(self.table)) ~= string.lower("table"))then
			return {result=false,
					mes=tostring(self.mes).." : Writer take not valid data! "..tostring(private.idWriter),
					id_writer = tostring(private.idWriter)
			        }
		end
		return private.is_validate({mes="Success check as table"})
    end

    function private:is_nil()
    --check data to nil and if it nil return false with message
    --format {obj=obj, mes=""}
    --if data not nil transcend
        if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Writer None message" end
        if (self.obj == nil)then
			return {result=false,
					mes=tostring(self.mes)..". "..tostring(private.idWriter),
					id_writer = tostring(private.idWriter)
			}
		end
		return private.is_validate({mes="Success check as table"})
    end

    local public = {}

    function public:getIdWriter()
        return private.idWriter
    end

    function public:getName()
        return private.name
    end

    function public:getLogFileName()
        return private.logFileName
    end

	function public:WriteToConsole()
		-- write to console (trade table)
		-- take table key-value ({mes="", column=6, row=2, red=0-255,green=0-255, blue=0-255 })

        private.is_nil({obj=self, mes="Writer.WriteToConsole(): self = nil"})
		private.is_nil({obj=self.mes, mes="Writer.WriteToConsole(): self.mes = nil"})
		private.is_table({table=self,mes="Writer.WriteToConsole(): Need to give data if format: ({mes='', row=2, column=6}) to fill cells"})
		

		if (self.row == nil or self.column == nil)then
		--if tables sells is nil then show message
			message(tostring(self.mes), 1)
		else
			local red = 0
			local green = 0
			local blue = 0

			if (self.row%2==0) then
				red = self.red or 220
				green = self.green or 220
				blue = self.blue or 220
			else
				red = self.red or 250
				green = self.green or 250
				blue = self.blue or 250
			end			

		    private.is_nil({obj=private.idTradeTable, mes="Writer.WriteToConsole(): private.idTradeTable = nil"})
			SetCell(private.idTradeTable.getAllocTable(), self.row, self.column, tostring(self.mes))
			SetColor(private.idTradeTable.getAllocTable(), self.row, self.column, RGB(red,green,blue), RGB(0,0,0), RGB(220,100,220), RGB(0,0,0))
		end
	end

	function public:WriteToEndOfFile()
		-- write to console (trade table)
		-- take table key-value ({mes=""}) or ({mes="", file_name = "", with_time = true})
        private.is_nil({obj=self, mes="Writer.WriteToEndOfFile(): self = nil"})
		private.is_nil({obj=self.mes, mes="Writer.WriteToEndOfFile(): self.mes = nil"})
		private.is_table({table=self,mes="Writer.WriteToEndOfFile(): Need to give data if format: ({mes=''}) to fill cells"})

        local _mes = tostring(self.mes)

		local serverTime_ = getInfoParam("SERVERTIME")
		local serverDate_ = getInfoParam("TRADEDATE")		
		local sFile = self.file_name or private.logFileName
		local sDataString = serverDate_.."  "..serverTime_..": ___ ".._mes..";".."\n"
		local sWithTime = self.with_time or true

		local f = io.open(sFile, "r+")

		if (f==nil) then
			f = io.open(sFile, "w")
		end

		if (f~=nil) then
			f:seek("end",0) -- to enter cursor to the end file on index 0, set - begin file, cur - now position
			if (sWithTime == true) then
				f:write(sDataString)
			end
			f:flush()
			f:close()
		end
	end

	--- Check if a file or directory exists in this path
	function private:exists()
		local ok, err, code = os.rename(self, self)
		if not ok then
			if code == 13 then
			-- Permission denied, but it exists
			return true
			end
			return false
		end
		return ok, err
	end

	--функция записывает таблицу в файл в формате json только словари
	--(все списки переделывает в словари)
	function public:JsonEncode() --format {table = table, file_name = string, record_kind = ("append" или "rewrite")}

		local is_main_table = private.is_table({table=self, mes = "JsonEncode(): not support format. Recomends: format {table = table, file_name = string, record_kind = ('append' или 'rewrite')"})
		local is_nil_table = private.is_nil({obj=self.table ,mes="JsonEncode(): not come table in field '{table = nil}'"})
		local is_file_name = private.is_nil({obj=self.file_name ,mes="JsonEncode(): not come table in field '{file_name = nil}'"})
		local is_record_kind = private.is_nil({obj=self.record_kind ,mes="JsonEncode(): not come table in field '{record_kind = nil}'"})

		if is_main_table.result == false then return is_main_table end
		if is_nil_table.result == false then return is_nil_table end
		if is_file_name.result == false then return is_file_name end
		if is_record_kind.result == false then return is_record_kind end


		if type(self.file_name) ~= "string" then
			message ('JsonEncode(): Come not string to file_name')
			return {result=false,
				mes="JsonEncode(): ".."Come not string to file_name in "..tostring(private.idWriter),
				id_writer = tostring(private.idWriter)
			    }

		end

		if type(self.record_kind) ~= "string" or (self.record_kind ~= "append" and self.record_kind ~= "rewrite" ) then
			message ('JsonEncode(): Come not string to record_kind or or \n(record_kind ~= "append" and record_kind ~= "rewrite" )')
			return {result=false,
				mes='JsonEncode(): Come not string to record_kind or or \n(record_kind ~= "append" and record_kind ~= "rewrite" ) in '..tostring(private.idWriter),
				id_writer = tostring(private.idWriter)
				}
		end
		
		--запускаю запись в файл таблицы
		local json_content = public.table_to_json({table = self.table, count = 0})

		
		local f
		if self.record_kind == 'rewrite' then
			f = io.open(self.file_name, "w+")
		else
			f = io.open(self.file_name, "r+")

			if (f==nil) then
				f = io.open(self.file_name, "w")
			end
		end

		if (f~=nil) then
			f:seek("end",0) -- to enter cursor to the end file on index 0, set - begin file, cur - now position
			f:write(json_content)
			f:flush()
			f:close()
		end
		return private.is_validate({mes="Success write to the file json"..self.file_name})
	end

	function public:table_to_json() -- формат (table = table, count = 0})
		--function take element, check it type if it is a table
		--call self to recurs
		local _mes = ""
		local _space = ""
		local count = self.count
		local i = 0
		while i < count do
			_space =_space.."    "
			i=i+1
		end

		if (string.lower(type(self.table)) ~= string.lower("table")) then
			_space = _space.."    "
			_mes =_mes.._space..tostring(self.table).."\n"
		else
			count = count + 1
			for key, value in pairs(self.table) do
				if(key ~= nil and key ~="") then
					_mes = _mes.._space..'"'..tostring(key)..'"'..": "
				end
				if (string.lower(type(value)) ~= string.lower("table")) then
					_mes = _mes..'"'..tostring(value)..'"'..",\n"
				else
					if (count > 1) then
					_mes =_mes.."\n".._space.."    {\n"..public.table_to_json({table = value, count = count}).._space.."    },\n"
					else
					_mes ="{\n"..public.table_to_json({table = value, count = count}).._space.."},\n"
					end
				end
			end
		end

		if(string.len(_mes) > 2) then
			_mes = string.sub(_mes, 1, string.len(_mes)-2).."\n"
		end
		
		return _mes
	end

	--метод принимает имя фала json для декодирования в словарь словарей
	function public:JsonDecode() --format {file_name = string}

		local is_main_table = private.is_table({table=self, mes = "JsonDecode(): not support format. Recomends: format {file_name = string}"})
		local is_file_name = private.is_nil({obj=self.file_name ,mes="JsonDecode(): not come table in field '{file_name = nil}'"})

		if is_main_table.result == false then return is_main_table end
		if is_file_name.result == false then return is_file_name end

		if type(self.file_name) ~= "string" then
			message ('JsonDecode(): Come not string to file_name')
			return {result=false,
				mes="JsonDecode(): ".."Come not string to file_name in n227 "..tostring(private.idWriter),
				id_writer = tostring(private.idWriter)
			    }
		end
		message(self.file_name)
		local file = io.open(self.file_name, "r");  -- или "rb" если хочется читать в "бинарном" режиме

		if(file == nil) then

			message("Writer: "..tostring(private.name)..": No json file id directory.")
			return {result=false,
				mes="JsonDecode(): ".."File of json is nil n238 "..tostring(private.idWriter),
				id_writer = tostring(private.idWriter)
			    }
		end

		local text_json = file:read( "*a" )

		if (file~=nil) then file:close() end

		text_json = string.gsub(text_json, "[\n\t\b\r\v\f ]", "")

		return private.json_decode({str = text_json, i=1, count = string.len(text_json), type_structure = 'dict'})
	end

	function private:json_decode() --формат {str = string_json, i=1, count=lenth, type_structure='dict'}
	   --пришла не строка возвращаю нил
	   local str = self.str
	   local i = self.i
	   local count = self.count
	   local type_structure = self.type_structure

		if type(str) ~= 'string' then
	        message ('json_decode258: Come not string to str')
	        return nil
	    end

	    if type(count) ~= 'number' then
	        message ('json_decode263: Come not number to count')
	        return nil
	    end

	    if type(type_structure) ~= 'string' then
	        message ('json_decode268: Come not type_structure to str')
	        return nil
	    end

	    if (type_structure ~= 'dict' and type_structure ~= 'list') then
	        message ('json_decode273: Come not type_structure == dict or list')
	        return nil
	    end

	    local dict_m = {}

	    local i = i
	    local _key = ""
	    local _key_for_list = 1
	    local _list = {}
	    local _value = ""
	    local now_value = false

	    --номер ковычек = открывающий или закр
	    local num_bracket = 1

	    while i <= count do
	        local _char = string.sub(str, i, i)
	        i = i + 1

	        if _char == '{' then
	            --str = str.gsub(str, "{", "", 1)
	            dict_m[_key], i = private.json_decode({str=str, i=i, count = string.len(str), type_structure = "dict"})
	        elseif _char == '"' then
	            --если попалась скабка то в зависимости от того какая это скобка по номеру принимаем решение открывающая или закрывающая
	                --str = str.gsub(str, '"', '', 1)
	                --num_bracket = num_bracket + 1
	        elseif _char == ':' then
	            --str = str.gsub(str, ':', '', 1)
	            now_value = true
	        elseif _char == '[' then
	            --str = str.gsub(str, '%[', '', 1)
	            --Если пришел другой символ пишем его либо
	            dict_m[_key], i = private.json_decode({str=str, i=i, count = string.len(str), type_structure = "list"})
	        elseif _char == ']' then
	            --str = str.gsub(str, '%]', '', 1)
	            if(_value ~= nil and _value ~= '') then
	                if type_structure == 'dict' then
	                    dict_m[_key] = _value
	                elseif type_structure == 'list' then
	                    dict_m[tostring(_key_for_list)] = _value
	                end
	            else
	                if (i > 1) then
	                    local prev_simb = string.sub(str, i-2, i-2)

	                    if type_structure == 'list' then
	                        if (prev_simb == '[') then
	                            --пустой список
	                        elseif (prev_simb == ',') then
	                            --текущий элемент пуст
	                            --dict_m[tostring(_key_for_list)] = "nil"
	                        end
	                    end
	                end
	            end

	            return dict_m, i--string.len(str)
	        elseif _char == '}' then
	            --str = str.gsub(str, '%}', '', 1)
	            if(_value ~= nil and _value ~= '') then
	                if type_structure == 'dict' then
	                    dict_m[_key] = _value
	                elseif type_structure == 'list' then
	                    dict_m[tostring(_key_for_list)] = _value
	                end

	            else
	                if (i > 1) then
	                    local prev_simb = string.sub(str, i-2, i-2)

	                    if type_structure == 'dict' then
	                        if (prev_simb == '{') then
	                            --пустой словарь
	                        elseif (prev_simb == ',' or prev_simb == ':') then
	                            --текущий элемент пуст
	                            --dict_m[_key] = "nil"
	                        end
	                    end
	                end
	            end
	            return dict_m, i-- string.len(str)
	        elseif _char == ',' then
	            if(_value ~= nil and _value ~= '') then
	                if type_structure == 'dict' then
	                    dict_m[_key] = _value
	                elseif type_structure == 'list' then
	                    dict_m[tostring(_key_for_list)] = _value
	                    _key_for_list = _key_for_list + 1
	                end
	            else
	                if (i > 1) then
	                    local prev_simb = string.sub(str, i-2, i-2)

	                    if type_structure == 'list' then
	                        if (prev_simb == '[') then
	                            --пустой список
	                        elseif (prev_simb == ',') then
	                            --текущий элемент пуст
	                           -- dict_m[tostring(_key_for_list)] = "nil"
	                        end
	                    elseif type_structure == 'dict' then
	                        if (prev_simb == '{') then
	                            --пустой словарь
	                        elseif (prev_simb == ',' or prev_simb == ':') then
	                            --текущий элемент пуст
	                            --dict_m[_key] = "nil"
	                        end
	                    end
	                end
	            end
	            _key = ""
	            _value = ""
	            now_value = false
	        else
	            if type_structure == 'list' then
	                if num_bracket == 1 then
	                    --если скобка открывающая
	                    _value = _value..tostring(_char)
	                elseif num_bracket == 2 then
	                    num_bracket = 1
	                end

	            elseif type_structure == 'dict' then
	                if num_bracket == 1 then
	                    if now_value == false then
	                        _key = _key..tostring(_char)
	                    else
	                        _value = _value..tostring(_char)
	                    end
	                elseif num_bracket == 2 then
	                    num_bracket = 1
	                end
	            end
	        end
	    end

	    return dict_m
	end

	--- Check if a directory exists in this path
	function private:isdir()
		-- "/" works on both Unix and Windows
		_path = private.exists(self.."/")
		if (_path == true)then
			return true
		end
		return false
	end

	setmetatable(public,self)
    self.__index = self; return public
end

