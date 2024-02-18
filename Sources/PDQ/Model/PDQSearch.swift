//
//  PDQSearch.swift
//  PDQ
//
//  Created by Ben Gottlieb on 5/3/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
#if os(iOS) || os(visionOS)
	import PDFKit
#else
	import Quartz
#endif
import CrossPlatformKit

public class PDQSearch: Equatable {
	static var activeSearches: [PDQSearch] = []
	static let activeSearchesSemaphore = DispatchSemaphore(value: 1)
	
	public var searchText: String
	var document: PDQDocument
	var completion: ((PDQSearch, [PDQSearchResult]) -> Void)?
	var progress: ((PDQSearch, [PDQSearchResult]) -> Void)?
	let resultsSemaphore = DispatchSemaphore(value: 1)
	let startPage: PDQPage?
	
	var lastResult: PDQSearchResult?

	var results: [PDQSearchResult] = []
	var visitedResults: [PDQSearchResult] = []
	
	public init(text: String, in doc: PDQDocument, currentPage: PDQPage? = nil, progress: ((PDQSearch, [PDQSearchResult]) -> Void)? = nil, completion: ((PDQSearch, [PDQSearchResult]) -> Void)? = nil) {
		self.searchText = text
		self.progress = progress
		self.completion = completion
		self.document = doc
		self.startPage = currentPage
		
		NotificationCenter.default.addObserver(self, selector: #selector(didFindSelection), name: NSNotification.Name.PDFDocumentDidFindMatch, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didFinishFind), name: NSNotification.Name.PDFDocumentDidEndFind, object: nil)
	}
	
	var searchCompareOptions: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
	
	@discardableResult public func next(from result: PDQSearchResult? = nil) -> PDQSearchResult? {
		if let result = result, self.results.count > 0 {
			guard let index = self.results.firstIndex(of: result), index < (self.results.count - 1) else { return nil }
			return self.results[index + 1]
		}

		if let current = result, let index = self.visitedResults.firstIndex(of: current), index < self.visitedResults.count - 1 {
			return self.visitedResults[index + 1]
		}
		
		var selection = result?.selection ?? self.lastResult?.selection
		if selection == nil, let page = self.startPage?.page {
			selection = self.document.document.selection(from: page, atCharacterIndex: 0, to: page, atCharacterIndex: 1)
		}
		if selection == nil { return nil }
		
		#if os(iOS) || os(visionOS)
			if let result = self.document.document.findString(self.searchText, fromSelection: selection, withOptions: self.searchCompareOptions) {
				self.lastResult = PDQSearchResult(selection: result, in: self)
			}
		#else
			if let result = self.document.document.findString(self.searchText, withOptions: self.searchCompareOptions).first {
			//if let result = self.document.document.findString(self.searchText, from: selection, with: self.searchCompareOptions) {
				self.lastResult = PDQSearchResult(selection: result, in: self)
			}
		#endif

		if let result = self.lastResult, !self.visitedResults.contains(result) {
			self.visitedResults.append(result)
		}
		return self.lastResult
	}
	
	public func prev(from result: PDQSearchResult) -> PDQSearchResult? {
		if let index = self.results.firstIndex(of: result) {
			if index > 0 { return self.results[index - 1] }
			return nil
		}

		if let index = self.visitedResults.firstIndex(of: result) {
			if index > 0 { return self.visitedResults[index - 1] }
			return nil
		}

		return nil
	}
	
	@discardableResult public func begin() -> Bool {
		guard let doc = self.document.document else { return false }
		
		#if os(iOS) || os(visionOS)
			doc.beginFindString(self.searchText, withOptions: .caseInsensitive)
		#else
			doc.beginFindString(self.searchText, withOptions: .caseInsensitive)
		#endif
		self.registerSearch()
		return true
	}
	
	public func cancel() -> [PDQSearchResult] {
		self.document.document?.cancelFindString()
		self.unregisterSearch()
		return self.results
	}
	
	@objc func didFindSelection(note: Notification) {
		if let selection = note.userInfo?["PDFDocumentFoundSelection"] as? PDFSelection {
			let newResult = PDQSearchResult(selection: selection, in: self)
			self.resultsSemaphore.wait()
			self.results.append(newResult)
			self.resultsSemaphore.signal()
			self.progress?(self, [newResult])
		}
	}
	
	@objc func didFinishFind(note: Notification) {
		self.resultsSemaphore.wait()
		self.completion?(self, self.results)
		self.resultsSemaphore.signal()
		self.unregisterSearch()
	}
	
	public static func ==(lhs: PDQSearch, rhs: PDQSearch) -> Bool { return lhs === rhs }
}

extension PDQSearch {
	func registerSearch() {
		PDQSearch.activeSearchesSemaphore.wait()
		PDQSearch.activeSearches.append(self)
		PDQSearch.activeSearchesSemaphore.signal()
	}
	
	func unregisterSearch() {
		PDQSearch.activeSearchesSemaphore.wait()
		if let index = PDQSearch.activeSearches.firstIndex(of: self) {
			PDQSearch.activeSearches.remove(at: index)
		}
		PDQSearch.activeSearchesSemaphore.signal()
	}
}
