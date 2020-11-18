//
//  PDQDocument.swift
//  PDQ
//
//  Created by Ben Gottlieb on 7/19/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

import Foundation

#if os(iOS)
	import PDFKit
#else
	import Quartz
#endif

public class PDQDocument {
	public let document: PDFDocument!
	
	public var identifier: String? { return self.identifierString(at: 0) }
	public var updateTag: String? { return self.identifierString(at: 1) }
	public var firstPage: PDQPage? { return self.page(at: 0) }
	
	public var documentAttributes: [PDFDocumentAttribute: Any] { return self.document.documentAttributes as? [PDFDocumentAttribute: Any] ?? [:] }
	public var title: String? { return self.documentAttributes[.titleAttribute] as? String }
	public var fallbackTitle: String? { return self.title ?? self.url?.lastPathComponent }			// if there's no 'official' title, use the filename
	public var url: URL? { return self.document.documentURL }
	public init?(url: URL) {
		self.document = PDFDocument(url: url)
		if self.document == nil { return nil }
	}
	
	public var soloFirstPage: Bool { return true }
	public var pageCount: Int { return self.document.pageCount }
	public var twoPagePanelCount: Int {
		let count = self.pageCount
		var panels = count / 2

		if count % 2 == 1 {
			panels += 1
		} else if self.soloFirstPage {
			panels += 1
		}
		return panels
	}
	
	/// zero-based index
	var cachedPages: [PDQPage?] = []
	public func page(at pageNumber: Int) -> PDQPage? {
		if self.cachedPages.count > pageNumber, pageNumber >= 0, let found = self.cachedPages[pageNumber] { return found }
		
		guard pageNumber < self.document.pageCount, let pdfPage = self.document.page(at: pageNumber) else { return nil }
		
		let page = PDQPage(pdfPage, number: pageNumber, in: self)
		while self.cachedPages.count <= pageNumber { self.cachedPages.append(nil) }
		self.cachedPages[pageNumber] = page
		return page
	}
	
	convenience public init?(data: Data) {
		let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".pdf")
		do {
			try data.write(to: url)
		} catch {
			return nil
		}
		
		self.init(url: url)
	}
	
	func page(from target: PDFPage?) -> PDQPage? {
		for i in 0..<self.pageCount {
			let page = self.page(at: i)
			if page?.page == target { return page }
		}
		return nil
	}
}

extension PDQDocument {
	public var twoUpPageCount: Int { return self.pageCount / 2 + (self.pageCount % 2) }
	
	public func firstPageNumberFor(twoPanel index: Int) -> Int {
		if !self.soloFirstPage { return index * 2 }
		if index == 0 { return 0 }
		return ((index - 1) * 2) + 1
	}
}

extension PDQDocument {
	func identifierString(at index: Int) -> String? {
		guard let ident = self.document.documentRef?.fileIdentifier else { return nil }
		let count = CGPDFArrayGetCount(ident)
		var result = ""
		
		var object: CGPDFObjectRef?
		if index >= count { return nil }
		guard CGPDFArrayGetObject(ident, index, &object), let obj = object else { return nil }
		guard CGPDFObjectGetType(obj) == .string else { return nil }
		
		var ptrObjectValue: UnsafePointer<Int8>?
		if CGPDFObjectGetValue(obj, .string, &ptrObjectValue), let ptr = ptrObjectValue {
			if let string = CGPDFStringCopyTextString(OpaquePointer(ptr)) {
				result += string as String
			}
		}
		
		return result.isEmpty ? nil : result
	}
}
