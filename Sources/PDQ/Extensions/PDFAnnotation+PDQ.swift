//
//  PDFAnnotation+PDQ.swift
//  PDQ
//
//  Created by Ben Gottlieb on 1/22/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if os(iOS)
	import PDFKit
#else
	import Quartz
#endif

public func ==(lhs: PDFAnnotationSubtype, rhs: String?) -> Bool {
	guard let rawRHS = rhs?.lowercased() else { return false }
	let rawLHS = lhs.rawValue.lowercased()
	
	return (rawRHS.hasSuffix(rawLHS) || rawLHS.hasSuffix(rawRHS)) && abs(rawRHS.count - rawLHS.count) <= 1
}

public func ==(lhs: String?, rhs: PDFAnnotationSubtype) -> Bool {
	return rhs == lhs
}

extension Array where Element == PDFAnnotation {
	func all(from point: CGPoint) -> [PDFAnnotation] {
		for annotation in self {
			if annotation.bounds.contains(point) {
				return self.all(connectedTo: annotation)
			}
		}
		
		return []
	}
	
	func all(connectedTo base: PDFAnnotation) -> [PDFAnnotation] {
		var subjects = self
		var selected = [base]
		subjects.remove(base)
		
		while true {
			let startedWith = selected
			
			for additional in subjects {
				for current in selected {
					if current.isAdjacent(to: additional) {
						selected.append(additional)
						subjects.remove(additional)
						break
					}
				}
			}
			if startedWith.count == selected.count { break }
		}
		
		return selected
	}
	
	mutating func remove(_ annotation: PDFAnnotation) {
		if let index = self.firstIndex(of: annotation) { self.remove(at: index) }
	}
}

extension PDFAnnotation {
	func isAdjacent(to annotation: PDFAnnotation) -> Bool {
		let myFrame = self.bounds
		let theirFrame = annotation.bounds
		let tolerance = min(myFrame.height / 3, 10)
	
		if abs(myFrame.maxY - theirFrame.minY) < tolerance || abs(myFrame.minY - theirFrame.maxY) < tolerance {
			let checkRect = CGRect(x: myFrame.origin.x, y: theirFrame.origin.y, width: myFrame.width, height: myFrame.height)
			return theirFrame.intersection(checkRect).width > 0
		}
		
		if abs(myFrame.maxX - theirFrame.minX) < tolerance || abs(myFrame.minX - theirFrame.maxX) < tolerance {
			let checkRect = CGRect(x: theirFrame.origin.x, y: myFrame.origin.y, width: myFrame.width, height: myFrame.height)
			return theirFrame.intersection(checkRect).height > 0
		}
		
		return false
	}
}
