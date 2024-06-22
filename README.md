#  Checkpoint

A Rate-Limit middleware implementation for Vapor servers using Redis database.

```swift
let tokenBucket = TokenBucket {
	TokenBucketConfiguration(bucketSize: 5,
							 refillRate: 5,
							 refillTimeInterval: .seconds(count: 30),
							 appliedField: .header(key: "X-ApiKey"),
							 scope: .nonScope)
} storage: {
	application.redis("rate")
} logging: {
	application.logger
}


let checkpoint = Checkpoint(using: tokenBucket)

// 💧 Vapor Middleware
app.middleware.use(checkpoint)
```

## Supported algorythims

### Tocken Bucket

### Leaking Bucket

### Fixed Window Counter

### Sliding Window Log


