//
//  PDFViewSelection+Annotations.swift
//  PDQ
//
//  Created by Ben Gottlieb on 1/21/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import CrossPlatformKit

#if os(iOS) || os(visionOS)
	import PDFKit
#else
	import Quartz
#endif


extension PDFAnnotation {
	convenience init(bounds: CGRect, onPage page: PDFPage, color: UXColor, text: String?) {
		self.init(bounds: bounds, forType: .highlight, withProperties: [PDFAnnotation.createdbyPDQKitKey: true])
		self.page = page
		self.color = color
		self.contents = text
	}
}

extension PDFView {
	struct HighlightAnnotationDeltas {
		let added: [PDFAnnotation]
		let removed: [PDFAnnotation]
	}
	
	func addHighlights(from selection: PDFSelection, color highlightColor: UXColor = UXColor.yellow) -> HighlightAnnotationDeltas {
		let components = selection.selectionsByLine()
		
		let annotations: [PDFAnnotation] = components.compactMap { component in
			if component.pages.count > 1 { Swift.print("Multi-page selection encountered in a single line. Should not happen. \(component)") }
			guard let page = component.pages.first else { return nil }
			let frame = component.bounds(for: page)
			return PDFAnnotation(bounds: frame, onPage: page, color: highlightColor, text: component.string)
		}
		
		selection.pages.first?.document?.addAnnotations(annotations)
		return HighlightAnnotationDeltas(added: annotations, removed: [])
	}
	
	func annotationsIntersecting(_ selection: PDFSelection) -> [PDFAnnotation] {
		let components = selection.selectionsByLine()
		var results: [PDFAnnotation] = []
		
		for component in components {
			guard let page = component.pages.first else { continue }
			let annotations = page.annotations
			let selectionFrame = component.bounds(for: page)
			
			for annotation in annotations {
				if selectionFrame.intersects(annotation.bounds) { results.append(annotation) }
			}
		}
		
		return results
	}
	
	func removeHighlights(from page: PDQPage?) {
		guard let pdfPage = page?.page else { return }
		
		for annotation in pdfPage.annotations {
			if annotation.type == PDFAnnotationSubtype.highlight {
				pdfPage.removeAnnotation(annotation)
			}
		}
	}
	
	func removeHighlights(for selection: PDFSelection) -> HighlightAnnotationDeltas {
		let components = selection.selectionsByLine()
		var added: [PDFAnnotation] = []
		var removed: [PDFAnnotation] = []
		
		for component in components {
			guard let page = component.pages.first else { continue }
			let annotations = page.annotations
			let selectionFrame = component.bounds(for: page)
			
			for annotation in annotations {
				let annotationFrame = annotation.bounds
				var newFrame = annotationFrame
				if selectionFrame.intersects(annotationFrame) { 	// assume they are the same height and y-pos, diff the xs
					let highlightColor = annotation.color
					
					page.removeAnnotation(annotation)
					removed.append(annotation)

					if selectionFrame.contains(annotationFrame) { continue }		//remove the whole thing
					
					if annotationFrame.minX == selectionFrame.minX {			//	[XXX___]
						newFrame.origin.x = selectionFrame.maxX
						newFrame.size.width -= selectionFrame.width
						added.append(PDFAnnotation(bounds: newFrame, onPage: page, color: highlightColor, text: nil))
					} else if annotationFrame.maxX == selectionFrame.maxX {		//  [___XXX]
						newFrame.size.width = selectionFrame.minX - annotationFrame.maxX
						added.append(PDFAnnotation(bounds: newFrame, onPage: page, color: highlightColor, text: nil))
					} else {													//  [__XX__]
						var secondFrame = annotationFrame
						newFrame.size.width = selectionFrame.minX - annotationFrame.minX
						secondFrame.origin.x = selectionFrame.maxX
						secondFrame.size.width = annotationFrame.maxX - selectionFrame.maxX
						added.append(PDFAnnotation(bounds: newFrame, onPage: page, color: highlightColor, text: nil))
						added.append(PDFAnnotation(bounds: secondFrame, onPage: page, color: highlightColor, text: nil))
					}
					
					page.addAnnotations(added)
				}
			}
		}
		
		return HighlightAnnotationDeltas(added: added, removed: removed)
	}
}

extension PDFAnnotation {
	static let createdbyPDQKitKey = "__createdByPDQKit"
}
