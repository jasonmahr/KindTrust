KindTrust = artifacts.require('./KindTrust.sol');

// Run using `truffle exec seed.js`
module.exports = function() {
  KindTrust.deployed().then(function(instance) {
    // The hashes correspond to KindTrust.jpg and SampleDescription.txt. View: http://ipfs.io/ipfs/hash.
    instance.addOrganization('Charity', 'QmSQH5xm4i1QAKTDuBuEYFW6EUomb1WPBY4zXmxXJXCZsj',
        'QmUJ9fH9wuDQCvymLo7K7kmzP41mTzXoxmR6XEzG1WsxmW').then(console.log);
  });
}
