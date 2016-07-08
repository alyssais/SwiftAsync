SwiftAsync
==========

[![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)

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
* `detect`
* `detectSeries`
* `detect limit:`
* `sortBy`
* `sortBySeries`
* `sortBy limit:`
* `some`
* `someSeries`
* `some limit:`
* `every`
* `everySeries`
* `every limit:`
* `concat`
* `concatSeries`
* `concat limit:`

Usage
-----

```swift
Async.map([1, 2, 3], { (n, next) in
	someAsyncFunction(n) { (result) in
		next(result)
	}
}, callback: { (results) in
	// do something with results
})
```
