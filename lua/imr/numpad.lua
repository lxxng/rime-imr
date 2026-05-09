local function to_string(x, seen)
    seen = seen or {} -- 用于检测循环引用
    local t = type(x)

    if t == "nil" then
        return "nil"
    elseif t == "boolean" then
        return x and "true" or "false"
    elseif t == "number" then
        return tostring(x)
    elseif t == "string" then
        return string.format("%q", x) -- 加双引号并转义内部字符
    elseif t == "table" then
        if seen[x] then
            return "<循环引用>"
        end
        seen[x] = true
        local parts = {}
        for k, v in pairs(x) do
            -- 键的表示：字符串加引号，其他直接 tostring
            local key_str = (type(k) == "string") and string.format("%q", k) or tostring(k)
            local val_str = to_string(v, seen)
            table.insert(parts, key_str .. " = " .. val_str)
        end
        seen[x] = nil -- 清理，避免影响同级其他分支（可选）
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        -- function, thread, userdata 等类型
        return "<" .. t .. ": " .. tostring(x) .. ">"
    end
end
local Processor = {
    init = function(env)
        env.db = ReverseLookup('imr_numpad_t9_reverse_pinyin')
    end,
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
                    -- " aa bb cc dd "
                    local data = context:get_property('pinyin_list')

                    local aux_code = context.input:match('`(.*)')
                    local new_code = ''

                    -- local input = context.input:match('[^123456789qwert` ]([123456789qwert` ]*)')
                    -- local left = input:match('(.*)`.*'):gsub(' ', '')
                    -- todo: 34664`zi 

                    if aux_code == '' then
                        if key_repr == 'Tab' then
                            -- 查第一个
                            -- 空格+非空格开头, 查找" aa", 匹配"aa"
                            new_code = data:match('^ ([^ ]*)')
                        end
                        if key_repr == 'Shift+Tab' then
                            -- 查最后一个
                            -- 非空格+空格结尾, 查找"dd ", 匹配"dd"
                            new_code = data:match('([^ ]*) $')
                        end
                    else
                        if key_repr == 'Tab' then
                            -- 查后一个
                            -- 空格+上一个+空格+非空格+空格, 查找" aa bb ", 匹配"bb"
                            new_code = data:match(' ' .. aux_code .. ' ([^ ]*) ')
                            if new_code == nil then
                                -- 如果已经到了结尾, 查第一个
                                new_code = data:match('^ ([^ ]*)')
                            end
                            context:pop_input(#aux_code)
                        end
                        if key_repr == 'Shift+Tab' then
                            -- 查前一个
                            -- 空格+非空格+空格+上一个+空格, 查找" cc dd ", 匹配"cc"
                            new_code = data:match(' ([^ ]*) ' .. aux_code .. ' ')
                            if new_code == nil then
                                -- 如果已经到了开头, 查最后一个
                                new_code = data:match(' ([^ ]*) $')
                            end
                            context:pop_input(#aux_code)
                        end
                    end
                    context:push_input(new_code)
                else
                    -- 第一次按Tab/Shift+Tab, 开启选拼音
                    local code = context:get_preedit().text
                        :gsub(' ', '')
                        :match('[^12345689]*([12345689]*)')
                    local pinyin_list = ''
                    for len = 6, 1, -1 do
                        if #code >= len then
                            local result = env.db:lookup(code:sub(1, len))
                            if #result > 0 then
                                pinyin_list = pinyin_list .. ' ' .. result
                            end
                        end
                    end
                    pinyin_list = pinyin_list .. ' '
                    context:set_property('pinyin_list', pinyin_list)
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
        local context_input = env.engine.context.input
        local aux_code = context_input:match('`(.*)')
        for cand in input:iter() do
            local first_en = cand.comment:match('^[^ ]*') or cand.comment
            local first_formatted = env.projection:apply(first_en, true)
            if aux_code and #aux_code > 0 then
                if first_formatted == aux_code then
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
