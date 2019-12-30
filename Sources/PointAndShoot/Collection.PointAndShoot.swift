//
//  Collection.PointAndShoot.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Little Pie, LLC. All rights reserved.
//

extension RangeReplaceableCollection where Element : AnyObject {

    /// Removes the first element that has the same identity as `element`.
    mutating func removeFirstInstance(of element: Element) {
        if let index = firstIndex(where: { $0 === element }) {
            remove(at: index)
        }
    }

}

extension Sequence {

    func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map { $0[keyPath: keyPath] }
    }

}
