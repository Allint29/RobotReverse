--Class save information about one position for loading from json
--and use it in other places
PositionInfo = {}
function PositionInfo:new(PositionInfo)
	local private = {}
	local private_func = {}
    local public = {}

    private.id_position_info = tostring(PositionInfo.id_position_info) or "position_1"
    private.side = tostring(PositionInfo.side) or "long"
    private.enter_price = tonumber(PositionInfo.enter_price) or 0
    private.stop_loss = tonumber(PositionInfo.stop_loss) or 0
    private.take_profit = tonumber(PositionInfo.take_profit) or 0
    private.auto_trade = PositionInfo.auto_trade or false
    private.hight_line_to_take_position = tonumber(PositionInfo.hight_line_to_take_position) or 0
    private.low_line_to_take_position = tonumber(PositionInfo.low_line_to_take_position) or 0
    private.row = tonumber(PositionInfo.row) or 0

    function public:set_enter_price()
        local price = tonumber(self) or 0
        private.enter_price = price
	end

    function public:set_stop_loss()
        local price = tonumber(self) or 0
        private.stop_loss = price
	end

    function public:set_take_profit()
        local price = tonumber(self) or 0
        private.take_profit = price
	end

    function public:set_auto_trade()
        local auto = false
        if (string.lower(self) == "true") then
            auto = true
        end
        private.auto_trade = auto
	end

    function public:set_hight_line_to_take_position()
        local price = tonumber(self) or 0
        private.hight_line_to_take_position = price
	end

    function public:set_low_line_to_take_position()
        local price = tonumber(self) or 0
        private.low_line_to_take_position = price
	end

    function public:get_id_position_info()
		return private.id_position_info
	end

    function public:get_side()
		return private.side
	end

    function public:get_enter_price()
		return private.enter_price or 0
	end

    function public:get_stop_loss()
		return private.stop_loss or 0
	end

    function public:get_take_profit()
		return private.take_profit or 0
	end

    function public:get_auto_trade()
		return private.auto_trade
	end
    
    function public:get_hight_line_to_take_position()
		return private.hight_line_to_take_position or 0
	end

    function public:get_low_line_to_take_position()
		return private.low_line_to_take_position or 0
    end

    function public:get_row()
		return private.row or 0
	end
    
    setmetatable(public,self)
    self.__index = self; return public
end