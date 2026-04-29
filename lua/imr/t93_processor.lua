---@param _text string
---@return string rest_text
local function ignore_word(_text)
    ---@param text string
    ---@return boolean is_word
    ---@return string rest_text
    local function is_word(text)
        if text:match('^[1-9][0-9][0-9][a-e]') then
            return true, text:sub(5)
        end
        if text:match('^[1-9][0-9][0-9]') then
            return true, text:sub(4)
        end
        return false, text
    end
    local flag, text = true, _text
    while flag do
        flag, text = is_word(text)
    end
    return text
end
local Processor = {
    init = function(env) end,
    func = function(key, env)
        local engine = env.engine
        local context = engine.context
        if
            not key:release()
            and (context:is_composing() or context:has_menu())
        then
            local key_repr = key:repr()
            if key_repr == '0' then
                local text = ignore_word(context.input)
                if text == '' or text == '`' then
                    context:push_input('`')
                    return 1
                end
            end
            if key_repr:match('^[a-e]$') then
                local text = ignore_word(context.input)
                if text:match('^[1-9]$') then
                    context:push_input('00')
                    context:push_input(key_repr)
                    return 1
                end
                if text:match('^[1-9][0-9]$') then
                    context:push_input('0')
                    context:push_input(key_repr)
                    return 1
                end
                if text == '' and context.input:sub(#context.input, #context.input):match('[a-e]') then
                    context:pop_input(1)
                    context:push_input(key_repr)
                    return 1
                end
            end
        end
        return 2
    end
}

return Processor
