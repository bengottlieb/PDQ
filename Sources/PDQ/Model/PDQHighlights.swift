//
//  PDQHighlights.swift
//  PDQ
//
//  Created by Ben Gottlieb on 1/21/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import CrossPlatformKit
#if os(iOS)
	import PDFKit
#else
	import Quartz
#endif

public struct PDQHighlights: Codable {
	public var highlights: [Section] = []
	
	init() { }
	
	mutating func add(selection: PDFSelection, in doc: PDQDocument, color: UXColor) {
		let sections: [Section] = selection.selectionsByLine().compactMap { component in
			guard let page = component.pages.first, let pageNumber = doc.page(from: page)?.pageNumber else { return nil }
			return Section(pageNumber: pageNumber, rect: component.bounds(for: page), text: component.string ?? "", color: color)
		}
		self.highlights += sections
	}
	
	mutating func remove(selection: PDFSelection, in doc: PDQDocument) {
		selection.selectionsByLine().forEach { component in
			guard let page = component.pages.first, let pageNumber = doc.page(from: page)?.pageNumber else { return }

			let rect = component.bounds(for: page)
			if let index = self.highlights.firstIndex(where: { section in
				return pageNumber == section.pageNumber && section.rect == rect
			}) {
				self.highlights.remove(at: index)
			}
		}
	}
	
	@available(OSXApplicationExtension 10.13, *)
	mutating func apply(deltas: PDFView.HighlightAnnotationDeltas, in doc: PDQDocument) {
		for element in deltas.removed {
			guard let page = element.page, let pageNumber = doc.page(from: page)?.pageNumber else { continue }
			
			let rect = element.bounds
			if let index = self.highlights.firstIndex(where: { section in
				return pageNumber == section.pageNumber && section.rect == rect
			}) {
				self.highlights.remove(at: index)
			}
		}
		
		let sections: [Section] = deltas.added.compactMap { annotation in
			guard let page = annotation.page, let pageNumber = doc.page(from: page)?.pageNumber else { return nil }
			return Section(pageNumber: pageNumber, rect: annotation.bounds, text: annotation.contents ?? "", color: annotation.color)
		}
		self.highlights += sections
	}
	
	@available(OSXApplicationExtension 10.13, *)
	func convertToAnnotations(in doc: PDQDocument) -> [PDFAnnotation] {
		return self.highlights.compactMap { $0.convertToAnnotation(in: doc) }
	}
	
	public struct Section: Codable {
		enum CodableKeys: CodingKey { case pageNumber, rect, text, color, r, g, b, a }
		
		let pageNumber: Int
		let rect: CGRect
		let text: String
		let color: UXColor
		
		init(pageNumber: Int, rect: CGRect, text: String, color: UXColor) {
			self.pageNumber = pageNumber
			self.rect = rect
			self.text = text
			self.color = color
		}
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKeys.self)
			
			try container.encode(self.pageNumber, forKey: .pageNumber)
			try container.encode(self.rect, forKey: .rect)
			try container.encode(self.text, forKey: .text)
			
			var r: CGFloat = 0
			var g: CGFloat = 0
			var b: CGFloat = 0
			var a: CGFloat = 0
			
			self.color.getRed(&r, green: &g, blue: &b, alpha: &a)
			
			try container.encode(r, forKey: .r)
			try container.encode(g, forKey: .g)
			try container.encode(b, forKey: .b)
			try container.encode(a, forKey: .a)
		}
		
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKeys.self)
			
			self.pageNumber = try container.decode(Int.self, forKey: .pageNumber)
			self.rect = try container.decode(CGRect.self, forKey: .rect)
			self.text = try container.decode(String.self, forKey: .text)
			
			let r = try container.decode(CGFloat.self, forKey: .r)
			let g = try container.decode(CGFloat.self, forKey: .g)
			let b = try container.decode(CGFloat.self, forKey: .b)
			let a = try container.decode(CGFloat.self, forKey: .a)
			
			self.color = UXColor(red: r, green: g, blue: b, alpha: a)
		}
		
		@available(OSXApplicationExtension 10.13, *)
		func convertToAnnotation(in doc: PDQDocument) -> PDFAnnotation? {
			guard let page = doc.document.page(at: self.pageNumber) else { return nil }
			
			return PDFAnnotation(bounds: self.rect, onPage: page, color: self.color, text: text)
		}

	}
}
