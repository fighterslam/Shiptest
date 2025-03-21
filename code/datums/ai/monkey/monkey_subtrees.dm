/datum/ai_planning_subtree/monkey_tree/SelectBehaviors(datum/ai_controller/monkey/controller, seconds_per_tick)
	var/mob/living/living_pawn = controller.pawn

	if(SHOULD_RESIST(living_pawn) && SPT_PROB(MONKEY_RESIST_PROB, seconds_per_tick))
		LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/resist)) //BRO IM ON FUCKING FIRE BRO
		return SUBTREE_RETURN_FINISH_PLANNING //IM NOT DOING ANYTHING ELSE BUT EXTUINGISH MYSELF, GOOD GOD HAVE MERCY.

	var/list/enemies = controller.blackboard[BB_MONKEY_ENEMIES]

	if(HAS_TRAIT(controller.pawn, TRAIT_PACIFISM)) //Not a pacifist? lets try some combat behavior.
		return

	var/mob/living/selected_enemy
	if(length(enemies) || controller.blackboard[BB_MONKEY_AGRESSIVE]) //We have enemies or are pissed
		var/list/valids = list()
		for(var/mob/living/possible_enemy in view(MONKEY_ENEMY_VISION, living_pawn))
			if(possible_enemy == living_pawn || (!enemies[possible_enemy] && (!controller.blackboard[BB_MONKEY_AGRESSIVE] || HAS_AI_CONTROLLER_TYPE(possible_enemy, /datum/ai_controller/monkey)))) //Are they an enemy? (And do we even care?)
				continue
			// Weighted list, so the closer they are the more likely they are to be chosen as the enemy
			valids[possible_enemy] = CEILING(100 / (get_dist(living_pawn, possible_enemy) || 1), 1)

		selected_enemy = pick_weight(valids)

		if(selected_enemy)
			if(!selected_enemy.stat) //He's up, get him!
				if(living_pawn.health < MONKEY_FLEE_HEALTH) //Time to skeddadle
					controller.blackboard[BB_MONKEY_CURRENT_ATTACK_TARGET] = selected_enemy
					LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/monkey_flee))
					return //I'm running fuck you guys

				if(controller.TryFindWeapon()) //Getting a weapon is higher priority if im not fleeing.
					return SUBTREE_RETURN_FINISH_PLANNING

				controller.blackboard[BB_MONKEY_CURRENT_ATTACK_TARGET] = selected_enemy
				controller.current_movement_target = selected_enemy
				if(controller.blackboard[BB_MONKEY_RECRUIT_COOLDOWN] < world.time)
					LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/recruit_monkeys))
				LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/battle_screech/monkey))
				LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/monkey_attack_mob))
				return SUBTREE_RETURN_FINISH_PLANNING //Focus on this

			else //He's down, can we disposal him?
				var/obj/machinery/disposal/bodyDisposal = locate(/obj/machinery/disposal/) in view(MONKEY_ENEMY_VISION, living_pawn)
				if(bodyDisposal)
					controller.blackboard[BB_MONKEY_CURRENT_ATTACK_TARGET] = selected_enemy
					controller.blackboard[BB_MONKEY_TARGET_DISPOSAL] = bodyDisposal
					LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/disposal_mob))
					return SUBTREE_RETURN_FINISH_PLANNING

	if(prob(5))
		LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/use_in_hand))

	if(selected_enemy || !SPT_PROB(MONKEY_SHENANIGAN_PROB, seconds_per_tick))
		return

	if(world.time >= controller.blackboard[BB_MONKEY_NEXT_HUNGRY] && controller.TryFindFood())
		return

	if(prob(50))
		var/list/possible_targets = list()
		for(var/atom/thing in view(2, living_pawn))
			if(!thing.mouse_opacity)
				continue
			if(thing.IsObscured())
				continue
			possible_targets += thing
		var/atom/target = pick(possible_targets)
		if(target)
			controller.current_movement_target = target
			LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/use_on_object))
			return

	if(prob(5) && (locate(/obj/item) in living_pawn.held_items))
		var/list/possible_receivers = list()
		for(var/mob/living/candidate in oview(2, controller.pawn))
			possible_receivers += candidate

		if(length(possible_receivers))
			var/mob/living/target = pick(possible_receivers)
			controller.current_movement_target = target
			LAZYADD(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/give))
			return

	controller.TryFindWeapon()
