//
//  PDQView.swift
//  PDQ
//
//  Created by Ben Gottlieb on 2/17/24.
//  Copyright © 2024 Stand Alone, Inc. All rights reserved.
//

import SwiftUI
import CrossPlatformKit

public struct PDQView: UXViewRepresentable {
	let pdf: PDQDocument
	public typealias UXViewType = UXView

	
	public init(pdf: PDQDocument) {
		self.pdf = pdf
	}
	
	public func makeUXView(context: Context) -> UXViewType {
		context.coordinator.view
	}
	
	public func updateUXView(_ uiView: UXViewType, context: Context) {
		
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator(pdf: pdf)
	}
		
	public class Coordinator {
		var view: PDQUXView
		var pdf: PDQDocument
		
		init(pdf: PDQDocument) {
			self.pdf = pdf
			self.view = PDQUXView(frame: CGRect(x: 0, y: 0, width: 300, height: 300), document: pdf)
			self.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		}
	}
	
}

