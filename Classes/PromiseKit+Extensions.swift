//
//  PromiseKit+Extensions.swift
//  PromisedArchitectureKit
//
//  Created by Pallas, Ricardo on 12/3/18.
//

import Foundation
import PromiseKit

private var loadingStateAssociationKey: Any!

public extension Promise {
    
    public var loadingState: T? {
        get {
            return objc_getAssociatedObject(self, &loadingStateAssociationKey) as? T
        }
        set(newValue) {
            objc_setAssociatedObject(self, &loadingStateAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public func map<U>(_ transformation: @escaping (T) -> (U)) -> Promise<U> {
        let resultPromise = Promise<U> { seal in
            self.done { result in
                seal.fulfill(transformation(result))
            }.catch { error in
                seal.reject(error)
            }
        }
        return resultPromise
    }
    
    public func mapError(_ transformation: @escaping (Error) -> (Error)) -> Promise<T>{
        
        let resultPromise = Promise<T> { seal in
            self.done { result in
                seal.fulfill(result)
            }.catch { error in
                seal.reject(transformation(error))
            }
        }
        
        resultPromise.loadingState = self.loadingState
        return resultPromise
    }
    
    public func mapErrorRecover( _ transformation: @escaping (Error) -> (T)) -> Promise<T> {
        
        let resultPromise = Promise<T> { seal in
            self.done { result in
                seal.fulfill(result)
            }.catch { error in
                    seal.fulfill(transformation(error))
            }
        }
        
        resultPromise.loadingState = self.loadingState
        return resultPromise
    }
    
    public func flatMap<U>(_ transformation: @escaping(T) -> (Promise<U>)) -> Promise<U>{
        
        let resultPromise = Promise<U> { seal in
            self.done { result in
                transformation(result).done { secondResult in
                    seal.fulfill(secondResult)
                }.catch { secondError in
                    seal.reject(secondError)
                }
            }.catch { error in
                seal.reject(error)
            }
        }
        
        return resultPromise
    }
    
    public func stateWhenLoading(_ state: T) -> Promise<T> {
        self.loadingState = state
        return self
    }
    
    public static func parallel(_ promises: [Promise<T>]) -> Promise<[T]> {
        return when(fulfilled: promises)
    }
    
    public static func zip<A,B>(_ a: Promise<A>, _ b: Promise<B>) -> Promise<(A,B)> {
        return a.flatMap { aValue -> Promise<(A,B)> in
            return b.map { bValue  in
                return (aValue,bValue)
            }
        }
    }
    
    public static func zip<A,B,C>(_ a: Promise<A>, _ b: Promise<B>, _ c : Promise<C>) -> Promise<(A,B,C)> {
        return Promise.zip(a, b).flatMap { pair -> Promise<(A,B,C)> in
            return c.map { cValue in
                return (pair.0, pair.1, cValue)
            }
        }
    }
    
    public static func zip<A,B,C,D>(_ a: Promise<A>, _ b: Promise<B>, _ c : Promise<C>, _ d: Promise<D>) -> Promise<(A,B,C,D)> {
        return Promise.zip(a, b, c).flatMap { pair -> Promise<(A,B,C,D)> in
            return d.map { dValue in
                return (pair.0, pair.1, pair.2, dValue)
            }
        }
    }
    
    public static func zip<A,B,C,D,E>(_ a: Promise<A>, _ b: Promise<B>, _ c : Promise<C>, _ d: Promise<D>, _ e: Promise<E>) -> Promise<(A,B,C,D,E)> {
        return Promise.zip(a, b, c, d).flatMap { pair -> Promise<(A,B,C,D,E)> in
            return e.map { eValue in
                return (pair.0, pair.1, pair.2, pair.3, eValue)
            }
        }
    }
    
}
