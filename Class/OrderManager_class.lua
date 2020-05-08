--class manage orders:
--take it if order come from callback function
--put it to dictionary, frome where other objects take it to 
--work
--this object must create ONCE more on starting robot

OrdersManager = {}
function OrdersManager:new(orderTable)
--data format
--	orderTable = {
--				  sIdOrdersManager,				  
--				  sIdStrategy = "",
--				  nSecTimeToKill = 0
--				}
--

	local private = {}
		private.__id_order_manager = orderTable.sIdOrdersManager or "default orders manager"
		private.__id_strategy = orderTable.sIdStrategy or "default strategy"
		private.__sec_time_to_kill = orderTable.nSecTimeToKill or 15
		
		private.__dic_states ={active="active", non_active="non_active"}
		
		private.__state_orders_manager = private.__dic_states.non_active
		
		private.__dic_executed_orders = {}  -- consist of table of transaction? what was executed from other clients
		--transaction who come at last iteration
		--must to delete for every itarate from block
		--checkReplyTransaction()
		private.__dic_crude_orders = {}  -- {table}
		private.__number_order = 1
		
				
	function private:IsActiveManager()
		--data format - string-message if manager is active transcend
		--format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "None message" end   
        if (private.__state_orders_manager == private.__dic_states.non_active)then   
            return {result=false,
                    mes=tostring(self.mes)..": Manager Order not active!",
                    id_manager = tostring(private.__id_order_manager)}            
        end 
    end		
    
	function private:IsTable()
		--data format - data - if table transcend
        --format {table=obj, mes=""}	
        if (self.mes == nil or tostring(self.mes)=="") then self.mes = "None message" end
		if (string.lower(type(self.table)) ~= string.lower("table"))then		    
			return {result=false, 
					mes=tostring(self.mes).." : Manager Orders take not valid data! "..tostring(private.__id_order_manager),
					id_manager = tostring(private.__id_order_manager)
			        }
		end	
    end
    
    function private:IsValidate()
    --function return true with message
		--data format - string
		----format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Manager Orders None message" end    
		return {result=true, 
				mes=tostring(self.mes).." "..tostring(private.__id_order_manager),
				id_manager = tostring(private.__id_order_manager)
			    }
    end
    
    function private:IsNil()
    --check data to nil and if it nil return false with message
    --format {obj=obj, mes=""}
    --if data not nil transcend
        if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Order Manager None message" end
        if (self.obj == nil)then            
			return {result=false, 
					mes=tostring(self.mes)..". "..tostring(private.__id_order_manager),
					id_manager = tostring(private.__id_order_manager)
			}
		end
    end		
	
	local public = {}
	
	function public:putCrudeOrders()
		--take order and write it to crude orders dictionary with self identity
		--format date self = "table" 
        --id order on field self.brokerref, self.trans_id
		--id of order on field self.order_num
		
		private.IsActiveManager({mes="putCrudeOrders()"})
	    private.IsTable({table=self,mes="putCrudeOrders()"})
	    
		--put order reply to crude dictionary of orders
		private.__dic_crude_orders[tostring(os.time())] = self
		private.IsValidate({mes="putCrudeOrders() Come new order from quik. Set it to crude dictionary."})		
	end
	

	function public:checkOrdersToDeleteByTime()
	    --none parametrs
	    --id order on field self.brokerref, self.trans_id
		--id of order on field self.order_num
		--status of transaction self.status
		--table of datetime in self table -- self.date_time
	    --function take table from active dictionary data private.__dic_crude_orders
	    --and put it in private.__dic_executed_transaction
	    
	    private.IsActiveManager({mes="checkOrdersToDeleteByTime()"})
	    private.IsTable({mes="checkOrdersToDeleteByTime()"})
	    	    	
        --private.__dic_crude_transactions[tostring(os.time())] = self(table)
        --private.__dic_executed_orders[tostring(os.time())] = self(table)
        --check table crude list for transaction, what 
        
        --list name of keys to del
        local list_key_to_del = {}
        
        for key, value in pairs(private.__dic_crude_orders) do
            --Compare date in table of crude dictionary with time now plus sec_time_to_kill
			local _nIdOrder = tonumber(value.brokerref)
			private.IsNil({obj=_nIdOrder, mes="checkOrdersToDeleteByTime(): value.brokerref = nil"})
			if(os.time(value.datetime) < os.time()-tonumber(private.__sec_time_to_kill))then
                --if true add key of this table to del  
                 list_key_to_del[key] = key				 
            end
        end
        
        --delete old transaction as non querible
        for key, value in pairs(list_key_to_del) do
            private.__dic_crude_orders[key]=nil
        end
	    
	    private.IsValidate({mes="checkOrdersToDeleteByTime() Success check"})
	end	
	
	
		
	function public:getDicExecutedOrders()
	--return dictionary executet transaction
		return private.__dic_executed_orders
	end
		
	function public:getDicCrudeOrders()
	--return dictionary crude transaction
		return private.__dic_crude_orders
	end		

	function public:activateOrdersManager()
		--turn on transaction manager
		private.__state_orders_manager = private.__dic_states.active
	end
	
	function public:getStateOrdersManager()
	--get state name active manager
		return private.__state_orders_manager
	end
	
	function public:isActiveOrdersManager()
	--get is active? manager
		return private.__state_orders_manager == private.__dic_states.active
	end
	
	function public:getIdOrdersManager()
	--get id transaction manager
		return private.__id_order_manager
	end
	
	function public:getIdStrategy()
	--get id strategy of manager
		return private.__id_strategy
	end
	
	function public:getSecTimeToKill()
	--get time to kill non querible transaction
		return private.__sec_time_to_kill
	end
	
	
	
	
		
	setmetatable(public,self)
    self.__index = self; return public
	
end