//
//  PDQView.swift
//  PDQ_iOS
//
//  Created by Ben Gottlieb on 7/20/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Cocoa
import Quartz

open class PDQViewCustom: NSView {
	public enum Style { case onePage, twoPagesHorizontally }
	
	open var scrollAxis = NSCollectionView.ScrollDirection.horizontal
	open var style = Style.twoPagesHorizontally
	open var firstVisiblePageNumber: Int {
		get {
			if self.style == .twoPagesHorizontally { return self.firstVisiblePanelIndex * 2 }
			return self.firstVisiblePanelIndex
		}
		set {
			if self.style == .twoPagesHorizontally {
				self.firstVisiblePanelIndex = newValue / 2
			} else {
				self.firstVisiblePanelIndex = newValue
			}
			self.scrollToCurrentPage()
		}
	}
	open var canScrollForward: Bool { return self.firstVisiblePanelIndex < self.numberOfPanels }
	open var canScrollBack: Bool { return self.firstVisiblePanelIndex > 0 }

	open var document: PDQDocument! { didSet {
		self.setupCollectionView()
		self.collectionView?.reloadData()
	}}
	
	var collectionView: PDQNSCollectionView!
	var firstVisiblePanelIndex = 0
	let collectionViewLayout = NSCollectionViewFlowLayout()
	
	var numberOfPanels: Int {
		guard let doc = self.document else { return 0 }
		
		if self.style == .twoPagesHorizontally { return doc.twoPagePanelCount }

		return doc.pageCount
	}
	
	public convenience init(frame: CGRect, document: PDQDocument?) {
		self.init(frame: frame)
		self.document = document
		self.setupCollectionView()
	}
	
	open override var canBecomeKeyView: Bool { return true }
	open override var acceptsFirstResponder: Bool { return true }
	func setupCollectionView() {
		if self.collectionView != nil { return }
		
		self.collectionView = PDQNSCollectionView.setup(in: self)
		self.collectionViewLayout.itemSize = self.bounds.size
		self.collectionViewLayout.minimumInteritemSpacing = 0
		self.collectionViewLayout.minimumLineSpacing = 0
		self.collectionViewLayout.sectionInset = NSEdgeInsets()
		self.collectionViewLayout.scrollDirection = self.scrollAxis
		self.collectionView.collectionViewLayout = self.collectionViewLayout
		let nib = NSNib(nibNamed: "PDQViewPageCollectionItem", bundle: Bundle(for: type(of: self)))
		self.collectionView.register(nib, forItemWithIdentifier: PDQViewPageCollectionItem.identifier)
		self.collectionView.delegate = self
		self.collectionView.dataSource = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(didFinishLiveScroll), name: NSScrollView.didEndLiveScrollNotification, object: self.collectionView.scrollView)
		
		self.collectionView.reloadData()
	}
	
	open override func keyDown(with event: NSEvent) {
		let leftArrow = 123
		let rightArrow = 124
		let downArrow = 125
		let upArrow = 126

		switch Int(event.keyCode) {
		case leftArrow, upArrow:
			self.goToPreviousPage(nil)
		case rightArrow, downArrow:
			self.goToNextPage(nil)

		default: break
		}
	}
	
	open override func viewDidMoveToSuperview() {
		self.collectionView?.reloadData()
	}
	
	open override var frame: CGRect { didSet { self.updateItemSize() }}
	open override var bounds: CGRect { didSet { self.updateItemSize() }}
	
	func updateItemSize() {
		self.collectionViewLayout.itemSize = self.bounds.size;
		if self.scrollAxis == .horizontal {
			let newScroll = CGFloat(self.firstVisiblePanelIndex) * self.bounds.width
			self.collectionView.scrollView.contentView.setBoundsOrigin(CGPoint(x: newScroll, y: 0))
		} else {
			let newScroll = CGFloat(self.firstVisiblePanelIndex) * self.bounds.height
			self.collectionView.scrollView.contentView.setBoundsOrigin(CGPoint(x: 0, y: newScroll))
		}
		self.collectionView?.reloadData()
	}
	
	open override func viewWillStartLiveResize() {
		if self.scrollAxis == .horizontal {
			self.collectionView.scrollView?.horizontalScroller?.alphaValue = 0.0
		} else {
			self.collectionView.scrollView?.verticalScroller?.alphaValue = 0.0
		}
	}
	
	open override func viewDidEndLiveResize() {
		self.collectionView?.reloadData()
		if self.scrollAxis == .horizontal {
			self.collectionView.scrollView?.horizontalScroller?.alphaValue = 1.0
		} else {
			self.collectionView.scrollView?.verticalScroller?.alphaValue = 1.0
		}
	}
}

