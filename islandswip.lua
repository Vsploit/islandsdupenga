--// SERVICES
local _S = game:GetService("ReplicatedStorage")
local _P = game:GetService("Players")
local _H = game:GetService("HttpService")
local _R = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local client = _P.LocalPlayer

--// LOAD RAYFIELD
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// CREATE WINDOW
local Window = Rayfield:CreateWindow({
   Name = "Pufferware Coin Dupe",
   LoadingTitle = "Loading Pufferware",
   LoadingSubtitle = "By CJS",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "PufferwareCoinDupe"
   },
   Discord = {
      Enabled = true,
      Invite = "BgH4kprxJ7",
      RememberJoins = true
   },
   KeySystem = false
})

--// COIN DUPE VARIABLES
local bridge = _S:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
local bank_trigger = bridge:WaitForChild("TransactionBankBalance")
local r_init = bridge:WaitForChild("vdejLrsuUtHdxgMnamqcwrddgseyltmjnutxAhuAdt/ohzbeybzqzfJRFwekzcvdLnpwpuaoia")
local r_access = bridge:WaitForChild("vdejLrsuUtHdxgMnamqcwrddgseyltmjnutxAhuAdt/amv")
local r_fund = bridge:WaitForChild("vdejLrsuUtHdxgMnamqcwrddgseyltmjnutxAhuAdt/uvgaYvclaqh")
local r_exit = bridge:WaitForChild("vdejLrsuUtHdxgMnamqcwrddgseyltmjnutxAhuAdt/uabQAzmslluxa")

local current_tasks = {}
local concurrent_limit = 32
local unit_goal = 5000000000
local is_dupe_active = false
local startup_time = tick()
local completion_time = nil

--// ANTI-AFK VARIABLES
local afk_enabled = false
local afk_start_time = tick()

--// STATS TRACKING
local session_start = tick()
local coins_earned = 0
local machines_filled = 0
local kicks_prevented = 0
local initial_coins = client:GetAttribute("Coins") or 0



--// INFINITE JUMP VARIABLES
local inf_jump_enabled = false
local jumping = false

--// CREATE TABS
local MainTab = Window:CreateTab("Main", 4483362458)
local StatsTab = Window:CreateTab("Stats", 4483362458)
local UtilityTab = Window:CreateTab("Utility", 4483362458)

--// COIN DUPE SECTION
local CoinSection = MainTab:CreateSection("Coin Dupe")

local DupeToggle = MainTab:CreateToggle({
   Name = "Coin Dupe",
   CurrentValue = false,
   Flag = "CoinDupeToggle",
   Callback = function(Value)
      is_dupe_active = Value
      if Value then
         startup_time = tick()
         completion_time = nil
         initial_coins = client:GetAttribute("Coins") or 0
         Rayfield:Notify({
            Title = "Coin Dupe",
            Content = "Coin dupe activated!",
            Duration = 3,
            Image = 4483362458
         })
      else
         Rayfield:Notify({
            Title = "Coin Dupe",
            Content = "Coin dupe deactivated!",
            Duration = 3,
            Image = 4483362458
         })
      end
   end,
})

--// ANTI-AFK SECTION
local AFKSection = MainTab:CreateSection("Anti-AFK")

local AFKToggle = MainTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = false,
   Flag = "AntiAFKToggle",
   Callback = function(Value)
      afk_enabled = Value
      if Value then
         afk_start_time = tick()
         Rayfield:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK activated!",
            Duration = 3,
            Image = 4483362458
         })
      else
         Rayfield:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK deactivated!",
            Duration = 3,
            Image = 4483362458
         })
      end
   end,
})

--// UTILITY SECTION
local MovementSection = UtilityTab:CreateSection("Movement")

local InfJumpToggle = UtilityTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJumpToggle",
   Callback = function(Value)
      inf_jump_enabled = Value
      Rayfield:Notify({
         Title = "Infinite Jump",
         Content = Value and "Enabled!" or "Disabled!",
         Duration = 2,
         Image = 4483362458
      })
   end,
})

--// STATS SECTION
local SessionSection = StatsTab:CreateSection("Session Statistics")

local SessionTimeLabel = StatsTab:CreateLabel("Session Time: 00:00:00")
local CoinsEarnedLabel = StatsTab:CreateLabel("Coins Earned: $0")
local CurrentBalanceLabel = StatsTab:CreateLabel("Current Balance: $0")
local MachinesFilledLabel = StatsTab:CreateLabel("Machines Filled: 0")
local KicksPreventedLabel = StatsTab:CreateLabel("Kicks Prevented: 0")

local ServerSection = StatsTab:CreateSection("Server Information")

local PlayerCountLabel = StatsTab:CreateLabel("Players: 0/" .. Players.MaxPlayers)
local PingLabel = StatsTab:CreateLabel("Ping: 0ms")
local FPSLabel = StatsTab:CreateLabel("FPS: 0")



