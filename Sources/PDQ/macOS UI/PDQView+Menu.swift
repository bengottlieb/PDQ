//
//  PDQView+Menu.swift
//  PDQ_macOS
//
//  Created by Ben Gottlieb on 1/20/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Cocoa
import Quartz

extension PDQView {
	func buildContextualMenu(for page: PDQPage?, at point: CGPoint) -> NSMenu {
		let menu = NSMenu()
		
		guard let page = page else { return menu }
		self.pageForContextualMenu = page
		self.lastClickLocation = nil

		if #available(OSXApplicationExtension 10.13, *) {
			let current = page.highlights(at: point)
			if current.count > 0 {
				self.lastClickLocation = point
				menu.addItem(NSMenuItem(title: NSLocalizedString("Remove Highlight", comment: "remove PDF highlight"), action: #selector(removeCurrentHighlight), keyEquivalent: ""))
			} else if let selection = self.pdfView.currentSelection {
				if self.pdfView.annotationsIntersecting(selection).count > 0 {
					menu.addItem(NSMenuItem(title: NSLocalizedString("Remove Highlight", comment: "remove PDF highlight"), action: #selector(removeHighlightFromSelection), keyEquivalent: ""))
				} else {
					menu.addItem(NSMenuItem(title: NSLocalizedString("Highlight Selection", comment: "highlight PDF selection"), action: #selector(highlightSelection), keyEquivalent: ""))
				}
			}
		}
		
		if #available(OSXApplicationExtension 10.13, *), page.hasHighlights {
			menu.addItem(NSMenuItem(title: NSLocalizedString("Remove Page Highlights", comment: "remove PDF page highlights"), action: #selector(removePageHighlights), keyEquivalent: ""))
		}

		return menu
	}
	
	@available(OSXApplicationExtension 10.13, *)
	@objc func highlightSelection() {
		guard let selection = self.pdfView.currentSelection else { return }
		
		let color = NSColor.yellow
		let results = self.pdfView.addHighlights(from: selection, color: color)
		self.highlights.apply(deltas: results, in: self.document)
		NotificationCenter.default.post(name: Notifications.pdfDidChangeHighlights, object: self.document)
		self.delegate?.highlightsChanged(in: self)
	}

	@available(OSXApplicationExtension 10.13, *)
	@objc func removeHighlightFromSelection() {
		guard let selection = self.pdfView.currentSelection else { return }
		
		let results = self.pdfView.removeHighlights(for: selection)
		self.highlights.apply(deltas: results, in: self.document)
		NotificationCenter.default.post(name: Notifications.pdfDidChangeHighlights, object: self.document)
		self.delegate?.highlightsChanged(in: self)
	}
	
	@available(OSXApplicationExtension 10.13, *)
	@objc func removePageHighlights() {
		self.pdfView.removeHighlights(from: self.pageForContextualMenu)
		NotificationCenter.default.post(name: Notifications.pdfDidChangeHighlights, object: self.document)
		self.delegate?.highlightsChanged(in: self)
	}
	
	@available(OSXApplicationExtension 10.13, *)
	@objc func removeCurrentHighlight() {
		if let point = self.lastClickLocation, let page = self.pageForContextualMenu {
			let current = page.highlights(at: point)
			page.page.removeAnnotations(current)
			let deltas = PDFView.HighlightAnnotationDeltas(added: [], removed: current)
			self.highlights.apply(deltas: deltas, in: self.document)
			NotificationCenter.default.post(name: Notifications.pdfDidChangeHighlights, object: self.document)
			self.delegate?.highlightsChanged(in: self)
		}
	}
}
#endif
