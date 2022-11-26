/mob/living/carbon/human/consistent

/// Unit test for the contents barfer element
/datum/unit_test/contents_barfer

/datum/unit_test/contents_barfer/Run()
	var/mob/living/simple_animal/hostile/space_dragon/dragon_time = allocate(/mob/living/simple_animal/hostile/space_dragon)
	var/mob/living/carbon/human/to_be_consumed = allocate(/mob/living/carbon/human/consistent)
	TEST_ASSERT(dragon_time.eat(to_be_consumed), "The space dragon failed to consume the dummy!")
	TEST_ASSERT_EQUAL(to_be_consumed.loc, dragon_time, "The dummy's location, after being successfuly consumed, was not within the space dragon's contents!")
	dragon_time.death()
	TEST_ASSERT(isturf(to_be_consumed.loc), "After dying, the space dragon did not eject the consumed dummy content barfer element.")

/// Unit tests that the space dragon - when its rift expires and it gets qdel'd - doesn't delete all the mobs it has eaten
/datum/unit_test/space_dragon_expiration

/datum/unit_test/space_dragon_expiration/Run()
	var/mob/living/simple_animal/hostile/space_dragon/dragon_time = allocate(/mob/living/simple_animal/hostile/space_dragon)
	var/mob/living/carbon/human/to_be_consumed = allocate(/mob/living/carbon/human/consistent)

	dragon_time.mind_initialize()
	var/datum/antagonist/space_dragon/dragon_antag_datum = dragon_time.mind.add_antag_datum(/datum/antagonist/space_dragon)
	dragon_time.eat(to_be_consumed)

	dragon_antag_datum.riftTimer = dragon_antag_datum.maxRiftTimer + 1
	dragon_antag_datum.rift_checks()

	TEST_ASSERT(QDELETED(dragon_time), "The space dragon wasn't deleted after having its rift timer exceeded!")
	TEST_ASSERT(!QDELETED(to_be_consumed), "After having its rift timer exceeded, the dragon deleted all the dummy instead!")
	TEST_ASSERT(isturf(to_be_consumed.loc), "After having its rift timer exceeded, the dragon did not eject all the dummy!")
