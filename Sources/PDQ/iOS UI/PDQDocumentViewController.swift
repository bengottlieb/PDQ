//
//  PDQDocumentViewController.swift
//  PDQ_iOS
//
//  Created by Ben Gottlieb on 8/13/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

#if canImport(UIKit)

import UIKit

open class PDQDocumentViewController: UIViewController {
	public var document: PDQDocument! { didSet { self.pdqView.document = self.document }}
	public var pdqView: PDQView!
	
	public var firstVisiblePageNumber: Int {
		set { self.pdqView.firstVisiblePageNumber = newValue }
		get { return self.pdqView.firstVisiblePageNumber }
	}
	public convenience init(document: PDQDocument) {
		self.init()
		self.document = document
	}
	
	open override func loadView() {
		self.pdqView = PDQView(frame: UIScreen.main.bounds, document: self.document)
		self.pdqView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.pdqView.backgroundColor = .white
		self.view = self.pdqView
	}
}
#endif
