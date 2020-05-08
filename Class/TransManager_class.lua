--class manage transaxtion:
--take it if transaction come from callback function
--put it to dictionary, frome where other objects take it to 
--work
--this object must create ONCE more on starting robot

TransManager = {}
function TransManager:new(transTable)
--data format
--	transTable = {
--				  sIdTransactionManager,				  
--				  sIdStrategy = "",
--				  nSecTimeToKill = 0
--				}
--
--	--have properties: 
--	--identifier of manager transation, __transaction_manager
--	--id_number_transaction, __id_transaction
--	--time of activate of transaction, __activate_time
--	--id strategy,  __id_strategy
--	--state of transaction,  __state_transaction  (active, non_active)
--	--time in seconds for life transaction, __sec_time_to_kill - if time over  
--		manager need to alert robot about it event? becouse it may be fatal error 
--	--dictionary with state of transaction, __dic_states {active="active", 
--											        non_active="nin_active"}
--		
--		private.__dic_executed_transaction = { id_transaction = open_time_transaction }
	
	local private = {}
	local public = {}
	
		private.__id_transaction_manager = transTable.sIdTransactionManager or "default transaction manager"
		private.__id_strategy = transTable.sIdStrategy or "default strategy"
		private.__sec_time_to_kill = transTable.nSecTimeToKill or 15
		
		private.__dic_states ={active="active", non_active="non_active"}
		
		private.__state_trans_manager = private.__dic_states.non_active
		
		private.__dic_executed_transaction = {}  -- consist of table of transaction? what was executed from other clients
		--transaction who come at last iteration
		--must to delete for every itarate from block
		--checkReplyTransaction()
		private.__dic_crude_transactions = {}  -- {table}
				
		private.__dic_executed_orders = {}
		private.__dic_crude_orders = {}
		
		private.__dic_executed_deals = {}
		private.__dic_crude_deals = {}
		
		
	function private:IsActiveManager()
		--data format - string-message if manager is active transcend
		--format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Trans Manager None message" end   
        if (private.__state_trans_manager == private.__dic_states.non_active)then   
            return {result=false,
                    mes=tostring(self.mes)..": Manager not active!",
                    id_manager = tostring(private.__id_transaction_manager)}            
        end 
		
		return {result=true,
            mes=tostring(self.mes)..": Manager is active!",
            id_manager = tostring(private.__id_transaction_manager)}  
    end		
    
	function private:IsTable()
		--data format - data - if table transcend
        --format {table=obj, mes=""}	
        if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Trans Manager None message" end
		if (string.lower(type(self.table)) ~= string.lower("table"))then		    
			return {result=false, 
					mes=tostring(self.mes).." : Manager take not valid data! "..tostring(private.__id_transaction_manager),
					id_manager = tostring(private.__id_transaction_manager)
			        }
		end	
		
		return {result=true,
            mes=tostring(self.mes)..": Is tabe!",
            id_manager = tostring(private.__id_transaction_manager)}  
    end
    
    function private:IsValidate()
    --function return true with message
		--data format - string
		----format {mes=""}
		if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Trans Manager None message" end    
		return {result=true, 
				mes=tostring(self.mes).." "..tostring(private.__id_transaction_manager),
				id_manager = tostring(private.__id_transaction_manager)
			    }
    end
    
    function private:IsNil()
    --check data to nil and if it nil return false with message
    --format {obj=obj, mes=""}
    --if data not nil transcend
        if (self.mes == nil or tostring(self.mes)=="") then self.mes = "Manager Trans None message" end
        if (self.obj == nil)then            
			return {result=false, 
					mes=tostring(self.mes)..". "..tostring(private.__id_transaction_manager),
					id_manager = tostring(private.__id_transaction_manager)
			}
		end
		return {result=true,
            mes=tostring(self.mes)..": is not nil!",
            id_manager = tostring(private.__id_transaction_manager)}  		
    end
    
	function public:putCrudeTransaction()
		--take transaction and write it to crude transaction dictionary
		--format date self = "table" 
        --id transaction on field self.brokerref, self.trans_id
		--id of order on field self.order_num
		local _is_active = private.IsActiveManager({mes="putCrudeTransaction()"})
	    local _is_table = private.IsTable({table=self,mes="putCrudeTransaction()"})
	    
		if _is_active.result == false then return _is_active end
		if _is_table.result == false then return _is_table end
		
		local key_for_table = self.brokerref
		
        local key_for_table_name = private.IsNil({obj=key_for_table, mes="putCrudeTransaction(): self.brokerref = nil"})
		
		if key_for_table_name.result == false then return key_for_table_name end
		--put transaction to crude dictionary
		private.__dic_crude_transactions[tostring(key_for_table)] = self
		
		return private.IsValidate({mes="putCrudeTransaction() Come new transaction from quik. Set it to crude ddictionary."})
		
	end
	
	function private:checkTransactionToDeleteByTime()
	    --={server_time=dt{year,month,day,hour,minuts,seconds}} parametrs
	    --id transaction on field self.brokerref, self.trans_id
		--id of order on field self.order_num
		--status of transaction self.status
		--table of datetime in self table -- self.date_time
	    --function take table from active dictionary data private.__dic_active_transaction
	    --and put it in private.__dic_executed_transaction
	    
		local _is_active = private.IsActiveManager({mes="checkTransactionToDeleteByTime()"})
	    local _is_table = private.IsTable({table=self,mes="checkTransactionToDeleteByTime()"})
		local _is_table_datetime = private.IsTable({table=self.server_time,mes="checkTransactionToDeleteByTime()"})
		
		if _is_active.result == false then return _is_active end
		if _is_table.result == false then return _is_table end
		if _is_table_datetime.result == false then return _is_table end	  
        --private.__dic_crude_transactions[tostring(key_for_table)] = self(table)
        --private.__dic_active_transactions[tostring(key_for_table)] = self(table)
        --check table crude list for transaction, what
        
        --list name of keys to del
        local list_key_to_del = {}
        
        for key, value in pairs(private.__dic_crude_transactions) do
            --Compare date in table of crude dictionary with time now plus sec_time_to_kill
			local _nIdTransaction = tonumber(value.brokerref)
			private.IsNil({obj=_nIdTransaction, mes="checkReplyTransaction(): value.brokerref = nil"})
			local _nReplyStatus = tonumber(value.status)
			private.IsNil({obj=_nReplyStatus, mes="checkReplyTransaction(): value.status = nil"})
			if(os.time(value.date_time) < os.time(self.server_time)-tonumber(private.__sec_time_to_kill))then
                --if true add key of this table to del
                 list_key_to_del[key] = key
            end
        end
        
        --delete old transaction as non querible
        for key, value in pairs(list_key_to_del) do
            private.__dic_crude_transactions[key]=nil
        end
	    
	    return private.IsValidate({mes="checkTransactionToDeleteByTime() Success check"})
	end
		
	function public:putCrudeOrders()
		--take order and write it to crude orders dictionary with self identity
		--format date self = "table" 
        --id order on field self.brokerref, self.trans_id
		--id of order on field self.order_num
		
		local _is_active = private.IsActiveManager({mes="putCrudeOrders()"})
	    local _is_table = private.IsTable({table=self,mes="putCrudeOrders()"})
		
		if _is_active.result == false then return _is_active end
		
		if _is_table.result == false then return _is_table end
	    
		--put order reply to crude dictionary of orders
		private.__dic_crude_orders[tostring(os.time()+math.random(1,10000))] = self
		
		return private.IsValidate({mes="putCrudeOrders() Come new order from quik. Set it to crude dictionary."})		
	end
	
	function private:checkOrdersToDeleteByTime()
	    --{server_time=dt{year,month,day,hour,minuts,seconds}} parametrs
	    --id order on field self.brokerref, self.trans_id
		--id of order on field self.order_num
		--status of transaction self.status
		--table of datetime in self table -- self.date_time
	    --function take table from active dictionary data private.__dic_crude_orders
	    --and put it in private.__dic_executed_deals

		local _is_active = private.IsActiveManager({mes="checkOrdersToDeleteByTime()"})
	    local _is_table = private.IsTable({table=self,mes="checkOrdersToDeleteByTime()"})
		local _is_table_datetime = private.IsTable({table=self.server_time,mes="checkOrdersToDeleteByTime()"})
		
		
		if _is_active.result == false then return _is_active end
		if _is_table.result == false then return _is_table end
	    if _is_table_datetime.result == false then return _is_table end	    	
        --private.__dic_crude_transactions[tostring(os.time())] = self(table)
        --private.__dic_executed_orders[tostring(os.time())] = self(table)
        --check table crude list for transaction, what 
        
        --list name of keys to del
        local list_key_to_del = {}
        
        for key, value in pairs(private.__dic_crude_orders) do
            --Compare date in table of crude dictionary with time now plus sec_time_to_kill
			--message(tostring(os.time(value.datetime)).."<"..tostring(os.time()-tonumber(private.__sec_time_to_kill)).."\n"..tostring(os.time(value.datetime) < os.time()-tonumber(private.__sec_time_to_kill)))
			if(os.time(value.datetime) < os.time(self.server_time)-tonumber(private.__sec_time_to_kill))then
                --if true add key of this table to del  				
                 list_key_to_del[key] = key
            end 
        end
        
        --delete old transaction as non querible
        for key, value in pairs(list_key_to_del) do
            private.__dic_crude_orders[key]=nil
        end
	    
	    return private.IsValidate({mes="checkOrdersToDeleteByTime() Success check"})
	end	

	function public:putCrudeDeals()
		--
		--take order and write it to crude orders dictionary as it is
		--format date self = "table" 
        --id order on field self.brokerref, self.trans_id
		--id of order on field self.order_num

		local _is_active = private.IsActiveManager({mes="putCrudeDeals()"})
	    local _is_table = private.IsTable({table=self,mes="putCrudeDeals()"})
		
		if _is_active.result == false then return _is_active end
		if _is_table.result == false then return _is_table end
	    	    				    
		--put deal reply to crude dictionary of deals if take two double table - replace it
		if (self.tradenum ~= 0) then
			private.__dic_crude_deals[tostring(self.tradenum)] = self
		elseif (self.tradenum == 0 and self.trade_num ~= 0) then
			private.__dic_crude_deals[tostring(self.trade_num)] = self
		end
		
		return private.IsValidate({mes="putCrudeDeals() Come new trade from quik. Set it to crude dictionary."})
	end
	
	function private:checkDealsToDeleteByTime()
		--{server_time=dt{year,month,day,hour,minuts,seconds}} parametrs
	    --function take table from active dictionary data private.__dic_crude_deals
	    --and put it in private.__dic_executed_deals	
		local _is_active = private.IsActiveManager({mes="checkDealsToDeleteByTime()"})
		if _is_active.result == false then return _is_active end
		
		local _is_table_datetime = private.IsTable({table=self.server_time,mes="checkDealsToDeleteByTime()"})
		if _is_table_datetime.result == false then return _is_table end				
		
		--list name of keys to del
        local list_key_to_del = {}
        
        for key, value in pairs(private.__dic_crude_deals) do
            --Compare date in table of crude dictionary with time now plus sec_time_to_kill
			--message(tostring(os.time(value.datetime)).."<"..tostring(os.time()-tonumber(private.__sec_time_to_kill)).."\n"..tostring(os.time(value.datetime) < os.time()-tonumber(private.__sec_time_to_kill)))
			if(os.time(value.datetime) < os.time(self.server_time)-tonumber(private.__sec_time_to_kill))then
                --if true add key of this table to del  				
                 list_key_to_del[key] = key
            end 
        end
        
        --delete old transaction as non querible
        for key, value in pairs(list_key_to_del) do
            private.__dic_crude_deals[key]=nil
        end
		
		return private.IsValidate({mes="checkOrdersToDeleteByTime() Success check"})	
	end
	
	function public:major_checking_for_clean() --format {server_time=_server_time}
		local _is_active = private.IsActiveManager({mes="major_checking_for_clean()"})
		if _is_active.result == false then return _is_active end

		
		local _is_table_datetime = private.IsTable({table=self.server_time,mes="major_checking_for_clean()"})
		if _is_table_datetime.result == false then return _is_table end		
		
		local t = private.checkTransactionToDeleteByTime({server_time=self.server_time})
		local o = private.checkOrdersToDeleteByTime({server_time=self.server_time})
		local d = private.checkDealsToDeleteByTime({server_time=self.server_time})	

		if (t.result == false) then
			return t
		elseif (o.result == false) then
			return o
		elseif (d.result == false) then
			return d
		end
		
		return private.IsValidate({mes="major_checking_for_clean() Success checking dictionaries"})
	end
	
	function public:getDicExecutedDeals()
	--return dictionary executet transaction
		return private.__dic_executed_deals
	end
		
	function public:getDicCrudeDeals()
	--return dictionary crude transaction
		return private.__dic_crude_deals
	end
	
	function public:getDicExecutedOrders()
	--return dictionary executet transaction
		return private.__dic_executed_orders
	end
		
	function public:getDicCrudeOrders()
	--return dictionary crude transaction
		return private.__dic_crude_orders
	end			
	
	function public:getDicExecutedTransactions()
	--return dictionary executet transaction
		return private.__dic_executed_transaction
	end
		
	function public:getDicCrudeTransactions()
	--return dictionary crude transaction
		return private.__dic_crude_transactions
	end		

	function public:activateTransManager()
		--turn on transaction manager
		private.__state_trans_manager = private.__dic_states.active
	end
	
	function public:getStateTransManager()
	--get state name active manager
		return private.__state_trans_manager
	end
	
	function public:isActiveTransManager()
	--get is active? manager
		return private.__state_trans_manager == private.__dic_states.active
	end
	
	function public:getIdTransactionManager()
	--get id transaction manager
		return private.__id_transaction_manager
	end
	
	function public:getIdStrategy()
	--get id strategy of manager
		return private.__id_strategy
	end
	
	function public:getSecTimeToKill()
	--get time to kill non querible transaction
		return private.__sec_time_to_kill
	end

	function public:count_executed_transactions()
		local c = 0
		for key, value in pairs(private.__dic_executed_transaction) do 
			c = c + 1
		end
		return tonumber(c)
	end
	
	function public:count_crude_transactions()
		local c = 0
		for key, value in pairs(private.__dic_crude_transactions) do 
			c = c + 1
		end
		return tonumber(c)
	end
	
	function public:count_executed_orders()
		local c = 0
		for key, value in pairs(private.__dic_executed_orders) do 
			c = c + 1
		end
		return tonumber(c)
	end
	
	function public:count_crude_orders()
		local c = 0
		for key, value in pairs(private.__dic_crude_orders) do 
			c = c + 1
		end
		return tonumber(c)
	end

	function public:count_executed_deals()
		local c = 0
		for key, value in pairs(private.__dic_executed_deals) do 
			c = c + 1
		end
		return tonumber(c)
	end
	
	function public:count_crude_deals()
		local c = 0
		for key, value in pairs(private.__dic_crude_deals) do 
			c = c + 1
		end
		return tonumber(c)
	end	
	
	function public:get_info_dic_trans_manager()
		return 
		"\n----------------------------------------\n"..
		"Info about dictionaries TransManager № '"..tostring(private.id_manager).."':\n"..
		"----------------------------------------"..
		"Crude trans count in manager = "..tostring(public.count_crude_transactions()).."\n"..
		"Executed trans count in transMan = "..tostring(public.count_executed_transactions()).."\n"..
		"Crude orders count in manager = "..tostring(public.count_crude_orders()).."\n"..
		"Executed orders count in transMan = "..tostring(public.count_executed_orders()).."\n"..
		"Crude deals count in manager = "..tostring(public.count_crude_deals()).."\n"..
		"Executed deals count in transMan = "..tostring(public.count_executed_deals()).."\n"..
		"----------------------------------------\n"
	end
		
	setmetatable(public,self)
    self.__index = self; return public
	
end
		
	