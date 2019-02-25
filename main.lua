ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local playerdb = {}
maxPlayers = 32;
-- Creates an empty table of tables to hold the blip/ped information for users.
for i = 0, maxPlayers, 1 do
    playerdb[i] = {}
end

local keyParam = 167 -- e.g : Keys["F6"]
local Godmode = false
local Godmodep = false
local group = "user"
local states = {}
states.frozen = false
states.frozenPos = nil
local TargetSpectate = nil
local InSpectatorMode = false
local LastPosition = nil
local polarAngleDeg = 0;
local azimuthAngleDeg = 90;
local radius = -3.5;
local cam = nil
local PlayerData = {}
local infiniteammo = false
local ignorePlayerNameDistance = false
local playerNamesDist = 15
local displayIDHeight = 1.5
local red = 255
local green = 255
local blue = 255
local playerBlips = false
local thermalvision = false
local nightvision = false
local displayradar = false
local godmod = false
local enginemuliplier = false
local torquemultiplier = false
local CustomX = 0.0
local CustomY = 0.0
local CustomZ = 0.0
local playergroup = "user"
local BlackOut = false
local nonpcstraffic = false




Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)

        if IsControlJustPressed(1, keyParam) and GetLastInputMethod(0) then
            ESX.TriggerServerCallback('Snippet:getUsergroup', function(group)
                playergroup = group
                if playergroup == "user" or playergroup == "admin" or playergroup == "mod" then
                    OpenMenuAdmin()
                else
                    ESX.ShowNotification("Vous n'avez pas la permission pour ouvrir ce menu")
                end
            end)
        end
    end
end)
Citizen.CreateThread(function()
    if not HasNamedPtfxAssetLoaded("core") then
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do
            Wait(1)
        end
    end
    SetPtfxAssetNextCall("core")
    StopParticleFxLooped(effet, 0)
    local coords = GetEntityCoords(PlayerPedId())
end)

function BulletCoords()
    local result, coord = GetPedLastWeaponImpactCoord(PlayerPedId(), Citizen.ReturnResultAnyway())
    return coord
end

function OpenMenuAdmin()
    local admmenu = {}
	
    if playergroup == "user" then
        table.insert(admmenu, { label = 'Administration', value = 'admin' })
        table.insert(admmenu, { label = 'Téléportation', value = 'teleport' })
        table.insert(admmenu, { label = "Joueur", value = 'player' })
        table.insert(admmenu, { label = "Monde", value = 'world' })
        table.insert(admmenu, { label = 'Armes', value = 'weapon' })
        table.insert(admmenu, { label = 'Véhicule', value = 'car' })
        table.insert(admmenu, { label = 'Gestion serveur', value = 'server' })
        table.insert(admmenu, { label = 'Autres', value = 'other' })

    elseif playergroup == "mod" then
        table.insert(admmenu, { label = 'Administration', value = 'admin' })
        table.insert(admmenu, { label = 'Téléportation', value = 'teleport' })
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'adminmenu',
        {
            title = "Menu Admin",
            align = 'top-right',
            elements = admmenu
        },
        function(data1, menu1)
            menu1.close()
            if data1.current.value == 'admin' then
                OpenAdmin()
            end
            if data1.current.value == 'server' then
                OpenServer()
            end
            if data1.current.value == 'player' then
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
            end
            if data1.current.value == 'weapon' then
                OpenWeapon()
            end
            if data1.current.value == 'car' then
                OpenCar()
            end
            if data1.current.value == 'teleport' then
                OpenTeleport()
            end
            if data1.current.value == 'world' then
                OpenWorld()
            end
            if data1.current.value == 'other' then
                OpenOther()
            end
        end,
        function(data, menu)
            menu.close()
        end)
end

function GetPlayers()
    local players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end


function OpenServer()
    local elements = {}
    table.insert(elements, { label = "Activer WL", value = "WLon" })
    table.insert(elements, { label = "Désactiver WL", value = "WLoff" })
    table.insert(elements, { label = "Godmode", value = "godmode" })

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'server',
        {
            title = 'Gestion serveur',
            align = 'top-right',
            elements = elements,
        },
        function(data, menu)
            if data.current.value == "WLon" then
                TriggerServerEvent('jijadmin:whitelist', true)
            end
            if data.current.value == "WLoff" then
                TriggerServerEvent('jijadmin:whitelist', false)
            end
            if data.current.value == "godmode" then
                Godmodep = not Godmodep
                if Godmodep then
                    ESX.ShowNotification('Godmode : ON')
                else
                    ESX.ShowNotification('Godmode : OFF')
                end
            end
        end,
        function(data, menu)
            menu.close()
            OpenMenuAdmin()
        end)
end

function OpenWorld()
    local elements = {}
    table.insert(elements, { label = "Blackout", value = "blackout" })
    table.insert(elements, { label = "Pas de PNJ ni de traffic", value = "nonpc" })
    table.insert(elements, { label = "Heure", value = "time" })
    table.insert(elements, { label = "Météo", value = "meteo" })

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'world',
        {
            title = 'Monde',
            align = 'top-right',
            elements = elements,
        },
        function(data, menu)
            if data.current.value == "nonpc" then
                nonpcstraffic = not nonpcstraffic
                if nonpcstraffic then
                    ESX.ShowNotification('~r~PNJ Désactivé')
                else
                    ESX.ShowNotification('~g~PNJ Activé')
                end
                TriggerServerEvent('jijadmin:nonpc', nonpcstraffic)
            end

            if data.current.value == "time" then
                local elements2 = {}
                table.insert(elements2, { label = "Client", value = "client" })
                table.insert(elements2, { label = "Serveur", value = "server" })
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'time',
                    {
                        title = 'Heure',
                        align = 'top-right',
                        elements = elements2,
                    },
                    function(data2, menu2)
                        AddTextEntry('FMMC_KEY_TIP8', "Heures :")
                        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                        while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                            Citizen.Wait(0)
                        end

                        local h = ESX.Math.Round(tonumber(GetOnscreenKeyboardResult()))
                        if h > 23 then
                            h = 23
                        end
                        AddTextEntry('FMMC_KEY_TIP8', "Minutes :")
                        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                        while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                            Citizen.Wait(0)
                        end

                        local m = ESX.Math.Round(tonumber(GetOnscreenKeyboardResult()))
                        if m > 59 then
                            m = 59
                        end
                        if data2.current.value == "server" then
                            TriggerServerEvent('jijadmin:settime', h, m)
                        end
                        if data2.current.value == "client" then
                            NetworkOverrideClockTime(h, m, 0)
                        end
                    end,
                    function(data2, menu2)
                        menu2.close()
                        OpenWorld()
                    end)
            end

            if data.current.value == "blackout" then
                local elements2 = {}
                table.insert(elements2, { label = "Client", value = "client" })
                table.insert(elements2, { label = "Serveur", value = "server" })
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'blackout',
                    {
                        title = 'Blackout',
                        align = 'top-right',
                        elements = elements2,
                    },
                    function(data2, menu2)
                        BlackOut = not BlackOut
                        if BlackOut then
                            ESX.ShowNotification('~g~Blackout Activé')
                        else
                            ESX.ShowNotification('~r~Blackout Désactivé')
                        end
                        if data2.current.value == "server" then
                            TriggerServerEvent('jijadmin:blackout', BlackOut)
                        end
                        if data2.current.value == "client" then
                            TriggerEvent('jijadmin:blackout', BlackOut)
                        end
                    end,
                    function(data2, menu2)
                        menu2.close()
                        OpenWorld()
                    end)
            end
            if data.current.value == "meteo" then
                local elements2 = {}
                table.insert(elements2, { label = "EXTRASUNNY", value = "EXTRASUNNY" })
                table.insert(elements2, { label = "SMOG", value = "SMOG" })
                table.insert(elements2, { label = "CLEAR", value = "CLEAR" })
                table.insert(elements2, { label = "CLOUDS", value = "CLOUDS" })
                table.insert(elements2, { label = "FOGGY", value = "FOGGY" })
                table.insert(elements2, { label = "OVERCAST", value = "OVERCAST" })
                table.insert(elements2, { label = "RAIN", value = "RAIN" })
                table.insert(elements2, { label = "THUNDER", value = "THUNDER" })
                table.insert(elements2, { label = "CLEARING", value = "CLEARING" })
                table.insert(elements2, { label = "NEUTRAL", value = "NEUTRAL" })
                table.insert(elements2, { label = "SNOW", value = "SNOW" })
                table.insert(elements2, { label = "BLIZZARD", value = "BLIZZARD" })
                table.insert(elements2, { label = "SNOWLIGHT", value = "SNOWLIGHT" })
                table.insert(elements2, { label = "XMAS", value = "XMAS" })
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'meteo',
                    {
                        title = 'Météo',
                        align = 'top-right',
                        elements = elements2,
                    },
                    function(data2, menu2)
                        AddTextEntry('FMMC_KEY_TIP8', "Vent :")
                        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                        while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                            Citizen.Wait(0)
                        end

                        local wind = ESX.Math.Round(tonumber(GetOnscreenKeyboardResult()), 2)
                        TriggerServerEvent('jijadmin:meteo', data2.current.value, wind)
                    end,
                    function(data2, menu2)
                        menu2.close()
                        OpenWorld()
                    end)
            end
        end,
        function(data, menu)
            menu.close()
            OpenMenuAdmin()
        end)
end

RegisterNetEvent("jijadmin:nonpc")
AddEventHandler("jijadmin:nonpc", function(state)
    nonpcstraffic = state
end)

Citizen.CreateThread(function()
    while true do
        if (nonpcstraffic == true) then
            local playerPedPos = GetEntityCoords(PlayerPedId())
            if ClearCount == 0 then
                ClearAreaOfCops(playerPedPos, 9999.0, 0)
                ClearAreaOfPeds(playerPedPos, 9999.0, 1)
                ClearAreaOfVehicles(playerPedPos, 9999.0, false, false, false, false, false)
            end
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            Citizen.InvokeNative(0x90B6DA738A9A25DA, 0.0)
            RemoveVehiclesFromGeneratorsInArea(playerPedPos.x - 1000.0, playerPedPos.y - 1000.0, playerPedPos.z - 1000.0, playerPedPos.x + 1000.0, playerPedPos.y + 1000.0, playerPedPos.z + 1000.0)
            SetGarbageTrucks(false)
            SetRandomBoats(false)
            SetRandomTrains(false)
        else
            SetGarbageTrucks(true)
            SetRandomBoats(true)
            SetRandomTrains(true)
            SetVehicleDensityMultiplierThisFrame(0.3)
            SetPedDensityMultiplierThisFrame(0.5)
        end

        Citizen.Wait(1)
    end
end)
RegisterNetEvent("jijadmin:swat")
AddEventHandler("jijadmin:swat", function(number)
    Citizen.CreateThread(function()
        local coords = GetEntityCoords(PlayerPedId())
        local model = GetHashKey("s_m_y_swat_01")
        RequestModel(model)

        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end

        local ped = CreatePed(5, model, coords.x + 5, coords.y, coords.z, 0.0, true, false)
        -- SetPedParachuteTintIndex(ped, 8)
        Citizen.Wait(1000)
        -- TaskParachuteToTarget(ped, coords.x, coords.y, coords.z)
        --Citizen.Wait(20000)
        SetAiWeaponDamageModifier(2.0)
        SetCurrentPedWeapon(ped, GetHashKey("weapon_smg"), true)
        GiveWeaponToPed(ped, GetHashKey("weapon_smg"), 1000, false)
        SetPedCanSwitchWeapon(ped, false)
        SetPedInfiniteAmmo(ped, true)
        SetPedInfiniteAmmoClip(ped, true)
        AddRelationshipGroup("rioters")
        SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey("rioters"))
        SetRelationshipBetweenGroups(5, GetHashKey("rioters"), GetHashKey('PLAYER'))

        TaskCombatPed(ped, PlayerPedId(), 0, 16)
    end)
end)

RegisterNetEvent("jijadmin:settime")
AddEventHandler("jijadmin:settime", function(h, m)
    NetworkOverrideClockTime(h, m, 0)
end)

