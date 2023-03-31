-- + Shortcuts for the minifier + --

local models_model = models.model
local anim_model = animations.model
local kb = keybinds

-- + --

local main_page = action_wheel:newPage()
action_wheel:setPage(main_page)

local UVParts = {
	body = { "body", "udder" },
	head = { "head", "hornl", "hornr" },
	leg_br = { "leg0" },
	leg_bl = { "leg1" },
	leg_fr = { "leg2", RIGHT_ARM = { "leg2" } },
	leg_fl = { "leg3", LEFT_ARM = { "leg3" } }
}
local PartsMushroom = {
	body = "mushrooms",
	head = "mushroom_front"
}

local GNA = require("libs.GNanim")
local States = { Move = GNA.newStateMachine(), Arms = GNA.newStateMachine(), Attack = GNA.newStateMachine(), Dance = GNA.newStateMachine() }
States.Move.blendTime = 0.18

local Keys = {
    attack = kb:newKeybind("attack", kb:getVanillaKey("key.attack")),
    interact = kb:newKeybind("interact", kb:getVanillaKey("key.use"))
}

function pings.attack()
	States.Attack:setState(player:isLeftHanded() and anim_model.Interact_Left or anim_model.Interact_Right, true)
end

Keys.attack:setOnPress(function() if not action_wheel:isEnabled() then pings.attack() end end)

function pings.interact()
	local plr, air = player, "minecraft:air"
	if plr:getTargetedBlock(true, 5).id == air then return end

	local held_item = plr:getHeldItem()
	if held_item.id == air then return end

	local states_attack = States.Attack
	if held_item:getUseAction() == "NONE" or plr:getHeldItem(true):getUseAction() == "NONE" then
		states_attack:setState(plr:isLeftHanded() and anim_model.Interact_Left or anim_model.Interact_Right, true)
    end
end
Keys.interact:setOnPress(function() pings.interact() end)

local is_legs_busy = false
local btn_dance = main_page:newAction(2)

local is_dancing, polish_sound = false, 'polish'
function pings.start_dance(pos)
	sounds:playSound(polish_sound, pos, 1, 1)
	States.Dance:setState(animations.model.PolishCow)
	btn_dance:color(vectors.hexToRGB("#FF0000")):item('barrier'):title('Stop Dancing')
end
function pings.end_dance()
	sounds:stopSound(polish_sound)
	States.Dance:setState(nil)
	btn_dance:color(vectors.hexToRGB("#B00B1E")):item('jukebox'):title('Dance')
end

events.TICK:register(function()
	local plr = player
    local vel, radRot, pose = plr:getVelocity(), math.rad(-plr:getBodyYaw()), plr:getPose()
	
    local local_vel = vec( 
		math.cos(radRot) * vel.x + math.sin(radRot) * vel.z,
    	math.sin(radRot) * vel.x + math.cos(radRot) * vel.z 
    )
    local distance_travel = local_vel:length()
	
	if is_dancing and (distance_travel>0.03 or math.abs(vel.y)>0.03) then 
		pings.end_dance()
		is_dancing = false 
	end

	local states_move, states_arms = States.Move, States.Arms

	local active_item = plr:getActiveItem().id	
	local minecraft_tag = "minecraft:"

	if active_item ~= (minecraft_tag .. "air") then
		if plr:getActiveHand() == "MAIN_HAND" then			
			local use_action, is_left_handed = plr:getActiveItem():getUseAction(), plr:isLeftHanded()

			if active_item == (minecraft_tag .. "bow") then
				states_arms:setState(anim_model.Bow)
			elseif active_item == (minecraft_tag .. "trident") then
				states_arms:setState(is_left_handed and anim_model.Trident_L or anim_model.Trident_R)
			elseif use_action == "EAT" or use_action == "DRINK" then
				states_arms:setState(is_left_handed and anim_model.Eating_L or anim_model.Eating_R)
			elseif use_action == "SPYGLASS" then
				states_arms:setState(is_left_handed and anim_model.Spyglass_L or anim_model.Spyglass_R)
			end

			is_legs_busy = true
		end
	elseif is_legs_busy then
		states_arms:setState(nil)
		is_legs_busy = false
	end

	local fast_vel = local_vel.y*12
	if pose == "SLEEPING" then
		states_move:setState(anim_model.Sleeping)
	elseif plr:getVehicle() then
		anim_model.Walking_Arms:speed(0)
		states_move:setState(anim_model.LayingDown)
	elseif pose == "SWIMMING" then
		if plr:isWet() then
			anim_model.Swimming:speed(fast_vel)
			states_move:setState(anim_model.Swimming)
		else
			if distance_travel > 0.03 then
				anim_model.Walking_Arms:speed(fast_vel)
				if not is_legs_busy then states_arms:setState(anim_model.Walking_Arms) end
			else
				if not is_legs_busy then states_arms:setState(nil) end
			end

			states_move:setState(anim_model.Flying)
		end
	else
		local models_model = models.model

		if pose == 'CROUCHING' then
			states_move.blendTime = 0.01

			if distance_travel > 0.03 then
				anim_model.Sneaking_Arms:speed(fast_vel)
				anim_model.Sneaking:speed(fast_vel)

				if not is_legs_busy then states_arms:setState(anim_model.Sneaking_Arms) end
				states_move:setState(anim_model.Sneaking)
			else
				if not is_legs_busy then states_arms:setState(nil) end
				states_move:setState(anim_model.Crouch)
			end

			models_model:setPos(0, 2, 0)
		elseif pose=="FALL_FLYING" then
			if not is_legs_busy then states_arms:setState(nil) end
			states_move:setState(anim_model.Flying)
		else
			models_model:setPos(0, 0, 0)

			if plr:isSprinting() then
				local fast_vel = local_vel.y * 16
				anim_model.Walking_Arms:speed(fast_vel)
				anim_model.Walking:speed(fast_vel)
				if not is_legs_busy then states_arms:setState(anim_model.Walking_Arms) end
				states_move:setState(anim_model.Walking)
			elseif distance_travel > 0.03 then
				anim_model.Walking_Arms:speed(fast_vel)
				anim_model.Walking:speed(fast_vel)
				if not is_legs_busy then states_arms:setState(anim_model.Walking_Arms) end
				states_move:setState(anim_model.Walking)
			else
				if not is_legs_busy then states_arms:setState(nil) end
				states_move:setState(anim_model.Idle)
				states_move.blendTime = 0.18
			end
		end
	end
end)

