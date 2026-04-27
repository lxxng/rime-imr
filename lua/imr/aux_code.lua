local AuxFilter = {}
local parse_aux_input

local function normalize_trigger(token, fallback)
    if token == nil or token == "" then
        return fallback
    end
    return token
end

local function merge_comment(origin, message)
    if not origin or origin == "" then
        return message
    end
    if origin:find(message, 1, true) then
        return origin
    end
    return origin .. " | " .. message
end

-- local log = require 'log'
-- log.outfile = "aux_code.log"

function AuxFilter.init(env)
    -- log.info("** AuxCode filter", env.name_space)
    local engine = env.engine
    local config = engine.schema.config

    AuxFilter.db = ReverseLookup(config:get_string('aux/db'))
    AuxFilter.comment_db = ReverseLookup(config:get_string('aux/comment/db'))

    -- 双触发键：learn 与 no_learn
    env.learn_trigger = normalize_trigger(config:get_string("aux/trigger/default"), nil)
        or normalize_trigger(config:get_string("aux/trigger/learn"), nil)
        or ";"
    env.no_learn_trigger = normalize_trigger(config:get_string("aux/trigger/no_learn"), "")

    if env.no_learn_trigger == env.learn_trigger then
        env.no_learn_trigger = ""
    end

    env.triggers = {
        { mode = "no_learn", token = env.no_learn_trigger },
        { mode = "learn", token = env.learn_trigger },
    }
    env.length = 2

    local active_triggers = {}
    for _, item in ipairs(env.triggers) do
        if item.token ~= "" then
            table.insert(active_triggers, item)
        end
    end
    env.triggers = active_triggers

    table.sort(env.triggers, function(a, b)
        return #a.token > #b.token
    end)

    -- 兼容旧逻辑，后续任务会替换为 parse 模式
    env.trigger_key = env.learn_trigger
    -- 设定是否显示辅助码，默认为显示
    env.show_comment = config:get_string("aux/comment/enable") or 'true'
    if env.show_comment == "false" then
        env.show_comment = false
    else
        env.show_comment = true
    end

    ----------------------------
    -- 持續選詞上屏，保持輔助碼分隔符存在 --
    ----------------------------
    env.notifier = engine.context.select_notifier:connect(function(ctx)
        local mode, _, trigger_token = parse_aux_input(ctx.input, env)
        if mode == "none" then
            return
        end

        local preedit = ctx:get_preedit()
        local trigger_pattern = trigger_token:gsub("%W", "%%%1")
        local removeAuxInput = ctx.input:match("([^,]+)" .. trigger_pattern)
        local reeditTextFront = preedit.text:match("([^,]+)" .. trigger_pattern)

        if not removeAuxInput then
            return
        end

        -- ctx.text 隨著選字的進行，oaoaoa； 有如下的輸出：
        -- ---- 有輔助碼 ----
        -- >>> 啊 oaoa；au
        -- >>> 啊吖 oa；au
        -- >>> 啊吖啊；au
        -- ---- 無輔助碼 ----
        -- >>> 啊 oaoa；
        -- >>> 啊吖 oa；
        -- >>> 啊吖啊；
        -- 這邊把已經上屏的字段 (preedit:text) 進行分割；
        -- 如果已經全部選完了，分割後的結果就是 nil，否則都是 吖卡 a 這種字符串
        -- 驗證方式：
        -- log.info('select_notifier', ctx.input, removeAuxInput, preedit.text, reeditTextFront)

        -- 當最終不含有任何字母時 (候選)，就跳出分割模式，並把輔助碼分隔符刪掉
        ctx.input = removeAuxInput
        if reeditTextFront and reeditTextFront:match("[a-z0-9]") then
            -- 給詞尾自動添加分隔符，上面的 re.match 會把分隔符刪掉
            ctx.input = ctx.input .. trigger_token
        else
            -- 剩下的直接上屏
            ctx:commit()
        end
    end)
-- AuxFilter.aux_code { ["啊"] = ka,["阿"] = ek,} 
end

----------------
-- 閱讀輔碼文件 --
----------------

-- local function getUtf8CharLength(byte)
--     if byte < 128 then
--         return 1
--     elseif byte < 224 then
--         return 2
--     elseif byte < 240 then
--         return 3
--     else
--         return 4
--     end
-- end

-- 预处理辅码索引，避免在候选循环中重复拆分字符串。
-- k1: 记录每个字可命中的首键；k12: 记录前两键完整命中。

local function char_matches_aux(char, auxStr)
    if auxStr == "" then
        return false
    end

    local code = AuxFilter.db:lookup(char)
    if not code or #code == 0 then
        return false
    end
    for part in code:gmatch('%S+') do
        if part:find(auxStr) == 1 then return true end
    end
    return false
end

-- 词组匹配按字位逐个检查，命中即返回。
-- 这样只允许同一个字完整命中，避免旧逻辑跨字混拼误命中。
local function find_phrase_match(word, auxStr)
    if auxStr == "" or not word or word == "" then
        return nil
    end

    local pos = 0
    for _, codePoint in utf8.codes(word) do
        pos = pos + 1
        local char = utf8.char(codePoint)
        if char_matches_aux(char, auxStr) then
            return { pos = pos, char = char }
        end
    end

    return nil
end

