//
//  PDQView.swift
//  PDQ_macOS
//
//  Created by Ben Gottlieb on 1/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Cocoa
import Quartz

open class PDQView: NSView {
	
	open var document: PDQDocument! { didSet {
		self.thumbnailView?.document = self.document
		self.setupInternalView()
	}}
	
	public var useThumbnailView = false { didSet { self.updateThumbnailView() }}
	
	public var highlights = PDQHighlights()
	
	public weak var delegate: PDQViewDelegate?
	var pdfView: PDFView!
	var thumbnailView: PDQThumbnailView!
	var controlsHidden = false
	var thumbnailBottomConstraint: NSLayoutConstraint!
	var initialScrollPage: Int?
	var pageNumberLabel: NSTextField!
	weak var contentClickedTimer: Timer?
	var scrollHorizontally: Bool {
		return self.pdfView?.displayDirection == .horizontal
	}
	
	public func showSearchResult(_ result: PDQSearchResult) {
		if let page = result.selection.pages.first {
			self.pdfView.go(to: page)
		}
		self.pdfView.go(to: result.selection)
		self.pdfView.setCurrentSelection(result.selection, animate: true)
	}
	
	func showPageNumber() {
		if self.pageNumberLabel == nil {
			self.pageNumberLabel = NSTextField(frame: .zero)
			self.addSubview(self.pageNumberLabel!)
			
			self.pageNumberLabel.translatesAutoresizingMaskIntoConstraints = false
			self.pageNumberLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
			self.pageNumberLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -200).isActive = true
			self.pageNumberLabel.widthAnchor.constraint(equalToConstant: 120).isActive = true
			self.pageNumberLabel.heightAnchor.constraint(equalToConstant: 70).isActive = true

			self.pageNumberLabel?.wantsLayer = true
			self.pageNumberLabel?.isBezeled = false
			self.pageNumberLabel?.alignment = .center
			self.pageNumberLabel?.textColor = .white
			self.pageNumberLabel?.font = NSFont.boldSystemFont(ofSize: 50)
			self.pageNumberLabel?.drawsBackground = true
			self.pageNumberLabel?.backgroundColor = NSColor(white: 0.2, alpha: 0.3)
		}
		
