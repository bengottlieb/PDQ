//
//  PDQThumbnailView.swift
//  PDQ_macOS
//
//  Created by Ben Gottlieb on 1/17/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Cocoa
import Quartz

public protocol PDQThumbnailTarget: class {
	func jump(to pageNumber: Int, animated: Bool)
	func startScrolling()
	func continueScrolling()
	func stopScrolling()
	
	var visiblePages: [PDQPage] { get }
}

@available(OSXApplicationExtension 10.13, *)
public class PDQThumbnailView: NSView {
	public var thumbnailTarget: PDQThumbnailTarget!
	
	public var document: PDQDocument? { didSet { 
		self.updateUI()
		DispatchQueue.main.async {
			self.updateCurrentPageThumbnails()
		}
	}}
	var isDebuggingLayout = false
	var thumbnailSize: CGSize = .zero
	var collectionView: PDQCollectionView!
	var thumbnailsToShow = 1
	var pagesPerThumbnail = 1
	let collectionViewLayout = NSCollectionViewFlowLayout()
	let margins = NSEdgeInsets(top: 6, left: 3, bottom: 6, right: 3)
	var imageHeight: CGFloat { return self.bounds.height - (self.margins.top + self.margins.bottom) }
	var currentPageThumbnailViews: [ThumbnailPageView] = []
	var backgroundView: NSView!
	
	var currentPageThumbnailSize: CGSize {
		let base = self.thumbnailSize
		let ratio = base.width / base.height
		let size = CGSize(width: self.bounds.height * ratio, height: self.bounds.height)
		return size
	}
	
	public override func viewDidEndLiveResize() {
		self.updateUI()
		self.updateCurrentPageThumbnails()
	}
	