local function is_phrase_candidate(cand)
    return cand.type == 'user_phrase' or cand.type == 'phrase' or cand.type == 'simplified'
end

local function is_multi_char_text(text)
    if not text or text == "" then
        return false
    end

    local count = 0
    for _ in utf8.codes(text) do
        count = count + 1
        if count > 1 then
            return true
        end
    end

    return false
end

local function append_phrase_match_hint(cand, matched_char, auxStr)
    local hint = "(" .. matched_char .. ":" .. auxStr .. ")"

    if cand:get_dynamic_type() == "Shadow" then
        local shadow_text = cand.text
        local shadow_comment = cand.comment or ""
        local original = cand:get_genuine()
        if not original then
            cand.comment = merge_comment(cand.comment, hint)
            return cand
        end
        local merged = merge_comment((original.comment or "") .. shadow_comment, hint)
        return ShadowCandidate(original, original.type, shadow_text, merged)
    end

    cand.comment = merge_comment(cand.comment, hint)
    return cand
end

local function escape_lua_pattern(text)
    return text:gsub("%W", "%%%1")
end

parse_aux_input = function(input_code, env)
    if input_code == "" then
        return "none", "", ""
    end

    for _, item in ipairs(env.triggers) do
        local token = item.token
        if token ~= "" then
            local token_pattern = escape_lua_pattern(token)
            if input_code:find(token, 1, true) then
                local local_split = input_code:match(token_pattern .. "([^,]+)")
                if not local_split then
                    return item.mode, "", token
                end
                return item.mode, local_split, token
            end
        end
    end

    return "none", "", ""
end

local function to_commit_only_candidate(cand)
    local rebuilt = Candidate(cand.type, cand.start, cand._end, cand.text, cand.comment)
    rebuilt.preedit = cand.preedit
    rebuilt.quality = cand.quality
    return rebuilt
end

------------------
-- filter 主函數 --
------------------
function AuxFilter.func(input, env)
    local context = env.engine.context
    local inputCode = context.input

    local mode, auxStr, _ = parse_aux_input(inputCode, env)

    -- 判断字符串中是否包含輔助碼分隔符
    if mode == "none" then
        -- 没有输入辅助码引导符，则直接yield所有待选项，不进入后续迭代，提升性能
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local first_exact_bucket = {}
    local full_aux_bucket = {}

    local function to_yield_candidate(cand)
        if mode == "no_learn" then
            return to_commit_only_candidate(cand)
        end
        return cand
    end

    -- 遍歷每一個待選項
    for _cand in input:iter() do
        local cand = _cand
        local auxCodes = AuxFilter.comment_db:lookup(cand.text) -- 僅單字非 nil

        -- 查看 auxCodes
        -- log.info(cand.text, #auxCodes)
        -- for i, cl in ipairs(auxCodes) do
        --     log.info(i, table.concat(cl, ',', 1, #cl))
        -- end

        -- 給待選項加上輔助碼提示
        if env.show_comment and auxCodes and #auxCodes > 0 then
            local codeComment = auxCodes:gsub(' ', ',')
            -- 處理 simplifier
            if cand:get_dynamic_type() == "Shadow" then
                local shadowText = cand.text
                local shadowComment = cand.comment
                local originalCand = cand:get_genuine()
                cand = ShadowCandidate(originalCand, originalCand.type, shadowText,
                    originalCand.comment .. shadowComment .. '(' .. codeComment .. ')')
            else
                cand.comment = '(' .. codeComment .. ')'
            end
        end

        -- 過濾輔助碼
        if #auxStr == 0 then
            -- 沒有輔助碼、不需篩選，直接返回待選項
            yield(to_yield_candidate(cand))
        elseif #auxStr > 0 and is_phrase_candidate(cand) then
            local matched = find_phrase_match(cand.text, auxStr)
            -- 仅词组候选显示命中提示，单字继续沿用“显示全部辅码”。
            if matched and env.show_comment and is_multi_char_text(cand.text) then
                -- 当前单字的辅助码提示
                local auxCodes = AuxFilter.comment_db:lookup(matched.char)
                cand = append_phrase_match_hint(cand, matched.char, auxCodes)
            end

            if matched and matched.pos == 1 then
                table.insert(first_exact_bucket, cand)
            elseif matched then
                table.insert(full_aux_bucket, cand)
            end
        else
            -- 待选项字词 没有 匹配到当前的辅助码，插入到列表中，最后插入到候选框里( 获得靠后的位置 )
            -- table.insert(insertLater, cand)
            -- 更新逻辑：没有匹配上就不出现再候选框里，提升性能
        end
    end

    local seen = {}
    local function yield_bucket(bucket)
        for _, cand in ipairs(bucket) do
            local key = cand.type .. "\t" .. cand.start .. "\t" .. cand._end .. "\t" .. cand.text
            if not seen[key] then
                seen[key] = true
                yield(to_yield_candidate(cand))
            end
        end
    end

    yield_bucket(first_exact_bucket)
    yield_bucket(full_aux_bucket)

    -- 把沒有匹配上的待選給添加上
    -- for _, cand in ipairs(insertLater) do
    --     yield(cand)
    -- end
    -- 更新逻辑：没有匹配上就不出现再候选框里，提升性能

end

function AuxFilter.fini(env)
    env.notifier:disconnect()
end

return AuxFilter

-- Local Variables:
-- lua-indent-level: 4
-- End: