//
//  PDQThumbnailCollectionItemCollectionViewCell.swift
//  PDQ_iOS
//
//  Created by Ben Gottlieb on 1/23/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

#if canImport(UIKit)

import UIKit

class PDQThumbnailUICollectionViewCell: UICollectionViewCell {
	@IBOutlet var imageView: UIImageView!
	
	static let identifier = "PDQThumbnailCollectionItem"
	
	var page: PDQPage? { didSet { self.updateUI() }}
	
	
	func updateUI() {
		guard let page = self.page else { return }
		
		self.imageView?.image = page.thumbnail(size: self.bounds.size)
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
#endif
