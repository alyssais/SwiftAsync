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

        /*
         * work around a tail recursion bug in the Swift compiler
         * where a function or closure inside a function cannot call itself
         */
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

    class func each(array: T[], limit: Int, _ iterator: (T, () -> ()) -> (), callback: () -> () = {}) -> T[] {
        return self(array).each(limit: limit, iterator, callback: callback).value
    }

    func each(#limit: Int, _ iterator: (T, () -> ()) -> (), callback: () -> () = {}) -> Async<T> {
        return map(limit: limit, { (elem, next) in
            iterator(elem) { next() }
        }, callback: { (results) in
            callback()
            return
        })
    }

    class func eachSeries(array: T[], _ iterator: (T, () -> ()) -> (), callback: () -> () = {}) -> T[] {
        return self(array).eachSeries(iterator, callback: callback).value
    }

    func eachSeries(iterator: (T, () -> ()) -> (), callback: () -> () = {}) -> Async<T> {
        return each(limit: 1, iterator, callback: callback)
    }

    class func each(array: T[], _ iterator: (T, () -> ()) -> (), callback: () -> ()) -> T[] {
        return self(array).each(iterator, callback: callback).value
    }

    func each(iterator: (T, () -> ()) -> (), callback: () -> ()) -> Async<T> {
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

    // reduce

    class func reduce<Result>(array: T[], _ accumulator: Result, _ iterator: (Result, T, (Result) -> ()) -> (), callback: (Result) -> ()) -> T[] {
        return self(array).reduce(accumulator, iterator, callback: callback).value
    }

    func reduce<Result>(var accumulator: Result, _ iterator: (Result, T, (Result) -> ()) -> (), callback: (Result) -> ()) -> Async<T> {
        return eachSeries({ (elem, next) in
            iterator(accumulator, elem) { (result) in
                accumulator = result
                next()
            }
        }, { callback(accumulator) })
    }

    // reduceRight

    class func reduceRight<Result>(array: T[], _ accumulator: Result, _ iterator: (Result, T, (Result) -> ()) -> (), callback: (Result) -> ()) -> T[] {
        return self(array).reduceRight(accumulator, iterator, callback: callback).value
    }

    func reduceRight<Result>(accumulator: Result, _ iterator: (Result, T, (Result) -> ()) -> (), callback: (Result) -> ()) -> Async<T> {
        Async.reduce(value.reverse(), accumulator, iterator, callback: callback)
        return self
    }

    // detect

    class func detect(array: T[], limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (T?) -> ()) -> T[] {
        return self(array).detect(limit: limit, iterator, callback: callback).value
    }

    func detect(#limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (T?) -> ()) -> Async<T> {
        var completed = false
        func complete(elem: T?) {
            if !completed {
                completed = true
                callback(elem)
            }
        }
        return each(limit: limit, { (elem, next) in
            iterator(elem) { (result) in
                next()
                if result { complete(elem) }
            }
        }, { complete(nil) })
    }

    class func detectSeries(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (T?) -> ()) -> T[] {
        return self(array).detectSeries(iterator, callback: callback).value
    }

    func detectSeries(iterator: (T, (Bool) -> ()) -> (), callback: (T?) -> ()) -> Async<T> {
        return detect(limit: 1, iterator, callback: callback)
    }

    class func detect(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (T?) -> ()) -> T[] {
        return self(array).detect(iterator, callback: callback).value
    }

    func detect(iterator: (T, (Bool) -> ()) -> (), callback: (T?) -> ()) -> Async<T> {
        return detect(limit: value.count, iterator, callback: callback)
    }

    // sortBy

    class func sortBy(array: T[], limit: Int, _ iterator: (T, (Int) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).sortBy(limit: limit, iterator, callback: callback).value
    }

    func sortBy(#limit: Int, _ iterator: (T, (Int) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return map(limit: limit, { (elem, next: ((Int, T)) -> ()) in
            iterator(elem) { (result) in next((result, elem)) }
        }, callback: { (results) in
            results.sort { $0.0 < $1.0 }
            callback(results.map { $0.1 })
        })
    }

    class func sortBySeries(array: T[], _ iterator: (T, (Int) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).sortBySeries(iterator, callback: callback).value
    }

    func sortBySeries(iterator: (T, (Int) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return sortBy(limit: 1, iterator, callback: callback)
    }

    class func sortBy(array: T[], _ iterator: (T, (Int) -> ()) -> (), callback: (T[]) -> ()) -> T[] {
        return self(array).sortBy(iterator, callback: callback).value
    }

    func sortBy(iterator: (T, (Int) -> ()) -> (), callback: (T[]) -> ()) -> Async<T> {
        return sortBy(iterator, callback: callback)
    }

    // some

    class func some(array: T[], limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> T[] {
        return self(array).some(limit: limit, iterator, callback: callback).value
    }

    func some(#limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> Async<T> {
        return detect(limit: limit, iterator) { callback($0 != nil) }
    }

    class func someSeries(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> T[] {
        return self(array).someSeries(iterator, callback: callback).value
    }

    func someSeries(iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> Async<T> {
        return some(limit: 1, iterator, callback: callback)
    }

    class func some(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> T[] {
        return self(array).some(iterator, callback: callback).value
    }

    func some(iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> Async<T> {
        return some(limit: value.count, iterator, callback: callback)
    }

    // every

    class func every(array: T[], limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> T[] {
        return self(array).every(limit: limit, iterator, callback: callback).value
    }

    func every(#limit: Int, _ iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> Async<T> {
        return map(limit: limit, iterator) { callback($0.reduce(true, combine: &)) }
    }

    class func everySeries(array: T[], iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> T[] {
        return self(array).everySeries(iterator, callback: callback).value
    }

    func everySeries(iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> Async<T> {
        return every(limit: 1, iterator, callback: callback)
    }

    class func every(array: T[], _ iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> T[] {
        return self(array).every(iterator, callback: callback).value
    }

    func every(iterator: (T, (Bool) -> ()) -> (), callback: (Bool) -> ()) -> Async<T> {
        return every(limit: 1, iterator, callback: callback)
    }

    // concat

    class func concat<Result>(array: T[], limit: Int, _ iterator: (T, (Result[]) -> ()) -> (), callback: (Result[]) -> ()) -> T[] {
        return self(array).concat(limit: limit, iterator, callback: callback).value
    }

    func concat<Result>(#limit: Int, _ iterator: (T, (Result[]) -> ()) -> (), callback: (Result[]) -> ()) -> Async<T> {
        var results = Result[]()
        return each(limit: limit, { (elem, next) in
            iterator(elem) { (iteratorResults) in
                results += iteratorResults
                next()
            }
        }, callback: { callback(results) })
    }

    class func concatSeries<Result>(array: T[],  _ iterator: (T, (Result[]) -> ()) -> (), callback: (Result[]) -> ()) -> T[] {
        return self(array).concat(iterator, callback: callback).value
    }

    func concatSeries<Result>(iterator: (T, (Result[]) -> ()) -> (), callback: (Result[]) -> ()) -> Async<T> {
        return concat(limit: 1, iterator, callback: callback)
    }

    class func concat<Result>(array: T[], _ iterator: (T, (Result[]) -> ()) -> (), callback: (Result[]) -> ()) -> T[] {
        return self(array).concat(iterator, callback: callback).value
    }

    func concat<Result>(iterator: (T, (Result[]) -> ()) -> (), callback: (Result[]) -> ()) -> Async<T> {
        return concat(limit: value.count, iterator, callback: callback)
    }
}
