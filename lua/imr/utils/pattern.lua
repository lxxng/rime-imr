local M = {}
---@param input string
---@param pattern '^([1-9][0-9]{2}[a-e]?)+$' 完整的t93拼音
---             | '^([1-9][0-9]{2}[a-e]?)+`$' 完整的t93拼音+'`'
---@return boolean
---@return string
M.match = function(input, pattern)
    if pattern == '^([1-9][0-9]{2}[a-e]?)+$' or pattern == '^([1-9][0-9]{2}[a-e]?)+`$' then
        if #input >= 3 then
            while #input >= 3 do
                local ch1 = input:sub(1, 1)
                local ch2 = input:sub(2, 2)
                local ch3 = input:sub(3, 3)
                if (not ch1:match('[1-9]')) or (not ch2:match('[0-9]')) or (not ch3:match('[0-9]')) then
                    return false, input
                end
                if #input >= 4 and input:sub(4,4):match('[a-e]') then
                    input = input:sub(5)
                else
                    input = input:sub(4)
                end
            end
            if pattern == '^([1-9][0-9]{2}[a-e]?)+$' then
                return #input == 0, input
            end
            if pattern == '^([1-9][0-9]{2}[a-e]?)+`$' then
                if input == '`' then
                    return true, ''
                else
                    return false, input
                end
            end
        end
    end
    return false, input
end
return M
