local M = {}
---@param input string
---@param pattern '^([1-9]{2}[0-9])+$' 完整的t93拼音
---             | '^([1-9]{2}[0-9])+`$' 完整的t93拼音+'`'
---@return boolean
M.match = function(input, pattern)
    if pattern == '^([1-9]{2}[0-9])+$' or pattern == '^([1-9]{2}[0-9])+`$' then
        if #input >= 3 then
            while #input >= 3 do
                local ch1 = input:sub(1, 1)
                local ch2 = input:sub(2, 2)
                local ch3 = input:sub(3, 3)
                if (not ch1:match('[1-9]')) or (not ch2:match('[1-9]')) or (not ch3:match('[0-9]')) then
                    return false
                end
                input = input:sub(4)
            end
            if pattern == '^([1-9]{2}[0-9])+$' then
                return #input == 0
            end
            if pattern == '^([1-9]{2}[0-9])+`$' then
                return input == '`'
            end
        end
    end
    return false
end
return M
