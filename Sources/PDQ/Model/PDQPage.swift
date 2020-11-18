//
//  PDQPage.swift
//  PDQ
//
//  Created by Ben Gottlieb on 8/12/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

import Foundation
import CrossPlatformKit

#if os(iOS)
	import PDFKit
#else
	import Quartz
	import Cocoa
#endif

public class PDQPage: Equatable {
	public let page: PDFPage
	public let document: PDQDocument
	public let pageNumber: Int
	var cachedThumbnail: UXImage?
	var pageSize: CGSize {
		return self.page.bounds(for: .mediaBox).size
	}
	
	var isLeftPage: Bool {
		if self.document.soloFirstPage { return self.pageNumber % 2 == 1 }
		return self.pageNumber % 2 == 0
	}
	
	init(_ page: PDFPage, number: Int, in doc: PDQDocument) {
		self.page = page
		self.document = doc
		self.pageNumber = number
	}
	
	public func generateImage(ofSize size: CGSize) -> UXImage? {
		if #available(OSX 10.13, iOS 11, *) {
			return self.page.thumbnail(of: size, for: .mediaBox)
		}
		#if os(OSX)
			guard let url = self.document.url,
				let data = try? Data(contentsOf: url),
				let rep = NSPDFImageRep(data: data)
			else { return nil }
			
			let image = NSImage(size: rep.size, flipped: false) { ctx in
				rep.draw(in: CGRect(origin: .zero, size: rep.size))
			}
			return image
		#else
			return nil
		#endif
	}
	
	var hasHighlights: Bool {
		if #available(OSXApplicationExtension 10.13, *) {
			for annotation in self.page.annotations {
				if annotation.type == PDFAnnotationSubtype.highlight { return true }
			}
		}
		return false
	}
	
	@available(OSXApplicationExtension 10.13, *)
	func thumbnail(size: CGSize) -> UXImage? {
		if self.cachedThumbnail == nil {
			self.cachedThumbnail = self.page.thumbnail(of: size, for: .mediaBox)
		}
		return self.cachedThumbnail
	}
	
	public static func ==(lhs: PDQPage, rhs: PDQPage) -> Bool {
		return lhs.page == rhs.page
	}
}

extension PDQPage {
	func highlights(at point: CGPoint) -> [PDFAnnotation] {
		return self.page.annotations.all(from: point)
	}
}
