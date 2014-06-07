SwiftAsync
==========

This is a port of [async](https://github.com/caolan/async) to the Swift programming language.

Currently, the following functions are implemented:

* `each`
* `map`
* `eachSeries`
* `mapSeries`

Usage
-----

```swift
Async.map([1, 2, 3]) { (n, next) in
  someAsyncFunction(n) { (result) in
	  next(result)
	}
}
```
