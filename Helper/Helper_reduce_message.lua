function GetRecurseMesssageHelper(self1)
	--function take element, check it type if it is a table
	--call self to recurs
	local _mes = "New Message: \n"		
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