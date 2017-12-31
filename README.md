# KindTrust
Decentralized crowdfunding platform on blockchain (backend)



Important files:
`contracts/KindTrust.sol`: The smart contract that ties together organizations, projects, suppliers, purchases, and donors
`seed.js`: These commands can be used to seed a blockchain, helping with testing



To test the contract, use two terminal windows:

1: `npm install` then start a test blockchain
`npm install`
`node_modules/.bin/ganache-cli`

2: Deploy with `truffle`
`truffle compile`
`truffle migrate`
`truffle exec seed.js`



To add new files to IPFS:

`cd go-ipfs`
`./ipfs add ../KindTrust.jpg`
`./ipfs add ../SampleDescription.txt`



Try adding additional functionality to `seed.js`
