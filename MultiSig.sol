// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSig {

    struct Transaction{
        address destination;
        uint256 value;
        bool executed;
        bytes data;
    }

    address[] public owners;
    uint256 public required;
    Transaction[] public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;

    constructor(address[] memory _addresses, uint256 _required){

        if(_addresses.length == 0){
            revert("Array needs to be greater than zero");
        }

        if(_required == 0 || _required > _addresses.length){
            revert("Confirmation has to be greater than zero and <= than addresses length");
        }

        owners = _addresses;
        required = _required;
    }

    function transactionCount() public view returns(uint){
        return transactions.length;
    }

    function addTransaction(address _destination, uint256 _value, bytes calldata _data) internal returns(uint256){
        transactions.push(Transaction(_destination, _value, false, _data));
        return transactions.length - 1;
    }

    function confirmTransaction(uint _id) public onlyOwners{
        confirmations[_id][msg.sender] = true;
        if(isConfirmed(_id)){
            executeTransaction(_id);
        }
    }

    function getConfirmationsCount(uint transactionId) public view returns(uint256){
        uint256 totalConfirmations = 0;
        for(uint i = 0; i < owners.length; i++){
            if(confirmations[transactionId][owners[i]]){
                totalConfirmations = totalConfirmations + 1;
            }
        }
        return totalConfirmations;
    }

    function submitTransaction(address _destination, uint256 _value, bytes calldata _data) external onlyOwners{
        uint id = addTransaction(_destination, _value, _data);
        confirmTransaction(id);
    }

    function isConfirmed(uint256 id) public view returns(bool){
        uint256 totalConfirmations = getConfirmationsCount(id);

        return totalConfirmations >= required;
    }

    function executeTransaction(uint id) public{
        (bool success, bytes memory returnData) = transactions[id].destination.call{ value: transactions[id].value }(transactions[id].data);
        if(!success){
            revert("Something went wrong");
        }
        transactions[id].executed = true;
    }

    // recive function to acept funds
    receive() external payable{
        
    }
    
    // helper modifier
    function isOwner(address _address) internal view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Modifier
    modifier onlyOwners() { 
        if(!isOwner(msg.sender)){
            revert("You are not an owner");
        }
        _;
    }

}
