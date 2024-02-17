//
//  PDQThumbnailView.swift
//  PDQ_iOS
//
//  Created by Ben Gottlieb on 1/23/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(UIKit)

import UIKit
import PDFKit
import CrossPlatformKit

public class PDQThumbnailUIView: UIView {
	var collectionView: UICollectionView!
	var collectionViewLayout = UICollectionViewFlowLayout()
	@MainActor var document: PDQDocument? { didSet {
		self.updateUI()
		self.updateCurrentPageThumbnails()
	}}
	var thumbnailSize: CGSize = .zero
	var pagesToShow = 1
	var pagesPerImage = 1
	let margins = UIEdgeInsets(top: 6, left: 3, bottom: 6, right: 3)
	var imageHeight: CGFloat {
		if self.bounds.height == 0 { return 44 }
		return self.bounds.height - (self.margins.top + self.margins.bottom)
	}
	weak var pdqView: PDQUIView?
	var currentPageThumbnailViews: [ThumbnailPageView] = []

	public override func layoutSubviews() {
		super.layoutSubviews()
		
		if self.collectionView == nil {
			self.collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
			
			let verticalOffset: CGFloat = 5
			self.collectionView = UICollectionView(frame: CGRect(x: 0, y: verticalOffset, width: self.bounds.width, height: self.bounds.height - verticalOffset), collectionViewLayout: self.collectionViewLayout)
			self.collectionViewLayout.minimumLineSpacing = 0
			self.collectionViewLayout.minimumInteritemSpacing = 1
			let nib = UINib(nibName: "PDQThumbnailCollectionViewCell", bundle: Bundle(for: PDQThumbnailUICollectionViewCell.self))
			self.collectionView.register(nib, forCellWithReuseIdentifier: PDQThumbnailUICollectionViewCell.identifier)
			self.collectionView.delegate = self
			self.collectionView.dataSource = self
			self.addSubview(self.collectionView)
			self.collectionView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
			self.updateUI()
			self.collectionView.isUserInteractionEnabled = false
			self.isUserInteractionEnabled = true

			self.collectionView.backgroundColor = .clear
			self.backgroundColor = .clear
			NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentPageThumbnails), name: .PDFViewPageChanged, object: nil)
		}
	}
	
	public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touch = touches.first {
			self.handle(touch: touch, asFirst: true)
			self.pdqView?.startScrolling()
		}
	}
	public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touch = touches.first {
			self.handle(touch: touch)
			self.pdqView?.continueScrolling()
		}
	}
	
	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.pdqView?.endScrolling()
	}

	func handle(touch: UITouch, asFirst: Bool = false) {
		guard let doc = self.document else { return }
		let point = touch.location(in: self.collectionView)
		let thumbnailWidth = (self.collectionViewLayout.itemSize.width + self.collectionViewLayout.minimumInteritemSpacing)
		var index = (point.x - (self.collectionView.frame.minX + self.collectionViewLayout.sectionInset.left)) / thumbnailWidth
		
		if asFirst { index = floor(index) }
		var newPage = Int(index * CGFloat(self.pagesPerImage))
		
		if newPage < 0 { newPage = 0 }
		if newPage >= doc.pageCount { newPage = doc.pageCount - 1 }
		self.pdqView?.jump(to: newPage, animated: true)
		self.updateCurrentPageThumbnails()
	}
	
	func updateItemSize(from oldSize: CGSize) {
		if oldSize == self.bounds.size { return }
		guard let doc = self.document, doc.pageCount > 0 else { return }
		guard let first = doc.page(at: 0) else { return }
		let size = first.pageSize
		let scale = self.imageHeight / size.height
		self.thumbnailSize = CGSize(width: scale * size.width, height: self.imageHeight)
		
		let availableWidth = (self.bounds.width - (self.margins.left + self.margins.top)) - 20
		self.collectionViewLayout.itemSize = self.thumbnailSize
		self.pagesToShow = min(doc.pageCount, Int(availableWidth / self.thumbnailSize.width))
		self.pagesPerImage = (doc.pageCount / self.pagesToShow)

		let contentWidth = floor(CGFloat(self.pagesToShow) * (self.thumbnailSize.width + self.collectionViewLayout.minimumInteritemSpacing))
		let margins = self.bounds.width - contentWidth
		if self.pagesToShow >= doc.pageCount {
			self.collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: margins / 2, bottom: 0, right: margins / 2)
		} else {
			self.collectionViewLayout.sectionInset = .zero
		}

		DispatchQueue.main.async {
			self.collectionView?.reloadData()
		}
		self.updateCurrentPageThumbnails()
	}
	
	func updateUI() {
		self.updateItemSize(from: .zero)
	}
	
	func currentPageChanged() {
		self.updateCurrentPageThumbnails()
	}
	
	open override var frame: CGRect { didSet { self.updateItemSize(from: oldValue.size) }}
	open override var bounds: CGRect { didSet { self.updateItemSize(from: oldValue.size) }}

	var currentPageThumbnailSize: CGSize {
		let base = self.thumbnailSize
		let ratio = base.width / base.height
		let size = CGSize(width: self.bounds.height * ratio, height: self.bounds.height)
		return size
	}

	@objc func updateCurrentPageThumbnails() {
		if self.bounds.width <= 0 { return }
		self.currentPageThumbnailViews.forEach { $0.removeFromSuperview() }
		
		var newThumbnails: [ThumbnailPageView] = []
		for page in self.pdqView?.visiblePages ?? [] {
			let view = self.pageThumbnail(for: page.pageNumber)
			self.addSubview(view)
			newThumbnails.append(view)
		}
		
		let size = self.currentPageThumbnailSize
		let thumbnailsWidth = CGFloat(newThumbnails.count) * size.width
		let availableWidth = self.bounds.width - (self.margins.left + self.margins.right)

		self.currentPageThumbnailViews = newThumbnails
		if let first = newThumbnails.first, let doc = self.document {
			let centerX = self.collectionViewLayout.sectionInset.left + self.margins.left + (availableWidth * CGFloat(first.pageNumber)) / CGFloat(doc.pageCount)
			var left = centerX - thumbnailsWidth * 0.5
			for thumb in newThumbnails {
				thumb.frame = CGRect(x: left, y: (self.bounds.height - size.height) / 2, width: size.width, height: size.height)
				left += size.width
			}
		}
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
		
		thumb.contentMode = .scaleAspectFit
		thumb.layer.backgroundColor = UIColor.white.cgColor
		thumb.layer.borderColor = UIColor.black.cgColor
		thumb.layer.borderWidth = 0.5
		return thumb
	}
}

extension PDQThumbnailUIView: UICollectionViewDelegate {
	
}

extension PDQThumbnailUIView: UICollectionViewDataSource {
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.pagesToShow
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PDQThumbnailUICollectionViewCell.identifier, for: indexPath) as! PDQThumbnailUICollectionViewCell
		
		
		cell.page = self.document?.page(at: indexPath.item * self.pagesPerImage)
		return cell
	}
}

extension PDQThumbnailUIView {
	class ThumbnailPageView: UIImageView {
		var pageNumber: Int = 0
	}
}
#endif
