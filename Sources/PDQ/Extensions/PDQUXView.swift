//
//  PDQUXView.swift
//  PDQ
//
//  Created by Ben Gottlieb on 2/17/24.
//  Copyright © 2024 Stand Alone, Inc. All rights reserved.
//

import Foundation

#if os(iOS)
	import PDFKit
	public typealias PDQUXView = PDQUIView
#else
	import Quartz
	public typealias PDQUXView = PDQNSView
#endif
