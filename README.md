# Checkpoint 💧

A Rate-Limit middleware implementation for Vapor servers using Redis database.

```swift
...

let tokenBucket = TokenBucket {
	TokenBucketConfiguration(bucketSize: 25,
							 refillRate: 5,
							 refillTimeInterval: .seconds(count: 45),
							 appliedField: .header(key: "X-ApiKey"),
							 scope: .endpoint)
} storage: {
	application.redis("rate")
} logging: {
	application.logger
}


let checkpoint = Checkpoint(using: tokenBucket)

// 🚨 Modify response HTTP header and body response when rate limit exceed
checkpoint.didFailWithTooManyRequest = { (request, response, metadata) in
	metadata.headers = [
		"X-RateLimit" : "Failure for request \(request.id)."
	]
	
	metadata.reason = "Rate limit for your api key exceeded"
}

// 💧 Vapor Middleware
app.middleware.use(checkpoint)
```

## Supported algorythims

Currently **Checkpoint** supports 4 rate-limit algorithims.

### Token Bucket

The Token Bucket rate-limiting algorithm is a widely-used and flexible approach that controls the rate of requests to a service while allowing for some bursts of traffic. Here’s an explanation of how it works:

The configuration for the Token Bucket is setted using the `TokenBucketConfiguration` type

```swift
let tokenbucketAlgorithm = TokenBucket {
	TokenBucketConfiguration(bucketSize: 10,
							 refillRate: 0,
							 refillTimeInterval: .seconds(count: 20),
							 appliedTo: .header(key: "X-ApiKey"),
							 inside: .endpoint)
} storage: {
	// Rate limit database in Redis
	app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
															 port: 9090,
															 database: 0)
	
	return app.redis("rate")
} logging: {
	app.logger
}
```

How the Token Bucket Algorithm Works:

1. Initialize the Bucket:

- The bucket has a fixed capacity, which represents the maximum number of tokens it can hold.
- Tokens are added to the bucket at a fixed rate, up to the bucket's capacity.

2. Handle Incoming Requests:

- When a new request arrives, check if there are enough tokens in the bucket.
- If there is at least one token, allow the request and remove a token from the bucket.
- If there are no tokens available, deny the request (rate limit exceeded).

3. Add Tokens:

- Tokens are added to the bucket at a steady rate, which determines the average rate of allowed requests.
- The bucket never holds more than its fixed capacity of tokens.

### Leaking Bucket

The Leaking Bucket rate-limit algorithm is an effective approach to rate limiting that ensures a smooth, steady flow of requests. It works similarly to a physical bucket with a hole in it, where water (requests) drips out at a constant rate. Here’s a detailed explanation of how it works:

The configuration for Leaking Bucket is the `LeakingBucketConfiguration` object

```swift
let leakingBucketAlgorithm = LeakingBucket {
	LeakingBucketConfiguration(bucketSize: 10,
							   removingRate: 5,
							   removingTimeInterval: .minutes(count: 1),
							   appliedTo: .header(key: "X-ApiKey"),
							   inside :.endpoint)
} storage: {
	// Rate limit database in Redis
	app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
															 port: 9090,
															 database: 0)
	
	return app.redis("rate")
} logging: {
	app.logger
}
```

How the Leaking Bucket Algorithm Works:

1. Initialize the Bucket:

- The bucket has a fixed capacity, representing the maximum number of requests that can be stored in the bucket at any given time.
- The bucket leaks at a fixed rate, representing the maximum rate at which requests are processed.

2. Handle Incoming Requests:

