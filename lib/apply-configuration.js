// Generated by CoffeeScript 1.10.0
var EventEmitter, applyConfiguration, clone, coerceToArray, logger,
  hasProp = {}.hasOwnProperty;

EventEmitter = require('events').EventEmitter;

clone = require('clone');

logger = require('./logger');

coerceToArray = function(value) {
  if (Array.isArray(value)) {
    return value;
  } else if (typeof value === 'string') {
    return [value];
  } else if (value == null) {
    return [];
  } else {
    return value;
  }
};

applyConfiguration = function(config) {
  var authHeader, configuration, customKey, customVal, i, key, len, method, ref, ref1, value;
  configuration = {
    blueprintPath: null,
    server: null,
    emitter: new EventEmitter,
    hooksCode: null,
    custom: {},
    options: {
      'dry-run': false,
      silent: false,
      reporter: null,
      output: null,
      debug: false,
      header: null,
      user: null,
      'inline-errors': false,
      details: false,
      method: [],
      only: [],
      color: true,
      level: 'info',
      timestamp: false,
      sorted: false,
      names: false,
      hookfiles: null,
      sandbox: false,
      language: 'nodejs',
      'hook-worker-timeout': 5000
    }
  };
  for (key in config) {
    if (!hasProp.call(config, key)) continue;
    value = config[key];
    if (key !== 'custom') {
      configuration[key] = value;
    } else {
      if (configuration['custom'] == null) {
        configuration['custom'] = {};
      }
      ref = config['custom'] || {};
      for (customKey in ref) {
        if (!hasProp.call(ref, customKey)) continue;
        customVal = ref[customKey];
        configuration['custom'][customKey] = clone(customVal, false);
      }
    }
  }
  configuration.options.reporter = coerceToArray(configuration.options.reporter);
  configuration.options.output = coerceToArray(configuration.options.output);
  configuration.options.header = coerceToArray(configuration.options.header);
  configuration.options.method = coerceToArray(configuration.options.method);
  configuration.options.only = coerceToArray(configuration.options.only);
  configuration.options.path = coerceToArray(configuration.options.path);
  if (config.blueprintPath) {
    configuration.options.path.push(config.blueprintPath);
  }
  if (configuration.options.color === 'false') {
    configuration.options.color = false;
  } else if (configuration.options.color === 'true') {
    configuration.options.color = true;
  }
  ref1 = configuration.options.method;
  for (i = 0, len = ref1.length; i < len; i++) {
    method = ref1[i];
    method.toUpperCase();
  }
  if (configuration.options.user != null) {
    authHeader = 'Authorization:Basic ' + new Buffer(configuration.options.user).toString('base64');
    configuration.options.header.push(authHeader);
  }
  logger.transports.console.colorize = configuration.options.color;
  logger.transports.console.silent = configuration.options.silent;
  logger.transports.console.level = configuration.options.level;
  logger.transports.console.timestamp = configuration.options.timestamp;
  logger.sys.transports.systemConsole.colorize = configuration.options.color;
  logger.sys.transports.systemConsole.silent = configuration.options.silent;
  logger.sys.transports.systemConsole.level = configuration.options.level;
  logger.sys.transports.systemConsole.timestamp = configuration.options.timestamp;
  return configuration;
};

module.exports = applyConfiguration;