extension PDQViewCustom {
	@objc func didFinishLiveScroll(note: Notification) {
		guard let scrollView = note.object as? NSScrollView else { return }
		
		if self.scrollAxis == .horizontal {
			let offset = scrollView.contentView.bounds.origin.x
			let pageSize = self.bounds.width
			let panelNumber = round(offset / pageSize)
		
			self.firstVisiblePanelIndex = Int(panelNumber)
			let rounded = panelNumber * pageSize
			scrollView.contentView.animator().setBoundsOrigin(CGPoint(x: rounded, y: 0))
		} else {
			let offset = scrollView.contentView.bounds.origin.y
			let pageSize = self.bounds.height
			let panelNumber = round(offset / pageSize)
			
			self.firstVisiblePanelIndex = Int(panelNumber)
			let rounded = panelNumber * pageSize
			scrollView.contentView.animator().setBoundsOrigin(CGPoint(x: 0, y: rounded))
		}
	}
	
	@IBAction func goToPreviousPage(_ sender: Any?) {
		if !self.canScrollBack{ return }

		self.firstVisiblePanelIndex -= 1
		self.scrollToCurrentPage()
	}

	@IBAction func goToNextPage(_ sender: Any?) {
		if !self.canScrollForward{ return }

		self.firstVisiblePanelIndex += 1
		self.scrollToCurrentPage()
	}
	
	
	func scrollToCurrentPage() {
		if self.scrollAxis == .horizontal {
			self.collectionView.scrollView.contentView.animator().setBoundsOrigin(CGPoint(x: CGFloat(self.firstVisiblePanelIndex) * self.bounds.width, y: 0))
		} else {
			self.collectionView.scrollView.contentView.animator().setBoundsOrigin(CGPoint(x: 0, y: CGFloat(self.firstVisiblePanelIndex) * self.bounds.height))
		}
		self.collectionView.scrollView?.flashScrollers()
	}
}

extension PDQViewCustom: NSCollectionViewDelegate {
	
}

extension PDQViewCustom: NSCollectionViewDataSource {
	open func numberOfSections(in collectionView: NSCollectionView) -> Int { return 1 }
	open func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		var count = self.numberOfPanels
		
		if self.window?.inLiveResize == true { count += 100 }
		
		return count
	}
	
	open func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(withIdentifier: PDQViewPageCollectionItem.identifier, for: indexPath)
		
		if let cell = item as? PDQViewPageCollectionItem {
			cell.showTwoPages = self.style == .twoPagesHorizontally
			cell.pages = self.pages(at: indexPath)
		}
		return item
	}
}

extension PDQViewCustom {
	func pages(at path: IndexPath) -> [PDQPage] {
		var pages: [PDQPage] = []
		guard let doc = self.document else { return pages }
		if self.style == .twoPagesHorizontally {
			let pageNumber = doc.firstPageNumberFor(twoPanel: path.item)
			if let page = doc.page(at: pageNumber) {
				pages.append(page)
				if !page.isLeftPage { return pages }
			}
			if let page = doc.page(at: pageNumber + 1) { pages.append(page) }
			return pages
		}
		
		let pageNumber = path.item
		if let page = doc.page(at: pageNumber) { pages.append(page) }
		return pages
	}
}



#endif