	func updateUI() {
		guard let doc = self.document, doc.pageCount > 0 else { return }
		
		if self.backgroundView == nil {
			self.backgroundView = NSView(frame: self.bounds)
			self.addSubview(self.backgroundView)
			self.backgroundView.wantsLayer = true
			self.backgroundView.layer?.backgroundColor = NSColor.white.cgColor
			self.backgroundView.layer?.borderColor = NSColor.lightGray.cgColor
			self.backgroundView.layer?.borderWidth = 0.5
		}
		
		if self.collectionView == nil {
			var frame = self.bounds
			frame.origin.x += self.margins.left - 2
			frame.origin.y += self.margins.bottom - 2
			frame.size.width -= (self.margins.left + self.margins.right) - 4
			frame.size.height -= (self.margins.top + self.margins.bottom) - 4

			self.collectionView = PDQThumbnailCollectionView.setup(in: self, frame: frame)
			self.collectionView.delegate = self
			self.collectionView.dataSource = self
			
			let nib = NSNib(nibNamed: NSNib.Name("PDQThumbnailCollectionItem_macOS"), bundle: Bundle(for: type(of: self)))
			self.collectionView.register(nib, forItemWithIdentifier: PDQThumbnailCollectionItem.identifier)
			
			self.collectionViewLayout.itemSize = CGSize(width: self.imageHeight, height: self.imageHeight)
			self.collectionViewLayout.minimumInteritemSpacing = 0
			self.collectionViewLayout.minimumLineSpacing = 0
			self.collectionViewLayout.sectionInset = NSEdgeInsets()
			self.collectionViewLayout.scrollDirection = .horizontal
			self.collectionView.collectionViewLayout = self.collectionViewLayout
			self.collectionView.userInteractionEnabled = false
			
			self.collectionView.backgroundColors = [NSColor.clear]
			
			NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentPageThumbnails), name: .PDFViewPageChanged, object: nil)
		}
		
		self.collectionView.wantsLayer = true
		
		self.collectionViewLayout.itemSize = CGSize(width: self.imageHeight, height: self.imageHeight)
		self.collectionView.scrollView.hasHorizontalScroller = false
		self.collectionView.scrollView.horizontalScroller?.wantsLayer = true
		self.collectionView.scrollView.horizontalScroller?.layer?.opacity = 0.0
		self.collectionView.scrollView.horizontalScroller?.isHidden = true
		if self.thumbnailSize == .zero { self.updateItemSize() }
		self.collectionView.reloadData()
	}
	
	@objc func updateCurrentPageThumbnails() {
		if self.bounds.width <= 0 { return }
		self.currentPageThumbnailViews.forEach { $0.removeFromSuperview() }
		
		if self.isDebuggingLayout { return }
		var newThumbnails: [ThumbnailPageView] = []
		for page in self.thumbnailTarget?.visiblePages ?? [] {
			let view = self.pageThumbnail(for: page.pageNumber)
			self.addSubview(view)
			newThumbnails.append(view)
		}
		
		let size = self.currentPageThumbnailSize
		let thumbnailsWidth = CGFloat(newThumbnails.count) * size.width
		let availableWidth = self.bounds.width - (self.margins.left + self.margins.top + thumbnailsWidth)

		self.currentPageThumbnailViews = newThumbnails
		if let first = newThumbnails.first, let doc = self.document {
			let centerX = self.collectionViewLayout.sectionInset.left + self.margins.left + (availableWidth * CGFloat(first.pageNumber)) / CGFloat(doc.pageCount) + size.width * 0.5
			var left = centerX - thumbnailsWidth * 0.5
			for thumb in newThumbnails {
				thumb.frame = CGRect(x: left, y: (self.bounds.height - size.height) / 2, width: size.width, height: size.height)
				left += size.width
			}
		}
		
		var frame = self.frame
		frame.origin.y = self.margins.top
		frame.origin.x = self.collectionViewLayout.sectionInset.left + self.margins.left
		frame.size.width -= (self.collectionViewLayout.sectionInset.left + self.collectionViewLayout.sectionInset.right + self.margins.left + self.margins.right)
		frame.size.height -= (self.margins.top + self.margins.bottom)
		self.backgroundView?.frame = frame
	}
	
	func pageThumbnail(for pageNumber: Int) -> ThumbnailPageView {
		for thumb in self.currentPageThumbnailViews {
			if thumb.pageNumber == pageNumber { return thumb }
		}
		
		let thumb = ThumbnailPageView()
		thumb.pageNumber = pageNumber
		if let page = self.document?.page(at: pageNumber) {
			thumb.image = page.thumbnail(size: self.currentPageThumbnailSize)
		}
		
		thumb.imageScaling = .scaleProportionallyUpOrDown
		thumb.wantsLayer = true
		thumb.layer?.backgroundColor = NSColor.white.cgColor
		thumb.layer?.borderColor = NSColor.black.cgColor
		thumb.layer?.borderWidth = 0.5
		return thumb
	}
	
	func clicked(at point: CGPoint) {
		guard let doc = self.document else { return }
		let pageNumber = Int((point.x / self.bounds.width) * CGFloat(doc.pageCount))
		if pageNumber < 0 { return }
		
		self.thumbnailTarget?.jump(to: pageNumber, animated: true)
		self.updateCurrentPageThumbnails()
	}

	var previousSize = CGSize.zero
	var resizeTimer: Timer?
	func updateItemSize(ignoreSmallChanges: Bool = false) {
		if self.previousSize == self.bounds.size { return }
		
		guard let doc = self.document, doc.pageCount > 0 else { return }
		guard let first = doc.page(at: 0) else { return }

		self.resizeTimer?.invalidate()
		if ignoreSmallChanges {
			self.resizeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] timer in
				self?.updateItemSize(ignoreSmallChanges: false)
			})
			RunLoop.current.add(self.resizeTimer!, forMode: .eventTrackingRunLoopMode)
		} else {
			self.previousSize = self.bounds.size
		}

		let size = first.pageSize
		let scale = self.imageHeight / size.height
		self.thumbnailSize = CGSize(width: scale * size.width, height: self.imageHeight)
		self.collectionViewLayout.itemSize = self.thumbnailSize

		self.thumbnailsToShow = min(doc.pageCount, Int(self.bounds.width / self.imageHeight))
		self.pagesPerThumbnail = (doc.pageCount / self.thumbnailsToShow)
		
		
		self.thumbnailSize = CGSize(width: self.imageHeight, height: self.imageHeight)
		self.collectionViewLayout.itemSize = self.thumbnailSize
		let contentWidth = (CGFloat(self.thumbnailsToShow) * (self.collectionViewLayout.itemSize.width + self.collectionViewLayout.minimumInteritemSpacing))
		let margins = self.bounds.width - contentWidth
		if self.thumbnailsToShow >= doc.pageCount {
			self.collectionViewLayout.sectionInset = NSEdgeInsets(top: 0, left: margins / 2, bottom: 0, right: margins / 2)
		} else {
			self.collectionViewLayout.sectionInset = NSEdgeInsetsZero
		}

		if !ignoreSmallChanges {
			self.updateUI()
		}
		self.updateCurrentPageThumbnails()
		self.collectionView.scrollView.horizontalScroller?.isHidden = true
	}

	open override var frame: CGRect { didSet { self.updateItemSize(ignoreSmallChanges: true) }}
	open override var bounds: CGRect { didSet { self.updateItemSize(ignoreSmallChanges: true) }}

	class PDQThumbnailCollectionView: PDQCollectionView {
		override func mouseDown(with event: NSEvent) {
			guard let thumbview = self.enclosingScrollView?.superview as? PDQThumbnailView else { return }
			thumbview.thumbnailTarget?.startScrolling()
			
			while true {
				guard let nextEvent = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else { continue }
				let location = self.convert(nextEvent.locationInWindow, from: nil)
				let isInside = self.bounds.contains(location)
				
				switch nextEvent.type {
				case .leftMouseDragged:
					if isInside {
						thumbview.clicked(at: location)
						thumbview.thumbnailTarget?.continueScrolling()
					}
					
				case .leftMouseUp:
					thumbview.thumbnailTarget?.stopScrolling()
					return

				default: break
				}
			}

		}
	}
}

@available(OSXApplicationExtension 10.13, *)
extension PDQThumbnailView: NSCollectionViewDataSource {
	open func numberOfSections(in collectionView: NSCollectionView) -> Int { return 1 }
	open func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.thumbnailsToShow
	}
	
	open func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(withIdentifier: PDQThumbnailCollectionItem.identifier, for: indexPath)
		
		if let cell = item as? PDQThumbnailCollectionItem {
			let pageNumber = indexPath.item * self.pagesPerThumbnail
			cell.showPageNumbers = self.isDebuggingLayout
			cell.page = self.document?.page(at: pageNumber)
		}
		return item
	}
}

@available(OSXApplicationExtension 10.13, *)
extension PDQThumbnailView: NSCollectionViewDelegate {}


@available(OSXApplicationExtension 10.13, *)
extension PDQThumbnailView {
	class ThumbnailPageView: NSImageView {
		var pageNumber: Int = 0
	}
}


#endif
