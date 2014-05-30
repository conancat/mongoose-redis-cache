# mongoose-redis-cache

Plugin to cache Mongoose MongoDB query results in Redis. Lean DB queries, at least 300% faster!

## 30/5/2014 - A note about this project

Sorry guys that I haven't been around to maintain this project! This project has not been actively maintained and I'm terribly sorry for that. 

I would love to have someone to help as active contributors to this project, if you're interested please do email me at conancat@gmail.com, and we'll work something out! Thank you so much guys!! 

## How to use
First, the usual:

    npm install mongoose-redis-cache

Then,

    Setup mongoose connect as usual:

       var mongoose = require("mongoose");
       var mongooseRedisCache = require("mongoose-redis-cache");
       mongoose.connect("mongodb://localhost/mongoose-redis-test")

    Create your schemas as usual:

       var ExampleSchema = new Schema(function(){
          field1: String
          field2: Number
          field3: Date
       });

    Enable redisCache on the schema!

       REQUIRED: Enable Redis caching on this schema by specifying

           ExampleSchema.set('redisCache', true)

       OPTIONAL: Change the time for the cache of this schema. Defaults to 60 seconds.

           ExampleSchema.set('expires', 30)

    Register the schema as usual:

         Example = mongoose.model('Example', ExampleSchema)

    Setup your mongooseCache options:

        # If you're running this locally,
        mongooseRedisCache(mongoose)

        # Or if you're running a remote Redis DB
        mongooseRedisCache(mongoose, {
           host: "redisHost",
           port: "redisPort",
           pass: "redisPass",
           options: "redisOptions"
         })

    Make a query as usual:

        query = Example.find({})
        query.where("field1", "foo")
        query.where("field2").gte(30)
        query.lean()  mongooseRedisCache only works for query.lean() queries!
        query.exec(function(err, result){
            Do whatever here!
        });

    Use nocache option to disable caching for the given query:

        query = Example.find({}).setOptions({nocache: true})

Check out the test example for more information.

## Test results:

    =========================
    Mongoose-Redis Cache Test
    =========================
    Total items in DB: 30000
    Total number of queries per round: 20
    Total number of rounds: 30

    Generating 30000 mocks...

    --------------------------------
    Test query without Redis caching
    --------------------------------
    Begin executing queries without caching
    ․․․․․․․․․․․․․․․․․․․․․․․․․․․․․․

    Total time for 30 test rounds: 12620ms
    Average time for each round: 420.67ms

    --------------------------------
    Test query with Redis caching
    --------------------------------
    Begin executing queries with Redis caching
    ․․․․․․․․․․․․․․․․․․․․․․․․․․․․․․

    Total time for 30 test rounds: 3618ms
    Average time for each round: 120.60ms
    ------------
    CONCLUSION
    ------------
    Caching with Redis makes Mongoose lean queries faster by 9002 ms.
    That's 348.81% faster!


    End tests.
    Wiping DB and exiting

## How this works

### What is a Mongoose `lean` query?

[Mongoose](http://mongoosejs.com), the MongoDB ORM for NodeJS has an awesome feature which casts each document
as a Mongoose [model](http://mongoosejs.com/docs/models.html). This allows awesome features like being able to call `model.save()` or `model.remove()` on each document directly, which makes coding much easier.

At the same time, Mongoose also casts each value in every document returned from MongoDB to their [schema types](http://mongoosejs.com/docs/guide.html), which makes sure your database value types stays consistent.

However, sometimes in situations where we need to READ a lot of data and have no intentions of doing anything to the
document, we can call [query.lean()](http://mongoosejs.com/docs/api.html#query_Query-lean) when constructing
our queries to remove the step which casts the documents into models. Documents are returned as normal Javascript
objects without the Model constructor functions, and values are not casted. This speeds things up considerably.

### Caching with Redis

What if we want to speed things up even faster?

In these situations where we don't need Mongoose model functionalities, we may want to ramp out our reading speed
higher by caching data in Redis.

Redis is awesome for caching data. By caching our MongoDB results in Redis, we can get at least 300% increase in
speed when reading the data. This is AFTER indexing in MongoDB.

Cool for high-volume data reading!

## API

### Setting up

    # If you're running this locally,
    mongooseRedisCache(mongoose)

    # Or if you're running a remote Redis DB
    mongooseRedisCache(mongoose, {
       host: "redisHost",
       port: "redisPort",
       pass: "redisPass",
       options: "redisOptions"
     })

    # You can also configure redis prefix
    # It'll allow you to create several completely isolated caches
    mongooseRedisCache(mongoose, {
       prefix: "cache1",
       cache: true
     })

### cache: Boolean
	mongooseRedisCache(mongoose, {
       cache: true
     })

OPTIONAL 
Set cache to true if you need to enable caching for all collections. 

### redisCache: Boolean

    ExampleSchema.set('redisCache', true)

OPTIONAL 
Call this function on whatever collection you want to cache. You don't have to use this on every collection,
right? Pick and choose your collections wisely, you shall.

### expires: Number

    ExampleSchema.set('expires', 30)

OPTIONAL
Set the expiry time for the Redis key in seconds. Defaults to 60.


### query.lean()

    query = Example.find({})
    query.lean()
    query.exec(function(err, results){
      # Your results here #
    })

REQUIRED
Just a reminder. Be sure to call this whenever you want the results to be cached! More info
about [query.lean()](http://mongoosejs.com/docs/api.html#query_Query-lean) here.

Yeah, that's it. What else did you expect? Meh.

## How to Run Test

Try testing this on your machine and let me know how it went for you!

The usual jazz:

    # Clone em!
    git clone https://github.com/conancat/mongoose-redis-cache.git

    # Install those packages
    cd mongoose-redis-cache
    npm install

    # If you don't have Mocha installed already
    npm install mocha -g

    # Yeah, just get in there and get on it
    cd tests
    mocha

### How the tests are run

#### Mock data
We generate a set number of mock data in the DB (defaults to 30000 items).
Each item contains a random person's name, some arbitary number as random data, a date, and
n array for the person's friend.

For testing purposes, we also called `ensureIndex()` on MongoDB to make sure we index
the field we want to query.

#### Execute test rounds
For every round we query the database for all the names (defaults to 20 of them),
and tracks the amount of time required to return the data. Each query returns around 1100 documents per call.
We run these same queries with and without Redis caching, for 20 rounds. Then we average out the time
needed to return the data.

All queries are query.lean(), meaning all documents returned are NOT casted as Mongoose models.
This gives us fair comparison between Redis caching and direct MongoDB queries.

## These awesome people!

* [mongoose](https://github.com/LearnBoost/mongoose)
* [node-redis](https://github.com/mranney/node_redis)

## Contact

Let's talk! I'm on [Twitter](https://twitter.com/conancat), [Reddit](http://www.reddit.com/user/conancat), or you can email me at conancat@gmail.com.

