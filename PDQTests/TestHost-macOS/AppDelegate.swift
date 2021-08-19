//
//  AppDelegate.swift
//  TestHost-macOS
//
//  Created by Ben Gottlieb on 7/21/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

import Cocoa
import PDQ

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		if let url = UserDefaults.standard.url(forKey: "last-doc"), let doc = PDQDocument(url: url) {
			PDFWindowController.show(document: doc)
		
		} else if let url = Bundle.main.url(forResource: "PDF Spec", withExtension: "pdf"), let doc = PDQDocument(url: url) {
			PDFWindowController.show(document: doc)
		}
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func application(_ sender: NSApplication, openFiles filenames: [String]) {
		for path in filenames {
			let url = URL(fileURLWithPath: path)
			if let doc = PDQDocument(url: url) {
				UserDefaults.standard.set(url, forKey: "last-doc")
				PDFWindowController.show(document: doc)
			}
		}
	}

}

