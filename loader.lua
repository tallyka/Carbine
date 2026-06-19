-- Carbine encrypted loader.
-- The Rogue Lineage hub is RC4 + base64 encrypted; without a valid key the
-- blob is gibberish, so there is nothing readable to copy or to strip.
-- Load with:  getgenv().Carbine_Key = "YOUR-KEY"  before running this loader.
local gameId = game.GameId

local function note(t)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Carbine", Text = t, Duration = 8 })
    end)
    warn("[Carbine] " .. t)
end

local function get_key()
    local k = rawget(getgenv(), "Carbine_Key")
    if (not k or k == "") and isfile and readfile then
        pcall(function() if isfile("Carbine/key.txt") then k = readfile("Carbine/key.txt") end end)
    end
    if type(k) == "string" then k = (k:gsub("^%s+", ""):gsub("%s+$", "")) end
    return k
end

local function b64decode(s)
    local ok, r
    ok, r = pcall(function() if crypt and crypt.base64decode then return crypt.base64decode(s) end end)
    if ok and r then return r end
    ok, r = pcall(function() if crypt and crypt.base64 and crypt.base64.decode then return crypt.base64.decode(s) end end)
    if ok and r then return r end
    ok, r = pcall(function() if base64 and base64.decode then return base64.decode(s) end end)
    if ok and r then return r end
    ok, r = pcall(function() if base64_decode then return base64_decode(s) end end)
    if ok and r then return r end
    -- pure-lua fallback (slow, only used if the executor exposes no base64)
    local bc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    s = string.gsub(s, '[^' .. bc .. '=]', '')
    return (s:gsub('.', function(x)
        if x == '=' then return '' end
        local rr, f = '', (string.find(bc, x, 1, true) - 1)
        for i = 6, 1, -1 do rr = rr .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return rr
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- standard RC4 (matches the PowerShell encryptor byte-for-byte)
local function rc4(key, data)
    local S = {}
    for i = 0, 255 do S[i] = i end
    local klen = #key
    local j = 0
    for i = 0, 255 do
        j = (j + S[i] + string.byte(key, (i % klen) + 1)) % 256
        S[i], S[j] = S[j], S[i]
    end
    local out = {}
    local i = 0
    j = 0
    for c = 1, #data do
        i = (i + 1) % 256
        j = (j + S[i]) % 256
        S[i], S[j] = S[j], S[i]
        local ks = S[(S[i] + S[j]) % 256]
        out[c] = string.char(bit32.bxor(string.byte(data, c), ks))
    end
    return table.concat(out)
end

local function run_hub(enc_b64)
    local key = get_key()
    if not key or key == "" then
        note('No key. Set  getgenv().Carbine_Key = "YOUR-KEY"  before loading.')
        return
    end
    local raw = b64decode(enc_b64)
    if not raw or #raw == 0 then note("Couldn't read the encrypted hub.") return end
    local hub = rc4(key, raw)
    local MARKER = "CARBINE_HUB_V1\n"
    if string.sub(hub, 1, #MARKER) ~= MARKER then
        note("Invalid key.")
        return
    end
    local fn, err = loadstring(string.sub(hub, #MARKER + 1))
    if not fn then note("Hub failed to compile: " .. tostring(err)) return end
    -- valid key: remember it (so serverhops / next runs don't need getgenv), then clear the global
    pcall(function()
        if makefolder and isfolder and not isfolder("Carbine") then makefolder("Carbine") end
        if writefile then writefile("Carbine/key.txt", key) end
    end)
    pcall(function() getgenv().Carbine_Key = nil end)
    fn()
end

if gameId == 1087859240 then
    -- Rogue Lineage hub: local encrypted blob first (for testing), else GitHub
    local enc
    if isfile and readfile then
        pcall(function() if isfile("Carbine/rogue_ui.enc") then enc = readfile("Carbine/rogue_ui.enc") end end)
    end
    if not enc then
        local ok, body = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/tallyka/Carbine/main/ROGUE/rogue_ui.enc", true)
        end)
        if ok then enc = body end
    end
    if not enc then note("Couldn't fetch the hub (is the repo public?).") return end
    run_hub(enc)
elseif gameId == 7359098240 then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/tallyka/Carbine/main/ROGUE_BATTLEGROUNDS/rlb.lua", true))()
    end)
end
