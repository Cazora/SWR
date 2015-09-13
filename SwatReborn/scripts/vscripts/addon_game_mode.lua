requires = {
	'timers',
	'my_file',
}


if CAddonTemplateGameMode == nil then
    CAddonTemplateGameMode = class({})
end

function Precache( context )

            PrecacheResource( "model",  'models/heroes/undying/undying_minion.vmdl' , context )
 
end

-- Create the game mode when we activate
function Activate()
    GameRules.AddonTemplate = CAddonTemplateGameMode()
    GameRules.AddonTemplate:InitGameMode()
end

function CAddonTemplateGameMode:InitGameMode()
    print( "Template addon is loaded." )

	--my code here
	math.randomseed(Time())
   self.UnitThinkerList = {}
    
	for i = 1,5 do
        self:SpawnAIUnitWanderer()
    end
    for i = 1,3 do
        self:SpawnAIUnitCaster()
    end
   
   GameRules:GetGameModeEntity():SetThink( "OnUnitThink", self, "UnitThink", 1 )
   --my code ends
   
    --GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
end

-- Evaluate the state of the game
function CAddonTemplateGameMode:OnThink()
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        print( "Template addon script is running." )
		spawn
    elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        return nil
    end
    return 1
end


-- spawn units wanderer and caster
function CAITesting:SpawnAIUnitWanderer()
    --Start an iteration finding each entity with this name
    --If you've named everything with a unique name, this will return your entity on the first go
    local spawnVectorEnt = Entities:FindByName(nil, "spawn_loc_test")

    -- GetAbsOrigin() is a function that can be called on any entity to get its location
    local spawnVector = spawnVectorEnt:GetAbsOrigin()

    -- Spawn the unit at the location on the neutral team
    local spawnedUnit = CreateUnitByName("npc_dota_creature_kobold_tunneler", spawnVector, true, nil, nil, DOTA_TEAM_NEUTRALS)

    -- make this unit passive
    spawnedUnit:SetIdleAcquire(false)

    -- Add some variables to the spawned unit so we know its intended behaviour
    -- You can store anything here, and any time you get this entity the information will be intact
    spawnedUnit.ThinkerType = "wander"
    spawnedUnit.wanderBounds = {}
    spawnedUnit.wanderBounds.XMin = -768
    spawnedUnit.wanderBounds.XMax = 768
    spawnedUnit.wanderBounds.YMin = -64
    spawnedUnit.wanderBounds.YMax = 768

    -- Add a random amount to the game time to randomise the behaviour a bit
    spawnedUnit.NextOrderTime = GameRules:GetGameTime() + math.random(5, 10) 

    -- finally, insert the unit into the table
    table.insert(self.UnitThinkerList, spawnedUnit)
end

function CAITesting:SpawnAIUnitCaster()
    -- Generate a random location inside the neutrals area
    local spawnVector = Vector(math.random(-768, 768), math.random(-64, 768), 128)

    -- Spawn the unit at the location on the neutral team
    local spawnedUnit = CreateUnitByName("npc_dota_creature_gnoll_assassin", spawnVector, true, nil, nil, DOTA_TEAM_NEUTRALS)

    -- make this unit passive
    spawnedUnit:SetIdleAcquire(false)

    -- Add some variables to the spawned unit so we know its intended behaviour
    -- You can store anything here, and any time you get this entity the information will be intact
    spawnedUnit.ThinkerType = "caster"
    spawnedUnit.CastAbilityIndex = spawnedUnit:GetAbilityByIndex(0):entindex()

    -- Add a random amount to the game time to randomise the behaviour a bit
    spawnedUnit.NextOrderTime = GameRules:GetGameTime() + math.random(5, 10) 

    -- finally, insert the unit into the table
    table.insert(self.UnitThinkerList, spawnedUnit)
end

-- Thinker

function CAITesting:OnUnitThink()
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then

        local deadUnitCount = 0

        -- Check each of the units in this table for their thinker behaviour
        for ind, unit in pairs(self.UnitThinkerList) do

            -- The first check should be to see if the units are still alive or not.
            -- Keep track of how many units are removed from the table, as the indices will change by that amount
            if unit:IsNull() or not unit:IsAlive() then
                table.remove(self.UnitThinkerList, ind - deadUnitCount)
                deadUnitCount = deadUnitCount + 1

            -- Check if the game time has passed our random time for next order
            elseif GameRules:GetGameTime() > unit.NextOrderTime then

                if unit.ThinkerType == "wander" then
                    --print("thinker unit is a wanderer")
                    --print("time: " .. GameRules:GetGameTime() .. ". next wander: " .. unit.NextWanderTime)

                    -- Generate random coordinates to wander to
                    local x = math.random(unit.wanderBounds.XMin, unit.wanderBounds.XMax)
                    local y = math.random(unit.wanderBounds.YMin, unit.wanderBounds.YMax)
                    local z = GetGroundHeight(Vector(x, y, 128), nil)

                    print("wandering to x: " .. x .. " y: " .. y)

                    -- Issue the movement order to the unit
                    unit:MoveToPosition(Vector(x, y, z))


                elseif unit.ThinkerType == "caster" then

                    -- If you want a more complicated order, use this syntax
                    -- Some more documentation: https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/API/Global.ExecuteOrderFromTable
                    -- Unit order list is here: https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Panorama/Javascript/API#dotaunitorder_t
                    -- (Ignore the dotaunitorder_t. on each one)

                    print("casting ability " .. EntIndexToHScript(unit.CastAbilityIndex):GetName())

                    local order = {
                        UnitIndex = unit:entindex(),
                        AbilityIndex = unit.CastAbilityIndex,
                        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
                        Queue = false
                    }
                    ExecuteOrderFromTable(order)
                end

                -- Generate the next time for the order
                unit.NextOrderTime = GameRules:GetGameTime() + math.random(5, 10)
            end
        end

        -- Make sure our testing map stays on day time      
        if not GameRules:IsDaytime() then
            GameRules:SetTimeOfDay(0.26)
        end

    elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        return nil
    end

    -- this return statement means that this thinker function will be called again in 1 second
    -- returning nil will cause the thinker to terminate and no longer be called
    return 1
end