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
                    require('imr.utils.pattern').match(context.input, '^([1-9]{2}[0-9])+$')
                      or
                    require('imr.utils.pattern').match(context.input, '^([1-9]{2}[0-9])+`$')
                then
                    context:push_input('`')
                    return 1
                end
            end
        end
        return 2
    end
}

return Processor
