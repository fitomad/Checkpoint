# Checkpoint 💧

A Rate-Limit middleware implementation for Vapor servers using Redis database.

```swift
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

// Modify response HTTP header and body response when rate limit exceed
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

### Tocken Bucket

### Leaking Bucket

### Fixed Window Counter

### Sliding Window Log

## Modify server response
