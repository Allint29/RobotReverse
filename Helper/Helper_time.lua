function GetServerTimeTable()
--func convert srting data from server about time to datetime table
	local dt = {};
	dt.day,dt.month,dt.year,dt.hour,dt.min,dt.sec = string.match(getInfoParam('TRADEDATE')..' '..getInfoParam('SERVERTIME'),"(%d*).(%d*).(%d*) (%d*):(%d*):(%d*)")
	for key,value in pairs(dt) do dt[key] = tonumber(value) end
	return dt
end

