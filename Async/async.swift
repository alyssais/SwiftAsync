//
//  async.swift
//  Async
//
//  Created by Alyssa Ross on 07/06/2014.
//  Copyright (c) 2014 Alyssa Ross. All rights reserved.
//

class Async<T> {
    let value: T[]
    
    @required init(_ contents: T[]) {
        value = contents
    }
    
    class func each(array: T[], iterator: (T, () -> ()) -> (), callback: () -> () = {}) -> T[] {
        return self(array).each(iterator, callback: callback).value
    }
    
    func each(iterator: (T, () -> ()) -> (), callback: () -> () = {}) -> Async<T> {
        return map({ (elem, callback) in
            iterator(elem) { callback(nil) }
        }, callback: { (results) in callback() })
    }
    
    class func map<Result>(array: T[], iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> T[] {
        return self(array).map(iterator, callback: callback).value
    }
    
    func map<Result>(iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> Async<T> {
        let tempResults = Array<Result?>(count: value.count, repeatedValue: nil)
        var finishedCount = 0
        for (i, elem) in enumerate(value) {
            iterator(elem) { (result) in
                tempResults[i] = result
                if (++finishedCount == self.value.count) {
                    let results = tempResults.map { $0! }
                    callback?(results)
                }
            }
        }
        return self
    }
    
    class func eachSeries(array: T[], iterator: (T, () -> ()) -> (), callback: (() -> ()) = {}) -> T[] {
        return self(array).eachSeries(iterator, callback: callback).value
    }
    
    func eachSeries(iterator: (T, () -> ()) -> (), callback: (() -> ()) = {}) -> Async<T> {
        return mapSeries({ (elem, callback) in
            iterator(elem) { callback(nil) }
        }, callback: { (results) in callback() })
    }
    
    class func mapSeries<Result>(array: T[], iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> T[] {
        return self(array).mapSeries(iterator, callback: callback).value
    }
    
    func mapSeries<Result>(iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> Async<T> {
        var results = Result[]()
        var i = 0
        
        var runNextFix: () -> () = {}
        func runNext() {
            if i == value.count {
                callback?(results)
            } else {
                let elem = value[i++]
                iterator(elem) { (result) in
                    results.append(result)
                    runNextFix()
                }
            }
        }
        runNextFix = runNext
        
        runNext()
        return self
    }
}

let x = Async.map([1, 2, 3], iterator: { (n, next) in
    someAsyncFunction(n) { (result) in
        next(result)
    }
}, callback: { (result) in
    // do something with results
})