RegisterNetEvent("jijadmin:blackout")
AddEventHandler("jijadmin:blackout", function(state)
    BlackOut = state
    if BlackOut == true then
        Citizen.CreateThread(function() --Panne GPS
            RequestAmbientAudioBank("DLC_HEIST_HACKING_SNAKE_SOUNDS", false)
            PlaySoundFrontend(-1, 'Power_Down', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', 0)
            SetBlackout(true)
            Citizen.Wait(2000)
            SetBlackout(false)
            PlaySoundFrontend(-1, 'Failur', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', 0)
            Citizen.Wait(2000)
            SetBlackout(true)
            RequestAmbientAudioBank("HUD_FRONTEND_MP_COLLECTABLE_SOUNDS", false)
            PlaySoundFrontend(-1, 'Enemy_Deliver', 'HUD_FRONTEND_MP_COLLECTABLE_SOUNDS', 0)
            Citizen.Wait(2000)
            SetBlackout(false)
            RequestAmbientAudioBank("CB_RADIO_SFX", false)
            PlaySoundFrontend(-1, 'End_Squelch', 'CB_RADIO_SFX', 0)
            SetBlackout(true)
            Citizen.Wait(200)
            SetBlackout(false)
            Citizen.Wait(200)
            PlaySoundFrontend(-1, 'End_Squelch', 'CB_RADIO_SFX', 0)
            SetBlackout(true)
            Citizen.Wait(1000)
            SetBlackout(false)
            Citizen.Wait(300)
            PlaySoundFrontend(-1, 'End_Squelch', 'CB_RADIO_SFX', 0)
            SetBlackout(true)
            Citizen.Wait(200)
            SetBlackout(false)
            Citizen.Wait(500)
            PlaySoundFrontend(-1, 'End_Squelch', 'CB_RADIO_SFX', 0)
            SetBlackout(true)
            Citizen.Wait(500)
            PlaySoundFrontend(-1, 'End_Squelch', 'CB_RADIO_SFX', 0)
            SetBlackout(false)
            Citizen.Wait(500)
            PlaySoundFrontend(-1, 'End_Squelch', 'CB_RADIO_SFX', 0)
            SetBlackout(true)
            Citizen.Wait(30000)
            TriggerEvent("scaleformAPI:minimess", "Batterie faible", "GPS", 2)
            PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
            StartScreenEffect('SuccessMichael', 1000, false)
            Citizen.Wait(5000)
            local time = 0
            while time < 20 do
                FlashMinimapDisplay()
                PlaySoundFrontend(-1, "MP_IDLE_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                time = time + 1
                Citizen.Wait(1000)
                -- PlaySoundFrontend(-1, 'MP_Flash', 'WastedSounds', 1)
                -- Citizen.Wait(500)
            end
            local time = 0
            while time < 20 do
                FlashMinimapDisplay()
                PlaySoundFrontend(-1, "MP_IDLE_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                time = time + 1
                Citizen.Wait(750)
                -- PlaySoundFrontend(-1, 'MP_Flash', 'WastedSounds', 1)
                -- Citizen.Wait(500)
            end
            local time = 0
            while time < 20 do
                FlashMinimapDisplay()
                PlaySoundFrontend(-1, "MP_IDLE_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                time = time + 1
                Citizen.Wait(500)
                -- PlaySoundFrontend(-1, 'MP_Flash', 'WastedSounds', 1)
                -- Citizen.Wait(500)
            end
            local time = 0
            while time < 20 do
                FlashMinimapDisplay()
                PlaySoundFrontend(-1, "MP_IDLE_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                time = time + 1
                Citizen.Wait(250)
                -- PlaySoundFrontend(-1, 'MP_Flash', 'WastedSounds', 1)
                -- Citizen.Wait(500)
            end
            local time = 0
            while time < 20 do
                FlashMinimapDisplay()
                PlaySoundFrontend(-1, "MP_IDLE_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                time = time + 1
                Citizen.Wait(200)
                -- PlaySoundFrontend(-1, 'MP_Flash', 'WastedSounds', 1)
                -- Citizen.Wait(500)
            end

            PlaySoundFrontend(-1, "MP_IDLE_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            Citizen.Wait(1000)
            PlaySoundFrontend(-1, 'MP_5_SECOND_TIMER', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            Citizen.Wait(1000)
            PlaySoundFrontend(-1, 'ERROR', 'HUD_AMMO_SHOP_SOUNDSET', false)
            FlashMinimapDisplay()
            Citizen.Wait(500)
            DisplayRadar(false)
        end)
    else
        RequestAmbientAudioBank("HUD_DEATHMATCH_SOUNDSET", false)
        PlaySoundFrontend(-1, 'DELETE', 'HUD_DEATHMATCH_SOUNDSET', 0)
        DisplayRadar(true)
        local time = 0
        while time < 20 do
            FlashMinimapDisplay()
            PlaySoundFrontend(-1, "MP_IDLE_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            time = time + 1
            Citizen.Wait(250)
            -- PlaySoundFrontend(-1, 'MP_Flash', 'WastedSounds', 1)
            -- Citizen.Wait(500)
        end
    end
    Citizen.CreateThread(function() --Blackout♀
        while true do
            Citizen.Wait(100)

            if (BlackOut == true) then
                SetBlackout(true)
            else
                SetBlackout(false)
            end
        end
    end)
end)

function OpenAdmin()
    local coord = { 0.0, 0.0, 0.0 }
    local playersInArea = ESX.Game.GetPlayersInArea(coord, 15000.0)
    local elements = {}

    for i = 1, #playersInArea, 1 do
        table.insert(elements, { label = GetPlayerServerId(playersInArea[i]) .. " - " .. GetPlayerName(playersInArea[i]), value = playersInArea[i] })
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player',
        {
            title = 'Joueurs',
            align = 'top-right',
            elements = elements,
        },
        function(data, menu)
            local admmenu2 = {}
            if playergroup == "user" then
                table.insert(admmenu2, { label = "Informations", value = 'info' })
                table.insert(admmenu2, { label = "Spectate", value = 'spectate' })
                table.insert(admmenu2, { label = "Stop spectate", value = 'stopspectate' })
                table.insert(admmenu2, { label = "Tp sur moi", value = 'bring' })
                table.insert(admmenu2, { label = "Tp sur le joueur", value = 'goto' })
                table.insert(admmenu2, { label = "Kick", value = 'kick' })
                table.insert(admmenu2, { label = "Ban", value = 'ban' })
                table.insert(admmenu2, { label = "Freeze", value = 'freeze' })
                table.insert(admmenu2, { label = "Bifle", value = 'bifle' })
                table.insert(admmenu2, { label = "Tuer", value = 'kill' })
                table.insert(admmenu2, { label = "Revive", value = 'revive' })
                table.insert(admmenu2, { label = "Noir", value = 'blackscreen' })
                table.insert(admmenu2, { label = "Ragdoll", value = 'ragdoll' })
                table.insert(admmenu2, { label = "SWAT on", value = 'swaton' })
                table.insert(admmenu2, { label = "SWAT off", value = 'swatoff' })
                table.insert(admmenu2, { label = "Gravité activée", value = 'gravityon' })
                table.insert(admmenu2, { label = "Gravité désactivée", value = 'gravityoff' })
                table.insert(admmenu2, { label = "Feu", value = 'fire' })
                table.insert(admmenu2, { label = "Noclip", value = 'noclip' })
                table.insert(admmenu2, { label = "Crash", value = 'crash' })

            elseif playergroup == "mod" then
                table.insert(admmenu2, { label = "Spectate", value = 'spectate' })
                table.insert(admmenu2, { label = "Stop spectate", value = 'stopspectate' })
                table.insert(admmenu2, { label = "Tp sur moi", value = 'bring' })
                table.insert(admmenu2, { label = "Tp sur le joueur", value = 'goto' })
                table.insert(admmenu2, { label = "Kick", value = 'kick' })
                table.insert(admmenu2, { label = "Ban", value = 'ban' })
                table.insert(admmenu2, { label = "Freeze", value = 'freeze' })
            end
            ESX.UI.Menu.CloseAll()
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'adminmenu',
                {
                    title = "Menu Admin : " .. data.current.label,
                    align = 'top-right',
                    elements = admmenu2
                },
                function(data3, menu3)

                    if data3.current.value == 'info' then
                        ESX.UI.Menu.CloseAll()
                        InfoPlayer(data.current.value)
                    end
                    if data3.current.value == 'spectate' then
                        TriggerServerEvent('jijadmin:requestSpectating', GetPlayerServerId(data.current.value))
                    end
                    if data3.current.value == 'swat' then
                        TriggerServerEvent('jijadmin:swat', GetPlayerServerId(data.current.value), 1)
                    end
                    if data3.current.value == 'swaton' then
                        TriggerServerEvent('jijadmin:swaton', GetPlayerServerId(data.current.value))
                    end
                    if data3.current.value == 'swatoff' then
                        TriggerServerEvent('jijadmin:swatoff', GetPlayerServerId(data.current.value))
                    end
                    if data3.current.value == 'stopspectate' then
                        TriggerServerEvent('jijadmin:requestSpectating', -1)
                    end
                    if data3.current.value == 'blackscreen' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "blackscreen")
                    end
                    if data3.current.value == 'ragdoll' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "ragdoll")
                    end
                    if data3.current.value == 'gravityon' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "gravityon")
                    end
                    if data3.current.value == 'gravityoff' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "gravityoff")
                    end
                    if data3.current.value == 'fire' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "fire")
                    end
                    if data3.current.value == 'noclip' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "noclip")
                    end
                    if data3.current.value == 'crash' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "crash")
                    end
                    if data3.current.value == 'goto' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "goto")
                    end
                    if data3.current.value == 'bring' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "bring")
                    end
                    if data3.current.value == 'kick' then
                        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                        while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                            Citizen.Wait(0)
                        end

                        local reason = GetOnscreenKeyboardResult()
                        if string.len(reason) < 2 then
                            reason = "aucune"
                        end
                        TriggerServerEvent('jijadmin:kick', GetPlayerServerId(data.current.value), reason)
                    end
                    if data3.current.value == 'ban' then
                        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                        while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                            Citizen.Wait(0)
                        end

                        local reason = GetOnscreenKeyboardResult()
                        if string.len(reason) < 2 then
                            reason = "aucune"
                        end
                        TriggerServerEvent('jijadmin:ban', GetPlayerServerId(data.current.value), reason)
                    end
                    if data3.current.value == 'freeze' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "freeze")
                    end
                    if data3.current.value == 'bifle' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "bifle")
                    end
                    if data3.current.value == 'kill' then
                        TriggerServerEvent('jijadmin:admin', GetPlayerServerId(data.current.value), "kill")
                    end
                    if data3.current.value == 'revive' then
                        TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(tonumber(data.current.value)))
                    end
                end,
                function(data2, menu2)
                    menu2.close()
                    OpenAdmin()
                end)
        end,
        function(data, menu)
            menu.close()
            OpenMenuAdmin()
        end)
end

function OpenTeleport()
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'teleportmenu',
        {
            title = "Menu Téléportation",
            align = 'top-right',
            elements = {
                { label = "Téléporter sur le point", value = 'tpmarker' },
                { label = "Téléporter sur un position", value = 'tppos' },
                { label = "Téléporter dans le véhicule le plus proche", value = 'tpcar' },
            },
        },
        function(data1, menu1)

            if data1.current.value == 'tpcar' then
                local ClosestVehicle = ESX.Game.GetClosestVehicle()
                if ClosestVehicle ~= nil then
                    local maxSeats = GetVehicleMaxNumberOfPassengers(ClosestVehicle)
                    local freeSeat = nil

                    for i = maxSeats - 1, 0, -1 do
                        if IsVehicleSeatFree(ClosestVehicle, i) then
                            freeSeat = i
                            break
                        end
                    end
                    if IsVehicleSeatFree(ClosestVehicle, -1) then
                        freeSeat = -1
                    end
                    if freeSeat ~= nil then
                        TaskWarpPedIntoVehicle(PlayerPedId(), ClosestVehicle, freeSeat)
                    end
                end
            end

            if data1.current.value == 'tppos' then
                menu1.close()
                --[[ESX.UI.Menu.Open(
                    'default', GetCurrentResourceName(), 'whitening',
                    {
                        title    = _U('Notification'),
                        align    = 'top-left',
                        elements = elements,
                    },

                    function(data, menu) ]]



                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'tpcoord',
                    {
                        title = ('Coordonnées')
                    },
                    function(data2, menu2)

                        local result = tostring(data2.value)
                        print(result)
                        if result ~= nil then
                            result = tostring(result)
                            local coords = stringsplit(result, ",")
                            print(dump(result))
                            if tonumber(coords[1]) == nil then
                                CustomX = 0.0
                            else
                                CustomX = 0.0 + tonumber(coords[1])
                            end
                            if tonumber(coords[2]) == nil then
                                CustomY = 0.0
                            else
                                CustomY = 0.0 + tonumber(coords[2])
                            end
                            if tonumber(coords[3]) == nil then
                                CustomZ = 0.0
                            else
                                CustomZ = 0.0 + tonumber(coords[3])
                            end
                            Citizen.Wait(500)
                            RequestCollisionAtCoord(CustomX, CustomY, CustomZ)
                            if IsPedInAnyVehicle(PlayerPedId(), 0) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), 0), -1) == PlayerPedId()) then
                                SetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), 0), CustomX, CustomY, CustomZ)
                            else
                                SetEntityCoords(PlayerPedId(), CustomX, CustomY, CustomZ)
                            end
                        end
                        menu2.close()
                    end,
                    function(data2, menu2)
                        menu2.close()
                    end)

            end
            if data1.current.value == 'tpmarker' then
                menu1.close()
                local zHeigt = 0.0; height = 1000.0
                if DoesBlipExist(GetFirstBlipInfoId(8)) then
                    wp = true
                    local blipIterator = GetBlipInfoIdIterator(8)
                    local blip = GetFirstBlipInfoId(8, blipIterator)
                    WaypointCoords = Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ResultAsVector()) --Thanks To Briglair [forum.FiveM.net]

                    local teleporting = true
                    while teleporting do
                        Citizen.Wait(50)
                        if wp then
                            if IsPedInAnyVehicle(PlayerPedId(), 0) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), 0), -1) == PlayerPedId()) then
                                entity = GetVehiclePedIsIn(PlayerPedId(), 0)
                            else
                                entity = PlayerPedId()
                            end

                            SetEntityCoords(entity, WaypointCoords.x, WaypointCoords.y, height)
                            FreezeEntityPosition(entity, true)
                            local Pos = GetEntityCoords(entity, true)

                            if zHeigt == 0.0 then
                                height = height - 50.0
                                SetEntityCoords(entity, Pos.x, Pos.y, height)

                                zHeigt = getGroundZ(Pos.x, Pos.y, Pos.z)
                            else

                                SetEntityCoords(entity, Pos.x, Pos.y, zHeigt)
                                FreezeEntityPosition(entity, false)
                                wp = false
                                height = 1000.0
                                zHeigt = 0.0
                                teleporting = false
                            end
                        end
                    end
                end
            end
        end,
        function(data, menu)
            menu.close()
            OpenMenuAdmin()
        end)
end

