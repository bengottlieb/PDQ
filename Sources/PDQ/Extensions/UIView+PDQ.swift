//
//  UIView+PDQ.swift
//  PDQ_iOS
//
//  Created by Ben Gottlieb on 5/2/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit

extension UIView {
	func firstChild(ofClassNamed className: String) -> UIView? {
		for child in self.subviews {
			if NSStringFromClass(type(of: child)) == className { return child }
			if let result = child.firstChild(ofClassNamed: className) { return result }
		}
		return nil
	}
}
#endif
