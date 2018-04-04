//https://github.com/OpenZeppelin/zeppelin-solidity/blob/f4228f1b49d6d505d3311e5d962dfb0febdf61df/test/helpers/expectEvent.js
const assert = require('chai').assert;

const inLogs = async (logs, eventName) => {
  const event = logs.find(e => e.event === eventName);
  assert.exists(event);
};

const inTransaction = async (tx, eventName) => {
  const { logs } = await tx;
  return inLogs(logs, eventName);
};

module.exports = {
  inLogs,
  inTransaction,
};