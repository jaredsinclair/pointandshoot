//
//  OperationQueue.PointAndShoot.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import Foundation

/// Quality-of-life extension of OperationQueue.
extension OperationQueue {

    /// Is `true` if called from the main queue.
    static var isMain: Bool {
        return main.isCurrent
    }

    /// Performs a block on the main queue as soon as possible without blocking
    /// execution on the current queue, if it isn't the main queue itself.
    ///
    /// - parameter block: The block to be performed.
    static func onMain(_ block: @escaping () -> Void) {
        OperationQueue.main.asap(block)
    }

    /// Initializes and returns a new queue with a max concurrent operation
    /// count of 1.
    static func serialQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }

    /// - returns: Returns `true` if called from `queue`.
    var isCurrent: Bool {
        return OperationQueue.current === self
    }

    /// Performs a block on the receiver as soon as possible without blocking
    /// execution on the current queue, if it isn't the receiver itself.
    ///
    /// - parameter block: The block to be performed.
    func asap(_ block: @escaping () -> Void) {
        if isCurrent {
            block()
        } else {
            addOperation(block)
        }
    }

    /// Adds an array of operations to the receiver.
    ///
    /// The operations added will be executed asynchronously, according to the
    /// standard
    ///
    /// - parameter operations: An array of operations to be added, in order.
    func add(_ operations: [Operation]) {
        addOperations(operations, waitUntilFinished: false)
    }

    func sync(_ block: @escaping () -> Void) {
        let op = BlockOperation(block: block)
        addOperations([op], waitUntilFinished: true)
    }

}
