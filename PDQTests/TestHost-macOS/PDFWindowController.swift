//
//  PDFWindowController.swift
//  TestHost-macOS
//
//  Created by Ben Gottlieb on 7/21/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

import Cocoa
import PDQ

class PDFWindowController: NSWindowController, PDQViewDelegate, NSWindowDelegate {
	func didClick(on url: URL) {
		print("Clicked on \(url)")
	}
	
	func setControls(visible: Bool, in: PDQNSView, with duration: TimeInterval) {
		
	}
	
	static var controllers: [PDFWindowController] = []
	
	@IBOutlet var thumbnailView: PDQNSThumbnailUIView!
	@IBOutlet var pdfView: PDQNSView!
	public var rememberPositionByDocument = true
	var pdf: PDQDocument?
	var defaultsKey: String? { guard let id = self.pdf?.identifier else { return nil }; return "pdf-window-\(id)" }
	
	class func show(document: PDQDocument) {
		let controller = PDFWindowController(windowNibName: "PDFWindowController")
		
		controller.pdf = document
		
		self.controllers.append(controller)
		
		controller.showWindow(nil)
	}

	var search: PDQSearch?
	override func windowDidLoad() {
        super.windowDidLoad()

		self.window?.delegate = self
//		self.pdfView.autoScales = true
//		self.pdfView.displayMode = .singlePage
		
		if let key = self.defaultsKey, let frameString = UserDefaults.standard.string(forKey: key + "-frame") {
			self.window?.setFrame(from: frameString)
		}
		
		if #available(OSX 10.13, *) {
//			self.pdfView.displayDirection = .horizontal
		}
		self.pdfView.document = self.pdf
		self.pdfView.jump(to: 13, animated: true)
		self.pdfView.useThumbnailView = true
		self.pdfView.delegate = self
		
		self.window?.title = self.pdf?.fallbackTitle ?? "Untitled PDF"
		
	//	NotificationCenter.default.addObserver(self, selector: #selector(highlightsChanged), name: PDQView.Notifications.pdfDidChangeHighlights, object: nil)
		
		if let data = UserDefaults.standard.data(forKey: "highlights"), let highlights = try? JSONDecoder().decode(PDQHighlights.self, from: data) {
			self.pdfView.load(highlights: highlights)
		}
		
		if self.window == nil {
			let search = PDQSearch(text: "dragon", in: self.pdf!, completion: { search, results in
				self.showResult(results.first, from: search)
			})
			
			search.begin()
		} else {
			self.search = PDQSearch(text: "dragon", in: self.pdf!, currentPage: self.pdf?.firstPage, progress:  nil, completion: nil)
			
			self.showResult(self.search?.next(), from: self.search!)
		}
	//	self.pdfView.firstVisiblePageNumber = 10
		
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
	
	func showResult(_ result: PDQSearchResult?, from search: PDQSearch) {
		guard let res = result?.next(in: self.pdfView) else { return }
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			self.showResult(res, from: search)
		}
	}
	
//	@objc func highlightsChanged(note: Notification) {
	func highlightsChanged(in view: PDQNSView) {
		let encoder = JSONEncoder()
		let data = try! encoder.encode(self.pdfView.highlights)
		UserDefaults.standard.set(data, forKey: "highlights")
	}

	func visiblePageChanged(in view: PDQNSView) {
	//	print("page changed to: \(view.currentPage!.pageNumber)")
	}
	
	func windowDidResize(_ notification: Notification) {
		if self.rememberPositionByDocument, let baseKey = self.defaultsKey, let frameString = self.window?.frameDescriptor {
			let key = baseKey + "-frame"
			UserDefaults.standard.set(frameString, forKey: key)
		}
	}
}
