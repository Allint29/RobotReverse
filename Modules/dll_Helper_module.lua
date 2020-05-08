function GetRecurseMesssageHelper(self1)
	--функция принимает элемент, проверяет если эта таблица то запускает саму себя и углубляется
	local _mes = ""		
	if (string.lower(type(self1)) ~= string.lower("table")) then
		_mes = _mes..tostring(self1).."\n"
	else				
		for key, value in pairs(self1) do 
			_mes = _mes..tostring(key)..": "
			if (string.lower(type(value)) ~= string.lower("table")) then					
				_mes = _mes..tostring(value)..",\n"
			else					
				_mes =_mes.."\n{\n"..GetRecurseMesssageHelper(value).."},\n"
			end
		end
	end
	return _mes
end