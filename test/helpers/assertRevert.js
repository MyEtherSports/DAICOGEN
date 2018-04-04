//https://github.com/OpenZeppelin/zeppelin-solidity/blob/f4228f1b49d6d505d3311e5d962dfb0febdf61df/test/helpers/assertRevert.js
export default async promise => {
  try {
    await promise;
    assert.fail('Expected revert not received');
  } catch (error) {
    const revertFound = error.message.search('revert') >= 0;
    assert(revertFound, `Expected "revert", got ${error} instead`);
  }
};