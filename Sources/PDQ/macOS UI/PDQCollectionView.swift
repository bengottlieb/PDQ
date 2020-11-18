//
//  PDQCollectionView.swift
//  PDQ_macOS
//
//  Created by Ben Gottlieb on 1/17/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Cocoa

class PDQCollectionView: NSCollectionView {
	var scrollView: NSScrollView!
	var userInteractionEnabled = true
	
	override func mouseDown(with event: NSEvent) {
		if !self.userInteractionEnabled { return }
		
		super.mouseDown(with: event)
	}
	
	override func keyDown(with event: NSEvent) {
		if !self.userInteractionEnabled { return }
		
		super.keyDown(with: event)
	}
	
	override func scrollWheel(with event: NSEvent) {
		if !self.userInteractionEnabled { return }
		
		super.scrollWheel(with: event)
	}
	
	class func setup(in parent: NSView, frame: CGRect? = nil) -> PDQCollectionView {
		let view = self.init()
		view.autoresizingMask = [.height, .width]
		
		view.scrollView = NSScrollView(frame: frame ?? parent.bounds)
		view.scrollView.documentView = view
		view.scrollView.autoresizingMask = [.width, .height]
		
		parent.addSubview(view.scrollView)
		
		return view
	}
}
#endif
