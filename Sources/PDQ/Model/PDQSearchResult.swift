//
//  PDQSearchResult.swift
//  PDQ
//
//  Created by Ben Gottlieb on 5/3/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
#if os(iOS)
	import PDFKit
#else
	import Quartz
#endif

public class PDQSearchResult: Equatable {
	let selection: PDFSelection
	weak var search: PDQSearch?
	
	init(selection: PDFSelection, in search: PDQSearch) {
		self.search = search
		self.selection = selection
	}
	
	public func show(in view: PDQUXView) {
		view.showSearchResult(self)
	}
	
	public func next(in view: PDQUXView) -> PDQSearchResult? {
		guard let next = self.search?.next(from: self) else { return nil }
		
		next.show(in: view)
		return next
	}

	public static func ==(lhs: PDQSearchResult, rhs: PDQSearchResult) -> Bool { return lhs === rhs }
}
