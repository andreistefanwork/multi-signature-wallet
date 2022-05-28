pragma solidity >=0.4.25 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MultiSignatureWallet is ReentrancyGuard {
    struct Transaction {
        address to;
        uint amount;
        uint numOfApprovals;
        mapping(address => bool) approvers;
        bool executed;
    }

    mapping(address => bool) public owners;
    uint public requiredApprovals;
    Transaction[] public transactions;

    event Deposit(uint indexed amount);
    event TransactionSubmitted(address indexed to, uint indexed amount);
    event TransactionApproved(uint indexed index, address indexed byWho);
    event TransactionRevoked(uint indexed index, address indexed byWho);
    event TransactionExecuted(address indexed to, uint indexed amount);

    modifier onlyOwners(address caller) {
        require(owners[caller], "Only owners of this multi-signature wallet can perform the operation.");
        _;
    }

    modifier transactionMustBePending(uint index) {
        require(index >= 0 && index < transactions.length, "Transaction index out of bounds.");
        require(!transactions[index].executed, "Transaction is already executed.");
        _;
    }

    constructor(address[] memory owners_, uint requiredApprovals_) {
        for (uint i = 0; i < owners_.length; i++) {
            address owner = owners_[i];
            owners[owner] = true;
        }

        requiredApprovals = requiredApprovals_;
    }

    receive() external payable {
        emit Deposit(msg.value);
    }

    function submitTransaction(address to, uint amount) external onlyOwners(msg.sender) {
        Transaction storage transaction = transactions.push();
        transaction.to = to;
        transaction.amount = amount;

        emit TransactionSubmitted(to, amount);
    }

    function approveTransaction(uint index) external onlyOwners(msg.sender) transactionMustBePending(index) {
        Transaction storage transaction = transactions[index];

        require(!transaction.approvers[msg.sender], "Transaction is already approved by the caller.");

        transaction.approvers[msg.sender] = true;
        transaction.numOfApprovals++;

        emit TransactionApproved(index, msg.sender);
    }

    function revokeTransaction(uint index) external onlyOwners(msg.sender) transactionMustBePending(index) {
        Transaction storage transaction = transactions[index];

        require(transaction.approvers[msg.sender], "Transaction has not been approved by the caller before.");

        transaction.approvers[msg.sender] = false;
        transaction.numOfApprovals--;

        emit TransactionRevoked(index, msg.sender);
    }

    function executeTransaction(uint index) external onlyOwners(msg.sender) transactionMustBePending(index) nonReentrant {
        Transaction storage transaction = transactions[index];

        require(transaction.numOfApprovals >= requiredApprovals, "Transaction cannot be executed, not enough approvals.");

        (bool success, ) = payable(transaction.to).call{value: transaction.amount}("");
        require(success, "Failed to execute transaction.");

        transaction.executed = true;

        emit TransactionExecuted(transaction.to, transaction.amount);
    }
}
