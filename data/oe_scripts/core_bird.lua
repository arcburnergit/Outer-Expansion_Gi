local mod_name = "Outer Expansion: Gi"
if not mods.oe then
	error("Outer Expansion: Core not detected, please ensure it is present in the mod list and patched before "..mod_name.."!")
elseif mods.oe.core_version.major < 1 and mods.oe.core_version.minor < 2 then
	error("Outer Expansion: Core incorrect version, please update it for "..mod_name.."!")
else
	mods.oe.bird = {}
	mods.oe.bird.version = {major = 0, minor = 1}
end

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


mods.oe.bird.birdStaticImages = {}
local birdStaticImages = mods.oe.bird.birdStaticImages
birdStaticImages["oe_bird"] = {
	moving = {
		base = Hyperspace.Resources:GetImageId("people/oe_bird_base.png"),
		color = Hyperspace.Resources:GetImageId("people/oe_bird_color.png"),
		layer1 = Hyperspace.Resources:GetImageId("people/oe_bird_layer1.png"),
	},
	static = {
		base = Hyperspace.Resources:GetImageId("people/oe_bird_s_base.png"),
		color = Hyperspace.Resources:GetImageId("people/oe_bird_s_color.png"),
		layer1 = Hyperspace.Resources:GetImageId("people/oe_bird_s_layer1.png"),
	},
}
birdStaticImages["oe_bird_tech"] = {
	moving = {
		base = Hyperspace.Resources:GetImageId("people/oe_bird_tech_base.png"),
		color = Hyperspace.Resources:GetImageId("people/oe_bird_tech_color.png"),
	},
	static = {
		base = Hyperspace.Resources:GetImageId("people/oe_bird_tech_s_base.png"),
		color = Hyperspace.Resources:GetImageId("people/oe_bird_tech_s_color.png"),
	},
}
birdStaticImages["unique_oe_jay"] = {
	moving = {
		base = Hyperspace.Resources:GetImageId("people/unique_oe_jay_base.png"),
		color = Hyperspace.Resources:GetImageId("people/unique_oe_jay_color.png"),
	},
	static = {
		base = Hyperspace.Resources:GetImageId("people/unique_oe_jay_s_base.png"),
		color = Hyperspace.Resources:GetImageId("people/unique_oe_jay_s_color.png"),
	},
}

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crewmem)
	if birdStaticImages[crewmem.type] then
		local images = birdStaticImages[crewmem.type].moving
		if crewmem:AtFinalGoal() then
			images = birdStaticImages[crewmem.type].static
		end
		if tostring(crewmem.crewAnim.baseStrip) ~= tostring(images.base) then
			crewmem.crewAnim.baseStrip = images.base
		end
		if tostring(crewmem.crewAnim.colorStrip) ~= tostring(images.color) then
			crewmem.crewAnim.colorStrip = images.color
		end
		if images.layer1 and tostring(crewmem.crewAnim.layerStrips[0]) ~= tostring(images.layer1) then
			crewmem.crewAnim.layerStrips[0] = images.layer1
		end
	end
end)


mods.oe.bird.birdCrew = {}
local birdCrew = mods.oe.bird.birdCrew
birdCrew["oe_bird"] = 0.5
birdCrew["oe_bird_tech"] = 1
birdCrew["unique_oe_jay"] = 0.5

mods.oe.bird.birdCrewFull = {}
local birdCrewFull = mods.oe.bird.birdCrewFull
birdCrewFull["unique_oe_jay"] = 1

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crewmem)
	if birdCrew[crewmem.type] and crewmem.iShipId == crewmem.currentShipId then
		local shipManager = Hyperspace.ships(crewmem.iShipId)
		if not shipManager then return end
		local system = shipManager:GetSystemInRoom(crewmem.iRoomId)
		if system then
			local speed = birdCrew[crewmem.type]
			if shipManager:HasAugmentation("BOON_CREW_OE_BIRD") > 0 then
				speed = speed + 0.25
			end
			if crewmem.iShipId == 1 then
				speed = speed / 2
			end
			system:PartialRepair(speed, false)
		end
	end

	if birdCrewFull[crewmem.type] and crewmem.iShipId == crewmem.currentShipId then
		local shipManager = Hyperspace.ships(crewmem.iShipId)
		if not shipManager then return end
		for system in vter(shipManager.vSystemList) do
			local speed = birdCrewFull[crewmem.type]
			if crewmem.iShipId == 1 then
				speed = speed / 2
			end
			system:PartialRepair(speed, false)
		end
	end
end)