//
//  PageCollectionItem.swift
//  PDQ_macOS
//
//  Created by Ben Gottlieb on 1/15/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import Cocoa

class PDQViewPageCollectionItem: NSCollectionViewItem {
	static let identifier = NSUserInterfaceItemIdentifier(rawValue: "PDQViewPageCollectionItem")
	
	var pageViews: [PDQPageNSView] = []
	var pages: [PDQPage] = [] { didSet { self.updateUI() }}
	var showTwoPages = false
	
	func updateUI() {
		while self.pageViews.count < self.pages.count {
			let pageView = PDQPageNSView(frame: self.view.bounds)
			self.view.addSubview(pageView)
			self.pageViews.append(pageView)
		}
		
		if self.pageViews.count == 0 { return }
		
		let size = self.view.bounds.size
		let pageWidth = size.width / (self.showTwoPages ? 2 : 1)
		
		for i in 0..<self.pageViews.count {
			let pageView = self.pageViews[i]
			if i >= self.pages.count {
				pageView.page = nil
				continue
			}
			
			pageView.page = self.pages[i]
			pageView.frame = CGRect(x: CGFloat(i) * pageWidth, y: 0, width: pageWidth, height: size.height)
			if self.pages.count == 1, !self.pages[i].isLeftPage, self.showTwoPages {
				pageView.frame = CGRect(x: CGFloat(i + 1) * pageWidth, y: 0, width: pageWidth, height: size.height)
			} else {
				pageView.frame = CGRect(x: CGFloat(i) * pageWidth, y: 0, width: pageWidth, height: size.height)
			}
		}
	}

}
#endif
