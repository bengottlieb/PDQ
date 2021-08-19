//
//  Protocols.swift
//  PDQ
//
//  Created by Ben Gottlieb on 2/5/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation

public protocol PDQViewDelegate: AnyObject {
	func highlightsChanged(in: PDQView)
	func visiblePageChanged(in: PDQView)
	func setControls(visible: Bool, in: PDQView, with duration: TimeInterval)
	func didClick(on url: URL)
}
