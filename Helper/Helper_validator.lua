function IsTable()
	--data format - data - if table transcend
    --format {table=obj, mes=""}	
    if (self.mes == nil or tostring(self.mes)=="") then self.mes = "None message" end
	if (string.lower(type(self.table)) ~= string.lower("table"))then		    
		return {result=false, 
				mes=tostring(self.mes).." : Manager take not valid data! "..tostring(private.__id_transaction_manager),
				id_manager = tostring(private.__id_transaction_manager)
			    }
	end	
end
    
function IsValidate()
    --function return true with message
	--data format - string
	----format {mes=""}
	if (self.mes == nil or tostring(self.mes)=="") then self.mes = "None message" end    
	return {result=true, 
			mes=tostring(self).." "..tostring(private.__id_transaction_manager),
			id_manager = tostring(private.__id_transaction_manager)
			}
end
    
function IsNil()
--check data to nil and if it nil return false with message
--format {obj=obj, mes=""}
--if data not nil transcend
    if (self.mes == nil or tostring(self.mes)=="") then self.mes = "None message" end
    if (self.obj == nil)then            
	    return {result=false, 
			    mes=tostring(self.mes)..". "..tostring(private.__id_transaction_manager),
				id_manager = tostring(private.__id_transaction_manager)
			    }
	end
end