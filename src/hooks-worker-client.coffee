net = require 'net'
{EventEmitter} = require 'events'
child_process = require 'child_process'

generateUuid = require('node-uuid').v4

# for stubbing in tests
logger = require './logger'
which = require './which'

CONNECT_TIMEOUT = 1500
CONNECT_RETRY = 500
AFTER_CONNECT_WAIT = 100

TERM_TIMEOUT = 5000
TERM_RETRY = 500

HANDLER_HOST = 'localhost'
HANDLER_PORT = 61321
HANDLER_MESSAGE_DELIMITER = "\n"


class HooksWorkerClient
  constructor: (@runner, @timeout) ->
    @language = @runner.hooks?.configuration?.options?.language
    @clientConnected = false
    @handlerEnded = false
    @handlerKilledIntentionally = false
    @connectError = false
    @emitter = new EventEmitter

  start: (callback) ->
    @setCommandAndCheckForExecutables (executablesError) =>
      return callback(executablesError) if executablesError
      @spawnHandler (spawnHandlerError) =>
        return callback(spawnHandlerError) if spawnHandlerError

        @connectToHandler (connectHandlerError) =>
          return callback(connectHandlerError) if connectHandlerError

          @registerHooks (registerHooksError) ->
            return callback(registerHooksError) if registerHooksError
            callback()

  stop: (callback) ->
    @disconnectFromHandler()
    @terminateHandler callback

  terminateHandler: (callback) ->
    term = =>
      logger.info 'Sending SIGTERM to the hooks handler'
      @handlerKilledIntentionally = true
      @handler.kill 'SIGTERM'

    kill = =>
      logger.info 'Killing hooks handler'
      @handler.kill 'SIGKILL'

    start = Date.now()
    term()

    waitForHandlerTermOrKill = =>
      if @handlerEnded == true
        clearTimeout timeout
        callback()
      else
        if (Date.now() - start) < TERM_TIMEOUT
          term()
          timeout = setTimeout waitForHandlerTermOrKill, TERM_RETRY
        else
          kill()
          clearTimeout(timeout)
          callback()

    timeout = setTimeout waitForHandlerTermOrKill, TERM_RETRY

  disconnectFromHandler: ->
    @handlerClient.destroy()

  setCommandAndCheckForExecutables: (callback) ->
    # Select handler based on option, use option string as command if not match anything
    if @language == 'ruby'
      @handlerCommand = 'dredd-hooks-ruby'
      unless which.which @handlerCommand
        msg = """ \
          Ruby hooks handler server command not found: #{@handlerCommand}
          Install ruby hooks handler by running:
          $ gem install dredd_hooks
        """
        error = new Error msg
        return callback(error)

    else if @language == 'python'
      @handlerCommand = 'dredd-hooks-python'
      unless which.which @handlerCommand
        msg = """ \
          Python hooks handler server command not found: #{@handlerCommand}
          Install python hooks handler by running:
          $ pip install dredd_hooks
        """
        error = new Error msg
        return callback(error)

    else if @language == 'php'
      handlerCommand = 'dredd-hooks-php'
      unless which.which @handlerCommand
        msg = """ \
          PHP hooks handler server command not found: #{@handlerCommand}
          Install php hooks handler by running:
          $ composer require ddelnano/dredd-hooks-php --dev
        """
        error = new Error msg
        return callback(error)

    else if @language == 'perl'
      handlerCommand = 'dredd-hooks-perl'
      unless which.which @handlerCommand
        msg = """ \
          Perl hooks handler server command not found: #{@handlerCommand}
          Install perl hooks handler by running:
          $ cpanm Dredd::Hooks
        """
        error = new Error msg
        return callback(error)

    else if @language == 'nodejs'
      msg = ''' \
        Hooks handler should not be used for nodejs. \
        Use Dredds' native node hooks instead.
      '''
      error = new Error msg
      return callback(error)

    else
      @handlerCommand = @language
      unless which.which @handlerCommand
        msg = "Hooks handler server command not found: #{@handlerCommand}"
        error = new Error msg
        return callback(error)

      else
        callback()

  spawnHandler: (callback) ->

    pathGlobs = [].concat @runner.hooks?.configuration?.options?.hookfiles

    @handler = child_process.spawn @handlerCommand, pathGlobs

    logger.info "Spawning `#{@language}` hooks handler"

    @handler.stdout.on 'data', (data) ->
      logger.info "Hook handler stdout:", data.toString()

    @handler.stderr.on 'data', (data) ->
      logger.info "Hook handler stderr:", data.toString()

    @handler.on 'exit', (status) =>
      if status?
        if status isnt 0
          msg = "Hook handler '#{@handlerCommand}' exited with status: #{status}"
          logger.error msg
          error = new Error msg
          @runner.hookHandlerError = error
      else
        # No exit status code means the hook handler was killed
        unless @handlerKilledIntentionally
          msg = "Hook handler '#{@handlerCommand}' was killed"
          logger.error msg
          error = new Error msg
          @runner.hookHandlerError = error

      @handlerEnded = true

    @handler.on 'error', (error) =>
      @runner.hookHandlerError = @handlerEnded = error

    callback()

  connectToHandler: (callback) ->
    start = Date.now()
    waitForConnect = =>
      if (Date.now() - start) < CONNECT_TIMEOUT
        clearTimeout(timeout)

        if @connectError != false
          msg = 'Error connecting to the hook handler. Is the handler running? Retrying...'
          logger.warn msg

          @connectError = false

        if @clientConnected != true
          connectAndSetupClient()
          timeout = setTimeout waitForConnect, CONNECT_RETRY

      else
        clearTimeout(timeout)
        if ! @clientConnected
          @handlerClient.destroy() if @handlerClient?
          msg = "Connect timeout #{CONNECT_TIMEOUT / 1000}s to the handler " +
          "on #{HANDLER_HOST}:#{HANDLER_PORT} exceeded, try increasing the limit."
          error = new Error msg
          callback(error)

    connectAndSetupClient = =>
      if @runner.hookHandlerError?
        return callback(@runner.hookHandlerError)

      @handlerClient = net.connect port: HANDLER_PORT, host: HANDLER_HOST

      @handlerClient.on 'connect', =>
        logger.info "Connected to the hook handler, waiting #{AFTER_CONNECT_WAIT / 1000}s to start testing."
        @clientConnected = true
        clearTimeout(timeout)
        setTimeout callback, AFTER_CONNECT_WAIT

      @handlerClient.on 'close', ->

      @handlerClient.on 'error', (connectError) =>
        @connectError = connectError

      handlerBuffer = ""

      @handlerClient.on 'data', (data) =>
        handlerBuffer += data.toString()
        if data.toString().indexOf(HANDLER_MESSAGE_DELIMITER) > -1
          splittedData = handlerBuffer.split(HANDLER_MESSAGE_DELIMITER)

          # add last chunk to the buffer
          handlerBuffer = splittedData.pop()

          messages = []
          for message in splittedData
            messages.push JSON.parse message

          for message in messages
            if message.uuid?
              @emitter.emit message.uuid, message
            else
              logger.log 'UUID not present in message: ', JSON.stringify(message, null, 2)

    timeout = setTimeout waitForConnect, CONNECT_RETRY

  registerHooks: (callback) ->
    eachHookNames = [
      'beforeEach'
      'beforeEachValidation'
      'afterEach'
      'beforeAll'
      'afterAll'
    ]

    for eventName in eachHookNames then do (eventName) =>
      @runner.hooks[eventName] (data, hookCallback) =>
        uuid = generateUuid()

        # send transaction to the handler
        message =
          event: eventName
          uuid: uuid
          data: data

        @handlerClient.write JSON.stringify message
        @handlerClient.write HANDLER_MESSAGE_DELIMITER

        # register event for the sent transaction
        messageHandler = (receivedMessage) ->
          clearTimeout timeout

          # We are directly modifying the `data` argument here. Neither direct
          # assignment (`data = receivedMessage.data`) nor `clone()` will work...

          # *All hooks receive array of transactions
          if eventName.indexOf("All") > -1
            for value, index in receivedMessage.data
              data[index] = value
          # *Each hook receives single transaction
          else
            for own key, value of receivedMessage.data
              data[key] = value

          hookCallback()

        handleTimeout = =>
          logger.warn 'Hook handling timed out.'

          if eventName.indexOf("All") is -1
            data.fail = 'Hook timed out.'

          @emitter.removeListener uuid, messageHandler

          hookCallback()

        # set timeout for the hook
        timeout = setTimeout handleTimeout, @timeout


        @emitter.on uuid, messageHandler

    @runner.hooks.afterAll (transactions, hookCallback) =>

      # This is needed for transaction modification integration tests.
      if process.env['TEST_DREDD_HOOKS_HANDLER_ORDER'] == "true"
        console.error 'FOR TESTING ONLY'
        for mod, index in transactions[0]['hooks_modifications']
          console.error "#{index} #{mod}"
        console.error 'FOR TESTING ONLY'


      @stop hookCallback

    callback()

module.exports = HooksWorkerClient
