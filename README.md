SwiftAsync
==========

This is a port of [async](https://github.com/caolan/async) to the Swift programming language.

Currently, the following functions are implemented:

* `each`
* `eachSeries`
* `each limit:`
* `map`
* `mapSeries`
* `map limit:`
* `filter`
* `filterSeries`
* `filter limit:`
* `reject`
* `rejectSeries`
* `reject limit:`
* `reduce`
* `reduceRight`

Usage
-----

```swift
Async.map([1, 2, 3], iterator: { (n, next) in
	someAsyncFunction(n) { (result) in
		next(result)
	}
}, callback: { (results) in
	// do something with results
})
```
