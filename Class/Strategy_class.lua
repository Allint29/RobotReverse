--Class of strategy. It search signal of indicators
--and create and deactivate positions
--it have dictionary of active position and dictionary of deactivated positions
--it have a triger of on/off strategy
--format of data positionTable = {
--								  id_strategy = "name" string
--								  id_indicator = "name_indicator" string
--								  id_price = "name_price" string
--								  market_type = "reverse", string may be "long","short", "reverse"
--								{


Startegy = {}
function Startegy:new(strategyTable)
	local private = {}
	local private_func = {}
	local public = {}

	private.id_strategy = tostring(strategyTable.id_strategy) or "default_parabolic_strategy"
	private.id_indicator = tostring(strategyTable.id_indicator) or ""
	private.id_price = tostring(strategyTable.id_price) or ""
	private.market_type = "reverse" -- may be "long","short", "reverse"

	private.number_position = 1
	private.name_position = tostring(private.number_position).."_"..private.id_strategy
	private.active_positions = {}
	private.not_active_position = {}

	--property to on/off strategy - activate in method of activation
	private.is_active = false

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
	-----------------------------------------------------------------------



	-----------------------------------------------------------------------
	function public:get_id_strategy()
		return private.id_strategy
	end
	function public:get_id_indicator()
		return private.id_indicator
	end
	function public:get_id_price()
		return private.id_price
	end
	function public:get_market_type()
		return private.market_type
	end
	function public:get_number_position()
		return private.number_position
	end
	function public:get_name_position()
		return private.name_position
	end
	function public:get_active_positions()
		return private.active_positions
	end
	function public:get_not_active_position()
		return private.not_active_position
	end
	function public:get_is_active()
		return private.is_active
	end

	setmetatable(public,self)
    self.__index = self; return public

end