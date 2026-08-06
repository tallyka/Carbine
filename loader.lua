-- Carbine loader.
local gameId = game.GameId

local function note(t)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Carbine", Text = t, Duration = 8 })
    end)
    warn("[Carbine] " .. t)
end

if gameId == 1087859240 then
    local ok, err = pcall(function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/tallyka/Carbine/main/ROGUE/rogue_ui.lua?nonce=" .. tostring(math.random()),
            true
        ))()
    end)
    if not ok then note("Hub failed to load: " .. tostring(err)) end
elseif gameId == 7359098240 then
    pcall(function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/tallyka/Carbine/main/ROGUE_BATTLEGROUNDS/rlb.lua?nonce=" .. tostring(math.random()),
            true
        ))()
    end)
end
