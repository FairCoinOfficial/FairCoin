// Copyright (c) 2014 The Bitcoin Core developers
// Copyright (c) 2014-2015 The Dash developers
// Copyright (c) 2015-2026 The FairCoin Core Developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "primitives/transaction.h"
#include "main.h"

#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(main_tests)

BOOST_AUTO_TEST_CASE(subsidy_limit_test)
{
    // Block 0: unspendable genesis (10 FAIR standard reward)
    CAmount nSubsidy = GetBlockValue(0);
    BOOST_CHECK_EQUAL(nSubsidy, 10 * COIN);

    // Block 1: premine of 5,000,000 FAIR
    nSubsidy = GetBlockValue(1);
    BOOST_CHECK_EQUAL(nSubsidy, 5000000 * COIN);

    nSubsidy = GetBlockValue(10000);
    BOOST_CHECK_EQUAL(nSubsidy, 10 * COIN);

    // First halving at block 525600: 5 FAIR
    nSubsidy = GetBlockValue(525600);
    BOOST_CHECK_EQUAL(nSubsidy, 5 * COIN);

    // Second halving at block 1051200: 2.5 FAIR
    nSubsidy = GetBlockValue(1051200);
    BOOST_CHECK_EQUAL(nSubsidy, 250000000); // 2.5 COIN

    // Third halving at block 1576800: 1.25 FAIR (minimum)
    nSubsidy = GetBlockValue(1576800);
    BOOST_CHECK_EQUAL(nSubsidy, 125000000); // 1.25 COIN

    // After many halvings, should still be minimum 1.25 FAIR
    nSubsidy = GetBlockValue(10000000);
    BOOST_CHECK_EQUAL(nSubsidy, 125000000);

    // Verify all subsidies are in money range
    BOOST_CHECK(MoneyRange(GetBlockValue(0)));
    BOOST_CHECK(MoneyRange(GetBlockValue(100)));
    BOOST_CHECK(MoneyRange(GetBlockValue(525600)));
}

BOOST_AUTO_TEST_SUITE_END()
