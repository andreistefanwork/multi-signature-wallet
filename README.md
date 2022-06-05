# Multi-signature Wallet

### Implementation details:
- the contract implements a receive function
- wallet owners can submit transactions (from, to, amount)
- wallet owners can approve and revoke approval of pending transactions (at index)
- wallet owners can execute a transaction after the required number of approvals is reached
- wallet owners' addresses and the number of required approvals for transactions are defined at contract creation