- When a new request arrives, check the current level of the bucket.
- If the bucket is not full (i.e., the number of stored requests is less than the bucket's capacity), add the request to the bucket.
- If the bucket is full, deny the request (rate limit exceeded).

3. Process Requests:

- Requests in the bucket are processed (leaked) at a constant rate.
- This ensures a steady flow of requests, preventing sudden bursts.

### Fixed Window Counter

The Fixed Window Counter rate-limit algorithm is a straightforward and easy-to-implement approach for rate limiting, used to control the number of requests a client can make to a service within a specified time period. Here’s an explanation of how it works:

To set the configuration you must use the `FixedWindowCounterConfiguration` type

```swift
let fixedWindowAlgorithm = FixedWindowCounter {
	FixedWindowCounterConfiguration(requestPerWindow: 10,
									timeWindowDuration: .minutes(count: 2),
									appliedTo: .header(key: "X-ApiKey"),
									inside: .endpoint)
} storage: {
	// Rate limit database in Redis
	app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
															 port: 9090,
															 database: 0)
	
	return app.redis("rate")
} logging: {
	app.logger
}
```

How the Fixed Window Counter Algorithm Works:

1. Define a Time Window
Choose a fixed duration (e.g., 1 minute, 1 hour) which will serve as the time window for counting requests.

2. Initialize a Counter:
Maintain a counter for each client (or each resource being accessed) that tracks the number of requests made within the current time window.

3. Track Request Timestamps:
Each time a request is made, check the current timestamp and determine which time window it falls into.
Increment the Counter:

- If the request falls within the current window, increment the counter.
- If the request falls outside the current window, reset the counter and start a new window.

4. Enforce Limits:

- If the counter exceeds the predefined limit within the current window, the request is denied (or throttled).
- If the counter is within the limit, the request is allowed.
 
 
 ```swift
 
 ```

### Sliding Window Log

The Sliding Window Log rate-limit algorithm is a more refined approach to rate limiting compared to the Fixed Window Counter. It offers smoother control over request rates by maintaining a log of individual request timestamps, allowing for a more granular and accurate rate-limiting mechanism. Here’s a detailed explanation of how it works:

To set the configuration for this rate-limit algorithim use the `` type

```swift
let slidingWindowLogAlgorith = SlidingWindowLog {
	SlidingWindowLogConfiguration(requestPerWindow: 10,
								  windowDuration: .minutes(count: 2),
								  appliedTo: .header(key: "X-ApiKey"),
								  inside: .endpoint)
} storage: {
	// Rate limit database in Redis
	app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
															 port: 9090,
															 database: 0)
	
	return app.redis("rate")
} logging: {
	app.logger
}
```

How the Sliding Window Log Algorithm Works:

1. Define a Time Window:
Choose a time window duration (e.g., 1 minute) within which you want to limit the number of requests.

2. Log Requests:
Maintain a log (typically a list or queue) for each client that stores the timestamps of each request.

3. Handle Incoming Requests:
When a new request arrives, do the following:

- Remove timestamps from the log that fall outside the current time window.
- Check the number of timestamps remaining in the log.
- If the number of requests (timestamps) within the window is below the limit, add the new request’s timestamp to the log and allow the request.
- If the number of requests meets or exceeds the limit, deny the request.


## Modify server response

Sometimes we need to modify the response sent to the client by adding a custom HTTP header or setting a failure reason text in the JSON payload.

In that case, you can use one of the closures defined in the `Checkpoint` class, one per Rate-Limit processing stage.

### Before performing Rate-Limit checking

This closure is invoked just before the Checkpoint middleware checking operation for a given request will be performed, and receive a Request object as a parameter.

```swift
public var willCheck: CheckpointAction?
```

### After perform Rate-Limit checking

If Rate-Limit checking goes well, this closure is invoked, and you know that the Request continues to be processed by the Vapor server.

```swift
public var willCheck: CheckpointAction?
```

### Rate-Limit reached
It's sure you want to know when a request reaches the rate limit you set when initializing Checkpoint.

In this case, Checkpoint will notify a rate-limit reached using the didFailWithTooManyRequest closure.

```swift
public var didFailWithTooManyRequest: CheckpointErrorAction?
```

This closure contains 3 parameter 

- `requests`. It's a [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) object type representing the user request that reaches the limit.
- `response`. It's the server response ([`Response`](https://api.vapor.codes/vapor/documentation/vapor/response) type) returned by Vapor.
- `metadata`. It's an object designed to set custom HTTP headers and a reason text that will be attached to the object payload returned by the response.

For example, if you want to add a custom HTTP header and a reason text to inform a user that he reaches the limit you will do something like this

```swift
// 👮‍♀️ Modify response HTTP header and body response when rate limit exceed
checkpoint.didFailWithTooManyRequest = { (request, response, metadata) in
	metadata.headers = [
		"X-RateLimit" : "Failure for request \(request.id)."
	]
	
	metadata.reason = "Rate limit for your api key exceeded"
}
```

### Error throwed while process a request  

If an error different from an HTTP 429 code (rate-limit) comes from Checkpoint, you will be reported in the following closure

```swift
// 🚨 Modify response HTTP header and body response when error occurs
checkpoint.didFail = { (request, response, abort, metadata) in
	metadata.headers = [
		"X-ApiError" : "Error for request \(request.id)."
	]
	
	metadata.reason = "Error code \(abort.status) for your api key exceeded"
}
```

The parameters used in this closure are the same as the ones received in the closure, you can add a custom HTTP header and/or a reason message.

## Redis

To work with Checkpoint you must install and configure a Redis database in your system. Thanks to Docker it's really easy to deploy a Redis installation. 

We recommend to install the [**redis-stack-server**](https://hub.docker.com/r/redis/redis-stack-server) image from the Docker Hub.

## History

### 0.1.0

Alpha version, a *Friends & Family* release 😜

- Support for Redis Database
- Logging system based on the Vapor `Logger` type
- Four rate-limit algorithims support
	- Fixed Window Counter
	- Leaking Bucket
	- Sliding Window Log
	- Token Bucket
	