local armor_part_suffix = { [6] = 'helmet', [5] = 'chestplate', [4] = 'leggings', [3] = 'boots' }
local armor_types = { "leather", "chain", "gold", "iron", "diamond", "netherite" }
local armor_parts = {
	[6] = {models_model.head.helmet},
	[5] = {models_model.body.cplate, models_model.leg_fl.shoulder, models_model.leg_fr.shoulder},
	[4] = {models_model.leg_bl.greave, models_model.leg_br.greave, --[[models_model.leg_fl.greave, models_model.leg_fr.greave,]] models_model.body.waist},
	[3] = {models_model.leg_fl.boot, models_model.leg_fr.boot, models_model.leg_bl.boot, models_model.leg_br.boot}
} -- udder gets disabled when wearing leggings, btw. aesthetic reasons.
local btn_armor = main_page:newAction(1)
local function handle_armor()
	for armor_part=6, 3, -1 do  -- loop from helmet to boots
		local item = player:getItem(armor_part).id

		if item == "minecraft:air" or not btn_armor:isToggled() then 
			for k,v in ipairs(armor_parts[armor_part]) do v:setVisible(false) end 
		else
			local found_armor

			for armor_type=1, 6, 1 do -- looping through all armor types
				if item == ("minecraft:" .. armor_types[armor_type] .. "_" .. armor_part_suffix[armor_part]) then
					found_armor = armor_type
					break
				end
			end

			if found_armor then
				for k,v in ipairs(armor_parts[armor_part]) do
	
					v:setVisible(true)

					if armor_part>4 then -- helmet, chestplate
						v:setUVPixels(
							math.floor(found_armor/4) * 48,
							40 * ((found_armor-1)%3)
						)
					else  -- leggings, boots
						v:setUVPixels(
							0,
							found_armor*16 - 16
						)
					end
				end
			elseif armor_part == 6 and item == "minecraft:turtle_helmet" then
				models_model.head.helmet:setUVPixels(80, -24)
				models_model.head.helmet:setVisible(true)
			elseif armor_part == 5 and item == "minecraft:elytra" then
				-- todo: actual elytra code
				for _,v in ipairs(armor_parts[5]) do v:setVisible(false) end
			end	
		end
	end
end

btn_armor:item('netherite_chestplate'):title('Enable armor rendering')
btn_armor:toggleItem('barrier'):toggleTitle('Disable armor rendering')
btn_armor:onToggle(function() btn_armor:toggled(true) end)
btn_armor:onUntoggle(function() btn_armor:toggled(false) end)
btn_armor:toggled( true )

local function show_arms(v)
	models_model.leg_fl.LEFT_ARM:setVisible(v)
	models_model.leg_fr.RIGHT_ARM:setVisible(v)
end

