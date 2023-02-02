/*
The MIT License (MIT)

 Copyright (c) 2023 Alessio Iodice

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

//
//  SettingsView.swift
//  YoddChatGpt
//
//  Created by Ale on 27/01/23.
//

import SwiftUI
import OpenAISwift

struct SettingsView: View {
    @Environment (\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var accentColor  = ThemeViewModel.shared
    @State var isPresentingConfirm = false
    @State var openAIViewModelToken = OpenAIViewModel.shared.tokenUserDefaults
    @State private var presentAlert = false
    
    var body: some View {
//        NavigationView {
            Form {
                Section("Theme", content: {
                    
                    
                    HStack {
                        ColorPicker("Change accent color", selection: $accentColor.accentColor)
                    }
                    .onChange(of: accentColor.accentColor) { _ in
                        UserDefaults.standard.set(accentColor.accentColor.toHex(), forKey: "AccentColor")
                    }
                    
                    ThemePickerView()
                    
                })
                
                Section("Chat", content: {
                    
                    NavigationLink(destination: {
                        SavedMessagesView()
                    }, label: {
                        HStack {
                            Text("Saved messages")
                            Spacer()
                            Image(systemName: "bookmark.fill")
                        }
                    })
                    
                        
                    Toggle(isOn: OpenAIViewModel.shared.$showModelType) {
                        Text("Show model type stamp")
                    }
                    
                    Button(action: {
                        isPresentingConfirm = true
                    }, label: {
                        HStack {
                            Text("Delete all messages")
                            Spacer()
                            Image(systemName: "trash")
                        }.foregroundColor(.red)
                    })
                    .confirmationDialog("Are you sure?",
                                        isPresented: $isPresentingConfirm) {
                        Button("Delete all messages?", role: .destructive) {
                            DataController.shared.deleteAllData(context: managedObjectContext)
                        }
                        Button("Delete all unsaved messages?", role: .destructive) {
                            DataController.shared.deleteAllUnsavedData(context: managedObjectContext)
                        }

                    } message: {
                        Text("You cannot undo this action")
                    }
                })
                Section("API", content: {
                    
                    NavigationLink(destination: {
                        ChatGPTModelTypesList()
                    }, label: {
                        HStack {
                            Text("Change model type")
                            Spacer()
                            Image(systemName: "list.bullet")
                        }
                    })

                    Button(action: {
                        presentAlert = true
                    }, label: {
                        HStack {
                            Text("Change API token")
                            Spacer()
                            Image(systemName: "key")
                        }
                    })
                    .alert("API Token", isPresented: $presentAlert, actions: {
                        TextField("Token", text: $openAIViewModelToken)
                    }, message: {
                        HStack {
                            Text("Paste your token here")
                        }
                    })
                    .onDisappear{
                        presentAlert = false
                    }
                    .onChange(of: openAIViewModelToken) { token in
                        OpenAIViewModel.shared.setToken(string: token)
                    }
                    
                    
                    Link(destination: URL(string: "https://beta.openai.com/account/api-keys")!) {
                        HStack {
                            Text("Get token API")
                            Spacer()
                            Image(systemName: "link")
                        }
                    }
                
                })
                
//                Section("Multipeer", content: {
//
//                    HStack {
//                        Text("Change multipeer name")
//                        Spacer()
//                        Image(systemName: "person")
//                    }
//                })
            }
            .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}


//
//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
