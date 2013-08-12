# Test case for Mongoose-Redis Cache

# Testing methodology:
#
# Mock data:
# We generate a set number of mock data in the DB. Defaults to 30000 items.
# Each item contains a random person's name, some arbitary number as data, a date, and
# an array for the person's friend. We index the name field to optimize
# MongoDB's performance.
#
# Execute test rounds:
# For every round we query the database for all the names (defaults to 20 of them),
# and tracks the amount of time required to return the data. We run these same queries
# with and without Redis caching, for 20 rounds. Then we average out the time
# needed to return the data. All queries are query.lean(), meaning all documents
# returned are NOT casted as Mongoose models.
#


# Just some basic requires and stuff
mongoose = require "mongoose"
{Schema} = mongoose
async = require "async"
_ = require "underscore"
mongooseRedisCache = require "../index"

# Some test variables, feel free to change this to play around
itemsCount = 100
testRounds = 5
cacheExpires = 60
timeout = 1000 * 30

totalTimeWithoutRedis = 0
totalTimeWithRedis = 0

# List of names to generate mocks
mockNames = [
  "Jacob"
  "Sophia"
  "Mason"
  "Isabella"
  "William"
  "Emma"
  "Jayden"
  "Olivia"
  "Noah"
  "Ava"
  "Michael"
  "Emily"
  "Ethan"
  "Abigail"
  "Alexander"
  "Madison"
  "Aiden"
  "Mia"
  "Daniel"
  "Chloe"
]

maxQueriesCount = mockNames.length

# BEGIN SETTING UP

# Setup Mongoose as usual
mongoose.connect("mongodb://test:abcd1234@ds037987.mongolab.com:37987/mongoose-redis-test")
# mongoose.connect("mongodb://localhost/mongoose-redis-test")

# Setup test item schema
TestItemSchema = new Schema
  num1: Number
  num2: Number
  num3: Number
  date: {type: String, default: Date.now()}
  friends: [String]
  name:
    type: String
    index: true # Index the Name field for query

# Set schema to include caching
TestItemSchema.set 'redisCache', true
TestItemSchema.set 'expires', cacheExpires

TestItem = mongoose.model 'TestItem', TestItemSchema


# Clear database for clean start next time
clearDb = (callback) ->
  TestItem.remove callback

# GENERATE MOCK DATA
# Just a random function to generate mockup data in DB
generateMocks = (amount, callback) ->
  count = 0
  items = []

  while count < amount
    items.push
      name: mockNames[Math.floor(Math.random() * mockNames.length)]
      num1: Math.random() * 10000
      num2: Math.random() * 10000
      num3: Math.random() * 10000
      friends: _.shuffle(mockNames)[0...Math.floor(Math.random() * 5)]
    count++

  TestItem.create items, callback


# RUN TEST ROUND

# Executes the test rounds
# For each round, run a query for every mock name defined
# It should return all results that matches the name
# Track the time required to execute each command, then average it out

runTestRound = (callback) ->
  currQueryCount = 0

  timeSpentArr = []

  test = ->
    currQueryCount < maxQueriesCount

  fn = (cb) ->
    queryStartTime = new Date()

    query = TestItem.find {}
    query.where "name", mockNames[currQueryCount]

    # Making sure it's a lean call!
    query.lean()

    query.exec (err, result) ->
      if err then throw err

      queryEndTime = new Date()
      timeSpent = queryEndTime - queryStartTime
      timeSpentArr.push timeSpent
      currQueryCount++
      cb null

  cb = ->
    totalTime = 0

    for t in timeSpentArr
      totalTime += t

    averageTime = totalTime / maxQueriesCount

    # To see each individual query's execution time, uncomment these two lines
    # console.log "Query -- time spent total -- ", totalTime + "ms"
    # console.log "Query -- time spent average per query -- ", averageTime.toFixed(3) + "ms"

    # Returns the total time and average time to track the results for each round
    callback null,
      totalTime: totalTime
      averageTime: averageTime

  async.whilst test, fn, cb


# BEGIN TEST PROCESS

# Clear database before starting, then generate mock data
before (done) ->
  console.log """

    =========================
    Mongoose-Redis Cache Test
    =========================
    Total items in DB: #{itemsCount}
    Total number of queries per round: #{maxQueriesCount}
    Total number of rounds: #{testRounds}

  """

  @timeout 60000
  clearDb ->
    console.log "Generating #{itemsCount} mocks..."
    generateMocks itemsCount, (err) ->
      if err then throw err

      # Make sure the data is indexed in DB for testing
      TestItem.ensureIndexes done


# Start test for queries without caching
describe "Mongoose queries without caching", ->
  before ->
    console.log """
      \n--------------------------------
      Test query without Redis caching
      --------------------------------
      Begin executing queries without caching
    """

  totalTime = 0

  for count in [1..testRounds]
    it "Run #{count}", (done) ->
      @timeout timeout
      runTestRound (err, result) ->
        totalTime += result.totalTime
        done()

  after ->
    console.log "\n\nTotal time for #{testRounds} test rounds:", totalTime + "ms"
    console.log "Average time for each round:", (totalTime / testRounds).toFixed(2) + "ms"

    totalTimeWithoutRedis = totalTime

# Start test for queries with caching
describe "Mongoose queries with caching", ->
  before ->
    # Setup mongooseRedisCache
    mongooseRedisCache mongoose,
      host: "proxy.openredis.com"
      port: 11406
      pass: "BNX8dYfmpAjm52b8dtBcB0lPij4dbZT0PmNurfNCNHmGGPy7Zq8SBR6ejezls11r"
    , (err) ->
      console.log """
        \n--------------------------------
        Test query with Redis caching
        --------------------------------
        Begin executing queries with Redis caching
      """

  totalTime = 0

  for count in [1..testRounds]
    it "Run #{count}", (done) ->
      @timeout timeout
      runTestRound (err, result) ->
        totalTime += result.totalTime
        done()

  after ->
    console.log "\n\nTotal time for #{testRounds} test rounds:", totalTime + "ms"
    console.log "Average time for each round:", (totalTime / testRounds).toFixed(2) + "ms"

    totalTimeWithRedis = totalTime


# Done test!
after (done) ->

  console.log """
  ------------
  CONCLUSION
  ------------
  Caching with Redis makes Mongoose lean queries faster by #{totalTimeWithoutRedis - totalTimeWithRedis} ms.
  That's #{(totalTimeWithoutRedis / totalTimeWithRedis * 100).toFixed(2)}% faster!
  """


  console.log "\n\nEnd tests. \nWiping DB and exiting"
  clearDb done




