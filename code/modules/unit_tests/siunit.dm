/datum/unit_test/siunit/Run()
	TEST_ASSERT_EQUAL(siunit(1234, "Pa", 1), "1.2 kPa", "")
	TEST_ASSERT_EQUAL(siunit(1234, "Pa", 2), "1.23 kPa", "")
	TEST_ASSERT_EQUAL(siunit(1234, "Pa", 3), "1.234 kPa", "")
	TEST_ASSERT_EQUAL(siunit(0.5345, "A", 0), "535 mA", "")
	TEST_ASSERT_EQUAL(siunit(0.5344, "A", 0), "534 mA", "")
	TEST_ASSERT_EQUAL(siunit(-0.5344, "A", 0), "-534 mA", "")
	TEST_ASSERT_EQUAL(siunit(1000, "Pa", 4), "1 kPa", "")
	TEST_ASSERT_EQUAL(siunit(0, "Pa"), "0 Pa", "")
	TEST_ASSERT_EQUAL(siunit(1e3, "Pa"), "1 MPa", "") // test for pascal require *10e-3, as the game thinks in kPa, the proc siunit in Pa
	TEST_ASSERT_EQUAL(siunit(999e3, "Pa"), "999 MPa", "")
	TEST_ASSERT_EQUAL(siunit(999.9e3, "Pa"), "999.9 MPa" , "")
	TEST_ASSERT_EQUAL(siunit(999.9e3, "Pa", 0), "1 GPa", "")
	TEST_ASSERT_EQUAL(siunit(1e6, "Pa"), "1 GPa", "")
	TEST_ASSERT_EQUAL(siunit(3e17, "Pa"), "300000 PPa", "")
