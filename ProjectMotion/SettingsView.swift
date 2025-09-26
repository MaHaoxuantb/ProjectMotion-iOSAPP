//
//  SettingsView.swift
//  ProjectMotion
//
//  Created by Thomas B on 9/26/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("needRippleEffect") var needRippleEffect = true
    @AppStorage("needDetailsOnContentView") var needDetailsOnContentView = true
    @AppStorage("RTDataServerURL") var RTDataServerURL = "http://192.168.0.102:8000/api"
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Experience")) {
                    Toggle(isOn: $needRippleEffect) {
                        Text("Ripple Effect")
                    }
                    Toggle(isOn: $needDetailsOnContentView) {
                        Text("Debug Details")
                    }
                }
                Section(header: Text("Dev Settings")) {
                    TextField("Your server URL", text: $RTDataServerURL)
                }
                Section(header: Text("APP")) {
                    NavigationLink(destination: AboutView()) {
                        Text("About")
                    }
                }
            }
        }
    }
}

//about this app VIEW
struct AboutView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 68)
                        .blur(radius: 80)
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer().frame(height: 190)
                    HStack {
                        VStack {
                            Spacer()
                                .frame(height: 4)
                            Text("LinecoFlow")
                                .font(.title3)
                                .bold()
                                .background(
                                    Color.gray.opacity(0.8)
                                        .blur(radius: 32)
                                )
                                .padding([.top, .leading, .bottom], 5)
                        }
                        Text("Project Motion")
                            .font(.title)
                            .bold()
                            .background(
                                Color.gray.opacity(0.8)
                                    .blur(radius: 32)
                            )
                            .padding([.top, .bottom, .trailing], 5)
                    }
                    Text("An APP for Experiments")
                        .font(.subheadline)
                        .padding()
                    Spacer().frame(height: 60)
                    Text("App Builder:")
                        .padding(2)
                    Text("ThomasB @ LinecoFlow Lab")
                        .bold()
                        .padding(2)
                    Spacer()
                    Text("©2025 LinecoFlow Tech Co.,")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(0.3)
                    Text("All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(0.3)
                    Text("A ThomasB Internet Services Company")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(0.3)
                    Spacer().frame(height: 8)
                }
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    SettingsView()
}
