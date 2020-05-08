--require('')
--print('commomn')
--local jsn = require("luarocks/dkjson")
----print(os.execute ("cd"))
--local lfs = require("luarocks/lfs")
--local f = debug.getinfo(1).source;
----local g = string.gsub(debug.getinfo(1).t_src, "^(.+\\)[^\\]+$", "%1");
--
--print(f)
--print(package.path)
--print(package.cpath)
--
----print(g)

COUNT_1 = 1

function GetRecurseMesssageHelper(self1, count)
	--function take element, check it type if it is a table
	--call self to recurs
    local _mes = ""
    local _space = ""
    local count = count
    local i = 0
    while i < count do
        _space =_space.."    "
        i=i+1
    end

    if (string.lower(type(self1)) ~= string.lower("table")) then
        _space = _space.."    "
		_mes =_mes.._space..tostring(self1).."\n"
    else
        count = count + 1
        for key, value in pairs(self1) do
            if(key ~= nil and key ~="") then
                _mes = _mes.._space..'"'..tostring(key)..'"'..": "
            end
			if (string.lower(type(value)) ~= string.lower("table")) then
				_mes = _mes..'"'..tostring(value)..'"'..",\n"
            else
                if (count > 1) then
                _mes =_mes.."\n".._space.."    {\n"..GetRecurseMesssageHelper(value, count).._space.."    },\n"
                else
                _mes ="{\n"..GetRecurseMesssageHelper(value, count).._space.."},\n"
                end
			end
		end
    end

    if(string.len(_mes) > 2) then
        _mes = string.sub(_mes, 1, string.len(_mes)-2).."\n"
    end

	return _mes
end

function EncodeJson(self1, count, file_to_write)
	--function take element, check it type if it is a table
	--call self to recurs
    local _mes = ""
    local _space = ""
    local count = count
    local i = 0
    while i < count do
        _space =_space.."    "
        i=i+1
    end

    if (string.lower(type(self1)) ~= string.lower("table")) then
        _space = _space.."    "
		_mes =_mes.._space..tostring(self1).."\n"
    else
        count = count + 1
        for key, value in pairs(self1) do
            if(key ~= nil and key ~="") then
                _mes = _mes.._space..'"'..tostring(key)..'"'..": "
            end
			if (string.lower(type(value)) ~= string.lower("table")) then
				_mes = _mes..'"'..tostring(value)..'"'..",\n"
            else
                if (count > 1) then
                _mes =_mes.."\n".._space.."    {\n"..GetRecurseMesssageHelper(value, count).._space.."    },\n"
                else
                _mes ="{\n"..GetRecurseMesssageHelper(value, count).._space.."},\n"
                end
			end
		end
    end
    
    if(string.len(_mes) > 2) then
        _mes = string.sub(_mes, 1, string.len(_mes)-2).."\n"
    end
    
    local f = io.open(file_to_write, "w+")

    --if (f==nil) then
    --    f = io.open(file_to_write, "w+")
    --end

    if (f~=nil) then
        f:seek("end",0) -- to enter cursor to the end file on index 0, set - begin file, cur - now position
        f:write(_mes)
        f:flush()
        f:close()
    end
end


function json_decode(str, i, count, type_structure)
    --пришла не строка возвращаю нил
    if type(str) ~= 'string' then
        print ('Come not string to str')
        return nil
    end

    if type(count) ~= 'number' then
        print ('Come not number to count')
        return nil
    end

    if type(type_structure) ~= 'string' then
        print ('Come not type_structure to str')
        return nil
    end

    if (type_structure ~= 'dict' and type_structure ~= 'list') then
        print ('Come not type_structure == dict or list')
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
            dict_m[_key], i = json_decode(str, i, string.len(str), "dict")
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
            dict_m[_key], i = json_decode(str, i, string.len(str), "list")
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



local f2 = '{"name":"Ivan","age"\t:"25", "la\fng"\n: [ "english", ,"russian", "bolgarian",], ,"adress" : {"Russia": {"city": "Saratov", "town": "Forse"}, "Bolgria": , "Germany" : "Berlin", "Africa": "Tik-Tock"}}'

-- открываете файл
local f = io.open ( "user.json" ,  "r" );  -- или "rb" если хочется читать в "бинарном" режиме
-- читаете
local test2 = nil
if (f  ~= nil) then
    test2 = f:read( "*a" )
else
    print ("no file")
end

if f~=nil then f:close() end

--f = f.gsub(f, "[%[%]]", "" )
--print (f)
--избавился от лишних спецсимволов
if f~=nil then
    test2 = string.gsub(f2, "[\n\t\b\r\v\f ]", "")
    --
    print (test2)

    local tab = json_decode(test2, 1, string.len(test2), 'dict')

    print(GetRecurseMesssageHelper(tab, 0))
    EncodeJson(tab, 0, "user2.json")
    print(type(tab))
end

