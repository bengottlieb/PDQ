//
//  PDQThumbnailCollectionItem.swift
//  PDQ_macOS
//
//  Created by Ben Gottlieb on 1/17/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)


import Cocoa

class PDQThumbnailCollectionItem: NSCollectionViewItem {
	static let identifier = NSUserInterfaceItemIdentifier(rawValue: "PDQThumbnailCollectionItem")
	
	var page: PDQPage? { didSet { self.updateUI() }}
	var showPageNumbers = false
	var pageNumberLabel: NSTextField?
	
	let content = NSImageView()
	
	override func loadView() {
		imageView = content
		self.view = content
		self.view.wantsLayer = true
		
	}
	
	func updateUI() {
		guard let page = self.page else { return }
		
		self.imageView?.tag = page.pageNumber
		self.imageView?.image = page.thumbnail(size: self.view.bounds.size)
		if self.showPageNumbers {
			if self.pageNumberLabel == nil {
				self.pageNumberLabel = NSTextField(frame: self.view.bounds)
				self.view.addSubview(self.pageNumberLabel!)
				self.pageNumberLabel?.alignment = .center
				self.pageNumberLabel?.textColor = .red
				self.pageNumberLabel?.font = NSFont.boldSystemFont(ofSize: 20)
				self.pageNumberLabel?.drawsBackground = false
				self.pageNumberLabel?.autoresizingMask = [.height, .width]
			}
			self.pageNumberLabel?.stringValue = "\(page.pageNumber)"
		} else {
			self.pageNumberLabel?.removeFromSuperview()
			self.pageNumberLabel = nil
		}
	}
	
}
#endif
