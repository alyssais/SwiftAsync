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

    // map
    
    class func map<Result>(array: T[], limit: Int, _ iterator: (T, (Result) -> ()) -> (), callback: (Result[]) -> ()) -> T[] {
        return self(array).map(limit: limit, iterator, callback: callback).value
    }
    
    func map<Result>(#limit: Int, _ iterator: (T, (Result) -> ()) -> (), callback: (Result[]) -> ()) -> Async<T> {
        let totalCount = value.count
        var results = Dictionary<Int, Result>(minimumCapacity: totalCount)
        var runningCount = 0
        var completeCount = 0
        var i = 0
        
        var runNextFix: () -> () = {}
        func runNext() {
            let index = i++
            let next = value[index]
            
            runningCount++
            iterator(next) { (result) in
                runningCount--
                completeCount++
                
                results[index] = result
                
                if completeCount == totalCount {
                    // all tasks complete
                    var resultsArray = Result[]()
                    for var j = 0; j < results.count; j++ {
                        resultsArray.append(results[j]!)
                    }
                    
                    callback(resultsArray)
                } else if i < totalCount {
                    runNextFix()
                }
            }
            
            if runningCount < limit {
                runNextFix()
            }
        }
        runNextFix = runNext
        runNext()
        
        return self
    }
    
    class func mapSeries<Result>(array: T[], _ iterator: (T, (Result) -> ()) -> (), callback: (Result[]) -> ()) -> T[] {
        return self(array).mapSeries(iterator, callback: callback).value
    }
    
    func mapSeries<Result>(iterator: (T, (Result) -> ()) -> (), callback: (Result[]) -> ()) -> Async<T> {
        return map(limit: 1, iterator, callback: callback)
    }
    
    class func map<Result>(array: T[], _ iterator: (T, (Result) -> ()) -> (), callback: (Result[]) -> ()) -> T[] {
        return self(array).map(iterator, callback: callback).value
    }
    
    func map<Result>(iterator: (T, (Result) -> ()) -> (), callback: (Result[]) -> ()) -> Async<T> {
        return map(limit: value.count, iterator, callback: callback)
    }

    // each

    class func each(array: T[], limit: Int, _ iterator: (T, () -> ()) -> (), callback: (() -> ())?) -> T[] {
        return self(array).each(limit: limit, iterator, callback: callback).value
    }

    func each(#limit: Int, _ iterator: (T, () -> ()) -> (), callback: (() -> ())?) -> Async<T> {
        return map(limit: limit, { (elem, next) in
            iterator(elem) { next() }
        }, callback: { (results) in
            callback?()
            return
        })
    }

    class func eachSeries(array: T[], _ iterator: (T, () -> ()) -> (), callback: (() -> ())?) -> T[] {
        return self(array).eachSeries(iterator, callback: callback).value
    }

    func eachSeries(iterator: (T, () -> ()) -> (), callback: (() -> ())?) -> Async<T> {
        return each(limit: 1, iterator, callback: callback)
    }

    class func each(array: T[], _ iterator: (T, () -> ()) -> (), callback: (() -> ())?) -> T[] {
        return self(array).each(iterator, callback: callback).value
    }

    func each(iterator: (T, () -> ()) -> (), callback: (() -> ())?) -> Async<T> {
        return each(limit: value.count, iterator, callback: callback)
    }

    // filter

    class func filter(array: T[], limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).filter(limit: limit, iterator, callback: callback).value
    }

    func filter(#limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return map(limit: limit, iterator) { (bools) in
            var results = T[]()
            for (i, elem) in enumerate(self.value) {
                if bools[i] {
                    results.append(elem)
                }
            }
            callback(results)
        }
    }

    class func filter(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).filter(iterator, callback: callback).value
    }

    func filter(iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return filter(limit: value.count, iterator, callback: callback);
    }

    class func filterSeries(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).filter(iterator, callback: callback).value
    }

    func filterSeries(iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return filter(limit: 1, iterator, callback: callback);
    }

    // reject

    class func reject(array: T[], limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).reject(limit: limit, iterator, callback: callback).value
    }

    func reject(#limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return filter(limit: limit, { (elem, next) in iterator(elem) { next(!$0) } }, callback: callback)
    }

    class func reject(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).reject(iterator, callback: callback).value
    }

    func reject(iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return reject(limit: value.count, iterator, callback: callback);
    }

    class func rejectSeries(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).reject(iterator, callback: callback).value
    }

    func rejectSeries(iterator: (T, (Bool) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return reject(limit: 1, iterator, callback: callback);
    }
}
