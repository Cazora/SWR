function OnStartTouch(trigger)

	print("On Start")
	print(trigger.caller)
	local spawnVector = Vector(math.random(0, 0), math.random(-4, 4), 10)
   local spawnedUnit = CreateUnitByName("npc_dota_neutral_gnoll_assassin", spawnVector, true, nil, nil, DOTA_TEAM_BADGUYS)
  spawnedUnit:SetIdleAcquire(true)
  
end
 
function OnEndTouch(trigger)
 
	print("On End")
	print(trigger.caller)
		local spawnVector = Vector(math.random(0, 0), math.random(-4, 4), 10)
    local spawnedUnit = CreateUnitByName("npc_dota_creep_badguys_melee", spawnVector, true, nil, nil, DOTA_TEAM_BADGUYS)
  spawnedUnit:SetIdleAcquire(true)
 
end

function Spawn(trigger)

	order.OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET

end
