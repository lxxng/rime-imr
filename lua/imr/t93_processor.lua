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
                if
                    require('imr.utils.pattern').match(context.input, '^([1-9][0-9]{2}[a-e]?)+$')
                      or
                    require('imr.utils.pattern').match(context.input, '^([1-9][0-9]{2}[a-e]?)+`$')
                then
                    context:push_input('`')
                    return 1
                end
            end
            if key_repr == 'a' or key_repr == 'b' or key_repr == 'c' or key_repr == 'd' or key_repr == 'e' then
                local flag, rest_text = require('imr.utils.pattern').match(context.input, '^([1-9][0-9]{2}[a-e]?)+$')
                if not flag then
                    flag, rest_text = require('imr.utils.pattern').match(context.input, '^([1-9][0-9]{2}[a-e]?)+`$')
                    if rest_text:match('^[1-9]$') then
                        context:push_input('00' .. key_repr)
                        return 1
                    end
                    if rest_text:match('^[1-9][0-9]$') then
                        context:push_input('0' .. key_repr)
                        return 1
                    end
                end
            end
        end
        return 2
    end
}

return Processor