		self.pageNumberLabel?.isHidden = false
		self.pageNumberLabel?.stringValue = "\((self.currentPage?.pageNumber ?? 0) + 1)"
	}
	
	func hidePageNumber() {
		self.pageNumberLabel?.isHidden = true
	}
	
	private var lastRecordedVisiblePageNumber = 0
	
	func setupInternalView() {
		if self.pdfView == nil {
			self.pdfView = PDQWrapperView(frame: self.bounds)
			self.pdfView.autoresizingMask = [.width, .height]
			self.pdfView.displayMode = .singlePageContinuous
			self.addSubview(self.pdfView)

			NotificationCenter.default.addObserver(self, selector: #selector(willStartLiveScroll), name: NSScrollView.willStartLiveScrollNotification, object: self.pdfView.documentView?.enclosingScrollView)
			NotificationCenter.default.addObserver(self, selector: #selector(didLiveScroll), name: NSScrollView.didLiveScrollNotification, object: self.pdfView.documentView?.enclosingScrollView)
			NotificationCenter.default.addObserver(self, selector: #selector(didFinishLiveScroll), name: NSScrollView.didEndLiveScrollNotification, object: self.pdfView.documentView?.enclosingScrollView)

			NotificationCenter.default.addObserver(self, selector: #selector(currentPageChanged), name: .PDFViewPageChanged, object: nil)

			let recog = NSClickGestureRecognizer(target: self, action: #selector(clicked))
			recog.delegate = self
			self.pdfView.addGestureRecognizer(recog)
			self.pdfView.delegate = self
		}
		
		self.pdfView.document = self.document?.document
		self.pdfView.displayDirection = .horizontal
		
		if let first = self.document.firstPage {
			self.pdfView.scaleFactor = first.page.getScale(within: self.bounds.size)
		}
	}
	
	@objc func currentPageChanged() {
		guard let current = self.currentPage?.pageNumber else { return }
		
		if self.lastRecordedVisiblePageNumber != current {
			self.lastRecordedVisiblePageNumber = current
			self.delegate?.visiblePageChanged(in: self)
		}
	}
	
	enum ClickAction { case previous, toggle, next }
	@objc func clicked(recog: NSClickGestureRecognizer) {
		let segmentSize = self.bounds.width / 3
		let x = recog.location(in: self).x
		let action: ClickAction
		
		if x < segmentSize {				//left third, page back
			action = .previous
			//self.goToPreviousPage(nil)
		} else if x < 2 * segmentSize {		//center, toggle controls
			action = .toggle
			//self.toggle(andTellDelegate: true, duration: 0.2)
		} else {							//right third, page forward
			action = .next
			//self.goToNextPage(nil)
		}
		
		self.contentClickedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
			switch action {
			case .previous: self.goToPreviousPage(nil)
			case .toggle: self.toggleControls(nil)
			case .next: self.goToNextPage(nil)
			}
		}
	}
	
	var lastClickLocation: CGPoint?
	
	public func load(highlights: PDQHighlights) {
		self.highlights = highlights
		let annotations = self.highlights.convertToAnnotations(in: self.document)
		self.pdfView.document?.addAnnotations(annotations)
	}
	
	public var currentPage: PDQPage? {
		if let offset = self.pdfView.documentView?.enclosingScrollView?.documentVisibleRect.origin.x, let contentWidth = self.pdfView.documentView?.frame.width {
			let pageCount = self.document.pageCount
			let pageSize = contentWidth / CGFloat(pageCount)
			let pageNumber = round(offset / pageSize)
			return self.document.page(at: Int(pageNumber))
		}
		if let page = self.pdfView.currentPage { return self.document.page(from: page) }
		return nil
	}
	
	public weak var pageForContextualMenu: PDQPage?
}

extension PDQView: PDQThumbnailTarget {
	public func jump(to pageNumber: Int, animated: Bool) {
		if let page = self.document.page(at: pageNumber)?.page {
			self.pdfView?.go(to: PDFDestination(page: page, at: .zero))
		}
	}
	
	public var visiblePages: [PDQPage] {
		if let page = self.currentPage {
			return [page]
		}
		return []
	}
	
	public func startScrolling() {
		self.showPageNumber()
	}
	
	public func continueScrolling() {
		self.showPageNumber()
	}
	
	public func stopScrolling() {
		self.hidePageNumber()
	}
}

extension PDQView {
	@IBAction func goToNextPage(_ sender: Any?) {
		guard let pageNumber = self.currentPage?.pageNumber else { return }
		self.jump(to: pageNumber + 1, animated: true)
	}
	
	@IBAction func goToPreviousPage(_ sender: Any?) {
		guard let pageNumber = self.currentPage?.pageNumber, pageNumber > 0 else { return }
		self.jump(to: pageNumber - 1, animated: true)
	}
	
	func hideControls(duration: TimeInterval) {
		if self.controlsHidden { return }
		self.controlsHidden = true
		self.delegate?.setControls(visible: false, in: self, with: duration)

		NSAnimationContext.runAnimationGroup({ ctx in
			ctx.duration = 0.2
			self.thumbnailBottomConstraint.animator().constant = 300
		}) {
		}
	}
	
	func showControls(duration: TimeInterval) {
		if !self.controlsHidden { return }
		self.controlsHidden = false
		NSAnimationContext.runAnimationGroup({ ctx in
			ctx.duration = 0.2
			self.thumbnailBottomConstraint.animator().constant = -40
		}) {
		}
	}
	
	func toggle(andTellDelegate: Bool, duration: TimeInterval) {
		if self.controlsHidden {
			self.showControls(duration: duration)
		} else {
			self.hideControls(duration: duration)
		}
		
		if andTellDelegate {
			self.delegate?.setControls(visible: !self.controlsHidden, in: self, with: duration)
		}
	}
	
	@IBAction func toggleControls(_ sender: Any?) {
		self.toggle(andTellDelegate: false, duration: 0.2)
	}
}

extension PDQView {
	@objc func willStartLiveScroll(note: Notification) {
		self.initialScrollPage = self.currentPage?.pageNumber
		self.showPageNumber()
	}
	
	@objc func didLiveScroll(note: Notification) {
		self.showPageNumber()
	}
	
	@objc func didFinishLiveScroll(note: Notification) {
		
		guard let scrollView = note.object as? NSScrollView, scrollView == self.pdfView.documentView?.enclosingScrollView, let viewSize = self.pdfView.documentView?.bounds.size else { return }
		self.hidePageNumber()

		if self.currentPage?.pageNumber == self.initialScrollPage { return }

		if self.scrollHorizontally {
			let offset = scrollView.contentView.bounds.origin.x
			let pageSize = viewSize.width / CGFloat(self.document.pageCount)
			let panelNumber = round(offset / pageSize)

			//self.firstVisiblePanelIndex = Int(panelNumber)
			let rounded = panelNumber * pageSize
			scrollView.contentView.animator().setBoundsOrigin(CGPoint(x: rounded, y: 0))
		} else {
			let offset = scrollView.contentView.bounds.origin.y
			let pageSize = viewSize.height / CGFloat(self.document.pageCount)
			let panelNumber = round(offset / pageSize)
			
			//self.firstVisiblePanelIndex = Int(panelNumber)
			let rounded = panelNumber * pageSize
			scrollView.contentView.animator().setBoundsOrigin(CGPoint(x: 0, y: rounded))
		}
	}
}

extension PDQView {
	class PDQWrapperView: PDFView {
		override func menu(for event: NSEvent) -> NSMenu? {
			guard let pdqView = self.superview as? PDQView, let contentView = self.window?.contentView else { return nil }
			
			let location = self.convert(event.locationInWindow, from: contentView)
			guard let page = pdqView.document.page(from: self.page(for: location, nearest: true)) else { return nil }
			let point = self.convert(location, to: page.page)
			
			let menu = pdqView.buildContextualMenu(for: page, at: point)
			return menu
		}
	}
}

extension PDQView {
	func updateThumbnailView() {
		if self.useThumbnailView {
			if self.thumbnailView?.superview == nil {
				if self.thumbnailView == nil {
					self.thumbnailView = PDQThumbnailView(frame: .zero)
					self.thumbnailView.translatesAutoresizingMaskIntoConstraints = false
					self.thumbnailView.heightAnchor.constraint(equalToConstant: 50).isActive = true
				}
				self.addSubview(self.thumbnailView)
				self.thumbnailView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 30).isActive = true
				self.thumbnailView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -30).isActive = true
				
				self.thumbnailBottomConstraint = self.thumbnailView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -40)
				self.thumbnailBottomConstraint.isActive = true
			}

			self.thumbnailView?.thumbnailTarget = self
			self.thumbnailView?.document = self.document
		} else {
			self.thumbnailView?.removeFromSuperview()
		}
	}
}

extension PDQView: PDFViewDelegate {
	public func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
		self.contentClickedTimer?.invalidate()
		self.delegate?.didClick(on: url)
	}
}

extension PDQView: NSGestureRecognizerDelegate {
	public func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: NSGestureRecognizer) -> Bool {
		return true
	}
	
	public func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
		guard let contentView = self.window?.contentView else { return false }
		let pt = self.pdfView.convert(event.locationInWindow, from: contentView)
		let areasOfInterest: PDFAreaOfInterest = [.linkArea, .textFieldArea, .annotationArea, .controlArea]
		let content = self.pdfView.areaOfInterest(for: pt)
		if content.intersection(areasOfInterest).isEmpty { return true }
		return false
	}
}
#endif
