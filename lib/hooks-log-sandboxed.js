// Generated by CoffeeScript 1.10.0
var hooksLog, hooksLogSandboxed, logger;

hooksLog = require('./hooks-log');

logger = null;

hooksLogSandboxed = function(logs, content) {
  if (logs == null) {
    logs = [];
  }
  logs = hooksLog(logs, logger, content);
  return logs;
};

module.exports = hooksLogSandboxed;