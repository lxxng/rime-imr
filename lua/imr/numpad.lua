local Processor = {
    func = function(key, env)
        local engine = env.engine
        local context = env.engine.context
        if
            not key:release()
            and (context:is_composing() or context:has_menu())
        then
            local key_repr = key:repr()
            if key_repr:match('^[qwert]$') then
                -- 输入声调且前面也是声调时, 覆盖前面的声调
                if context.input:sub(context.caret_pos, context.caret_pos):match('[qwert]') then
                    context:pop_input(1)
                    context:push_input(key_repr)
                    return 1
                end
            end
            -- Tab/Shift+Tab选词
            if key_repr == 'Tab' or key_repr == 'Shift+Tab' then
                if context.input:match('`') then
                    local aux_code = context.input:match('`(.*)')
                    -- " aa bb cc dd "
                    local data = context:get_property('pinyin_list')
                    if aux_code == '' then
                        if key_repr == 'Tab' then
                            -- 查第一个
                            -- 空格+非空格开头, 查找" aa", 匹配"aa"
                            local new_code = data:match('^ ([^ ]*)')
                            context:push_input(new_code)
                        end
                        if key_repr == 'Shift+Tab' then
                            -- 查最后一个
                            -- 非空格+空格结尾, 查找"dd ", 匹配"dd"
                            local new_code = data:match('([^ ]*) $')
                            context:push_input(new_code)
                        end
                    else
                        if key_repr == 'Tab' then
                            -- 查后一个
                            -- 空格+上一个+空格+非空格+空格, 查找" aa bb ", 匹配"bb"
                            local new_code = data:match(' ' .. aux_code .. ' ([^ ]*) ')
                            if new_code == nil then
                                -- 如果已经到了结尾, 查第一个
                                new_code = data:match('^ ([^ ]*)')
                            end
                            context:pop_input(#aux_code)
                            context:push_input(new_code)
                        end
                        if key_repr == 'Shift+Tab' then
                            -- 查前一个
                            -- 空格+非空格+空格+上一个+空格, 查找" cc dd ", 匹配"cc"
                            local new_code = data:match(' ([^ ]*) ' .. aux_code .. ' ')
                            if new_code == nil then
                                -- 如果已经到了开头, 查最后一个
                                new_code = data:match(' ([^ ]*) $')
                            end
                            context:pop_input(#aux_code)
                            context:push_input(new_code)
                        end
                    end
                else
                    -- 第一次按Tab/Shift+Tab, 开启选拼音
                    context:set_property('select_pinyin', 'on')
                    context:push_input('`')
                end
                return 1
            end
        end
        return 2
    end,
}
local Filter = {
    init = function(env)
        local config = env.engine.schema.config
        local format = config:get_list('imr_numpad_t9/search_format')
        env.projection = Projection()
        env.projection:load(format)


        env.notifier = env.engine.context.select_notifier:connect(function(ctx)
            local input = ctx.input
            local preedit = ctx:get_preedit()
            local removeAuxInput = input:match('([^,]+)`')
            local reeditTextFront = preedit.text:match('([^,]+)`')
            if not removeAuxInput then
                return
            end
            ctx.input = removeAuxInput
            if reeditTextFront and reeditTextFront:match("[a-z0-9]") then
            else
                ctx:commit()
            end
        end)
    end,
    fini = function(env)
        env.notifier:disconnect()
    end,
    func = function(input, env)
        local context = env.engine.context
        local pinyin_list = ''
        local set = {}
        local flag = context:get_property('select_pinyin') == 'on'
        -- 仅在开启的时候查一次就够了
        context:set_property('select_pinyin', 'off')
        for cand in input:iter() do
            local first_en = cand.comment:match('^[^ ]*') or cand.comment
            local context_input = env.engine.context.input
            local first_formatted = env.projection:apply(first_en, true)
            local aux_code = context_input:match('`(.*)')
            if flag then
                if set[first_formatted] == nil then
                    set[first_formatted] = true
                    pinyin_list = pinyin_list .. ' ' .. first_formatted
                    -- 不能放在最后, 放在最后不执行
                    -- 将pinyin_list存为" aa bb cc dd "的形式
                    context:set_property('pinyin_list', pinyin_list .. ' ')
                end
            end

            if aux_code and #aux_code > 0 then
                if first_formatted:match(aux_code) then
                    yield(cand)
                end
            else
                yield(cand)
            end
        end
    end
}
return {
    Processor = Processor,
    Filter = Filter,
}
