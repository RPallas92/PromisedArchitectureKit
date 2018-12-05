//
//  AsyncResult.swift
//  Fanatics
//
//  Created by Pallas, Ricardo on 12/3/18.
//

import Foundation
import PromiseKit

public class AsyncResult<T: Equatable> {
    
    private let promise: Promise<T>
    
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
    
}

extension AsyncResult: Equatable {
    public static func == (lhs: AsyncResult<T>, rhs: AsyncResult<T>) -> Bool {
        let areLoading = lhs.isLoading || rhs.isLoading
        let areError = lhs.error != nil ||  rhs.error != nil
        
        let sameResult = lhs.result == rhs.result
        
        return !areLoading && !areError && sameResult
    
    }
}
