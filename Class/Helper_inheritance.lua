function extended (child, parent)
--func help to inherite
    setmetatable(child,{__index = parent})
end