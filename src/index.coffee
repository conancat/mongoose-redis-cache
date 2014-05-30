# Some module requires
redis = require "redis"
crypto = require "crypto"
_ = require "underscore"

# Begin the happy thing!
# How we do it:
# We cache the original mongoose.Query.prototype.exec function,
# and replace it with this version that utilizes Redis caching.
#
# For more information, get on to the readme.md!


# We need RegExp::toJSON to serialize queries with reqular expressions

RegExp::toJSON = ->
  json = $regexp: @source
  str = @toString()
  ind = str.lastIndexOf '/'
  opts = str.slice ind + 1
  json.$options = opts if opts.length > 0
  json

# Let's start the party!

mongooseRedisCache = (mongoose, options, callback) ->
  options ?= {}

  # Setup redis with options provided
  host = options.host || ""
  port = options.port || ""
  pass = options.pass || ""
  redisOptions = options.options || {}
  prefix = options.prefix || "cache"

  mongoose.redisClient = client = redis.createClient port, host, redisOptions

  if pass.length > 0
    client.auth pass, (err) ->
      if callback then return callback err

  # Cache original exec function so that
  # we can use it later
  mongoose.Query::_exec = mongoose.Query::exec

  # Replace original function with this version that utilizes
  # Redis caching when executing finds.
  # Note: We only use this version of execution if it's a lean call,
  # meaning we don't cast each object to the Mongoose schema objects!
  # Also this will only enabled if user had specified cache: true option
  # when creating the Mongoose Schema object!

  mongoose.Query::exec = (callback) ->
    self = this
    model = @model
    query = @_conditions || {}
    options = @_optionsForExec(model) || {}
    fields = _.clone(@_fields) || {}
    populate = @options.populate || {}

    schemaOptions = model.schema.options
    collectionName = model.collection.name
    expires = @_mongooseOptions.redisExpires || schemaOptions.expires || 60

    # We only use redis cache of user specified to use cache on the schema,
    # and it will only execute if the call is a lean call.
    unless schemaOptions.redisCache and @_mongooseOptions.redisCache and @_mongooseOptions.lean
      delete @_mongooseOptions.redisCache
      delete @_mongooseOptions.redisExpires
      return mongoose.Query::_exec.apply self, arguments

    delete @_mongooseOptions.redisCache
    delete @_mongooseOptions.redixExpires

    hash = crypto.createHash('md5')
      .update(JSON.stringify query)
      .update(JSON.stringify options)
      .update(JSON.stringify fields)
      .update(JSON.stringify populate)
      .digest('hex')

    key = [prefix, collectionName, hash].join ':'

    cb = (err, result) ->
      if err then return callback err

      if not result
        # If the key is not found in Redis, executes Mongoose original
        # exec() function and then cache the results in Redis

        for k, path of populate
          path.options ||= {}
          _.defaults path.options, cache: false

        mongoose.Query::_exec.call self, (err, docs) ->
          if err then return callback err
          str = JSON.stringify docs
          client.setex key, expires, str
          callback null, docs
      else
        # Key is found, yay! Return the baby!
        docs = JSON.parse(result)
        return callback null, docs

    client.get key, cb

    return @

  return

# Just some exports, hah.
module.exports = mongooseRedisCache
