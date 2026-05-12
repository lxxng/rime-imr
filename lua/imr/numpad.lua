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
-- 查找下一个
local function lookup_next(db, right_number, en_code)
    local code = right_number:match('[12345689]+[qwert]?')
    local flag = false
    local code_len = #code > 7 and 7 or #code
    while code_len > 0 do
        local number_code = code:sub(1, code_len)
        local en_codes = db:lookup(number_code)
        if en_code == nil or en_code == '' or flag then
            local first_lookup = en_codes:match('[a-z]+[0-4]?')
            if first_lookup ~= nil then
                return first_lookup
            end
        else
            local _, _end = string.find(' ' .. en_codes .. ' ', ' ' .. en_code .. ' ')
            if _end ~= nil then
                local matched = string.match(' ' .. en_codes, '[a-z]+[0-4]?', _end + 1)
                if matched ~= nil then
                    return matched
                end
                flag = true
            end
        end
        -- 最后一个是声调, 额外减一 (只正常减一的是同拼音无声调, 应过滤)
        if number_code:sub(code_len, code_len):match('[qwert]') then
            code_len = code_len - 1
        end
        code_len = code_len - 1
    end
    return nil
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
            if key_repr == 'Tab' or key_repr == 'Shift+Taab' then
                local start = context:get_selected_candidate().start + 1
                local left_input = context.input:sub(1, start - 1)
                local right_input = context.input:sub(start, #context.input)
                local en_code = right_input:match("'([a-z]*[12340]?)'")
                if en_code then
                    local number_code = env.db:lookup(en_code)
                    right_input = number_code .. right_input:sub(#en_code + 3, #right_input)
                end
                local code = lookup_next(env.db, right_input, en_code)
                if code == nil then
                    context.input = left_input .. right_input
                else
                    context.input = left_input
                        .. "'" .. code .. "'"
                        .. right_input:sub(#code + 1, #right_input)
                end

                return 1
            end
        end
        return 2
    end,
}
return {
    Processor = Processor,
}
