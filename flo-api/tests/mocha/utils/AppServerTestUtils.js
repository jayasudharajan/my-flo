
function withRandomPort(config) {
  return Object.assign({}, config, { port: Math.floor(Math.random() * 500) + 9000  });
}

module.exports = {
  withRandomPort: withRandomPort
};
