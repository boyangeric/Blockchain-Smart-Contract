///SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;
 
/// @title Contract to agree on the lunch venue
/// @author Dilum Bandara , CSIRO ’s Data61
/// ISSUE SOLVED 1-7
/// ISSUE 1: In the doVote function, added a condition to check if a friend has voted
/// ISSUE 2: In addFriend and addRestaurant functions, added conditions to check if the friend name or restaurant name have duplicates, if they have, ignore the addition.
/// ISSUE 3: Added a voteState variable to keep track of the vote phase and added conditions in the doVote function to check the state variable to prevent chaos
/// ISSUE 4: Added openVoting function to allow manager to set a timeout variable specifying how long the vote will be open before opening vote. Once the time is up, friends can no long vote and the most voted restaurant can be checked.
/// ISSUE 5: Added a modifier-contractIsActive() and a function deactivateContract to allow the manager diabling the contract
/// ISSUE 6, Used more simple data structures for implementation
/// ISSUE 7, Added more test cases to improve coverage 

contract LunchVenue {
    struct Friend {
        string name;
        bool voted; // Vote state
    }
    struct Vote {
        address voterAddress;
        uint restaurant;
    }
    mapping ( uint => string ) public restaurants; // List of restaurants ( restaurant no , name )
    mapping ( address => Friend ) public friends; // List of friends ( address , Friend )
    uint public numRestaurants = 0;
    uint public numFriends = 0;
    uint public numVotes = 0;
    address public manager; // Contract manager
    string public votedRestaurant = ""; // Where to have lunch
    mapping ( uint => Vote ) public votes; // List of votes ( vote no , Vote )
    mapping ( uint => uint ) private _results; // List of vote counts ( restaurant no , no of votes )
    bool public voteOpen = true; // voting is open
    uint public voteState = 0; // 0: Create, 1: VoteOpen, 2: VoteClose -- A state variable to keep track of the current phase of the contract, default to creat phase
    bool public restaurantExist = false;
    uint public deadlineBlockNumber; // Deadline defined in block number
    bool public contractActive;
    /**
    * @dev Set manager when contract starts
    */
    constructor () {
        manager = msg.sender; // Set contract creator as manager
        contractActive = true; // Contract is active when it's created, ISSUE 5
    }

    // ISSUE 5
    function deactivateContract() public restricted {
        contractActive = false; // Disable the contract
    }
    
    /**
    * @notice Add a new restaurant
    *
    * @param name Restaurant name
    * @return Number of restaurants added so far
    */
    function addRestaurant (string memory name) public restricted contractIsActive
    returns (uint) {
        // ISSUE2: Ensure no duplicate restaurant name.
        // Check all restaurant names and see if "name" already exists
        for(uint i = 1; i <= numRestaurants; i++) {
            if (keccak256(abi.encodePacked(restaurants[i])) == keccak256(abi.encodePacked(name))) {
                restaurantExist = true;
            }
        } 
        if (restaurantExist == false && voteState == 0 && bytes(name).length > 0) { // if restaurant name doesnt exist, numRestaurants + 1, else just return the original value
            numRestaurants++;
            restaurants[numRestaurants] = name;
        } 
        restaurantExist = false;
        return numRestaurants;
    }
    
    /**
    * @notice Add a new friend to voter list
    *
    * @param friendAddress Friend ’s account / address
    * @param name Friend ’s name
    * @return Number of friends added so far
    */
    function addFriend (address friendAddress, string memory name) public restricted contractIsActive
    returns (uint) {
        // ISSUE2: Ensure that the a friend can only be added once. 
        // If not added, add it and numFriends + 1
        if(bytes(friends[friendAddress].name).length == 0 && voteState == 0) {
            Friend memory f;
            f.name = name;
            f.voted = false;
            friends[friendAddress] = f;
            numFriends++;
            return numFriends;
        } else { // If already added, just return numFriends
            return numFriends;
        }
    }

    // ISSUE3 & ISSUE4
    // add a function for the manager to open the voting
    function openVoting(uint blocks) public restricted contractIsActive{
        if (voteState == 0) {// Voting can only be opened during the create phase- 0: Create
            voteState = 1; // 1: VoteOpen
            deadlineBlockNumber = block.number + blocks;
        }
    }
 
    /**
    * @notice Vote for a restaurant
    *
    * @param restaurant Restaurant number being voted
    * @return validVote Is the vote valid ? A valid vote should be from a registered end to a registered restaurant
    */
    function doVote (uint restaurant) public votingOpen contractIsActive returns (bool validVote){
        validVote = false; // Is the vote valid ?
        if (bytes(friends[msg.sender].name).length != 0 && !friends[msg.sender].voted && voteState == 1 ) { // ISSUE 1: Ensure that the friend exists and has not voted yet
            if (bytes(restaurants[restaurant]).length != 0) { // Ensure restaurant exists
                if (block.number <= deadlineBlockNumber) { //ISSUE 4, Only accept vote during the voting period
                    validVote = true ;
                    friends[msg.sender].voted = true ;
                    Vote memory v;
                    v.voterAddress = msg.sender;
                    v.restaurant = restaurant;
                    numVotes++;
                    votes[numVotes] = v;
                } else { // If voting period passed, change voteState to close
                    voteState = 2;
                    finalResult();
                }
            }
        }
        if (numVotes >= numFriends/2 + 1) { // Quorum is met
            finalResult();
        }
        return validVote;
    }
    /**
    * @notice Determine winner restaurant
    * @dev If top 2 restaurants have the same no of votes , result depends on vote order
    */
    function finalResult() private{
        uint highestVotes = 0;
        uint highestRestaurant = 0;
        voteState = 2; // 2: VoteClose Voting is now closed
        for (uint i = 1; i <= numVotes; i++) { // For each vote
            uint voteCount = 1;
            if( _results[votes[i].restaurant] > 0) { // Already start counting
                voteCount += _results[votes[i].restaurant];
            }
            _results[votes[i].restaurant] = voteCount;
            if (voteCount > highestVotes){ // New winner
                highestVotes = voteCount;
                highestRestaurant = votes[i].restaurant;
            }
        }
        votedRestaurant = restaurants[highestRestaurant]; // Chosen restaurant
        voteOpen = false; // Voting is now closed
    }
        /**
        * @notice Only the manager can do
        */
        modifier restricted() {
            require(msg.sender == manager, "Can only be executed by the manager");
            _;
        }
        /**
        * @notice Only when voting is still open
        */
        modifier votingOpen() {
            require (voteOpen == true, "Can vote only while voting is open.") ;
            _;
        }

        // ISSUE 5
        // New modifier to require that the contract is active
        modifier contractIsActive() {
            require(contractActive == true, "The contract needs to be active.");
        _;
    }
}