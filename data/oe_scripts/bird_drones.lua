local time_increment = mods.multiverse.time_increment
local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table

local get_room_at_location = mods.oe.get_room_at_location
local xor = mods.oe.xor
local isPointInEllipse = mods.oe.isPointInEllipse
local worldToPlayerLocation = mods.oe.worldToPlayerLocation
local worldToEnemyLocation = mods.oe.worldToEnemyLocation
local get_distance = mods.oe.get_distance
local offset_point_in_direction = mods.oe.offset_point_in_direction
local get_point_local_offset = mods.oe.get_point_local_offset
local get_random_point_in_radius = mods.oe.get_random_point_in_radius
local normalise_angle = mods.oe.normalise_angle
local angle_diff = mods.oe.angle_diff
local get_angle_between_points = mods.oe.get_angle_between_points
local find_closest_slot = mods.oe.find_closest_slot

local RandomList = {
	New = function(self, table)
		table = table or {}
		self.__index = self
		setmetatable(table, self)
		return table
	end,

	GetItem = function(self)
		local index = Hyperspace.random32() % #self + 1
		return self[index]
	end,
}

mods.oe.burstDrones = {}
local burstDrones = mods.oe.burstDrones
burstDrones["OE_BEAM_BIRD_BURST_1"] = 2
burstDrones["OE_BEAM_BIRD_BURST_2"] = 3
burstDrones["OE_BEAM_BIRD_BURST_3"] = 4


script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, drone)
	local burstAmount = burstDrones[projectile.extend.name]
	if burstAmount then
		userdata_table(drone, "mods.oe.burstDrones").table = {0.0, burstAmount, projectile.position.x, projectile.position.y, projectile.currentSpace, projectile.target1, projectile.destinationSpace, projectile.heading, projectile.entryAngle}
		projectile:Kill()
	end
	return Defines.Chain.CONTINUE
end)

local burstLaserBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint("DRONE_LASER_COMBAT")
burstSounds = RandomList:New {"lightLaser1", "lightLaser2", "lightLaser3"}

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
	for drone in vter(shipManager.spaceDrones) do
		local burstDrone = userdata_table(drone, "mods.oe.burstDrones")
		if burstDrone.table then
			burstDrone.table[1] = math.max(burstDrone.table[1] - Hyperspace.FPS.SpeedFactor/16, 0)
			if burstDrone.table[1] == 0 then
				--print("DRONE_BURST_FIRE")
				local soundName = burstSounds:GetItem()
				Hyperspace.Sounds:PlaySoundMix(soundName, -1, false)
				local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space
				local laser = spaceManager:CreateLaserBlast(
					burstLaserBlueprint,
					Hyperspace.Pointf(burstDrone.table[3],burstDrone.table[4]),
					burstDrone.table[5],
					shipManager.iShipId,
					burstDrone.table[6],
					burstDrone.table[7],
					burstDrone.table[8])
				laser.entryAngle = burstDrone.table[9]

				if burstDrone.table[2] <= 1 then
					burstDrone.table = nil
				else
					burstDrone.table[1] = 0.25
					burstDrone.table[2] = burstDrone.table[2] -1
				end
			end
		end
	end
end)

mods.oe.bioDrones = {}
local bioDrones = mods.oe.bioDrones
bioDrones["OE_LASER_BIO_DRONE"] = true
bioDrones["OE_LASER_BIO_DRONE_3"] = true

script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, drone)
	local bioAmount = bioDrones[projectile.extend.name]
	if bioAmount then
		local random = math.random()
		if drone.iShipId == 1 and random > 0.33 then return Defines.Chain.CONTINUE end
		local shipManager = Hyperspace.ships(projectile.destinationSpace)
		local crewList = shipManager.vCrewList
		local crewListEnemy = {}
		local crewListSize = 0
		for crewmem in vter(crewList) do
			if not crewmem.intruder then
				crewListSize = crewListSize + 1
				table.insert(crewListEnemy, crewmem)
			end
		end
		if crewListSize > 0 then
			local random = math.random(crewListSize)
			local crew = crewListEnemy[random]
			drone.targetLocation = Hyperspace.Pointf(crew.x,crew.y)
		end
	end
	return Defines.Chain.CONTINUE