local btn_pov = main_page:newAction(3)
events.RENDER:register(function(tick, source)
	local orig_head_rot = vanilla_model.HEAD:getOriginRot()
	models_model.head:setRot(orig_head_rot)

	if source == "FIRST_PERSON" then
		if renderer:isFirstPerson() then
			show_arms(true)
			renderer:offsetCameraPivot(vec(0, btn_pov:isToggled() and -0.3 or 0, 0))
		else 
			show_arms(false)
			renderer:offsetCameraPivot(vec(0, player:getPose() == "SWIMMING" and 0 or -0.4, 0)) 
		end
	else
		show_arms(false)
	end

	handle_armor()
	local show_udder = player:getItem(4).tag == nil or not btn_armor:isToggled()
	models_model.body.udder:setVisible(show_udder)

	local foreleg_left, foreleg_right = models_model.leg_fl, models_model.leg_fr
	local offset_rot = 'offsetRot'
	local rot = vec(0, 0, 0)

	if player:getActiveItem().id == "minecraft:bow" then
		rot = vec(
			orig_head_rot.x * 0.9, 
			orig_head_rot.y * 0.9,
			0
		)
	end

	foreleg_left[offset_rot](foreleg_left, r)
    foreleg_right[offset_rot](foreleg_right, r)

	renderer:setShadowRadius(0.7)	
end)
btn_pov:title('Set POV to model height'):toggleTitle('Set POV to normal height')
btn_pov:item('player_head{SkullOwner:"MHF_Cow"}'):toggleItem('player_head')
btn_pov:color(vectors.hexToRGB('#413424'))
btn_pov:onToggle(function() btn_pov:toggled(true) end)
btn_pov:onUntoggle(function() btn_pov:toggled(false) end)

-- + Sounds + --

local last_seen_health
local health_damage_delay = 0

function pings.cow_hurt(pos, pitch)
	sounds:playSound("entity.cow.hurt", pos, 1, pitch, false)
end
function pings.cow_dead(pos, pitch)
	sounds:playSound("entity.cow.death", pos, 1, pitch, false)
end
function pings.cow_moo(pos)
	sounds:playSound("entity.cow.ambient", pos, 1, 1, false)
end

random_time = 50 + math.random() * 100

events.TICK:register(function()
	local pos = player:getPos()
	local health = player:getHealth()

	-- Player is hurt
	if health > 0 then
		if health < last_seen_health then
			if health_damage_delay == 0 then
				pings.cow_hurt(pos,0.8+math.random(0,4)*0.1)
				health_damage_delay = 5
			end
			random_time = 250 + math.random() * 500
		end

		if health_damage_delay > 0 then health_damage_delay = health_damage_delay - 1 end
		last_seen_health = health
	end

	-- Player dies
	if player:getDeathTime()==1 then
		pings.cow_dead(pos, 0.8 + math.random(0, 4) * 0.1)
	end

	-- Random moo's
	if random_time>0 then
		random_time=random_time-1

		if random_time==0 then 
			pings.cow_moo(pos) 
			random_time = 250 + math.random() * 500 
		end
	end
end)

local btn_moo = main_page:newAction(5)
btn_moo:color(vectors.hexToRGB("#413625")):item('note_block'):title('Make noise')
btn_moo:onLeftClick(function() random_time = 1 end)

local btn_type = main_page:newAction(4)
local btn_type_curr = 1
local type_infos = {
	{'Cow',             vectors.hexToRGB('#413424'), 'wheat'},
	{'Red Mooshroom',   vectors.hexToRGB('#951716'), 'red_mushroom'},
	{'Brown Mooshroom', vectors.hexToRGB('#8B684A'), 'brown_mushroom'}
}

function set_part_uv(part, model, x, y)
	for k,v in pairs(part) do
		if type(v) == "table" then
			set_part_uv(v, model[k], x, y)
		else
			model[v]:setUV(x, y)
		end
	end
end

function pings.change_cow_type(t)
	local current_cow, next_cow= type_infos[t], type_infos[t+1>3 and 1 or t+1]
	btn_type:title('Change to '..next_cow[1]):color(next_cow[2]):item(next_cow[3])

	set_part_uv( UVParts, models_model, 0, 0.25 * (t-1) )

	local mushroom = (t >= 2)
	for parent,child in pairs(PartsMushroom) do
		local m = models_model[parent][child]
		m:setVisible( mushroom )
		if mushroom then
			m:setUV((1/8)*(t-2),0)
		end
	end
end
pings.change_cow_type(btn_type_curr)
btn_type:onLeftClick(function()
	btn_type_curr = btn_type_curr + 1
	if btn_type_curr > 3 then btn_type_curr = 1 end
	pings.change_cow_type(btn_type_curr)
end)

btn_dance:color(vectors.hexToRGB("#B00B1E")):item('jukebox'):title('Dance')
btn_dance:onLeftClick(function()
	is_dancing = not is_dancing
	if is_dancing then pings.start_dance( player:getPos() )
	else pings.end_dance() end
end)

-- + Setup + --

events.ENTITY_INIT:register(function()
	local vanilla_m = vanilla_model
	vanilla_m.ALL:setVisible(false)
	vanilla_m.HELD_ITEMS:setVisible(true)
	vanilla_m.PARROTS:setVisible(true)
	
	local nameplate_entity = nameplate.ENTITY
	nameplate_entity:setScale(0, 0, 0)
	nameplate_entity:setText("")
	if type(nameplate_entity.visible) == 'function' then
		nameplate_entity:visible(false)
	else
		nameplate_entity.visible = false
	end

	last_seen_health = player:getHealth()
end)
