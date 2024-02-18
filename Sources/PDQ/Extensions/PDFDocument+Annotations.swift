//
//  PDFDocument+Annotations.swift
//  PDQ
//
//  Created by Ben Gottlieb on 1/21/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if os(iOS) || os(visionOS)
	import PDFKit
#else
	import Quartz
#endif

extension PDFDocument {
	public func addAnnotations(_ annotations: [PDFAnnotation]) {
		annotations.forEach { annotation in
			annotation.page?.addAnnotation(annotation)
		}
	}
	
}
