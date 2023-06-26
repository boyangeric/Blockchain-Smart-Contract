// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >= 0.8.00 < 0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/LunchVenue_updated.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts

contract LunchVenueTest is LunchVenue {
    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    address acc5;
    /// ’beforeAll ’ runs before all other tests
    /// More special functions are : ’beforeEach ’, ’beforeAll ’, ’afterEach ’ & ’afterAll ’
    function beforeAll() public {
        // Initiate account variables
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
        acc5 = TestsAccounts.getAccount(5);
    }
    /// Check manager
    /// account -0 is the default account that deploy contract , so it should be the manager (i.e., acc0 )
    function managerTest() public {
        Assert.equal(manager, acc0, 'Manager should be acc0');
    }
    /// Add restuarant as manager
    /// When msg.sender isn ’t specified , default account (i.e., account -0) is the sender
    function setRestaurant() public {
        Assert.equal(addRestaurant('Courtyard Cafe'), 1, 'Should be equal to 1');
        Assert.equal(addRestaurant('Uni Cafe'), 2, 'Should be equal to 2');
    }
    /// Try to add a restaurant as a user other than manager . This should fail
    /// #sender: account-1
    function setRestaurantFailure() public {
        // Try to catch reason for failure using try - catch. When using
        // try - catch we need ’this ’ keyword to make function call external
        try this.addRestaurant('Atomic Cafe') returns (uint v){
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason , check if it is as expected
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch Panic (uint /* errorCode */) { // In case of a panic
            Assert.ok(false, 'Failed unexpected with error code');
        } catch ( bytes memory /* lowLevelData */) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    /// Set friends as account-0
    /// #sender doesn ’t need to be specified explicitly for account -0
    function setFriend() public {
        /// Set friends as account - /// # sender doesn ’t need to be specified explicitly for account - function setFriend () public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
        Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2');
        Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
        Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
    }
    /// Try adding friend as a user other than manager . This should fail
    function setFriendFailure() public {
        try this.addFriend(acc4, 'Daniels') returns ( uint f) { // acc4 is not a friend
            Assert.notEqual(f, 5, 'Method execution did not fail');
        } catch Error(string memory reason ) { // In case revert () called
            // Compare failure reason , check if it is as expected
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed withunexpected reason');
        } catch Panic( uint /* errorCode */) { // In case of a panic
            Assert.ok(false, 'Failed unexpected with error code');
        } catch( bytes memory /* lowLevelData */) {
            Assert.ok(false, 'Failed unexpected');
        }
    }

    /// ISSUE 2: Try to add the same friend twice. This should fail
    function addFriendTwiceFailure() public {
        addFriend(acc5, 'Daniels');
        uint countBeforeAdding = numFriends;
        addFriend(acc5, 'Daniels');
        addFriend(acc3, 'Eric');
        addFriend(acc2, 'Erik');
        uint countAfterAdding = numFriends;
        Assert.equal(countBeforeAdding, countAfterAdding, "The count of friends should remain the same after adding the same friend again.");
    }

    /// ISSUE2: Try to add the same restaurant twice. This should fail
    function addRestaurantTwiceFailure() public {
        uint countBeforeAdding = numRestaurants;
        addRestaurant('Courtyard Cafe');
        uint countAfterAdding = numRestaurants;
        Assert.equal(countBeforeAdding, countAfterAdding, "The count of restaurants should remain the same after adding the same restaurant again.");
    }

    // Test the create voting pahse
    function createPhase() public {
        Assert.equal(voteState, 0, "Should be in create phase");
    }
    // Test cannot doVote during create phase, Vote as Bob(acc1)
    /// #sender: account-1
    function invalidVote() public {
        bool result = doVote(2);
        Assert.equal(result, false, "Voting should not be allowed during creation phase");
    }

    // Test openVoting phase
    function openVotingPhase() public {
        openVoting(100);
        Assert.equal(voteState, 1, "Should be in voting open phase");
    }

    /// Vote as Bob ( acc1 )
    /// #sender: account-1
    function vote() public {
        Assert.ok(doVote(2), "Voting result should be true");
        Assert.equal(voteState, 1, "Should still be in voting open phase");
    }

    /// Vote as Charlie
    /// #sender: account-2
    function vote2() public {
        Assert.ok(doVote(1), "Voting result should be true");
        Assert.equal(voteState, 1, "Should still be in voting open phase");
    }

    /// Try voting as a user not in the friends list . This should fail
    /// #sender: account-4
    function voteFailure() public {
        Assert.equal(doVote(1), false, "Voting result should be false");
        Assert.equal(voteState, 1, "Should be in voting open phase");
    }

    /// Try voting twice as the same user (Bob). The second vote should fail
    /// #sender: account-1
    function voteTwiceFailure() public {
        // Try to vote again as Bob
        try this.doVote(1) returns (bool validVote) {
            Assert.equal(validVote, false, "Second vote should not be successful");
        } catch Error(string memory reason) {
            // Compare failure reason , check if it is as expected
            Assert.equal(reason, 'You have already voted.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) { // In case of a panic
            Assert.ok(false, 'Failed unexpectedly with error code');
        } catch (bytes memory /* lowLevelData */) {
            Assert.ok(false, 'Failed unexpectedly');
        }
    }

    /// Vote for non-existent restaurant as Charlie ( acc2 )
    /// #sender: account-2
    function voteForInvalidRestaurant() public {
        uint invalidRestaurantNumber = numRestaurants + 1;
        bool voteResult = doVote(invalidRestaurantNumber);
        Assert.equal(voteResult, false, "Voting for a non-existent restaurant should fail");
    }

    /// Vote as Eve
    /// #sender: account-3
    function vote3() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    // Verify voting phase has closed
    function vote4() public {
        // Keep voting until quorum is met...
        Assert.equal(voteState, 2, 'Should be in vote close phase');
    }

    // Test once voting phase has closed, cannot addFriend/addRestaurant
    function voteClosed() public {
        Assert.equal(voteState, 2, 'Should be in vote close phase');
        Assert.equal(addFriend(acc4, 'Tom'), 5, 'Should still be equal to 5');
        Assert.equal(addRestaurant('Subway'), 2, 'Should still be equal to 2');
    }

    /// Verify lunch venue is set correctly
    function lunchVenueTest() public {
        Assert.equal(votedRestaurant, 'Uni Cafe', 'Selected restaurant should be Uni Cafe');
    }

    /// Verify voting is now closed
    function voteOpenTest() public {
        Assert.equal(voteOpen, false, 'Voting should be closed') ;
    }

    /// Verify voting after vote closed . This should fail
    function voteAfterClosedFailure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.equal(validVote, true, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason , check if it is as expected
            Assert.equal(reason, 'Can vote only while voting is open.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) { // In case of a panic
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /* lowLevelData */) {
            Assert.ok(false, 'Failed unexpectedly');
        }
    }

    /// Test deactivation fails when sender is not the manager
    /// #sender: account-1
    function deactivateContractFailure() public {
        try this.deactivateContract() {
            Assert.ok(false, "Method execution did not fail");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Can only be executed by the manager", "Failed with unexpected reason");
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, "Failed unexpected with error code");
        } catch (bytes memory /* lowLevelData */) {
            Assert.ok(false, "Failed unexpected");
        }
    }

    /// Test only manager can deactivate the contract
    /// #sender: account-0
    function deactivateContractTest() public {
        deactivateContract();
        Assert.equal(contractActive, false, "Contract should be inactive after deactivation by manager");
    }

}