--// HELPER FUNCTIONS
local function format_currency(amount)
    local raw = tostring(amount)
    return raw:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function format_duration(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function get_unit_balance(target)
    if not target or not target.Parent then return unit_goal + 1 end
    local val_obj = target:FindFirstChild("CoinBalance")
    if val_obj and (val_obj:IsA("IntValue") or val_obj:IsA("NumberValue")) then return val_obj.Value end
    return target:GetAttribute("CoinBalance") or 0
end

local function calculate_world_metrics()
    local total_balance = 0
    local target_cap = 0
    local world_islands = workspace:FindFirstChild("Islands")
    if world_islands then
        for _, island in ipairs(world_islands:GetChildren()) do
            local block_folder = island:FindFirstChild("Blocks")
            if block_folder then
                for _, object in ipairs(block_folder:GetChildren()) do
                    if object.Name:lower():find("vendingmachine") then
                        total_balance = total_balance + get_unit_balance(object)
                        target_cap = target_cap + unit_goal
                    end
                end
            end
        end
    end
    return total_balance, target_cap
end

--// FPS COUNTER
local fps_count = 0
local fps_rate = 0
_R.RenderStepped:Connect(function()
    fps_count = fps_count + 1
end)

task.spawn(function()
    while task.wait(1) do
        fps_rate = fps_count
        fps_count = 0
    end
end)

--// STATS UPDATE LOOP
task.spawn(function()
    while task.wait(0.5) do
        -- Session stats
        local session_time = tick() - session_start
        SessionTimeLabel:Set("Session Time: " .. format_duration(session_time))
        
        local current_balance = client:GetAttribute("Coins") or 0
        coins_earned = math.max(0, current_balance - initial_coins)
        CoinsEarnedLabel:Set("Coins Earned: $" .. format_currency(coins_earned))
        CurrentBalanceLabel:Set("Current Balance: $" .. format_currency(current_balance))
        MachinesFilledLabel:Set("Machines Filled: " .. machines_filled)
        KicksPreventedLabel:Set("Kicks Prevented: " .. kicks_prevented)
        
        -- Server stats
        PlayerCountLabel:Set("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        
        local ping = client:GetNetworkPing()
        PingLabel:Set("Ping: " .. math.floor(ping * 1000) .. "ms")
        FPSLabel:Set("FPS: " .. fps_rate)
    end
end)

--// BANK WITHDRAWAL LOOP (Changed to 1.5B)
task.spawn(function()
    while task.wait(0.1) do
        if is_dupe_active then
            local wallet = client:GetAttribute("Coins") or 0
            if wallet < 4500000000 then
                pcall(function()
                    bank_trigger:FireServer("", {{amount = 1500000000, transferType = "WITHDRAWAL", accountType = "shared"}})
                end)
            end
        end
    end
end)

--// VENDING MACHINE CYCLE (Changed to 1.5B)
local function run_machine_cycle(machine)
    if current_tasks[machine] then return end
    current_tasks[machine] = true
    
    task.spawn(function()
        pcall(function()
            local session_token = _H:GenerateGUID(false)
            r_init:FireServer(session_token, {{vendingMachine = machine}})
            r_access:FireServer(session_token, {{vendingMachine = machine}})
            local deficit = unit_goal - get_unit_balance(machine)
            if deficit > 0 then
                local iterations = math.ceil(deficit / 1500000000)
                for i = 1, iterations do
                    if not is_dupe_active or not machine.Parent then break end
                    r_fund:FireServer(_H:GenerateGUID(false), {{
                        vendingMachine = machine, 
                        player_tracking_category = "join_from_web", 
                        amount = 1500000000
                    }})
                    if i % 10 == 0 then task.wait() end
                end
                machines_filled = machines_filled + 1
            end
            r_exit:FireServer({{vendingMachine = machine}})
        end)
        current_tasks[machine] = nil
    end)
end

--// MAIN VENDING MACHINE LOOP
task.spawn(function()
    while task.wait(0.3) do
        if is_dupe_active then
            local env_islands = workspace:FindFirstChild("Islands")
            if env_islands then
                local thread_count = 0
                for _ in pairs(current_tasks) do thread_count = thread_count + 1 end
                
                if thread_count < concurrent_limit then
                    for _, island_obj in ipairs(env_islands:GetChildren()) do
                        local items = island_obj:FindFirstChild("Blocks")
                        if items then
                            for _, obj in ipairs(items:GetChildren()) do
                                if thread_count >= concurrent_limit or not is_dupe_active then break end
                                if not current_tasks[obj] and obj.Name:lower():find("vendingmachine") then
                                    if get_unit_balance(obj) < unit_goal then
                                        thread_count = thread_count + 1
                                        run_machine_cycle(obj)
                                    end
                                end
                            end
                        end
                        if thread_count >= concurrent_limit or not is_dupe_active then break end
                    end
                end
            end
        end
    end
end)

--// INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if not inf_jump_enabled then return end
    local character = client.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

--// ANTI-AFK CORE
client.Idled:Connect(function()
    if not afk_enabled then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    kicks_prevented = kicks_prevented + 1
    Rayfield:Notify({
        Title = "Anti-AFK",
        Content = "Blocked AFK kick!",
        Duration = 2,
        Image = 4483362458
    })
end)



--// FINAL NOTIFICATION
Rayfield:Notify({
   Title = "Pufferware Loaded",
   Content = "Coin Dupe By CJS",
   Duration = 5,
   Image = 4483362458
})