end)

mods.oe.bioBeamDrones = {}
local bioBeamDrones = mods.oe.bioBeamDrones
bioBeamDrones["OE_BEAM_BIRD_COMBAT_BOSS"] = true
bioBeamDrones["OE_BEAM_BIRD_COMBAT_BOSS_CHAOS"] = true

script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, drone)
	local bioAmount = bioBeamDrones[projectile.extend.name]
	if bioAmount then
		local random = math.random()
		if drone.iShipId == 1 and random > 0.33 then return Defines.Chain.CONTINUE end
		local shipManager = Hyperspace.ships(projectile.destinationSpace)
		local crewList = shipManager.vCrewList
		local crewListEnemy = {}
		local crewListSize = 0
		for crewmem in vter(crewList) do
			if not crewmem.intruder then
				crewListSize = crewListSize + 1
				table.insert(crewListEnemy, crewmem)
			end
		end
		if crewListSize > 0 then
			local random = math.random(crewListSize)
			local crew = crewListEnemy[random]
			local crewPos = crew:GetLocation()
			--print("TARGET BEAM START:"..crew.type)
			--drone.beamCurrentTarget = Hyperspace.Pointf(crew.x,crew.y)
			drone.targetLocation = Hyperspace.Pointf(crewPos.x,crewPos.y)
			--[[if crewListSize > 1 then
				table.remove(crewListEnemy, random)
				local random2 = math.random(crewListSize - 1)
				local crew2 = crewListEnemy[random2]
				local crew2Pos = crew2:GetLocation()
				--print("TARGET BEAM FINAL:"..crew2.type)
				drone.beamFinalTarget = get_point_local_offset(Hyperspace.Pointf(crewPos.x,crewPos.y), Hyperspace.Pointf(crew2Pos.x,crew2Pos.y), 300, 0)
			else
				drone.beamFinalTarget = get_point_local_offset(Hyperspace.Pointf(crewPos.x,crewPos.y), shipManager:GetRandomRoomCenter(), 300, 0)
			end]]
		end
	end
	return Defines.Chain.CONTINUE
end)

mods.oe.multiDrones = {}
local multiDrones = mods.oe.multiDrones
multiDrones["OE_DRONE_LASER_COMBAT_MULTI"] = Hyperspace.Blueprints:GetWeaponBlueprint("OE_DRONE_WION_COMBAT_MULTI")
multiDrones["OE_DRONE_BEAM_COMBAT_MULTI"] = Hyperspace.Blueprints:GetWeaponBlueprint("OE_DRONE_WION_COMBAT_MULTI")

multiDrones["OE_DRONE_LASER_COMBAT_MULTI_LOOT"] = Hyperspace.Blueprints:GetWeaponBlueprint("OE_DRONE_LOOT_COMBAT_MULTI")
multiDrones["OE_DRONE_BEAM_COMBAT_MULTI_LOOT"] = Hyperspace.Blueprints:GetWeaponBlueprint("OE_DRONE_LOOT_COMBAT_MULTI")


script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, drone)
	if log_events then
		log("DRONE_FIRE 1")
	end
	local multi = multiDrones[projectile.extend.name]
	if multi then
		local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space

		local ionPoint = get_point_local_offset(projectile.position,projectile.target or projectile.target1, 0, 17)
		local ion = spaceManager:CreateLaserBlast(
			multi,
			ionPoint,
			projectile.currentSpace,
			drone.iShipId,
			projectile.target or projectile.target1,
			projectile.destinationSpace,
			projectile.heading)
		ion:ComputeHeading()
	end
	return Defines.Chain.CONTINUE
end)

