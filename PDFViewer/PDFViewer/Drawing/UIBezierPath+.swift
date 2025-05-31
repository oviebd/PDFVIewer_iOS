//
//  UIBezierPath+.swift
//  RUDNDocs
//
//  Created by Tim on 24/08/2019.
//  Copyright © 2019 Tim. All rights reserved.
//

import SwiftUI

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: size.width / 2.0, y: size.height / 2.0)
    }
}

extension CGPoint {
    func vector(to p1: CGPoint) -> CGVector {
        return CGVector(dx: p1.x - x, dy: p1.y - y)
    }
}

extension UIBezierPath {
    @discardableResult
    func moveCenter(to: CGPoint) -> Self {
        let bound = cgPath.boundingBox
        let center = bounds.center

        let zeroedTo = CGPoint(x: to.x - bound.origin.x, y: to.y - bound.origin.y)
        let vector = center.vector(to: zeroedTo)

        offset(to: CGSize(width: vector.dx, height: vector.dy))
        return self
    }

    @discardableResult
    func offset(to offset: CGSize) -> Self {
        let t = CGAffineTransform(translationX: offset.width, y: offset.height)
        applyCentered(transform: t)
        return self
    }

    func fit(into: CGRect) -> Self {
        let bounds = cgPath.boundingBox

        let sw = into.size.width / bounds.width
        let sh = into.size.height / bounds.height
        let factor = min(sw, max(sh, 0.0))

        return scale(x: factor, y: factor)
    }

    func scale(x: CGFloat, y: CGFloat) -> Self {
        let scale = CGAffineTransform(scaleX: x, y: y)
        applyCentered(transform: scale)
        return self
    }

    @discardableResult
    func applyCentered(transform: @autoclosure () -> CGAffineTransform) -> Self {
        let bound = cgPath.boundingBox
        let center = CGPoint(x: bound.midX, y: bound.midY)
        var xform = CGAffineTransform.identity

        xform = xform.concatenating(CGAffineTransform(translationX: -center.x, y: -center.y))
        xform = xform.concatenating(transform())
        xform = xform.concatenating(CGAffineTransform(translationX: center.x, y: center.y))
        apply(xform)

        return self
    }
}
