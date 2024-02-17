//
//  Protocols.swift
//  PDQ
//
//  Created by Ben Gottlieb on 2/5/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation

public protocol PDQViewDelegate: AnyObject {
	func highlightsChanged(in: PDQUXView)
	func visiblePageChanged(in: PDQUXView)
	func setControls(visible: Bool, in: PDQUXView, with duration: TimeInterval)
	func didClick(on url: URL)
}
