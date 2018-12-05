//
//  AsyncResult.swift
//  PromisedArchitectureKit
//
//  Created by Pallas, Ricardo on 12/3/18.
//

import Foundation
import PromiseKit

public class AsyncResult<T> {
    
    public let promise: Promise<T>
    
    fileprivate var result: T?
    fileprivate var error: Error?
    fileprivate var isLoading = false
    
    public init(_ promise: Promise<T>) {
        self.promise = promise
    }
    
    public func fold(
        loading: @escaping () -> (),
        failure: @escaping (Error) -> (),
        success: @escaping (T) -> ()
    )
    {
        loading()
        isLoading = true
        self.promise.done { result in
            self.isLoading = false
            self.result = result
            let _ = success(result)
            }.catch { error in
                self.isLoading = false
                self.error = error
                failure(error)
        }
    }
    
    public func map<U>(_ transformation: @escaping (T) -> (U)) -> AsyncResult<U> {
        
        let resultPromise = Promise<U> { seal in
            self.promise.done { result in
                seal.fulfill(transformation(result))
                }.catch { error in
                    seal.reject(error)
            }
        }
        
        return AsyncResult<U>(resultPromise)
    }
    
    public func mapError(_ transformation: @escaping (Error) -> (Error)) -> AsyncResult<T>{
        
        let resultPromise = Promise<T> { seal in
            self.promise.done { result in
                seal.fulfill(result)
            }.catch { error in
                seal.reject(transformation(error))
            }
        }
        
        return AsyncResult<T>(resultPromise)
    }
    
    public func mapErrorRecover( _ transformation: @escaping (Error) -> (T)) -> AsyncResult<T> {
        
        let resultPromise = Promise<T> { seal in
            self.promise.done { result in
                seal.fulfill(result)
            }.catch { error in
                seal.fulfill(transformation(error))
            }
        }
        
        return AsyncResult<T>(resultPromise)
    }
    
    public func flatMap<U>(_ transformation: @escaping(T) -> (AsyncResult<U>)) -> AsyncResult<U>{
        
        let resultPromise = Promise<U> { seal in
            self.promise.done { result in
                transformation(result).promise.done { secondResult in
                    seal.fulfill(secondResult)
                    }.catch { secondError in
                        seal.reject(secondError)
                }
                
                }.catch { error in
                    seal.reject(error)
            }
        }
        
        return AsyncResult<U>(resultPromise)
    }
    
    static func parallel(_ asyncResults: [AsyncResult<T>]) -> AsyncResult<[T]> {
        let promises = asyncResults.map { $0.promise }
        let allPromise = when(fulfilled: promises)
        return AsyncResult<[T]>(allPromise)
    }
    
    static func zip<A,B>(_ a: AsyncResult<A>, _ b: AsyncResult<B>) -> AsyncResult<(A,B)> {
        return a.flatMap { aValue -> AsyncResult<(A,B)> in
            return b.map { bValue  in
                return (aValue,bValue)
            }
        }
    }
    
    static func zip<A,B,C>(_ a: AsyncResult<A>, _ b: AsyncResult<B>, _ c : AsyncResult<C>) -> AsyncResult<(A,B,C)> {
        return AsyncResult.zip(a, b).flatMap { pair -> AsyncResult<(A,B,C)> in
            return c.map { cValue in
                return (pair.0, pair.1, cValue)
            }
        }
    }
    
    static func zip<A,B,C,D>(_ a: AsyncResult<A>, _ b: AsyncResult<B>, _ c : AsyncResult<C>, _ d: AsyncResult<D>) -> AsyncResult<(A,B,C,D)> {
        return AsyncResult.zip(a, b, c).flatMap { pair -> AsyncResult<(A,B,C,D)> in
            return d.map { dValue in
                return (pair.0, pair.1, pair.2, dValue)
            }
        }
    }
    
    static func zip<A,B,C,D,E>(_ a: AsyncResult<A>, _ b: AsyncResult<B>, _ c : AsyncResult<C>, _ d: AsyncResult<D>, _ e: AsyncResult<E>) -> AsyncResult<(A,B,C,D,E)> {
        return AsyncResult.zip(a, b, c, d).flatMap { pair -> AsyncResult<(A,B,C,D,E)> in
            return e.map { eValue in
                return (pair.0, pair.1, pair.2, pair.3, eValue)
            }
        }
    }
    
}

extension AsyncResult: Equatable where T: Equatable{
    public static func == (lhs: AsyncResult<T>, rhs: AsyncResult<T>) -> Bool {
        let areLoading = lhs.isLoading || rhs.isLoading
        let areError = lhs.error != nil ||  rhs.error != nil
        
        let sameResult = lhs.result == rhs.result
        
        return !areLoading && !areError && sameResult
    }
}
