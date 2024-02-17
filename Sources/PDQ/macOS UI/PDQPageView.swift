//
//  PDQPageNSView.swift
//  PDQ_macOS
//
//  Created by Ben Gottlieb on 1/15/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Cocoa
import Quartz
import CrossPlatformKit

class PDQPageNSView: NSView {
	var page: PDQPage? { didSet {
		if self.page == oldValue { return }
		self.hidePDFView()
		self.updateUI()
	}}
	
	var pageContainer: PDQPageContainer!
	var pdfPageView: NSView!
	
	func updateUI() {
		self.setNeedsDisplay(self.bounds)
	}
	
	override func draw(_ dirtyRect: NSRect) {
		guard let page = self.page, let ctx = NSGraphicsContext.current?.cgContext else { return }

		let transform = page.page.transformFor(size: self.bounds.size)
		ctx.concatenate(transform)

		page.page.draw(with: .mediaBox, to: ctx)
	}
	
	override var frame: CGRect { didSet { self.setNeedsDisplay(self.bounds) }}
	override var bounds: CGRect { didSet { self.setNeedsDisplay(self.bounds) }}
	
	override func mouseDown(with event: NSEvent) {
		self.showPDFView()
	}
	
	func showPDFView() {
		guard let page = self.page, self.pdfPageView == nil else { return }
		self.pageContainer = PDQPageContainer(frame: self.bounds)
		self.pageContainer.load(page: page)
		
		self.pdfPageView = self.pageContainer
		self.pdfPageView.frame = page.page.contentFrame(within: self.bounds.size)
		self.addSubview(self.pdfPageView)
		
	}
	
	func hidePDFView() {
		self.pageContainer?.removeFromSuperview()
		self.pdfPageView?.removeFromSuperview()
		self.pageContainer = nil
	}
	
	class PDQPageContainer: PDFView {
		func load(page: PDQPage?) {
			guard let pdfPage = page?.page else { return }
			self.displayMode = .singlePage
			self.document = page?.document.document
			self.go(to: PDFDestination(page: pdfPage, at: .zero))
		}
		
		override func scrollWheel(with event: NSEvent) {
			
		}
		
		override func keyDown(with event: NSEvent) {
			
		}
	}
}


#endif
