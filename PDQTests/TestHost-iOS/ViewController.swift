//
//  ViewController.swift
//  TestHost
//
//  Created by Ben Gottlieb on 7/19/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

import UIKit
import PDQ
import PDFKit

extension PDQDocument {
	static var testDocument: PDQDocument {
		let url = Bundle.main.url(forResource: "CoreData", withExtension: "pdf")!
		let doc = PDQDocument(url: url)
		
		return doc!
	}
}

class ViewController: UIViewController, PDQViewDelegate {
	var pdqView: PDQUIView!
	var search: PDQSearch?

	var testing = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(didChangeHighlights), name: PDQUIView.Notifications.pdfDidChangeHighlights, object: nil)
		
		self.pdqView = PDQUIView(frame: self.view.bounds, document: PDQDocument.testDocument)
		self.view.addSubview(self.pdqView)
		self.pdqView.delegate = self
		self.pdqView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		self.view.backgroundColor = .red
		self.pdqView.useThumbnailView = true
		if let data = UserDefaults.standard.data(forKey: "highlights"), let highlights = try? JSONDecoder().decode(PDQHighlights.self, from: data) {
			self.pdqView.load(highlights: highlights)
		}

		if self.testing {
			if self.pdqView == nil {
				self.pdqView.jump(to: 11, animated: true)
				let search = PDQSearch(text: "dragon", in: self.pdqView.document!, completion: { search, results in
					self.showResult(results.first, from: search)
				})

				search.begin()
			} else {
			//	self.search = PDQSearch(text: "Volume", in: self.pdqView.document!, currentPage: self.pdqView.document?.firstPage, progress:  nil, completion: nil)

			//	self.showResult(self.search?.next(), from: self.search!)

				//self.pdqView.beginEditing()
			}
		}
		//	self.pdfView.firstVisiblePageNumber = 10
		
		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	}
	
	func showResult(_ result: PDQSearchResult?, from search: PDQSearch) {
		guard let res = result?.next(in: self.pdqView) else { return }
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			self.showResult(res, from: search)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@objc func didChangeHighlights(note: Notification) {
		let encoder = JSONEncoder()
		let data = try! encoder.encode(self.pdqView.highlights)
		UserDefaults.standard.set(data, forKey: "highlights")
		print(note)
	}
	
	func visiblePageChanged(in view: PDQUIView) {
		print("page changed to: \(view.currentPage!.pageNumber)")
	}
	
	func highlightsChanged(in view: PDQUIView) {
		let encoder = JSONEncoder()
		let data = try! encoder.encode(self.pdqView.highlights)
		UserDefaults.standard.set(data, forKey: "highlights")
	}
	
	func setControls(visible: Bool, in: PDQUIView, with duration: TimeInterval) {
		UIView.animate(withDuration: duration) {
			self.navigationController?.isNavigationBarHidden = !visible
		}
	}

	func didClick(on url: URL) {
		print("Clicked on \(url)")
	}
}

