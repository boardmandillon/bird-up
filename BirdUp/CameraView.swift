//
//  CameraView.swift
//  BirdUp
//
//  Created by Dillon Boardman on 11/11/2023.
//

import SwiftUI

struct CameraView: View {
    var body: some View {
        ZStack {
            CameraViewControllerRepresentable().ignoresSafeArea()
            VStack {
                ZStack {
                    Text("boardmandillon")
                        .bold()
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .shadow(color: .black, radius: 1)
                }
                Spacer()
            }
        }.background(Color.black)
    }
}

#Preview {
    CameraView()
}