local weakIonDamage = Hyperspace.Damage()
weakIonDamage.iIonDamage = 1
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response) 
	if projectile and projectile.extend.name == "OE_DRONE_WION_COMBAT_MULTI" then
		if shipManager:HasSystem(0) then
			local shieldSystem = shipManager.shieldSystem
			--print(shieldSystem.shields.power.super.first)
			if shieldSystem.shields.power.super.first >= 1 then return end
			local roomPos = shipManager:GetRoomCenter(shieldSystem.roomId)
			shipManager:DamageArea(roomPos, weakIonDamage, true)
		end
	end
end)


local systemTargetWeapons = {}
local sysWeights = {}
sysWeights.weapons = 6
sysWeights.shields = 6
sysWeights.drones = 5
sysWeights.pilot = 3
sysWeights.engines = 3
sysWeights.teleporter = 2
sysWeights.hacking = 2
sysWeights.medbay = 2
sysWeights.clonebay = 2
systemTargetWeapons.OE_DRONE_LASER_COMBAT_SMART = sysWeights

mods.oe.intelDrones = {}
local intelDrones = mods.oe.intelDrones
intelDrones["OE_DRONE_LASER_COMBAT_SMART"] = true

local combatLaserBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint("DRONE_LASER_COMBAT")

script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, drone)
	local thisShip = Hyperspace.ships(drone.iShipId)
	local otherShip = Hyperspace.ships(1 - drone.iShipId)

	local sysWeights = systemTargetWeapons[projectile.extend.name]

	if thisShip and otherShip and sysWeights then

		local random = math.random()
		if drone.iShipId == 1 and random > 0.66 then return Defines.Chain.CONTINUE end

		local sysTargets = {}
		local weightSum = 0
		
		-- Collect all player systems and their weights
		for system in vter(otherShip.vSystemList) do
			local sysId = system:GetId()
			if otherShip:HasSystem(sysId) then
				local weight = sysWeights[Hyperspace.ShipSystem.SystemIdToName(sysId)] or 1
				if weight > 0 then
					weightSum = weightSum + weight
					table.insert(sysTargets, {
						id = sysId,
						weight = weight
					})
				end
			end
		end
		
		-- Pick a random system using the weights
		if #sysTargets > 0 then
			local rnd = math.random(weightSum);
			for i = 1, #sysTargets do
				if rnd <= sysTargets[i].weight then
					drone.targetLocation = otherShip:GetRoomCenter(otherShip:GetSystemRoom(sysTargets[i].id))
					return Defines.Chain.CONTINUE
				end
				rnd = rnd - sysTargets[i].weight
			end
			error("Weighted selection error - reached end of options without making a choice!")
		end
	end
	return Defines.Chain.CONTINUE
end)

script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, drone)
	local intel = intelDrones[projectile.extend.name]
	if intel then
		local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space

		local ionPoint = get_point_local_offset(projectile.position,projectile.target or projectile.target1, 0, 20)
		local ionTarget = get_point_local_offset(projectile.target or projectile.target1, projectile.position, 0, -15)
		local ion = spaceManager:CreateLaserBlast(
			combatLaserBlueprint,
			ionPoint,
			projectile.currentSpace,
			drone.iShipId,
			ionTarget,
			projectile.destinationSpace,
			projectile.heading)
		ion:ComputeHeading()
		
		local ionPoint2 = get_point_local_offset(projectile.position,projectile.target or projectile.target1, 0, -20)
		local ionTarget2 = get_point_local_offset(projectile.target or projectile.target1, projectile.position, 0, 15)
		local ion2 = spaceManager:CreateLaserBlast(
			combatLaserBlueprint,
			ionPoint2,
			projectile.currentSpace,
			drone.iShipId,
			ionTarget2,
			projectile.destinationSpace,
			projectile.heading)
		ion2:ComputeHeading()
		projectile:Kill()
	end	
	return Defines.Chain.CONTINUE
end)