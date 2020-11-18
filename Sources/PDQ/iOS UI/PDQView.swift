//
//  PDQView.swift
//  PDQ_iOS
//
//  Created by Ben Gottlieb on 7/20/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

#if canImport(UIKit)
import PDFKit

public class PDQView: UIView {
	public var document: PDQDocument! { didSet {
		self.thumbnailView?.document = self.document
		self.pdfView?.document = self.document.document
	}}
	public var highlights = PDQHighlights()

	public weak var delegate: PDQViewDelegate?
	public var pdfView: PDFView!
	var controlsHidden = false
	var pageNumberLabel: UILabel?
	var thumbnailView: PDQThumbnailView!
	var editView: EditView!
	public var useThumbnailView = false { didSet {
		self.updateThumbnailView()
	}}

	
	public convenience init(frame: CGRect, document: PDQDocument?) {
		self.init(frame: frame)
		self.document = document

		self.pdfView = PDFView(frame: self.bounds)
		self.pdfView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		self.addSubview(self.pdfView)
		self.pdfView.displayDirection = .horizontal
		self.pdfView.displayMode = .singlePage
		self.pdfView.delegate = self

		self.pdfView.document = self.document?.document
		self.pdfView.maxScaleFactor = 4.0
		self.pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
		
		self.pdfView.autoScales = true
		self.pdfView.usePageViewController(true, withViewOptions: [convertFromUIPageViewControllerOptionsKey(UIPageViewController.OptionsKey.interPageSpacing): 20])
		
		NotificationCenter.default.addObserver(self, selector: #selector(selectionChanged), name: .PDFViewSelectionChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(currentPageChanged), name: .PDFViewPageChanged, object: nil)
		
		let recog = UITapGestureRecognizer(target: self, action: #selector(tapped))
		recog.delegate = self
		self.pdfView.addGestureRecognizer(recog)
	}
	
	public override var frame: CGRect { didSet { self.didChangeFrame() }}
	public override var bounds: CGRect { didSet { self.didChangeFrame() }}

	public func showSearchResult(_ result: PDQSearchResult) {
		if let page = result.selection.pages.first {
			self.pdfView.go(to: page)
		}
		self.pdfView.go(to: result.selection)
		self.pdfView.setCurrentSelection(result.selection, animate: true)
	}
	
	func didChangeFrame() {
		let newDisplayMode = self.bounds.width > self.bounds.height ? PDFDisplayMode.twoUp : PDFDisplayMode.singlePage
		if newDisplayMode != self.pdfView?.displayMode {
			self.pdfView?.displayMode = newDisplayMode
		}
	}
	
	@objc func tapped(recog: UITapGestureRecognizer) {
		let segmentSize = self.bounds.width / 3
		let x = recog.location(in: self).x
		
		if x < segmentSize {				//left third, page back
			self.goToPreviousPage(nil)
		} else if x < 2 * segmentSize {		//center, toggle controls
			self.toggle(andTellDelegate: true, duration: 0.2)
		} else {							//right third, page forward
			self.goToNextPage(nil)
		}
	}
	
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
		UIView.animate(withDuration: duration) {
			self.thumbnailView?.transform = CGAffineTransform(translationX: 0, y: 300)
		}
	}
	
	func showControls(duration: TimeInterval) {
		if !self.controlsHidden { return }
		self.controlsHidden = false
		UIView.animate(withDuration: duration) {
			self.thumbnailView?.transform = .identity
		}
	}
	
	private func toggle(andTellDelegate: Bool, duration: TimeInterval) {
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
	
	private var lastRecordedVisiblePageNumber = 0
	@objc func currentPageChanged() {
		guard let current = self.currentPage?.pageNumber else { return }
		
		if self.lastRecordedVisiblePageNumber != current {
			self.lastRecordedVisiblePageNumber = current
			self.delegate?.visiblePageChanged(in: self)
		}
	}

	@objc func selectionChanged() {
		var items: [UIMenuItem] = []
		
		if let selection = self.pdfView.currentSelection, self.pdfView.annotationsIntersecting(selection).count > 0 {
			items.append(UIMenuItem(title: NSLocalizedString("Un-Highlight", comment: "Un-Highlight"), action: #selector(removeHighlightFromSelection)))
		} else {
			items.append(UIMenuItem(title: NSLocalizedString("Highlight", comment: "Highlight"), action: #selector(highlightSelection)))
		}
		
		UIMenuController.shared.menuItems = items
	}
	
	@objc func highlightSelection() {
		guard let selection = self.pdfView.currentSelection else { return }
		
		let color = UIColor.yellow
		let results = self.pdfView.addHighlights(from: selection, color: color)
		self.highlights.apply(deltas: results, in: self.document)
		NotificationCenter.default.post(name: Notifications.pdfDidChangeHighlights, object: self.document)
		self.delegate?.highlightsChanged(in: self)
	}
	
	@objc func removeHighlight() {
		guard let selection = self.pdfView.currentSelection else { return }
		
		let results = self.pdfView.removeHighlights(for: selection)
		self.highlights.apply(deltas: results, in: self.document)
		NotificationCenter.default.post(name: Notifications.pdfDidChangeHighlights, object: self.document)
		self.delegate?.highlightsChanged(in: self)
	}

	@objc func removeHighlightFromSelection() {
		guard let selection = self.pdfView.currentSelection else { return }
		
		var removeThese: [PDFAnnotation] = []
		
		selection.pages.forEach { page in
			let bounds = selection.bounds(for: page)
			let center = CGPoint(x: bounds.midX, y: bounds.midY)
			let found = page.annotations.all(from: center)
			page.removeAnnotations(found)
			removeThese += found
		}
		
		let deltas = PDFView.HighlightAnnotationDeltas(added: [], removed: removeThese)
		self.highlights.apply(deltas: deltas, in: self.document)
	}
	
	public func jump(to pageNumber: Int, animated: Bool) {
		if let page = self.document.page(at: pageNumber)?.page {
			self.pdfView?.go(to: PDFDestination(page: page, at: .zero))
		}
	}

	public var firstVisiblePageNumber: Int {
		set {
			if let page = self.document.page(at: newValue) {
				self.pdfView.go(to: page.page)
			}
		}
		get {
			guard let page = self.pdfView.currentPage, let pdqPage = self.document?.page(from: page) else { return 1 }
			return pdqPage.pageNumber
		}
	}
	
	public var currentPage: PDQPage? {
		if let page = self.pdfView.currentPage { return self.document.page(from: page) }
		return nil
	}

	public func load(highlights: PDQHighlights) {
		self.highlights = highlights
		let annotations = self.highlights.convertToAnnotations(in: self.document)
		self.pdfView.document?.addAnnotations(annotations)
	}
	
	public var visiblePages: [PDQPage] {
		if let page = self.document?.page(from: self.pdfView?.currentPage) {
			return [page]
		}
		return []
	}
	
	func startScrolling() {
		DispatchQueue.main.async {
			if self.pageNumberLabel == nil {
				self.pageNumberLabel = UILabel(frame: .zero)
				self.pageNumberLabel?.backgroundColor = UIColor(white: 0.3, alpha: 0.3)
				self.pageNumberLabel?.textColor = .white
				self.pageNumberLabel?.textAlignment = .center
				self.pageNumberLabel?.adjustsFontSizeToFitWidth = true
				self.pageNumberLabel?.minimumScaleFactor = 0.5
				
				self.addSubview(self.pageNumberLabel!)
				self.pageNumberLabel?.translatesAutoresizingMaskIntoConstraints = false
				self.pageNumberLabel?.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
				self.pageNumberLabel?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -200).isActive = true
				self.pageNumberLabel?.widthAnchor.constraint(equalToConstant: 120).isActive = true
				self.pageNumberLabel?.heightAnchor.constraint(equalToConstant: 70).isActive = true

				self.pageNumberLabel?.font = UIFont.boldSystemFont(ofSize: 60)
			}
			
			self.pageNumberLabel?.isHidden = false
			self.pageNumberLabel?.text = "\((self.currentPage?.pageNumber ?? 0) + 1)"
		}
	}
	
	func continueScrolling() {
		DispatchQueue.main.async {
			self.startScrolling()
		}
	}
	
	func endScrolling() {
		DispatchQueue.main.async {
			self.pageNumberLabel?.isHidden = true
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
					self.thumbnailView.pdqView = self
				}
				self.addSubview(self.thumbnailView)
				self.thumbnailView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 30).isActive = true
				self.thumbnailView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -30).isActive = true
				self.thumbnailView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -40).isActive = true
			}
			
			self.thumbnailView.document = self.document
		//	thumb.thumbnailTarget = self
		} else {
			self.thumbnailView?.removeFromSuperview()
		}
	}
}

extension PDQView: PDFViewDelegate {
	public func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
		self.delegate?.didClick(on: url)
	}
}

extension PDQView: UIGestureRecognizerDelegate {
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return true
	}
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIPageViewControllerOptionsKey(_ input: UIPageViewController.OptionsKey) -> String {
	return input.rawValue
}
#endif
