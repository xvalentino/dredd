// Generated by CoffeeScript 1.10.0
var Hooks, hooksLog,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  slice = [].slice;

hooksLog = require('./hooks-log');

Hooks = (function() {
  function Hooks(options) {
    if (options == null) {
      options = {};
    }
    this.dumpHooksFunctionsToStrings = bind(this.dumpHooksFunctionsToStrings, this);
    this.log = bind(this.log, this);
    this.afterEach = bind(this.afterEach, this);
    this.beforeEachValidation = bind(this.beforeEachValidation, this);
    this.beforeEach = bind(this.beforeEach, this);
    this.afterAll = bind(this.afterAll, this);
    this.beforeAll = bind(this.beforeAll, this);
    this.after = bind(this.after, this);
    this.beforeValidation = bind(this.beforeValidation, this);
    this.before = bind(this.before, this);
    this.logs = options.logs, this.logger = options.logger;
    this.transactions = {};
    this.beforeHooks = {};
    this.beforeValidationHooks = {};
    this.afterHooks = {};
    this.beforeAllHooks = [];
    this.afterAllHooks = [];
    this.beforeEachHooks = [];
    this.beforeEachValidationHooks = [];
    this.afterEachHooks = [];
  }

  Hooks.prototype.before = function(name, hook) {
    return this.addHook(this.beforeHooks, name, hook);
  };

  Hooks.prototype.beforeValidation = function(name, hook) {
    return this.addHook(this.beforeValidationHooks, name, hook);
  };

  Hooks.prototype.after = function(name, hook) {
    return this.addHook(this.afterHooks, name, hook);
  };

  Hooks.prototype.beforeAll = function(hook) {
    return this.beforeAllHooks.push(hook);
  };

  Hooks.prototype.afterAll = function(hook) {
    return this.afterAllHooks.push(hook);
  };

  Hooks.prototype.beforeEach = function(hook) {
    return this.beforeEachHooks.push(hook);
  };

  Hooks.prototype.beforeEachValidation = function(hook) {
    return this.beforeEachValidationHooks.push(hook);
  };

  Hooks.prototype.afterEach = function(hook) {
    return this.afterEachHooks.push(hook);
  };

  Hooks.prototype.addHook = function(hooks, name, hook) {
    if (hooks[name]) {
      return hooks[name].push(hook);
    } else {
      return hooks[name] = [hook];
    }
  };

  Hooks.prototype.log = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    this.logs = hooksLog.apply(null, [this.logs, this.logger].concat(slice.call(args)));
  };

  Hooks.prototype.processExit = function(code) {
    return process.exit(code);
  };

  Hooks.prototype.dumpHooksFunctionsToStrings = function() {
    var funcArray, hookFunc, i, index, len, names, property, ref, ref1, toReturn, transactionName;
    toReturn = {};
    names = ['beforeHooks', 'beforeValidationHooks', 'afterHooks', 'beforeAllHooks', 'afterAllHooks', 'beforeEachHooks', 'beforeEachValidationHooks', 'afterEachHooks'];
    for (i = 0, len = names.length; i < len; i++) {
      property = names[i];
      if (Array.isArray(this[property])) {
        toReturn[property] = [];
        ref = this[property];
        for (index in ref) {
          hookFunc = ref[index];
          toReturn[property][index] = hookFunc.toString();
        }
      } else if (typeof this[property] === 'object' && !Array.isArray(this[property])) {
        toReturn[property] = {};
        ref1 = this[property];
        for (transactionName in ref1) {
          funcArray = ref1[transactionName];
          if (!funcArray.length) {
            continue;
          }
          toReturn[property][transactionName] = [];
          for (index in funcArray) {
            hookFunc = funcArray[index];
            toReturn[property][transactionName][index] = hookFunc.toString();
          }
        }
      }
    }
    return toReturn;
  };

  return Hooks;

})();

module.exports = Hooks;