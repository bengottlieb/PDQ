//
//  PDQView.EditView.swift
//  PDQ_iOS
//
//  Created by Ben Gottlieb on 4/19/19.
//  Copyright © 2019 Stand Alone, Inc. All rights reserved.
//

#if canImport(UIKit)

import UIKit

extension PDQView {
	public enum EditMode { case layoutFrame(CGPoint?, CGSize?) }

	public func beginEditing(mode: EditMode = .layoutFrame(nil, nil)) {
		if self.editView == nil {
			self.editView = EditView(frame: self.bounds)
			self.editView.backgroundColor = UIColor(white: 0.3, alpha: 0.1)
			self.addSubview(editView)
		}
		self.editView.editMode = mode
	}

	class EditView: UIView {
		var editMode: EditMode? { didSet { self.setNeedsDisplay() }}
		var panRecog: UIPanGestureRecognizer!

		public override func draw(_ rect: CGRect) {
			guard let mode = self.editMode else { return }

			switch mode {
			case .layoutFrame(let origin, let size):
				guard let origin = origin, let size = size else { return }
				let bezier = UIBezierPath(rect: CGRect(origin: origin, size: size))
				bezier.stroke()
			}
		}

		override func didMoveToSuperview() {
			super.didMoveToSuperview()

			if self.panRecog == nil {
				self.panRecog = UIPanGestureRecognizer(target: self, action: #selector(panned))
				self.addGestureRecognizer(self.panRecog)

				self.isUserInteractionEnabled = true
			}

		}

		func commitEditing(_ mode: EditMode) {
			print(mode)
		}

		@objc func panned(recog: UIPanGestureRecognizer) {
			guard let editMode = self.editMode else { return }

			let location = recog.location(in: self)

			switch editMode {
			case .layoutFrame(let origin, let size):
				switch recog.state {
				case .began, .changed:
						if let initial = origin {
							let rect = CGRect(origin: initial, size: size ?? .zero)
							let newOrigin = CGPoint(x: min(location.x, rect.minX), y: min(location.y, rect.minY))
							let endPoint = CGPoint(x: max(location.x, rect.maxX), y: max(location.y, rect.maxY))
							self.editMode = .layoutFrame(origin, CGSize(width: endPoint.x - newOrigin.x, height: endPoint.y - newOrigin.y))
						} else {
							self.editMode = .layoutFrame(location, nil)
						}

				case .ended:
					self.commitEditing(editMode)

				default: break
				}

			}
		}

	}
}
#endif
