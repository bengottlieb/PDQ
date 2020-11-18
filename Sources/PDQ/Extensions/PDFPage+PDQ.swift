//
//  PDFPage+PDQ.swift
//  PDQ
//
//  Created by Ben Gottlieb on 1/15/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if os(iOS)
	import PDFKit
#else
	import Quartz
#endif

extension PDFPage {
	func transformFor(size: CGSize, box: PDFDisplayBox = .mediaBox) -> CGAffineTransform {
		let rect = self.bounds(for: box)
		
		let scale = min(size.height / rect.height, size.width / rect.width)
		let width = rect.width * scale
		let height = rect.height * scale
		
		var transform = CGAffineTransform(scaleX: scale, y: scale)
		
		transform.tx = (size.width - width) / 2
		transform.ty = (size.height - height) / 2
		
		return transform
	}
	
	func contentFrame(within limit: CGSize) -> CGRect {
		let mediaBox = self.bounds(for: .mediaBox)
		
		if mediaBox.width < limit.width, mediaBox.height < limit.height {
			return CGRect(x: (limit.width - mediaBox.width) / 2, y: (limit.height - mediaBox.height) / 2, width: mediaBox.width, height: mediaBox.height)
		}
		
		let scale = min(limit.width / mediaBox.width, limit.height / mediaBox.height)
		let newWidth = mediaBox.width * scale
		let newHeight = mediaBox.height * scale
		
		return CGRect(x: (limit.width - newWidth) / 2, y: (limit.height - newHeight) / 2, width: newWidth, height: newHeight)
	}
	
	func getScale(within limit: CGSize) -> CGFloat {
		let mediaBox = self.bounds(for: .mediaBox)
		return min(limit.width / mediaBox.width, limit.height / mediaBox.height)
	}
	
	func addAnnotations(_ annotations: [PDFAnnotation]) {
		annotations.forEach { self.addAnnotation($0) }
	}
	
	func removeAnnotations(_ annotations: [PDFAnnotation]) {
		annotations.forEach { self.removeAnnotation($0) }
	}
	
}
