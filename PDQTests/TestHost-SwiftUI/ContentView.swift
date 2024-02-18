//
//  ContentView.swift
//  TestHost-SwiftUI
//
//  Created by Ben Gottlieb on 2/17/24.
//  Copyright © 2024 Stand Alone, Inc. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
			  Color.blue
				  .frame(maxWidth: .infinity, maxHeight: .infinity)
				  .layoutPriority(10)
				  .ignoresSafeArea()

			  PDQView(pdf: .testDocument)
        }
        .padding()
		  .background(.red)
    }
}

#Preview {
    ContentView()
}

extension PDQDocument {
	static var testDocument: PDQDocument {
		let url = Bundle.main.url(forResource: "CoreData", withExtension: "pdf")!
		let doc = PDQDocument(url: url)
		
		return doc!
	}
}