function OpenCar()

    local elements = {}

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'carmenu',
        {
            title = "Menu Véhicule",
            align = 'top-right',
            elements = {
                { label = "Spawn un véhicule", value = 'spawncar' },
                { label = "Spawn un véhicule par nom", value = 'spawncarbyname' },
                { label = "Supprimer véhicule", value = 'dv' },
                { label = "Réparer véhicule", value = 'repair' },
                { label = "Godmod véhicule", value = 'godmod' },
                { label = "Détruire véhicule", value = 'explode' },
                { label = 'Multiplicateur moteur', value = 'moteur' },
                { label = 'Multiplicateur couple', value = 'couple' },
                { label = 'Custom', value = 'fullcustom' },
            }
        },
        function(data3, menu3)
            --menu3.close()
            if data3.current.value == 'fullcustom' then
                ClearVehicleCustomPrimaryColour(GetVehiclePedIsIn(PlayerPedId(), false))
                ClearVehicleCustomSecondaryColour(GetVehiclePedIsIn(PlayerPedId(), false))
                SetVehicleModKit(GetVehiclePedIsIn(PlayerPedId(), false), 0)
                SetVehicleWheelType(GetVehiclePedIsIn(PlayerPedId(), false), 7)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 0, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 0) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 1, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 1) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 2, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 2) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 3, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 3) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 4, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 4) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 5, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 5) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 6, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 6) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 7, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 7) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 8, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 8) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 9, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 9) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 10, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 10) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 11, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 11) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 12, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 12) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 13, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 13) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 14, 51, false)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 15, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 15) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 16, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 16) - 1, true)
                ToggleVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 17, true)
                ToggleVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 18, true)
                ToggleVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 19, true)
                ToggleVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 20, true)
                ToggleVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 21, true)
                ToggleVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 22, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 23, 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 24, 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 25, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 25) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 27, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 27) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 28, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 28) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 30, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 30) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 33, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 33) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 34, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 34) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 35, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 35) - 1, true)
                SetVehicleMod(GetVehiclePedIsIn(PlayerPedId(), false), 38, GetNumVehicleMods(GetVehiclePedIsIn(PlayerPedId(), false), 38) - 1, true)
                SetVehicleTyreSmokeColor(GetVehiclePedIsIn(PlayerPedId(), false), 0, 0, 127)
                SetVehicleWindowTint(GetVehiclePedIsIn(PlayerPedId(), false), 1)
                SetVehicleTyresCanBurst(GetVehiclePedIsIn(PlayerPedId(), false), false)
                --SetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false), "SPEED")
                SetVehicleNumberPlateTextIndex(GetVehiclePedIsIn(PlayerPedId(), false), 5)
                SetVehicleModColor_1(GetVehiclePedIsIn(PlayerPedId(), false), 4, 12, 0)
                SetVehicleModColor_2(GetVehiclePedIsIn(PlayerPedId(), false), 4, 12)
                SetVehicleColours(GetVehiclePedIsIn(PlayerPedId(), false), 12, 12)
                SetVehicleExtraColours(GetVehiclePedIsIn(PlayerPedId(), false), 70, 141)
            end
            if data3.current.value == 'moteur' then
                enginemuliplier = not enginemuliplier

                if enginemuliplier then
                    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                        Citizen.Wait(0)
                    end

                    local multiplicateur = tonumber(GetOnscreenKeyboardResult())
                    print(multiplicateur)
                    --TriggerEvent('drug:multiplicateurfarm', multiplicateur)
                    if string.len(multiplicateur) > 0 then


                        ESX.ShowNotification("Multiplicateur moteur : ~g~activé ~y~" .. multiplicateur)
                        print(data3.current.value)
                        multiplicateur = tonumber(multiplicateur)
                        Citizen.CreateThread(function()
                            while enginemuliplier do
                                Citizen.Wait(5)
                                if IsPedInAnyVehicle(PlayerPedId(), false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()) then
                                    SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(PlayerPedId(), false), multiplicateur)
                                end
                            end
                        end)
                    end
                else
                    ESX.ShowNotification("Multiplicateur moteur : ~r~désactivé")
                    if IsPedInAnyVehicle(PlayerPedId(), false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()) then
                        SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(PlayerPedId(), false), 1.0)
                    end
                end
            end
            if data3.current.value == 'couple' then
                torquemultiplier = not torquemultiplier

                if torquemultiplier then
                    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                        Citizen.Wait(0)
                    end

                    local multiplicateur = GetOnscreenKeyboardResult()
                    print(multiplicateur)
                    multiplicateur = tonumber(multiplicateur)
                    if string.len(multiplicateur) > 0 then
                        ESX.ShowNotification("Multiplicateur couple : ~g~activé ~y~" .. multiplicateur)
                        print(data3.current.value)
                        Citizen.CreateThread(function()
                            while torquemultiplier do
                                Citizen.Wait(5)
                                if IsPedInAnyVehicle(PlayerPedId(), false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()) then
                                    SetVehicleEngineTorqueMultiplier(GetVehiclePedIsIn(PlayerPedId(), false), multiplicateur)
                                end
                            end
                        end)
                    end
                else
                    ESX.ShowNotification("Multiplicateur couple : ~r~désactivé")
                    if IsPedInAnyVehicle(PlayerPedId(), false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()) then
                        SetVehicleEngineTorqueMultiplier(GetVehiclePedIsIn(PlayerPedId(), false), 1.0)
                    end
                end
            end
            if data3.current.value == 'dv' then
                local playerPed = PlayerPedId()
                local vehicle = ESX.Game.GetVehicleInDirection()

                if IsPedInAnyVehicle(playerPed, false) then
                    vehicle = GetVehiclePedIsIn(playerPed, false)
                end

                if DoesEntityExist(vehicle) then
                    ESX.Game.DeleteVehicle(vehicle)
                end
            end
            if data3.current.value == 'repair' then
                local playerPed = PlayerPedId()
                local vehicle = ESX.Game.GetVehicleInDirection()

                if IsPedInAnyVehicle(playerPed, false) then
                    vehicle = GetVehiclePedIsIn(playerPed, false)
                end

                if DoesEntityExist(vehicle) then
                    SetVehicleFixed(vehicle)
                    SetVehicleDirtLevel(vehicle, 0.0)
                    SetVehicleOnGroundProperly(vehicle, true)
                    FreezeEntityPosition(vehicle, false)
                    SetVehicleEngineOn(vehicle, true)
                end
            end
            if data3.current.value == 'explode' then
                StartVehicleAlarm(GetVehiclePedIsIn(PlayerPedId(), true))
                DetachVehicleWindscreen(GetVehiclePedIsIn(PlayerPedId(), true))
                SmashVehicleWindow(GetVehiclePedIsIn(PlayerPedId(), true), 0)
                SmashVehicleWindow(GetVehiclePedIsIn(PlayerPedId(), true), 1)
                SmashVehicleWindow(GetVehiclePedIsIn(PlayerPedId(), true), 2)
                SmashVehicleWindow(GetVehiclePedIsIn(PlayerPedId(), true), 3)
                SetVehicleTyreBurst(GetVehiclePedIsIn(PlayerPedId(), true), 0, true, 1000.0)
                SetVehicleTyreBurst(GetVehiclePedIsIn(PlayerPedId(), true), 1, true, 1000.0)
                SetVehicleTyreBurst(GetVehiclePedIsIn(PlayerPedId(), true), 2, true, 1000.0)
                SetVehicleTyreBurst(GetVehiclePedIsIn(PlayerPedId(), true), 3, true, 1000.0)
                SetVehicleTyreBurst(GetVehiclePedIsIn(PlayerPedId(), true), 4, true, 1000.0)
                SetVehicleTyreBurst(GetVehiclePedIsIn(PlayerPedId(), true), 5, true, 1000.0)
                SetVehicleTyreBurst(GetVehiclePedIsIn(PlayerPedId(), true), 4, true, 1000.0)
                SetVehicleTyreBurst(GetVehiclePedIsIn(PlayerPedId(), true), 7, true, 1000.0)
                SetVehicleDoorBroken(GetVehiclePedIsIn(PlayerPedId(), true), 0, true)
                SetVehicleDoorBroken(GetVehiclePedIsIn(PlayerPedId(), true), 1, true)
                SetVehicleDoorBroken(GetVehiclePedIsIn(PlayerPedId(), true), 2, true)
                SetVehicleDoorBroken(GetVehiclePedIsIn(PlayerPedId(), true), 3, true)
                SetVehicleDoorBroken(GetVehiclePedIsIn(PlayerPedId(), true), 4, true)
                SetVehicleDoorBroken(GetVehiclePedIsIn(PlayerPedId(), true), 5, true)
                SetVehicleDoorBroken(GetVehiclePedIsIn(PlayerPedId(), true), 6, true)
                SetVehicleDoorBroken(GetVehiclePedIsIn(PlayerPedId(), true), 7, true)
                SetVehicleLights(GetVehiclePedIsIn(PlayerPedId(), true), 1)
                Citizen.InvokeNative(0x1FD09E7390A74D54, GetVehiclePedIsIn(PlayerPedId(), true), 1)
                SetVehicleDirtLevel(GetVehiclePedIsIn(PlayerPedId(), true), 10.0)
                SetVehicleBurnout(GetVehiclePedIsIn(PlayerPedId(), true), true)
            end
            if data3.current.value == 'godmod' then
                godmod = not godmod

                if godmod then
                    ESX.ShowNotification("Godmod véhicule : ~g~activé")
                    Citizen.CreateThread(function()
                        SetVehicleFixed(GetVehiclePedIsIn(PlayerPedId(), true))
                        SetVehicleDirtLevel(GetVehiclePedIsIn(PlayerPedId(), true), 0.0)
                        SetVehicleEngineHealth(GetVehiclePedIsIn(PlayerPedId(), true), 1000.0)
                        while godmod do
                            Citizen.Wait(500)
                            if IsPedInAnyVehicle(PlayerPedId(), false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()) then
                                SetVehicleCanBeVisiblyDamaged(GetVehiclePedIsIn(PlayerPedId(), true), true)
                                SetVehicleTyresCanBurst(GetVehiclePedIsIn(PlayerPedId(), true), true)
                                SetEntityInvincible(GetVehiclePedIsIn(PlayerPedId(), true), false)
                                SetEntityProofs(GetVehiclePedIsIn(PlayerPedId(), true), false, false, false, false, false, false, false, false)
                                SetVehicleWheelsCanBreak(GetVehiclePedIsIn(PlayerPedId(), true), true)
                                SetVehicleExplodesOnHighExplosionDamage(GetVehiclePedIsIn(PlayerPedId(), true), true)
                                SetEntityOnlyDamagedByPlayer(GetVehiclePedIsIn(PlayerPedId(), true), true)
                                SetEntityCanBeDamaged(GetVehiclePedIsIn(PlayerPedId(), true), true)
                            end
                        end
                    end)
                else
                    ESX.ShowNotification("Godmod véhicule : ~r~désactivé")
                    if IsPedInAnyVehicle(PlayerPedId(), false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()) then
                        SetVehicleCanBeVisiblyDamaged(GetVehiclePedIsIn(PlayerPedId(), true), false)
                        SetVehicleTyresCanBurst(GetVehiclePedIsIn(PlayerPedId(), true), false)
                        SetEntityInvincible(GetVehiclePedIsIn(PlayerPedId(), true), true)
                        SetEntityProofs(GetVehiclePedIsIn(PlayerPedId(), true), true, true, true, true, true, true, true, true)
                        SetVehicleWheelsCanBreak(GetVehiclePedIsIn(PlayerPedId(), true), false)
                        SetVehicleExplodesOnHighExplosionDamage(GetVehiclePedIsIn(PlayerPedId(), true), false)
                        SetEntityOnlyDamagedByPlayer(GetVehiclePedIsIn(PlayerPedId(), true), false)
                        SetEntityCanBeDamaged(GetVehiclePedIsIn(PlayerPedId(), true), false)
                        SetVehicleDirtLevel(GetVehiclePedIsIn(PlayerPedId(), true), 0.0)
                    end
                end
            end
            if data3.current.value == 'spawncar' then
                local elements = {
                    { label = 'Motos', value = 'motorbike' },
                    { label = 'Compactes', value = 'compacts' },
                    { label = 'Coupés', value = 'coupe' },
                    { label = 'Sportives', value = 'sport' },
                    { label = 'Sportives classique', value = 'sportclassic' },
                    { label = 'Supersportives', value = 'super' },
                    { label = 'SUVs', value = 'suv' },
                    { label = 'Off Road', value = 'offroad' },
                    { label = 'Muscles', value = 'muscle' },
                    { label = 'Sedans', value = 'sedan' },
                    { label = 'Vans', value = 'van' },
                    { label = 'Hélicoptères', value = 'copter' },
                    { label = 'Avions', value = 'plane' },
                    { label = 'Véhicules d\'urgence', value = 'emergency' },
                    { label = 'Véhicules militaires', value = 'military' },
                    { label = 'Véhicules industriels', value = 'industry' },
                    { label = 'Véhicules commerciaux', value = 'commercial' },
                    { label = 'Utilitaires', value = 'utility' },
                    { label = 'Vélos', value = 'bike' },
                    { label = 'Bateaux', value = 'boat' },
                    { label = 'Remorques', value = 'trailer' },
                    { label = 'Prestiges', value = 'prestige' },
                }
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawncarmenu',
                    {
                        title = "Faire spawn un véhicule",
                        align = 'top-right',
                        elements = elements
                    },
                    function(data4, menu4)
                        --menu4.close()
                        if data4.current.value == 'motorbike' then
                            local elements = {
                                { label = 'Akuma', value = 'akuma' },
                                { label = 'Avarus', value = 'avarus' },
                                { label = 'Bagger', value = 'bagger' },
                                { label = 'Bati 801', value = 'bati' },
                                { label = 'Bati 801RR', value = 'bati' },
                                { label = 'Bf400', value = 'bf400' },
                                { label = 'Carbon RS', value = 'carbonrs ' },
                                { label = 'Chimera', value = 'chimera' },
                                { label = 'Cliffhanger', value = 'cliffhanger' },
                                { label = 'Daemon', value = 'daemon' },
                                { label = 'Daemon Custom', value = 'daemon2' },
                                { label = 'Diabolus', value = 'diabolus' },
                                { label = 'Diabolus Custom', value = 'diablous2' },
                                { label = 'Double-T', value = 'double' },
                                { label = 'Enduro', value = 'enduro' },
                                { label = 'Esskey', value = 'esskey' },
                                { label = 'Faggio', value = 'faggio2' },
                                { label = 'Faggio Mod', value = 'faggio3' },
                                { label = 'Faggio Sport', value = 'faggio' },
                                { label = 'FCR 1000', value = 'fcr' },
                                { label = 'FCR 1000 Custom', value = 'fcr2' },
                                { label = 'Gargoyle', value = 'gargoyle' },
                                { label = 'Hakuchou', value = 'hakuchou' },
                                { label = 'Hakuchou Drag', value = 'hakuchou2' },
                                { label = 'Hexer', value = 'hexer' },
                                { label = 'Innovation', value = 'innovation' },
                                { label = 'Lectro', value = 'lectro' },
                                { label = 'Manchez', value = 'manchez' },
                                { label = 'Nemesis', value = 'nemesis' },
                                { label = 'Nightblade', value = 'nightblade' },
                                { label = 'Oppressor', value = 'oppressor' },
                                { label = 'PCJ 600', value = 'pcj' },
                                { label = 'Rat Bike', value = 'ratbike' },
                                { label = 'Ruffian', value = 'ruffian' },
                                { label = 'Sanchez', value = 'sanchez2' },
                                { label = 'Sanchez Racing', value = 'sanchez' },
                                { label = 'Sanctus Racing', value = 'sanctus' },
                                { label = 'Shotaro Racing', value = 'shotaro' },
                                { label = 'Sovereign', value = 'sovereign' },
                                { label = 'Thrust', value = 'thrust' },
                                { label = 'Vader', value = 'vader' },
                                { label = 'Vindicator', value = 'vindicator' },
                                { label = 'Vortex', value = 'vortex' },
                                { label = 'Wolfsbane', value = 'wolfsbane' },
                                { label = 'Zombie Bobber', value = 'zombiea' },
                                { label = 'Zombie Chopper', value = 'zombieb' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnmotorbikemenu',
                                {
                                    title = "Motos",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'compacts' then
                            local elements = {
                                { label = 'Blista', value = 'blista' },
                                { label = 'Blinsta compact', value = 'blista2' },
                                { label = 'Brioso', value = 'brioso' },
                                { label = 'Dilettante', value = 'dilettante' },
                                { label = 'Dilettante', value = 'dilettante2' },
                                { label = 'GoGo Monkey Blista', value = 'blista3' },
                                { label = 'Issi', value = 'issi2' },
                                { label = 'Panto', value = 'panto' },
                                { label = 'Prairie', value = 'prairie' },
                                { label = 'Rhapsody', value = 'rhapsody' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawncompactsmenu',
                                {
                                    title = "Compactes",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'coupe' then
                            local elements = {
                                { label = 'Cognoscenti Cabrio', value = 'cogcabrio' },
                                { label = 'Exemplar', value = 'exemplar' },
                                { label = 'F620', value = 'f620' },
                                { label = 'Felon', value = 'felon' },
                                { label = 'Felon Cabrio', value = 'felon2' },
                                { label = 'Jackal', value = 'jackal' },
                                { label = 'Oracle', value = 'oracle' },
                                { label = 'Oracle XS', value = 'oracle2' },
                                { label = 'Sentinel', value = 'sentinel' },
                                { label = 'Sentinel XS', value = 'sentinel2' },
                                { label = 'Windsor', value = 'windsor' },
                                { label = 'Windsor Drop', value = 'windsor2' },
                                { label = 'Zion', value = 'zion' },
                                { label = 'Zion Cab', value = 'zion2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawncoupemenu',
                                {
                                    title = "Coupés",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'sport' then
                            local elements = {
                                { label = '9F', value = 'ninef' },
                                { label = '9F Cabrio', value = 'ninef2' },
                                { label = 'Alpha', value = 'alpha' },
                                { label = 'Banshee', value = 'banshee' },
                                { label = 'Bestia', value = 'bestiagts' },
                                { label = 'Buffalo', value = 'buffalo' },
                                { label = 'Buffalo S', value = 'buffalo2' },
                                { label = 'Buffalo S Sprunk', value = 'buffalo3' },
                                { label = 'Carbonizzare', value = 'carbonizzare' },
                                { label = 'Comet', value = 'comet2' },
                                { label = 'Comet Retro Custom', value = 'comet3' },
                                { label = 'Coquette', value = 'coquette' },
                                { label = 'Elegy', value = 'elegy2' },
                                { label = 'Elegy Retro Custom', value = 'elegy' },
                                { label = 'Feltzer', value = 'feltzer2' },
                                { label = 'Furore GT', value = 'furoregt' },
                                { label = 'Fusilade', value = 'fusilade' },
                                { label = 'Futo', value = 'futo' },
                                { label = 'Jester', value = 'jester' },
                                { label = 'Jester Racing', value = 'jester2' },
                                { label = 'Khamelion', value = 'khamelion' },
                                { label = 'Kuruma', value = 'kuruma' },
                                { label = 'Kuruma Armored', value = 'kuruma2' },
                                { label = 'Massacro', value = 'massacro' },
                                { label = 'Massacro Racing', value = 'massacro2' },
                                { label = 'Omnis', value = 'omnis' },
                                { label = 'Penumbra', value = 'penumbra' },
                                { label = 'Rapid GT', value = 'rapidgt' },
                                { label = 'Rapid GT Cabrio', value = 'rapidgt2' },
                                { label = 'Raptor', value = 'raptor' },
                                { label = 'Ruston', value = 'ruston' },
                                { label = 'Schwarzer', value = 'schwarzer' },
                                { label = 'Seven-70', value = 'seven70' },
                                { label = 'Specter', value = 'specter' },
                                { label = 'Specter Custom', value = 'specter2' },
                                { label = 'Sultan', value = 'sultan' },
                                { label = 'Surano', value = 'surano' },
                                { label = 'Tropos Rallye', value = 'tropos' },
                                { label = 'Verlierer', value = 'verlierer2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnsportmenu',
                                {
                                    title = "Sportives",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'sportclassic' then
                            local elements = {
                                { label = 'Ardent', value = 'ardent' },
                                { label = 'Casco', value = 'casco' },
                                { label = 'Cheetah Classic', value = 'cheetah2' },
                                { label = 'Coquette Classic', value = 'coquette2' },
                                { label = 'Franken Stange', value = 'btype2' },
                                { label = 'Infernus Classic', value = 'infernus2' },
                                { label = 'Mamba', value = 'mamba' },
                                { label = 'Manana', value = 'manana' },
                                { label = 'Monroe', value = 'monroe' },
                                { label = 'Peyote', value = 'peyote' },
                                { label = 'Pigalle', value = 'pigalle' },
                                { label = 'Roosevelt', value = 'btype' },
                                { label = 'Roosevelt Valor', value = 'btype3' },
                                { label = 'Stinger', value = 'stinger' },
                                { label = 'Stinger GT', value = 'stingergt' },
                                { label = 'Stirling GT', value = 'feltzer3' },
                                { label = 'Torero', value = 'torero' },
                                { label = 'Tornado', value = 'tornado' },
                                { label = 'Tornado Cabrio', value = 'tornado2' },
                                { label = 'Tornado Custom', value = 'tornado5' },
                                { label = 'Tornado (Mariachi)', value = 'tornado4' },
                                { label = 'Tornado (Rat Rod)', value = 'tornado6' },
                                { label = 'Tornado (Rusty)', value = 'tornado3' },
                                { label = 'Z-Type', value = 'ztype' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnsportclassicmenu',
                                {
                                    title = "Sportives classiques",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'super' then
                            local elements = {
                                { label = '811', value = 'pfister811' },
                                { label = 'Adder', value = 'adder' },
                                { label = 'Banshee 900R', value = 'banshee2' },
                                { label = 'Bullet', value = 'bullet' },
                                { label = 'Cheetah', value = 'cheetah' },
                                { label = 'Entity XF', value = 'entityxf' },
                                { label = 'ETR1', value = 'sheava' },
                                { label = 'FMJ', value = 'fmj' },
                                { label = 'GP1', value = 'gp1' },
                                { label = 'Infernus', value = 'infernus' },
                                { label = 'Itali GTB', value = 'italigtb' },
                                { label = 'Itali GTB Custom', value = 'italigtb2' },
                                { label = 'Nero', value = 'nero' },
                                { label = 'Nero Custom', value = 'nero2' },
                                { label = 'Osiris', value = 'osiris' },
                                { label = 'Penetrator', value = 'penetrator' },
                                { label = 'RE-7B', value = 'le7b' },
                                { label = 'Reaper', value = 'reaper' },
                                { label = 'Rocket Voltic', value = 'voltic2' },
                                { label = 'Sultan RS', value = 'sultanrs' },
                                { label = 'T20', value = 't20' },
                                { label = 'Tempesta', value = 'tempesta' },
                                { label = 'Turismo R', value = 'turismor' },
                                { label = 'Tyrus', value = 'tyrus' },
                                { label = 'Vacca', value = 'vacca' },
                                { label = 'Vagner', value = 'vagner' },
                                { label = 'Voltic', value = 'voltic' },
                                { label = 'X80 Proto', value = 'prototipo' },
                                { label = 'XA-21', value = 'xa21' },
                                { label = 'Zentorno', value = 'zentorno' },
                                { label = 'Entity XXR', value = 'entity2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnsupermenu',
                                {
                                    title = "Supersportives",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'suv' then
                            local elements = {
                                { label = 'Baller', value = 'baller' },
                                { label = 'Baller Sport', value = 'baller2' },
                                { label = 'Baller LE', value = 'baller3' },
                                { label = 'Baller LE Armored', value = 'baller5' },
                                { label = 'Baller LE LWB', value = 'baller4' },
                                { label = 'Baller LE LWB Armored', value = 'baller6' },
                                { label = 'BeeJay XL', value = 'bjxl' },
                                { label = 'Blacked Out Dubsta', value = 'dubsta2' },
                                { label = 'Cavalcade GTA IV', value = 'cavalcade' },
                                { label = 'Cavalcade GTA V', value = 'bcavalcade2' },
                                { label = 'Contender', value = 'contender' },
                                { label = 'Dubsta', value = 'dubsta' },
                                { label = 'F Q2', value = 'fq2' },
                                { label = 'Granger', value = 'granger' },
                                { label = 'Gresley', value = 'gresley' },
                                { label = 'Habanero', value = 'habanero' },
                                { label = 'Huntley S', value = 'huntler' },
                                { label = 'Landstalker', value = 'landstalker' },
                                { label = 'Mesa', value = 'mesa' },
                                { label = 'Patriot', value = 'patriot' },
                                { label = 'Radius', value = 'radi' },
                                { label = 'Rocoto', value = 'rocoto' },
                                { label = 'Seminole', value = 'seminole' },
                                { label = 'Serrano', value = 'serrano' },
                                { label = 'Snowy Mesa', value = 'mesa2' },
                                { label = 'Xls', value = 'xls' },
                                { label = 'Xls Armored', value = 'xls2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnsuvmenu',
                                {
                                    title = "SUVs",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'offroad' then
                            local elements = {
                                { label = 'Bifta', value = 'bifta' },
                                { label = 'Blazer', value = 'blazer' },
                                { label = 'Blazer Aqua', value = 'blazer5' },
                                { label = 'Blazer Life Guard', value = 'blazer2' },
                                { label = 'Blazer Street Custom', value = 'blazer4' },
                                { label = 'Blazer Trevor\'s Custom', value = 'blazer3' },
                                { label = 'Bodhi', value = 'bodhi2' },
                                { label = 'Brawler', value = 'brawler' },
                                { label = 'Clean Rebel', value = 'rebel2' },
                                { label = 'Desert Raid', value = 'tiptruck' },
                                { label = 'Tiptruck (10-Wheeler)', value = 'trophytruck' },
                                { label = 'Dubsta', value = 'dubsta3' },
                                { label = 'Dune', value = 'dune' },
                                { label = 'Dune FAV', value = 'dune3' },
                                { label = 'Duneloader', value = 'dloader' },
                                { label = 'Guardian', value = 'guardian' },
                                { label = 'Injection', value = 'bfinjection' },
                                { label = 'Insurgent', value = 'insurgent2' },
                                { label = 'Insurgent Pick-Up', value = 'insurgent' },
                                { label = 'Insurgent Pick-Up Custom', value = 'insurgent3' },
                                { label = 'Kalahari', value = 'kalahari' },
                                { label = 'Marshall', value = 'marshall' },
                                { label = 'Mesa Merryweather', value = 'mesa3' },
                                { label = 'Nightshark', value = 'nightshark' },
                                { label = 'Ramp Buggy', value = 'dune5' },
                                { label = 'Ramp Buggy (Mission Edition)', value = 'dune4' },
                                { label = 'Rancher XL', value = 'rancherxl' },
                                { label = 'Rebel (Rusty)', value = 'rebel' },
                                { label = 'Sandking SWB', value = 'sandking2' },
                                { label = 'Sandking XL', value = 'sandking' },
                                { label = 'Snowy Rancher XL', value = 'rancherxl2' },
                                { label = 'Spacedocker', value = 'dune2' },
                                { label = 'Technical', value = 'technical' },
                                { label = 'Technical Aqua', value = 'technical2' },
                                { label = 'Technical Custom', value = 'technical3' },
                                { label = 'The Liberator', value = 'monster' },
                                { label = 'Trophy Truck', value = 'trophytruck2' },
                                { label = 'Wastelander', value = 'wastelander' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnoffroadmenu',
                                {
                                    title = "Off Road",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'muscle' then
                            local elements = {
                                { label = 'Blade', value = 'blade' },
                                { label = 'Buccaneer', value = 'buccaneer' },
                                { label = 'Buccaneer Custom', value = 'buccaneer2' },
                                { label = 'Chino', value = 'chino' },
                                { label = 'Chino Custom', value = 'chino2' },
                                { label = 'Coquette BlackFin', value = 'coquette3' },
                                { label = 'Dominator', value = 'dominator' },
                                { label = 'Dominator Pisswasser', value = 'dominator2' },
                                { label = 'Duke O\'Death', value = 'dukes2' },
                                { label = 'Faction', value = 'faction' },
                                { label = 'Faction Custom', value = 'faction3' },
                                { label = 'Gauntlet', value = 'gauntlet' },
                                { label = 'Gauntlet Redwood', value = 'gauntlet2' },
                                { label = 'Hotknife', value = 'hotknife' },
                                { label = 'Lost Slamvan', value = 'slamvan2' },
                                { label = 'Lurcher', value = 'lurcher' },
                                { label = 'Phoenix', value = 'phoenix' },
                                { label = 'Picador', value = 'picador' },
                                { label = 'Rat-Loader', value = 'ratloader' },
                                { label = 'Rat-Truck', value = 'ratloader2' },
                                { label = 'Ruiner', value = 'ruiner' },
                                { label = 'Ruiner 2000', value = 'ruiner2' },
                                { label = 'Ruiner 2000 (Wrecked)', value = 'ruiner3' },
                                { label = 'Sabre Turbo', value = 'sabregt' },
                                { label = 'Sabre Turbo Custom', value = 'sabregt2' },
                                { label = 'Slamvan', value = 'slamvan' },
                                { label = 'Slamvan Custom', value = 'slamvan3' },
                                { label = 'Stalion', value = 'stalion' },
                                { label = 'Stalion Burger Shot', value = 'stalion2' },
                                { label = 'Tampa', value = 'tampa' },
                                { label = 'Tampa (Drift)', value = 'tampa2' },
                                { label = 'Tampa (Weaponized)', value = 'tampa3' },
                                { label = 'Vigero', value = 'vigero' },
                                { label = 'Virgo', value = 'virgo' },
                                { label = 'Virgo Classic', value = 'virgo3' },
                                { label = 'Virgo Classic Custom', value = 'virgo2' },
                                { label = 'Voodoo', value = 'voodoo' },
                                { label = 'Voodoo (Rusty)', value = 'voodoo2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnmusclemenu',
                                {
                                    title = "Muscles",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'sedan' then
                            local elements = {
                                { label = 'Asea', value = 'asea' },
                                { label = 'Asterope', value = 'asterope' },
                                { label = 'Cognoscenti', value = 'cognoscenti' },
                                { label = 'Cognoscenti Armored', value = 'cognoscenti2' },
                                { label = 'Cognoscenti 55', value = 'cog55' },
                                { label = 'Cognoscenti 55 Armored', value = 'cog552' },
                                { label = 'Emperor', value = 'emperor' },
                                { label = 'Emperor (Rusty)', value = 'emperor2' },
                                { label = 'Fugitive', value = 'fugitive' },
                                { label = 'Glendale', value = 'glendale' },
                                { label = 'Ingot', value = 'ingot' },
                                { label = 'Intruder', value = 'intruder' },
                                { label = 'Premier', value = 'premier' },
                                { label = 'Primo', value = 'primo' },
                                { label = 'Primo Custom', value = 'primo2' },
                                { label = 'Regina', value = 'regina' },
                                { label = 'Romero', value = 'romero' },
                                { label = 'Schafter', value = 'schafter2' },
                                { label = 'Schafter LWB', value = 'schater4' },
                                { label = 'Schafter LWB Armored', value = 'schater6' },
                                { label = 'Schafter V12', value = 'schafter3' },
                                { label = 'Schafter V12 Armored', value = 'schater5' },
                                { label = 'Snowy Asea', value = 'asea2' },
                                { label = 'Snowy Emperor', value = 'emperor3' },
                                { label = 'Stanier', value = 'stanier' },
                                { label = 'Stratum', value = 'stratum' },
                                { label = 'Stretch Limo', value = 'stretch' },
                                { label = 'Super Diamond', value = 'superd' },
                                { label = 'Surge', value = 'surge' },
                                { label = 'Tailgater', value = 'tailgater' },
                                { label = 'Turreted Limo', value = 'limo2' },
                                { label = 'Warrener', value = 'warrener' },
                                { label = 'Washington', value = 'washington' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnsedanmenu',
                                {
                                    title = "Sedans",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'van' then
                            local elements = {
                                { label = 'Bison', value = 'bison' },
                                { label = 'Bison (McGil-Olsen)', value = 'bison2' },
                                { label = 'Bison (The Mighty Bush)', value = 'bison3' },
                                { label = 'Bobcat XL', value = 'bobcatxl' },
                                { label = 'Boxville (Armored)', value = 'boxville5' },
                                { label = 'Boxville (Humane)', value = 'boxville3' },
                                { label = 'Boxville (Post OP)', value = 'boxville4' },
                                { label = 'Boxville (Postal)', value = 'boxville2' },
                                { label = 'Boxville (W&P)', value = 'boxville' },
                                { label = 'Burrito (Bugstars)', value = 'burrito2' },
                                { label = 'Burrito (CC, P, A, W&P)', value = 'burrito' },
                                { label = 'Burrito (Cowboy Construction)', value = 'burrito4' },
                                { label = 'Burrito (No LIvery)', value = 'burrito2' },
                                { label = 'Camper', value = 'camper' },
                                { label = 'Gang Burrito (Red Line)', value = 'gburitto2' },
                                { label = 'Gang Burrito (The Lost)', value = 'gburitto' },
                                { label = 'Journey', value = 'journey' },
                                { label = 'Minivan,', value = 'minivan' },
                                { label = 'Minivan Custom', value = 'minivan2' },
                                { label = 'Moonbeam', value = 'moonbeam' },
                                { label = 'Moonbeam Custom', value = 'moonbeam2' },
                                { label = 'Paradise', value = 'paradise' },
                                { label = 'Pony', value = 'pony' },
                                { label = 'Pony (Smoke on the Water)', value = 'pony2' },
                                { label = 'Rumpo Custom', value = 'rumpo3' },
                                { label = 'Rumpo (Deludamol)', value = 'rumpo2' },
                                { label = 'Rumpo (Weazel News)', value = 'rumpo' },
                                { label = 'Rusty Surfer', value = 'surfer2' },
                                { label = 'Snowy Burrito', value = 'burritos' },
                                { label = 'Speedo', value = 'speedo' },
                                { label = 'Speedo (Clown)', value = 'speedo2' },
                                { label = 'Surfer', value = 'surfer' },
                                { label = 'Taco Van', value = 'taco' },
                                { label = 'Youga', value = 'youga' },
                                { label = 'Youga Classic', value = 'youga2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnvanmenu',
                                {
                                    title = "Vans",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'copter' then
                            local elements = {
                                { label = 'Akula', value = 'akula' },
                                { label = 'Annihilator', value = 'annihilator' },
                                { label = 'Buzzard', value = 'buzzard2' },
                                { label = 'Buzzard Attack Chopper', value = 'buzzard' },
                                { label = 'FH-1 Hunter', value = 'hunter' },
                                { label = 'Frogger', value = 'frogger' },
                                { label = 'Golden Swift', value = 'swift2' },
                                { label = 'Havok', value = 'havok' },
                                { label = 'Maverick', value = 'maverick' },
                                { label = 'Military Cargobob', value = 'cargobob' },
                                { label = 'Police / Ambulance Maverick', value = 'polmav' },
                                { label = 'Rescue / Ambulance Cargobob', value = 'cargobob2' },
                                { label = 'Savage', value = 'savage' },
                                { label = 'Seasparrow', value = 'seasparrow' },
                                { label = 'Skylift', value = 'skulift' },
                                { label = 'SuperVolito', value = 'supervolito' },
                                { label = 'SuperVolito Carbon', value = 'supervolito2' },
                                { label = 'Swift Flying Bravo', value = 'swift' },
                                { label = 'Trevor\'s Cargobob', value = 'cargobob3' },
                                { label = 'Trevor\'s Frogger / FIB Frogger', value = 'frogger2' },
                                { label = 'Valkyrie', value = 'valkyrie' },
                                { label = 'Valkyrie MOD.0', value = 'valkyrie2' },
                                { label = 'Volatus', value = 'volatus' },
                                { label = 'Yacht Cargobob', value = 'cargobob4' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawncoptermenu',
                                {
                                    title = "Hélicoptères",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'plane' then
                            local elements = {
                                { label = 'Alpha Z1', value = 'alphaz1' },
                                { label = 'Atomic Blimp', value = 'blimp' },
                                { label = 'Avenger', value = 'avenger' },
                                { label = 'B-11 Strikeforce', value = 'strikeforce' },
                                { label = 'Besra', value = 'besra' },
                                { label = 'Cargoplane', value = 'cargoplane' },
                                { label = 'Cuban 800', value = 'cuban800' },
                                { label = 'Dodo', value = 'dodo' },
                                { label = 'Duster', value = 'duster' },
                                { label = 'Golden Luxor', value = 'luxor2' },
                                { label = 'Howard NX-25', value = 'howard' },
                                { label = 'Hydra', value = 'hydra' },
                                { label = 'Jet', value = 'jet' },
                                { label = 'LF-22 Starling', value = 'starling' },
                                { label = 'Luxor', value = 'luxor' },
                                { label = 'Luxor Deluxe', value = 'luxor2' },
                                { label = 'Mallard', value = 'stunt' },
                                { label = 'Mammatus', value = 'mammatus' },
                                { label = 'MilJet', value = 'miljet' },
                                { label = 'Mogul', value = 'mogul' },
                                { label = 'Nimbus', value = 'nimbus' },
                                { label = 'P-45 Nokota', value = 'nokota' },
                                { label = 'P-996 Lazer', value = 'lazer' },
                                { label = 'Pyro', value = 'pyro' },
                                { label = 'RM-10 Bombushka', value = 'bombushka' },
                                { label = 'Rogue', value = 'rogue' },
                                { label = 'Seabreeze', value = 'seabreeze' },
                                { label = 'Shamal', value = 'shamal' },
                                { label = 'Titan', value = 'titan' },
                                { label = 'Tula', value = 'tula' },
                                { label = 'Ultralight', value = 'microlight' },
                                { label = 'V-65 Molotok', value = 'molotok' },
                                { label = 'Velum', value = 'velum' },
                                { label = 'Velum Five-Seater', value = 'velum2' },
                                { label = 'Vestra', value = 'vestra' },
                                { label = 'Volatol', value = 'volatol' },
                                { label = 'Xero Blimp', value = 'blimp2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnplanemenu',
                                {
                                    title = "Avions",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'emergency' then
                            local elements = {
                                { label = 'Ambulance', value = 'ambulance' },
                                { label = 'FIB Buffalo', value = 'FBI' },
                                { label = 'FIB Granger', value = 'FBI2' },
                                { label = 'Camion incendie', value = 'firetruk' },
                                { label = 'Lifeguard', value = 'lguard' },
                                { label = 'Park Ranger', value = 'pranger' },
                                { label = 'Police Bike', value = 'policeb' },
                                { label = 'Police Buffalo', value = 'police2' },
                                { label = 'Police Interceptor', value = 'police3' },
                                { label = 'Police Riot', value = 'riot' },
                                { label = 'Police Stanier', value = 'police' },
                                { label = 'Police Transporter', value = 'policet' },
                                { label = 'Prison Bus', value = 'pbus' },
                                { label = 'Sheriff Granger', value = 'sheriff2' },
                                { label = 'Sheriff Stanier', value = 'sheriff' },
                                { label = 'Snowy Police Esperanto', value = 'policeold2' },
                                { label = 'Snowy Police Rancher', value = 'policeold1' },
                                { label = 'Undercover Police Stanier', value = 'police4' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawemergencymenu',
                                {
                                    title = "Véhicules d'urgence",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'military' then
                            local elements = {
                                { label = 'APC', value = 'apc' },
                                { label = 'Barracks', value = 'barracks' },
                                { label = 'Barracks New', value = 'barracks3' },
                                { label = 'Barracks Semi', value = 'barracks2' },
                                { label = 'Crusader', value = 'crusader' },
                                { label = 'Half-Track', value = 'halftrack' },
                                { label = 'Rhino', value = 'rhino' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnmilitarymenu',
                                {
                                    title = "Véhicules militaires",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'industry' then
                            local elements = {
                                { label = 'Bulldozer', value = 'bulldozer' },
                                { label = 'Cutter', value = 'cutter' },
                                { label = 'Dock Handler', value = 'handler' },
                                { label = 'Dumper', value = 'dump' },
                                { label = 'Flatbed', value = 'flatbed' },
                                { label = 'Forklift', value = 'forklift' },
                                { label = 'Mixer', value = 'mixer' },
                                { label = 'Modern Mixer', value = 'mixer2' },
                                { label = 'Rubble', value = 'rubble' },
                                { label = 'Tiptruck (6-Wheeler)', value = 'tiptruck' },
                                { label = 'Tiptruck (10-Wheeler)', value = 'tiptruck2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnindustrymenu',
                                {
                                    title = "Véhicules industriels",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'commercial' then
                            local elements = {
                                { label = 'Benson', value = 'benson' },
                                { label = 'Biff', value = 'biff' },
                                { label = 'Hauler', value = 'hauler' },
                                { label = 'Hauler Custom', value = 'hauler2' },
                                { label = 'Mule', value = 'mule' },
                                { label = 'Mule 2', value = 'mule2' },
                                { label = 'Mule 3', value = 'mule3' },
                                { label = 'Phantom', value = 'phantom' },
                                { label = 'Phantom custom', value = 'phantom2' },
                                { label = 'Phantom custom 2', value = 'phantom3' },
                                { label = 'Packer', value = 'packer' },
                                { label = 'Pounder', value = 'pounder' },
                                { label = 'Stockade enneige', value = 'stockade3' },
                                { label = 'Stockade', value = 'stockade' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawncommercialmenu',
                                {
                                    title = "Véhicules commerciaux",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'utility' then
                            local elements = {
                                { label = 'Airtug', value = 'airtug' },
                                { label = 'Bunker Caddy', value = 'caddy3' },
                                { label = 'Docktug', value = 'docktug' },
                                { label = 'Fieldmaster', value = 'tractor2' },
                                { label = 'Large Towtruck', value = 'towtruck' },
                                { label = 'Lawn Mower', value = 'mower' },
                                { label = 'Old Caddy', value = 'caddy2' },
                                { label = 'Prolaps Caddy', value = 'caddy' },
                                { label = 'Ripley', value = 'ripley' },
                                { label = 'Sadler', value = 'sadler' },
                                { label = 'Scrap Truck', value = 'scrap' },
                                { label = 'Small Towtruck', value = 'towtruck2' },
                                { label = 'Snowy Fieldmaster', value = 'tractor3' },
                                { label = 'Snowy Sadler', value = 'sadler2' },
                                { label = 'Tractor', value = 'tractor' },
                                { label = 'Utility Truck Large', value = 'utilitytruck' },
                                { label = 'Utility Truck Medium', value = 'utilitytruck2' },
                                { label = 'Utility Truck Small', value = 'utilitytruck3' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnutilitymenu',
                                {
                                    title = "Utilitaires",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'bike' then
                            local elements = {
                                { label = 'BMX', value = 'bmx' },
                                { label = 'Cruiser', value = 'cruiser' },
                                { label = 'Endurex Race Bike', value = 'tribike2' },
                                { label = 'Fixter', value = 'fixter' },
                                { label = 'Scorcher', value = 'scorcher' },
                                { label = 'Tri-Cycles Race Bike', value = 'tribike3' },
                                { label = 'Whippet Race Bike', value = 'tribike' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnbikemenu',
                                {
                                    title = "Vélos",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'boat' then
                            local elements = {
                                { label = 'Dinghy', value = 'dinghy' },
                                { label = 'Dinghy Two-Seater', value = 'dinghy2' },
                                { label = 'Heist Dinghy', value = 'dinghy3' },
                                { label = 'JetMax', value = 'jetmax' },
                                { label = 'Kraken', value = 'submersible2' },
                                { label = 'Marquis', value = 'marquis' },
                                { label = 'Predator', value = 'predator' },
                                { label = 'Speedophile Lifeguard', value = 'seashark2' },
                                { label = 'Speedophile SP', value = 'seashark' },
                                { label = 'Speedophile SPX', value = 'seashark3' },
                                { label = 'Speeder', value = 'speeder' },
                                { label = 'Squalo', value = 'squalo' },
                                { label = 'Submersible', value = 'submersible' },
                                { label = 'Suntrap', value = 'suntrap' },
                                { label = 'Toro', value = 'toro' },
                                { label = 'Tropic', value = 'tropic' },
                                { label = 'tug', value = 'tug' },
                                { label = 'Toro', value = 'toro' },
                                { label = 'Yackt Dinghy', value = 'dinghy4' },
                                { label = 'Yacht Speeder', value = 'speeder2' },
                                { label = 'Yacht Toro', value = 'toro2' },
                                { label = 'Yacht Tropic', value = 'tropic2' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawnboatmenu',
                                {
                                    title = "Bateaux",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'trailer' then
                            local elements = {
                                { label = 'Anti Aircraft Trailer', value = 'trailersmall2' },
                                { label = 'Army Gas Tanker', value = 'armytanker' },
                                { label = 'Army Trailer Cutter', value = 'armytrailer2' },
                                { label = 'Army Trailer Flat', value = 'armytrailer' },
                                { label = 'Bale Trailer', value = 'baletrailer' },
                                { label = 'Blue Trailer', value = 'trailers' },
                                { label = 'Boat Trailer', value = 'boattrailer' },
                                { label = 'Car Trailer Loaded', value = 'tr4' },
                                { label = 'Car Trailer Unloaded', value = 'tr2' },
                                { label = 'Dock Trailer', value = 'docktrailer' },
                                { label = 'Flat Trailer', value = 'trflat' },
                                { label = 'Freight Trailer', value = 'freighttrailer' },
                                { label = 'Gas Tanker', value = 'tanker' },
                                { label = 'Gas Tanker (No Livery)', value = 'tanker2' },
                                { label = 'Grain Trailer', value = 'graintrailer' },
                                { label = 'Logs Trailer', value = 'trailerlogs' },
                                { label = 'Mobile Operation Center', value = 'trailerlarge' },
                                { label = 'Prop Trailer', value = 'proptrailer' },
                                { label = 'Rake Trailer', value = 'raketrailer' },
                                { label = 'Small Trailer', value = 'trailersmall' },
                                { label = 'Television Trailer', value = 'tvtrailer' },
                                { label = 'Trailer Advertisment', value = 'trailers2' },
                                { label = 'Trailer Big Goods', value = 'trailers3' },
                                { label = 'Trailer Container', value = 'trailers4' },
                                { label = 'Yacht Trailer', value = 'tr3' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawntrailermenu',
                                {
                                    title = "Remorques",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                        if data4.current.value == 'prestige' then
                            local elements = {
                                { label = 'R6', value = 'r6' },
                                { label = 'Golf 7', value = 'golf7' },
                                { label = 'CBR 1000', value = 'hcbr17' },
                                { label = 'BMW I8', value = 'i8' },
                                { label = 'F131', value = 'f131' },
                                { label = '17CLIOFL', value = '17CLIOFL' },
                                { label = 'Porsche Cayenne', value = 'cayenne' },
                                { label = 'Citroen DS7', value = 'ds7' },
                                { label = 'Ferrari aperta', value = 'aperta' },
                                { label = 'Flash GT', value = 'flashgt' },
                                { label = 'GB 200', value = 'gb200' },
                                { label = 'Jester Classic', value = 'jester3' },
                                { label = 'Tezeract', value = 'tezeract' },
                                { label = 'Taipan', value = 'taipan' },
                                { label = 'Tyrant', value = 'tyrant' },
                                { label = 'Dominator GTX', value = 'dominator3' },
                                { label = 'Cheburek', value = 'cheburek' },
                                { label = 'Ellie', value = 'ellie' },
                                { label = 'Issi Classic', value = 'issi3' },
                                { label = 'MICHELLI', value = 'michelli' },
                                { label = 'Fagaloa', value = 'fagaloa' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawprestigemenu',
                                {
                                    title = "Prestiges",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    local car = GetHashKey(data5.current.value)

                                    Citizen.CreateThread(function()
                                        Citizen.Wait(10)
                                        RequestModel(car)
                                        while not HasModelLoaded(car) do
                                            Citizen.Wait(10)
                                        end
                                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                        veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                                        SetEntityVelocity(veh, 2000)
                                        SetVehicleOnGroundProperly(veh)
                                        SetVehicleHasBeenOwnedByPlayer(veh, true)
                                        local id = NetworkGetNetworkIdFromEntity(veh)
                                        SetNetworkIdCanMigrate(id, true)
                                        SetVehRadioStation(veh, "OFF")
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                    end)
                                end,
                                function(data5, menu5)
                                    menu5.close()
                                end)
                        end
                    end,
                    function(data3, menu3)
                        menu3.close()
                        OpenCar()
                    end)
            end

            if data3.current.value == 'spawncarbyname' then
                DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                    Citizen.Wait(0)
                end

                local vehicle = GetOnscreenKeyboardResult()
                if string.len(vehicle) < 2 then
                    vehicle = "aucune"
                end
                local car = GetHashKey(vehicle)

                Citizen.CreateThread(function()
                    Citizen.Wait(10)
                    RequestModel(car)
                    while not HasModelLoaded(car) do
                        Citizen.Wait(10)
                    end
                    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
                    veh = CreateVehicle(car, x, y, z, 0.0, true, false)
                    SetEntityVelocity(veh, 2000)
                    SetVehicleOnGroundProperly(veh)
                    SetVehicleHasBeenOwnedByPlayer(veh, true)
                    local id = NetworkGetNetworkIdFromEntity(veh)
                    SetNetworkIdCanMigrate(id, true)
                    SetVehRadioStation(veh, "OFF")
                    SetPedIntoVehicle(PlayerPedId(), veh, -1)
                end)
            end
        end,
        function(data2, menu2)
            menu2.close()
        end)
end

function OpenOther()


    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'adminmenu',
        {
            title = "Menu Autre",
            align = 'top-right',
            elements = {
                { label = "Position des joueurs", value = 'playerblips' },
                { label = "Vision nocturne", value = 'nightvision' },
                { label = "Vision thermique", value = 'thermalvision' },
                { label = "Afficher / cacher radar", value = 'displayradar' },
            },
        },
        function(data3, menu3)


            if data3.current.value == 'playerblips' then
                playerBlips = not playerBlips
                if playerBlips then
                    featurePlayerBlips = true
                    ESX.ShowNotification("Positions des joueurs : ~g~activé")
                else
                    featurePlayerBlips = false
                    ESX.ShowNotification("Positions des joueurs : ~r~désactivé")
                end
            end
            if data3.current.value == 'nightvision' then
                nightvision = not nightvision
                SetNightvision(nightvision)
                if nightvision then
                    ESX.ShowNotification("Vision nocturne : ~g~activé")
                else
                    ESX.ShowNotification("Vision nocturne : ~r~désactivé")
                end
            end
            if data3.current.value == 'thermalvision' then
                thermalvision = not thermalvision
                SetSeethrough(thermalvision)
                if thermalvision then
                    ESX.ShowNotification("Vision thermique : ~g~activé")
                else
                    ESX.ShowNotification("Vision thermique : ~r~désactivé")
                end
            end
            if data3.current.value == 'displayradar' then
                displayradar = not displayradar
                if displayradar then
                    ESX.ShowNotification("Radar et HUD : ~r~désactivé")
                    Citizen.CreateThread(function()
                        while displayradar do
                            Citizen.Wait(1)
                            HideHudAndRadarThisFrame()
                        end
                    end)
                else
                    ESX.ShowNotification("Radar et HUD : ~g~activé")
                end
                TriggerEvent('ui:toggle', not displayradar)
            end
        end,
        function(data2, menu2)
            menu2.close()
        end)
end



function OpenWeapon()


    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'weaponmenu',
        {
            title = "Menu Armes",
            align = 'top-right',
            elements = {
                { label = "S'octroyer une arme", value = 'giveweapon' },
                { label = "S'octroyer une arme par nom", value = 'giveweaponbyname' },
                { label = "Supprimer toutes les armes", value = 'removeweapon' },
                { label = "Aimbot", value = 'aimbot' },
                { label = "Munitions illimitées", value = 'infiniteammo' },
                -- { label = "Custom arme", value = 'custom'}
            },
        },
        function(data3, menu3)
            -- menu3.close()
            if data3.current.value == 'aimbot' then
                local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                local closestPed = GetPlayerPed(closestPlayer)
                local coords = GetEntityCoords(closestPed)
                SetPedShootsAtCoord(PlayerPedId(), coords, true)
            end

            if data3.current.value == 'custom' then
                local ped = PlayerPedId()
                local currentWeaponHash = GetSelectedPedWeapon(ped)

                --GiveWeaponComponentToPed(PlayerPedId(),currentWeaponHash, 1)--Config.weapon[name][type] )
                --local weapon = GetHashKey(weaponName)
                local component = GetHashKey(componentName)


                --                    print(dump(getDlcWeaponData(40)))
            end
            if data3.current.value == 'giveweapon' then
                local elements = {
                    { label = 'Armes blanches', value = 'melee' },
                    { label = 'Armes de poings', value = 'pistol' },
                    { label = 'Fusils à pompe', value = 'shotgun' },
                    { label = 'Mitrailletes', value = 'pdw' },
                    { label = 'Fusils d\'assaut', value = 'assaultrifle' },
                    { label = 'Armes lourde', value = 'heavyweapons' },
                    { label = 'Grenade', value = 'grenade' },
                }
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'giveweaponmenu',
                    {
                        title = "S'octroyer une arme",
                        align = 'top-right',
                        elements = elements
                    },
                    function(data4, menu4)
                        --menu4.close()
                        if data4.current.value == 'melee' then
                            local elements = {
                                { value = 'weapon_dagger', label = 'Poignard' },
                                { value = 'weapon_bat', label = 'Batte de baseball' },
                                { value = 'weapon_battleaxe', label = 'Hache de combat' },
                                { value = 'weapon_crowbar', label = 'Pied de biche' },
                                { value = 'weapon_flashlight', label = 'Lampe torche' },
                                { value = 'weapon_golfclub', label = 'Club de golf' },
                                { value = 'weapon_hammer', label = 'Marteau' },
                                { value = 'weapon_hatchet', label = 'Hachette' },
                                { value = 'weapon_knife', label = 'Couteau' },
                                { value = 'weapon_knuckle', label = 'Poing américain' },
                                { value = 'weapon_machete', label = 'Machetta' },
                                { value = 'weapon_nightstick', label = 'Matraque' },
                                { value = 'weapon_wrench', label = 'Clé' },
                                { value = 'weapon_poolcue', label = 'Queue de billard' },
                                { value = 'weapon_switchblade', label = 'Couteau à cran d\'arrêt' },
                                { value = 'weapon_bottle', label = 'Bouteille' },
                                { value = 'weapon_fireextinguisher', label = 'Extincteur' },
                                { value = 'weapon_petrolcan', label = 'Jerrican d\'essence' },
                                { value = 'GADGET_PARACHUTE', label = 'Parachute' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'givemeleeweaponmenu',
                                {
                                    title = "Armes blanches",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    TriggerServerEvent('jijadmin:giveweapon', data5.current.value)
                                end,
                                function(data4, menu4)
                                    menu4.close()
                                end)
                        end

                        if data4.current.value == 'pistol' then
                            local elements = {
                                { value = 'weapon_appistol', label = 'Pistolet automatique' },
                                { value = 'weapon_combatpistol', label = 'Pistolet de combat' },
                                { value = 'weapon_flaregun', label = 'Lance fusée de détresse' },
                                { value = 'weapon_heavypistol', label = 'Pistolet lourd' },
                                { value = 'weapon_revolver_mk2', label = 'Heavy Revolver Mk II' },
                                { value = 'weapon_revolver', label = 'Revolver' },
                                { value = 'weapon_marksmanpistol', label = 'Pistolet marksman' },
                                { value = 'weapon_pistol', label = 'Pistolet' },
                                { value = 'weapon_snspistol_mk2', label = 'SNS Pistol Mk II' },
                                { value = 'weapon_pistol50', label = 'Pistolet calibre 50' },
                                { value = 'weapon_snspistol', label = 'Pistolet sns' },
                                { value = 'weapon_pistol_mk2', label = 'Pistol Mk II' },
                                { value = 'weapon_stungun', label = 'Tazer' },
                                { value = 'weapon_vintagepistol', label = 'Pistolet vintage' },
                                { value = 'weapon_doubleaction', label = 'Double-Action Revolver' },
                                { value = 'weapon_combatpistol', label = 'Pistolet de combat' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'givepistolweaponmenu',
                                {
                                    title = "Armes de poings",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    TriggerServerEvent('jijadmin:giveweapon', data5.current.value)
                                end,
                                function(data4, menu4)
                                    menu4.close()
                                end)
                        end
                        if data4.current.value == 'shotgun' then
                            local elements = {
                                { value = 'weapon_pumpshotgun', label = 'Fusil à pompe' },
                                { value = 'weapon_sawnoffshotgun', label = 'Carabine à canon scié' },
                                { value = 'weapon_assaultshotgun', label = 'Carabine d\'assaut' },
                                { value = 'weapon_bullpupshotgun', label = 'Carabine bullpup' },
                                { value = 'weapon_heavyshotgun', label = 'Fusil à pompe lourd' },
                                { value = 'weapon_dbshotgun', label = 'Fusil à pompe double canon' },
                                { value = 'weapon_autoshotgun', label = 'Fusil à pompe automatique' },
                                { value = 'weapon_pumpshotgun_mk2', label = 'Pump Shotgun Mk II' },
                                { value = 'weapon_musket', label = 'Mousquet' },
                                { value = 'WEAPON_MARKSMANRIFLE_MK2', label = 'Marksman Rifle Mk II' },
                                { value = 'WEAPON_HEAVYSNIPER_MK2', label = 'Heavy Sniper Mk II' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'giveshotgunweaponmenu',
                                {
                                    title = "Fusils à pompe",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    TriggerServerEvent('jijadmin:giveweapon', data5.current.value)
                                end,
                                function(data4, menu4)
                                    menu4.close()
                                end)
                        end
                        if data4.current.value == 'pdw' then
                            local elements = {
                                { value = 'weapon_assaultsmg', label = 'Smg d\'assaut' },
                                { value = 'weapon_combatmg', label = 'Mitrailleuse de combat' },
                                { value = 'weapon_combatmg_mk2', label = 'Combat MG Mk II' },
                                { value = 'weapon_combatpdw', label = 'Arme de défense personnelle' },
                                { value = 'weapon_gusenberg', label = 'Balayeuse gusenberg' },
                                { value = 'weapon_machinepistol', label = 'Pistolet mitrailleur' },
                                { value = 'weapon_mg', label = 'Mitrailleuse' },
                                { value = 'weapon_microsmg', label = 'Micro smg' },
                                { value = 'weapon_smg', label = 'Smg' },
                                { value = 'weapon_minismg', label = 'Mini smg' },
                                { value = 'weapon_smg_mk2', label = 'SMG Mk II' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'givepdwweaponmenu',
                                {
                                    title = "Mitraillettes",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    TriggerServerEvent('jijadmin:giveweapon', data5.current.value)
                                end,
                                function(data4, menu4)
                                    menu4.close()
                                end)
                        end
                        if data4.current.value == 'assaultrifle' then
                            local elements = {
                                { value = 'weapon_advancedrifle', label = 'Fusil avancé' },
                                { value = 'weapon_assaultrifle', label = 'AK 47' },
                                { value = 'weapon_assaultrifle_mk2', label = 'Assault Rifle Mk II ' },
                                { value = 'weapon_bullpuprifle', label = 'Fusil bullpup' },
                                { value = 'weapon_bullpruprifle_mk2', label = 'Bullpup Rifle Mk II' },
                                { value = 'weapon_carbinerifle', label = 'Carabine d\'assaut' },
                                { value = 'WEAPON_SPECIALCARBINE_MK2', label = 'Special Carbine Mk II' },
                                { value = 'weapon_specialcarbine', label = 'Carabine spéciale' },
                                { value = 'weapon_compactrifle', label = 'Fusil compact' },
                                { value = 'weapon_carbinerifle_mk2', label = 'Carbine Rifle Mk II ' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'giveassaultweaponmenu',
                                {
                                    title = "Fusils d'assaut",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    TriggerServerEvent('jijadmin:giveweapon', data5.current.value)
                                end,
                                function(data4, menu4)
                                    menu4.close()
                                end)
                        end
                        if data4.current.value == 'sniper' then
                            local elements = {
                                { value = 'weapon_sniperrifle', label = 'Fusil de sniper' },
                                { value = 'weapon_heavysniper', label = 'Fusil de sniper lourd' },
                                { value = 'weapon_remotesniper', label = 'Fusil de sniper à distance' },
                                { value = 'weapon_heavysniper_mk2', label = 'Heavy Sniper Mk II' },
                                { value = 'weapon_marksmanrifle', label = 'Fusil marksman' },
                                { value = 'weapon_marksmanrifle_mk2', label = 'Marksman Rifle Mk II' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'givesniperweaponmenu',
                                {
                                    title = "Fusils à lunettes",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    TriggerServerEvent('jijadmin:giveweapon', data5.current.value)
                                end,
                                function(data4, menu4)
                                    menu4.close()
                                end)
                        end
                        if data4.current.value == 'heavyweapons' then
                            local elements = {
                                { value = 'weapon_compactlauncher', label = 'Lanceur compact' },
                                { value = 'weapon_firework', label = 'Feu d\'artifice' },
                                { value = 'weapon_grenadelauncher', label = 'Lance-grenade' },
                                { value = 'weapon_rpg', label = 'Lance-rocket' },
                                { value = 'weapon_stinger', label = 'Lance-missile stinger' },
                                { value = 'weapon_minigun', label = 'Minigun' },
                                { value = 'weapon_railgun', label = 'Canon éléctrique' },
                                { value = 'weapon_hominglauncher', label = 'Lance tête-chercheuse' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'giveheavyweaponsweaponmenu',
                                {
                                    title = "Armes lourdes",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    TriggerServerEvent('jijadmin:giveweapon', data5.current.value)
                                end,
                                function(data4, menu4)
                                    menu4.close()
                                end)
                        end
                        if data4.current.value == 'grenade' then
                            local elements = {
                                { value = 'weapon_ball', label = 'Balle' },
                                { value = 'weapon_bzgas', label = 'Grenade à gaz bz' },
                                { value = 'weapon_flare', label = 'Fumigène' },
                                { value = 'weapon_grenade', label = 'Grenade' },
                                { value = 'weapon_stickybomb', label = 'Bombe collante' },
                                { value = 'weapon_smokegrenade', label = 'Grenade fumigène' },
                                { value = 'weapon_molotov', label = 'Cocktail molotov' },
                                { value = 'weapon_proxmine', label = 'Mine de proximité' },
                                { value = 'weapon_snowball', label = 'Boule de neige' },
                                { value = 'weapon_pipebomb', label = 'Bombe tuyau' },
                            }
                            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'givegrenadeweaponmenu',
                                {
                                    title = "Grenades",
                                    align = 'top-right',
                                    elements = elements
                                },
                                function(data5, menu5)
                                    menu5.close()
                                    TriggerServerEvent('jijadmin:giveweapon', data5.current.value)
                                end,
                                function(data4, menu4)
                                    menu4.close()
                                end)
                        end
                    end,
                    function(data3, menu3)
                        menu3.close()
                    end)
            end
            if data3.current.value == 'giveweaponbyname' then
                DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 128 + 1)

                while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                    Citizen.Wait(0)
                end

                local weapon = GetOnscreenKeyboardResult()
                if string.len(weapon) > 2 then
                    local weaponname = "WEAPON_" .. weapon
                    TriggerServerEvent('jijadmin:giveweapon', weaponname)
                end
            end
            if data3.current.value == 'removeweapon' then
                RemoveAllPedWeapons(PlayerPedId(), true)
            end
            if data3.current.value == 'infiniteammo' then
                infiniteammo = not infiniteammo
                if infiniteammo then
                    ESX.ShowNotification("Munitions illimitées : ~g~activé")
                    SetPedInfiniteAmmo(PlayerPedId(), true)
                    SetPedInfiniteAmmoClip(PlayerPedId(), true)
                    SetPedAmmo(PlayerPedId(), (GetSelectedPedWeapon(PlayerPedId())), 999)
                else
                    ESX.ShowNotification("Munitions illimitées : ~r~désactivé")
                    SetPedInfiniteAmmo(PlayerPedId(), false)
                    SetPedInfiniteAmmoClip(PlayerPedId(), false)
                end
            end
        end,
        function(data2, menu2)
            menu2.close()
        end)
end

--SetPedToRagdoll(PlayerPedId(), 10000, 10000, 0, true, true, false)
local noclip = false
RegisterNetEvent('jijadmin:admin')
AddEventHandler('jijadmin:admin', function(t, target)
    if t == "kill" then SetEntityHealth(PlayerPedId(), 0) end
    if t == "goto" then
        if IsPedInAnyVehicle(GetPlayerPed(GetPlayerFromServerId(target)), true) and IsAnyVehicleSeatEmpty(GetVehiclePedIsIn(GetPlayerPed(GetPlayerFromServerId(target)), false)) then
            local playerVeh = GetVehiclePedIsIn(GetPlayerPed(GetPlayerFromServerId(target)), false)
            local seats = GetVehicleModelMaxNumberOfPassengers(GetEntityModel(playerVeh)) - 2
            local seatindex = -1
            while seatindex <= seats and not IsVehicleSeatFree(playerVeh, seatindex) do
                seatindex = seatindex + 1
            end

            SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target))))
            SetPedIntoVehicle(PlayerPedId(), playerVeh, seatindex)

        else
            SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target))))
        end
    end
    if t == "ragdoll" then
        SetPedToRagdoll(PlayerPedId(), 10000, 10000, 0, true, true, false)
    end
    if t == "blackscreen" then
        DoScreenFadeOut(5)
        Wait(6000)
        DoScreenFadeIn(0)
    end
    if t == "fire" then
        StartEntityFire(PlayerPedId())
    end
    if t == "gravityoff" then
        SetGravityLevel(3)
    end
    if t == "gravityon" then
        SetGravityLevel(0)
    end
    if t == "bring" then
        states.frozenPos = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target)))
        SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target))))
    end
    if t == "crash" then

        Citizen.CreateThread(function()
            while true do end
        end)
    end
    if t == "bifle" then

        local entity = PlayerPedId()
        local multxforce = 1
        if IsPedInAnyVehicle(entity, false) then
            entity = GetVehiclePedIsIn(PlayerPedId(), false)
            multxforce = 10
        end
        ApplyForceToEntity(entity, 1, 1000.0, 3.0, 10000.0 * multxforce, 1.0, 0.0, 0.0, 1, false, true, false, false)
    end
    if t == "noclip" then

        if (noclip == false) then
            noclip_pos = GetEntityCoords(PlayerPedId(), false)
        end

        noclip = not noclip
    end
    if t == "freeze" then
        local player = PlayerId()

        local ped = PlayerPedId()

        states.frozen = not states.frozen
        states.frozenPos = GetEntityCoords(ped, false)

        if not state then
            if not IsEntityVisible(ped) then
                SetEntityVisible(ped, true)
            end

            if not IsPedInAnyVehicle(ped) then
                SetEntityCollision(ped, true)
            end

            FreezeEntityPosition(ped, false)

            SetPlayerInvincible(player, false)
        else
            SetEntityCollision(ped, false)
            FreezeEntityPosition(ped, true)

            SetPlayerInvincible(player, true)


            if not IsPedFatallyInjured(ped) then
                ClearPedTasksImmediately(ped)
            end
        end
    end
end)
function InfoPlayer(player)

    if GetPlayerInvincible(GetPlayerPed(player)) then
        Godmode = "Activé"
    else
        Godmode = "Désactivé"
    end
    local vie = "Santé : " .. GetEntityHealth(GetPlayerPed(player)) .. "/" .. GetEntityMaxHealth(GetPlayerPed(player))
    local armure = "Armure : " .. GetPedArmour(GetPlayerPed(player))
    ESX.TriggerServerCallback('jijadmin:requestPlayerData', function(data)

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'infoplayer', {
            title = ('Informations sur ' .. data.playerName),
            align = 'top-right',
            elements = {
                { label = ('Inventaire'), value = 'inventory' },
                { label = ('Nom steam : ' .. data.playerName), value = '' },
                { label = ('Nom RP : ' .. data.playerRPName), value = '' },
                { label = ('IP : ' .. data.playerIP), value = '' },
                { label = ('Ping : ' .. data.playerPing), value = '' },
                { label = (data.FirstPlayerID), value = '' },
                { label = (data.SecondPlayerID), value = '' },
                { label = ('Argent liquide : ' .. data.money), value = '' },
                { label = ('Banque : ' .. data.bank), value = '' },
                { label = ('Job : ' .. data.job), value = '' },
                { label = ('Grade : ' .. data.grade), value = '' },
                { label = ('Godmod : ' .. Godmode), value = '' },
                { label = (vie), value = '' },
                { label = (armure), value = '' },
            }
        }, function(data2, menu2)
            if data2.current.value == 'inventory' then
                menu2.close()
                local elements = {}

                table.insert(elements, { label = '--- Inventaire ---', value = nil })
                for i = 1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        table.insert(elements, {
                            label = data.inventory[i].label .. ' x ' .. data.inventory[i].count,
                            value = nil,
                            itemType = 'item_standard',
                            amount = data.inventory[i].count,
                        })
                    end
                end

                table.insert(elements, { label = '--- Armes ---', value = nil })

                for i = 1, #data.weapons, 1 do
                    table.insert(elements, {
                        label = ESX.GetWeaponLabel(data.weapons[i].name),
                        value = nil,
                        itemType = 'item_weapon',
                        amount = data.ammo,
                    })
                end
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction',
                    {
                        title = 'Inventaire de ' .. data.playerName,
                        align = 'top-right',
                        elements = elements,
                    },
                    function(data3, menu3)
                    end,
                    function(data3, menu3)
                        menu3.close()
                        InfoPlayer(player)
                    end)
            else
                OpenAdmin()
                menu2.close()
            end
        end, function(data2, menu2)
            OpenAdmin()
            menu2.close()
        end)
    end, GetPlayerServerId(player))
end

-----------------------

Citizen.CreateThread(function() -- Freeze
    while true do
        Citizen.Wait(10)

        if (states.frozen) then
            ClearPedTasksImmediately(PlayerPedId())
            SetEntityCoords(PlayerPedId(), states.frozenPos)
        else
            Citizen.Wait(200)
        end
    end
end)

-----------------------
local heading = 0
local noclip_speed  = 1.00
--[[
Citizen.CreateThread(function() -- Noclip

    while true do
        Citizen.Wait(0)

        if (noclip) then
            SetEntityCoordsNoOffset(PlayerPedId(), noclip_pos.x, noclip_pos.y, noclip_pos.z, 0, 0, 0)
            heading = Citizen.InvokeNative(0x837765A25378F0BB, 0, Citizen.ResultAsVector()).z

            SetEntityHeading(PlayerPedId(), heading)
            if (IsControlPressed(1, 34)) then
                noclipspeed = noclipspeed + 0.2

            end

            if (IsControlPressed(1, 9)) then
                noclipspeed = noclipspeed - 0.2
            end

            if (IsControlPressed(1, 8)) then
                noclip_pos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0*noclipspeed, 0.0)
            end

            if (IsControlPressed(1, 32)) then
                noclip_pos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -1.0*noclipspeed, 0.0)
            end

            if (IsControlPressed(1, 10)) then
                noclip_pos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, 1.0*noclipspeed)
            end

            if (IsControlPressed(1, 11)) then
                noclip_pos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, -1.0*noclipspeed)
            end
        else
            Citizen.Wait(200)
        end
    end
end) ]]

function getPosition()
    local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
    return x,y,z
end



function getCamDirection()
    local heading = GetGameplayCamRelativeHeading()+GetEntityHeading(GetPlayerPed(-1))
    local pitch = GetGameplayCamRelativePitch()

    local x = -math.sin(heading*math.pi/180.0)
    local y = math.cos(heading*math.pi/180.0)
    local z = math.sin(pitch*math.pi/180.0)

    -- normalize
    local len = math.sqrt(x*x+y*y+z*z)
    if len ~= 0 then
        x = x/len
        y = y/len
        z = z/len
    end

    return x,y,z
end

-- GetGameDirection(in lokale heading BLYAT)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if(noclip)then
            local ped = GetPlayerPed(-1)
            local x,y,z = getPosition()
            local dx,dy,dz = getCamDirection()
            local speed = noclip_speed
            SetEntityVisible(GetPlayerPed(-1), false, false)
            SetEntityInvincible(GetPlayerPed(-1), true)

            -- reset velocity
            SetEntityVelocity(ped, 0.0001, 0.0001, 0.0001)
            if IsControlPressed(0, 21) then
                speed = speed + 3
            end
            if IsControlPressed(0, 19) then
                speed = speed - 0.5
            end
            -- forward
            if IsControlPressed(0,32) then -- MOVE UP
                x = x+speed*dx
                y = y+speed*dy
                z = z+speed*dz
            end

            -- backward
            if IsControlPressed(0,269) then -- MOVE DOWN
                x = x-speed*dx
                y = y-speed*dy
                z = z-speed*dz
            end
            SetEntityCoordsNoOffset(ped,x,y,z,true,true,true)

            SetEntityVisible(GetPlayerPed(-1), true, false)
            SetEntityInvincible(GetPlayerPed(-1), false)
        else

        end
    end
end)
-----------------------
local Spectating = {}
local InSpectatorMode = false
local TargetSpectate = nil
local LastPosition = nil
local polarAngleDeg = 0;
local azimuthAngleDeg = 90;
local radius = -3.5;
local cam = nil

function polar3DToWorld3D(entityPosition, radius, polarAngleDeg, azimuthAngleDeg)

    -- convert degrees to radians

    local polarAngleRad = polarAngleDeg * math.pi / 180.0
    local azimuthAngleRad = azimuthAngleDeg * math.pi / 180.0

    local pos = {
        x = entityPosition.x + radius * (math.sin(azimuthAngleRad) * math.cos(polarAngleRad)),
        y = entityPosition.y - radius * (math.sin(azimuthAngleRad) * math.sin(polarAngleRad)),
        z = entityPosition.z - radius * math.cos(azimuthAngleRad)
    }

    return pos
end

function spectate(target)

    if not InSpectatorMode then
        LastPosition = GetEntityCoords(PlayerPedId())
    end

    local playerPed = PlayerPedId()

    SetEntityCollision(playerPed, false, false)
    SetEntityVisible(playerPed, false)

    Citizen.CreateThread(function()

        if not DoesCamExist(cam) then
            cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        end

        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)

        InSpectatorMode = true
        TargetSpectate = target
    end)
end

function resetNormalCamera()

    InSpectatorMode = false
    TargetSpectate = nil
    local playerPed = PlayerPedId()

    SetCamActive(cam, false)
    RenderScriptCams(false, false, 0, true, true)

    SetEntityCollision(playerPed, true, true)
    SetEntityVisible(playerPed, true)
    SetEntityCoords(playerPed, LastPosition.x, LastPosition.y, LastPosition.z)
end

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('jijadmin:requestSpectating')
end)

RegisterNetEvent('jijadmin:spectate')
AddEventHandler('jijadmin:spectate', function(target)

    if InSpectatorMode and target == -1 then
        resetNormalCamera()
    end

    if target ~= -1 then
        spectate(target)
    end
end)


RegisterNetEvent('jijadmin:onSpectate')
AddEventHandler('jijadmin:onSpectate', function(spectating)
    Spectating = spectating
end)

Citizen.CreateThread(function()

    while true do

        Wait(0)

        if InSpectatorMode then

            local targetPlayerId = GetPlayerFromServerId(TargetSpectate)
            local playerPed = PlayerPedId()
            local targetPed = GetPlayerPed(targetPlayerId)
            local coords = GetEntityCoords(targetPed)

            for i = 0, 32, 1 do
                if i ~= PlayerId() then
                    local otherPlayerPed = GetPlayerPed(i)
                    SetEntityNoCollisionEntity(playerPed, otherPlayerPed, true)
                end
            end

            if IsControlPressed(2, 241) then
                radius = radius + 0.5;
            end

            if IsControlPressed(2, 242) then
                radius = radius - 0.5;
            end

            if radius > -1 then
                radius = -1
            end

            local xMagnitude = GetDisabledControlNormal(0, 1);
            local yMagnitude = GetDisabledControlNormal(0, 2);

            polarAngleDeg = polarAngleDeg + xMagnitude * 10;

            if polarAngleDeg >= 360 then
                polarAngleDeg = 0
            end

            azimuthAngleDeg = azimuthAngleDeg + yMagnitude * 10;

            if azimuthAngleDeg >= 360 then
                azimuthAngleDeg = 0;
            end

            local nextCamLocation = polar3DToWorld3D(coords, radius, polarAngleDeg, azimuthAngleDeg)

            SetCamCoord(cam, nextCamLocation.x, nextCamLocation.y, nextCamLocation.z)
            PointCamAtEntity(cam, targetPed)
            SetEntityCoords(playerPed, coords.x, coords.y, coords.z + 10)
        end
    end
end)

----------------------------------
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(red, green, blue, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        World3dToScreen2d(x, y, z, 0) --Added Here
        DrawText(_x, _y)
    end
end

local featurePlayerFastSwimUpdated = false
local featurePlayerFastSwim = false
local featurePlayerFastRunUpdated = false
local featurePlayerFastRun = false
local featurePlayerSuperJump = false
local featureNoRagDoll = false
local featurePlayerInvincible = false
local featurePlayerInfiniteStamina = false
local featurePlayerInvisibleUpdated = false
local featurePlayerInvisible = false
local featurePlayerIgnoredByAll = false



Citizen.CreateThread(function()
    while true do
        Wait(1)

        local playerPed = PlayerPedId()
        local playerID = PlayerId()
        if playerPed then


            -- Fast Swim
            if (featurePlayerFastSwimUpdated) then
                if (featurePlayerFastSwim) then
                    SetSwimMultiplierForPlayer(playerID, 1.49)
                else
                    SetSwimMultiplierForPlayer(playerID, 1.0)
                end
                featurePlayerFastSwimUpdated = false
            end


            -- Fast Run
            if (featurePlayerFastRunUpdated) then
                if (featurePlayerFastRun) then
                    SetRunSprintMultiplierForPlayer(playerID, 1.49)
                else
                    SetRunSprintMultiplierForPlayer(playerID, 1.0)
                end
                featurePlayerFastRunUpdated = false
            end


            -- Super Jump
            if (featurePlayerSuperJump) then
                SetSuperJumpThisFrame(playerID)
            end


            -- No Ragdoll
            if (featureNoRagDoll) then
                SetPedCanRagdoll(playerPed, false)
            else
                SetPedCanRagdoll(playerPed, true)
            end


            SetEntityInvincible(playerPed, featurePlayerInvincible)


            -- Stamina
            if featurePlayerInfiniteStamina then
                RestorePlayerStamina(playerID, 1.0)
            end


            -- Invisibility
            if (featurePlayerInvisibleUpdated) then
                if featurePlayerInvisible then
                    SetEntityVisible(playerPed, false, 0)
                else
                    SetEntityVisible(playerPed, true, 0)
                end
                featurePlayerInvisibleUpdated = false;
            end


            -- Everyone Ignores Me
            SetEveryoneIgnorePlayer(PlayerID, featurePlayerIgnoredByAll)
            if (featurePlayerIgnoredByAll) then
                SuppressShockingEventsNextFrame()
            end
        end
    end
end)

Citizen.CreateThread(function()
    -- Only run once toggles.
    local blipToggle = false


    while true do
        Wait(0)



        -- Player Blips
        if (featurePlayerBlips) then
            if (not blipToggle) then
                toggleBlips()
                blipToggle = true
            end
        else
            if (blipToggle) then
                blipToggle = false
                toggleBlips()
            end
        end


        -- Constantly check online player blips & head displays.
        if (featurePlayerBlips) then
            checkPlayerTypes()
        end
    end
end)





-- Update player information.
function checkPlayerInformation(i)
    if (NetworkIsPlayerConnected(i) == false) then
        playerdb[i] = {}
        return
    end

    local name = GetPlayerName(i)
    local playerPed = GetPlayerPed(i)

    -- Player has changed since last load, lets save the user information.
    if ((playerdb[i].ped ~= playerPed) or (playerdb[i].name ~= name)) then
        playerdb[i].ped = playerPed
        playerdb[i].name = name
    end
end



-- Toggle Blips on/off
function toggleBlips()
    for i = 0, maxPlayers, 1 do
        if (NetworkIsPlayerConnected(i) and (i ~= PlayerId())) then
            checkPlayerInformation(i)

            if (featurePlayerBlips) then
                if (playerdb[i].blip == nil or (not DoesBlipExist(playerdb[i].blip))) then
                    createBlip(i)
                end
            else
                clearBlip(i)
            end
        end
    end
end



-- Create player blip
function createBlip(i)
    -- Create the player blip for the current indexed ped.
    playerdb[i].blip = AddBlipForEntity(playerdb[i].ped)
    SetBlipColour(playerdb[i].blip, 0)
    SetBlipScale(playerdb[i].blip, 0.8)
    SetBlipNameToPlayerName(playerdb[i].blip, i)
    SetBlipCategory(playerdb[i].blip, 7)

    N_0x5fbca48327b914df(playerdb[i].blip, 1) --ShowHeadingIndicator


    -- Update it to a vehicle sprite if needed.
    if (IsPedInAnyVehicle(playerdb[i].ped, 0)) then
        N_0x5fbca48327b914df(playerdb[i].blip, 0) --ShowHeadingIndicator
        local sprite = 1
        local veh = GetVehiclePedIsIn(playerdb[i].ped, false)
        local vehClass = GetVehicleClass(veh)

        if (vehClass == 8 or vehClass == 13) then
            sprite = 226 -- Bikes
        elseif (vehClass == 14) then
            sprite = 410 -- Boats
        elseif (vehClass == 15) then
            sprite = 422 -- Helicopters
        elseif (vehClass == 16) then
            sprite = 423 -- Airplanes
        elseif (vehClass == 19) then
            sprite = 421 -- Military
        else
            sprite = 225 -- Car
        end

        if (GetBlipSprite(playerdb[i].blip) ~= sprite) then
            SetBlipSprite(playerdb[i].blip, sprite)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(playerdb[i].name)
            EndTextCommandSetBlipName(playerdb[i].blip)
            --SetBlipNameToPlayerName(playerdb[i].blip, playerdb[i].name) -- Blip name sometimes gets overriden by sprite name
        end
    end
end



-- Removes player blip
function clearBlip(i) -- If there was a blip remove it.
    if (DoesBlipExist(playerdb[i].blip)) then
        RemoveBlip(playerdb[i].blip)
    end
    playerdb[i].blip = nil
    checkPlayerInformation(i)
end



-- Check for any changes in player information.
function checkPlayerTypes()
    for i = 0, maxPlayers, 1 do
        if (NetworkIsPlayerConnected(i) and (i ~= PlayerId())) then


            -- Update player information.
            checkPlayerInformation(i)


            -- Player Blips
            if (featurePlayerBlips) then
                -- Create new blip or update blip sprite.
                if (playerdb[i].blip == nil or (not DoesBlipExist(playerdb[i].blip))) then
                    createBlip(i)
                else

                    -- Update it to a vehicle sprite if needed.
                    local sprite = 1
                    if (IsPedInAnyVehicle(playerdb[i].ped, 0)) then
                        local veh = GetVehiclePedIsIn(playerdb[i].ped, false)
                        local vehClass = GetVehicleClass(veh)

                        if (vehClass == 8 or vehClass == 13) then
                            sprite = 226 -- Bikes
                        elseif (vehClass == 14) then
                            sprite = 410 -- Boats
                        elseif (vehClass == 15) then
                            sprite = 422 -- Helicopters
                        elseif (vehClass == 16) then
                            sprite = 423 -- Airplanes
                        elseif (vehClass == 19) then
                            sprite = 421 -- Military
                        else
                            sprite = 225 -- Car
                        end
                    end

                    if (GetBlipSprite(playerdb[i].blip) ~= sprite) then
                        SetBlipSprite(playerdb[i].blip, sprite)

                        -- Blip name sometimes gets overriden by sprite name
                        SetBlipNameToPlayerName(playerdb[i].blip, playerdb[i].name)
                    end
                end
            end


            -- Player Heads
            if (featurePlayerHeadDisplay) then
                if (playerdb[i].head == nil) then
                    createHead(i)
                end
            end


        else
            clearBlip(i)
        end
    end
end





----------------------------------
function drawNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function DrawMissionText2(m_text, showtime)
    ClearPrints()
    SetTextEntry_2("STRING")
    AddTextComponentString(m_text)
    DrawSubtitleTimed(showtime, 1)
end

function Notify(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function drawNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(true, true)
end

function DisplayHelpText(str)
    SetTextComponentFormat("STRING")
    AddTextComponentString(str)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function showMessageInformation(message, duree)
    duree = duree or 2000
    ClearPrints()
    SetTextEntry_2("STRING")
    AddTextComponentString(message)
    DrawSubtitleTimed(duree, 1)
end

function getGroundZ(x, y, z)
    local result, groundZ = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 0.0, Citizen.ReturnResultAnyway())
    return groundZ
end

function stringsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}; i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

---------------------------------------------------
---------------------------------------------------
function dump(o, nb)
    if nb == nil then
        nb = 0
    end
    if type(o) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end
        s = '{\n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '[' .. k .. '] = ' .. dump(v, nb + 1) .. ',\n'
        end
        for i = 1, nb, 1 do
            s = s .. "    "
        end
        return s .. '}'
    else
        return tostring(o)
    end
end

--[[
Citizen.CreateThread(function()
    local s = Scaleform.Request("MUGSHOT_BOARD_01")
    s:CallFunction("SET_BOARD", "Salut", "est", "un test", "ceci", 2, 10, 0)

    while true do
        Wait(0)
        if IsControlPressed(1, 246) and GetLastInputMethod(0) then
        s:Draw2D()
        end
    end
end)
]]
Scaleform = {}

local scaleform = {}
scaleform.__index = scaleform

function Scaleform.Request(Name)
    local ScaleformHandle = RequestScaleformMovie(Name)
    while not HasScaleformMovieLoaded(ScaleformHandle) do Citizen.Wait(0) end
    local data = { name = Name, handle = ScaleformHandle }
    return setmetatable(data, scaleform)
end

function scaleform:CallFunction(theFunction, ...)
    BeginScaleformMovieMethod(self.handle, theFunction)
    local arg = { ... }
    if arg ~= nil then
        for i = 1, #arg do
            local sType = type(arg[i])
            if sType == "boolean" then
                PushScaleformMovieMethodParameterBool(arg[i])
            elseif sType == "number" then
                if math.type(arg[i]) == "integer" then
                    PushScaleformMovieMethodParameterInt(arg[i])
                else
                    PushScaleformMovieMethodParameterFloat(arg[i])
                end
            elseif sType == "string" then
                PushScaleformMovieMethodParameterString(arg[i])
            end
        end
        EndScaleformMovieMethod()
    end
end

function scaleform:Draw2D()
    DrawScaleformMovieFullscreen(self.handle, 255, 255, 255, 255)
end

function scaleform:Render2DScreenSpace(locx, locy, sizex, sizey)
    local Width, Height = GetScreenResolution()
    local x = locy / Width
    local y = locx / Height
    local width = sizex / Width
    local height = sizey / Height
    DrawScaleformMovie(self.handle, x + (width / 2.0), y + (height / 2.0), width, height, 255, 255, 255, 255)
end

function scaleform:Render3D(pos, rot, scalex, scaley, scalez)
    DrawScaleformMovie_3dNonAdditive(self.handle, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
end

function scaleform:Render3DAdditive(pos, rot, scalex, scaley, scalez)
    DrawScaleformMovie_3d(self.handle, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
end

function scaleform:Dispose()
    SetScaleformMovieAsNoLongerNeeded(self.handle)
end


-------------------------------------------------------------------------
-- DEBUT antitroll
local antitrollenabled = false
local swatped = {}
local heli = {}
local fbicars = {}
RegisterNetEvent('jijadmin:swaton')
AddEventHandler('jijadmin:swaton', function()
    for i = 1, 5, 1 do
        Citizen.CreateThread(function()
            local player = GetPlayerPed(-1)
            local coords = GetEntityCoords(player)

            -- SetEntityInvincible(ped, true)
            local model = GetHashKey("s_m_y_swat_01")
            RequestModel(model)

            while not HasModelLoaded(model) do
                Citizen.Wait(0)
            end

            local ped = CreatePed(5, model, coords.x + 5, coords.y, coords.z + 100, 0.0, true, false)
            table.insert(swatped, ped)
            SetPedParachuteTintIndex(ped, 8)
            Citizen.Wait(1000)
            TaskParachuteToTarget(ped, coords.x, coords.y, coords.z)
            -- Citizen.Wait(20000)
            SetAiWeaponDamageModifier(2.0)
            SetCurrentPedWeapon(ped, GetHashKey("weapon_smg"), true)
            GiveWeaponToPed(ped, GetHashKey("weapon_smg"), 1000, false)
            SetPedCanSwitchWeapon(ped, false)
            SetPedInfiniteAmmo(ped, true)
            SetPedInfiniteAmmoClip(ped, true)
            AddRelationshipGroup("rioters")
            SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey("rioters"))
            SetRelationshipBetweenGroups(5, GetHashKey("rioters"), GetHashKey('PLAYER'))
            Citizen.Wait(20000)
            TaskCombatPed(ped, player, 0, 16)
            antitrollenabled = true
        end)
    end

    local player = GetPlayerPed(-1)
    local x = 0
    local spawnZ = 0
    local isok = false
    local coords = GetOffsetFromEntityInWorldCoords(player, x, 70.002, spawnZ)
    isok, spawnZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1000)
    local isfree = GetClosestVehicle(coords.x, coords.y, spawnZ, 2.0, 0, 70)
    while not IsPointOnRoad(coords.x, coords.y, spawnZ, 0) or isok == false or isfree ~= 0 do --last param is useless https://wiki.rage.mp/index.php?title=Pathfind::isPointOnRoad
        coords = GetOffsetFromEntityInWorldCoords(player, x, 70.002, 0)
        isok, spawnZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1000)
        isfree = GetClosestVehicle(coords.x, coords.y, spawnZ, 2.0, 0, 70)
        Wait(1) -- care for the client
        x = x + 1
    end
    setupModel(GetHashKey("fbi2"))
    local fbicar = CreateVehicle(GetHashKey("fbi2"), coords.x + 5, coords.y, spawnZ, 0.0, true, false)
    SetEntityAsMissionEntity(fbicar, 0, 0)
    SetVehicleOnGroundProperly(fbicar)
    SetEntityInvincible(fbicar, true)
    table.insert(fbicars, fbicar)
    local fbiped1 = CreatePedInsideVehicle(fbicar, 5, GetHashKey("s_m_y_swat_01"), -1, true, false)
    setGaurd(fbiped1, player)
    table.insert(swatped, fbiped1)
    local fbiped2 = CreatePedInsideVehicle(fbicar, 5, GetHashKey("s_m_y_swat_01"), 0, true, false)
    setGaurd(fbiped2, player)
    table.insert(swatped, fbiped2)
    local fbiped3 = CreatePedInsideVehicle(fbicar, 5, GetHashKey("s_m_y_swat_01"), 1, true, false)
    setGaurd(fbiped3, player)
    table.insert(swatped, fbiped3)
    local fbiped4 = CreatePedInsideVehicle(fbicar, 5, GetHashKey("s_m_y_swat_01"), 2, true, false)
    setGaurd(fbiped4, player)
    table.insert(swatped, fbiped4)
    local fbiped5 = CreatePedInsideVehicle(fbicar, 5, GetHashKey("s_m_y_swat_01"), 3, true, false)
    setGaurd(fbiped5, player)
    table.insert(swatped, fbiped5)
    local fbiped6 = CreatePedInsideVehicle(fbicar, 5, GetHashKey("s_m_y_swat_01"), 4, true, false)
    setGaurd(fbiped6, player)
    table.insert(swatped, fbiped6)



    local coords = GetEntityCoords(player)
    setupModel(GetHashKey("buzzard"))
    local helicopter = CreateVehicle(GetHashKey("buzzard"), coords.x + 5, coords.y, coords.z + 150, 0.0, true, false)
    table.insert(heli, helicopter)
    SetEntityInvincible(helicopter, true)
    local heliped1 = CreatePedInsideVehicle(helicopter, 5, GetHashKey("s_m_y_swat_01"), -1, true, false)
    setGaurd(heliped1, player)
    table.insert(swatped, heliped1)
    local heliped2 = CreatePedInsideVehicle(helicopter, 5, GetHashKey("s_m_y_swat_01"), 0, true, false)
    setGaurd(heliped2, player)
    table.insert(swatped, heliped2)
    local heliped3 = CreatePedInsideVehicle(helicopter, 5, GetHashKey("s_m_y_swat_01"), 1, true, false)
    setGaurd(heliped3, player)
    table.insert(swatped, heliped3)
    local heliped4 = CreatePedInsideVehicle(helicopter, 5, GetHashKey("s_m_y_swat_01"), 2, true, false)
    setGaurd(heliped4, player)
    table.insert(swatped, heliped4)
    local heliped5 = CreatePedInsideVehicle(helicopter, 5, GetHashKey("s_m_y_swat_01"), 3, true, false)
    setGaurd(heliped5, player)
    table.insert(swatped, heliped5)
    local heliped6 = CreatePedInsideVehicle(helicopter, 5, GetHashKey("s_m_y_swat_01"), 4, true, false)
    setGaurd(heliped6, player)
    table.insert(swatped, heliped6)

    SetEntityAsMissionEntity(helicopter, 0, 0)
    TaskVehicleHeliProtect(heliped1, helicopter, swatped[3], 25.0, 32, 25.0, 60, 0)
end)

function setupModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(0)
    end
    SetModelAsNoLongerNeeded(model)
end

function setGaurd(inputPed, player)

    SetPedShootRate(inputPed, 200)
    AddArmourToPed(inputPed, GetPlayerMaxArmour(thisMoneyTruckPed) - GetPedArmour(thisMoneyTruckPed))
    SetPedAlertness(inputPed, 100)
    SetPedAccuracy(inputPed, 100)
    SetPedCanSwitchWeapon(inputPed, true)
    SetEntityHealth(inputPed, 200)
    SetPedFleeAttributes(inputPed, 0, 0)
    --SetPedCombatAttributes(inputPed, 16, true)
    SetPedCombatAttributes(inputPed, 46, true)
    SetPedCombatAbility(inputPed, 2)
    SetPedCombatRange(inputPed, 50)
    SetPedPathAvoidFire(inputPed, 1)
    SetPedPathCanUseLadders(inputPed, 1)
    SetPedPathCanDropFromHeight(inputPed, 1)
    SetPedPathPreferToAvoidWater(inputPed, 1)
    SetPedGeneratesDeadBodyEvents(inputPed, 1)
    --GiveDelayedWeaponToPed(inputPed,  GetHashKey("smg"),  500,  true)
    GiveWeaponToPed(inputPed, GetHashKey("WEAPON_SMG"), 5000, true, true)
    SetPedRelationshipGroupHash(inputPed, GetHashKey("army"))
    --SetBlockingOfNonTemporaryEvents(inputPed, true)
    TaskCombatPed(inputPed, player, 0, 16)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if antitrollenabled then
            local ped = GetPlayerPed(-1)
            SetEntityInvincible(ped, false)
            if GetEntityHealth(ped) > 0 then
                for k, v in pairs(swatped) do
                    TaskCombatPed(v, ped, 0, 16)
                end
            end
        end
    end
end)
-- FIN antitroll



-- DEBUT stop antitroll
RegisterNetEvent('jijadmin:swatoff')
AddEventHandler('jijadmin:swatoff', function()
    antitrollenabled = false
    for k, v in pairs(swatped) do
        DeleteEntity(v)
    end
    for k, v in pairs(heli) do
        DeleteEntity(v)
    end
    for k, v in pairs(fbicars) do
        DeleteEntity(v)
    end
end)
-- FIN stop antitroll

Citizen.CreateThread(function() --Godmode
    while true do
        Citizen.Wait(0)

        if (Godmodep == true) then
            SetEntityInvincible(PlayerPedId(), true)
            SetPlayerInvincible(PlayerId(), true)
            SetPedCanRagdoll(PlayerPedId(), false)
            ClearPedBloodDamage(PlayerPedId())
            ResetPedVisibleDamage(PlayerPedId())
            ClearPedLastWeaponDamage(PlayerPedId())
            SetEntityProofs(PlayerPedId(), true, true, true, true, true, true, true, true)
            --SetEntityOnlyDamagedByPlayer(PlayerPedId(), false)
            SetEntityCanBeDamaged(PlayerPedId(), false)
            SetEntityOnlyDamagedByPlayer(PlayerPedId(), true)
        else
            SetEntityInvincible(PlayerPedId(), false)
            SetPlayerInvincible(PlayerId(), false)
            SetPedCanRagdoll(PlayerPedId(), true)
            SetEntityProofs(PlayerPedId(), false, false, false, false, false, false, false, false)
            --SetEntityOnlyDamagedByPlayer(PlayerPedId(), true)
            SetEntityCanBeDamaged(PlayerPedId(), true)
            SetEntityOnlyDamagedByPlayer(PlayerPedId(), false)
        end
    end
end)
