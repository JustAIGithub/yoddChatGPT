/*
The MIT License (MIT)

 Copyright (c) 2023 Alessio Iodice

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


//
//  OpenAIViewModel.swift
//  YoddChatGpt
//
//  Created by Ale on 17/01/23.
//

import Foundation
import OpenAISwift //External framework
import ChatGPTSwift //External framework
import SwiftUI
/**
 This is the ViewModel that manages the OpenAISwift implementation.

 - Version: 0.3
 
 */
final class AIChatViewModel : ObservableObject {
    
    private var client : OpenAISwift?
    var openAiModelType : OpenAIModelType = .gpt3(.davinci)
    static var shared = AIChatViewModel()
    @AppStorage ("showModelType") var showModelType : Bool = false

    
    @Published var token : OpenAISwift? //this is for the OpenAISwift library, it is the default one because all the app initially was based just on this library
    @Published var chatGPTSwift : ChatGPTAPI?
    @Published var selectedAILibrary : AILibrary?
    ///This is the token that takes from the user defaults. If user defaults it's empty it just get an empty string
    @Published var tokenUserDefaults : String = UserDefaults.standard.string(forKey: "token") ?? ""

    func setup() {
        let AILibraryUserDefaults = UserDefaults.standard.string(forKey: "AILibrary")
        selectedAILibrary = getLibraryFromString(string: AILibraryUserDefaults ?? "")
        token = OpenAISwift(authToken: UserDefaults.standard.string(forKey: "token") ?? "")
        
        chatGPTSwift = ChatGPTAPI(apiKey: UserDefaults.standard.string(forKey: "token") ?? "")
        
        let openAIModelTypeString : String =  UserDefaults.standard.string(forKey: "openAiModelType") ?? ""
        if !openAIModelTypeString.isEmpty {
            self.openAiModelType = getOpenAIModelTypeFromString(openAIModelTypeString: openAIModelTypeString)
        } else {
            self.openAiModelType = .gpt3(.davinci)
        }
    }
    
    
    func sendChatGPTSwift(text: String, completion: @escaping((String, MessageType) -> Void)) {
        Task {
            do {
                let response = try await chatGPTSwift?.sendMessage(text: text)
                let messageType : MessageType = .text
                print("ChatGPT: \(String(describing: response))")
                completion(response ?? "", messageType)

            } catch {
                print(error.localizedDescription)
                let messageType : MessageType = .error
                let response = "API error, check your connection or change model type"
                completion(response, messageType)

            }
        }
    }

    func sendOpenAIViewModel(text: String, completion: @escaping((String, MessageType) -> Void)) {
        print(self.openAiModelType)
        token?.sendCompletion(with: text, model: self.openAiModelType, maxTokens: 500, completionHandler: { result in
            switch result {
            case .success(let model):
                let output = model.choices.first?.text ?? ""
                let messageType : MessageType = .text
                print("ChatGPT: \(output)")
                completion(output, messageType)
            case .failure(let error):
                let output = error.localizedDescription
                let messageType : MessageType = .error
                completion(output, messageType)
            }
        })
    }
    
    
    func setOpenAIViewModelType(openAIModelTypeString : String) {
        self.openAiModelType = getOpenAIModelTypeFromString(openAIModelTypeString: openAIModelTypeString)
        UserDefaults.standard.set(openAIModelTypeString, forKey: "openAiModelType")
    }
    
    ///Function to set a token
    func setToken(string: String) {
        self.token = OpenAISwift(authToken: string)
        UserDefaults.standard.set(string, forKey: "token")
        setup()
    }
 
    func getOpenAIModelTypeFromString (openAIModelTypeString : String) -> OpenAIModelType  {
        switch openAIModelTypeString {
        case "text-davinci-003":
            return .gpt3(.davinci)
        case "text-ada-001":
            return .gpt3(.ada)
        case "text-babbage-001":
            return .gpt3(.babbage)
        case "text-curie-001":
            return .gpt3(.curie)
        case "code-davinci-002":
            return .codex(.davinci)
        case "code-cushman-001":
            return .codex(.cushman)
        default:
            return .gpt3(.davinci)
        }
    }
    
    
    func getOpenAIModelNameFromString (openAIModelTypeString : String) -> String  {
        switch openAIModelTypeString {
        case "text-davinci-003":
            return "ChatGPT Davinci"
        case "text-ada-001":
            return "ChatGPT Ada"
        case "text-babbage-001":
            return "ChatGPT Babbage"
        case "text-curie-001":
            return "ChatGPT Curie"
        case "code-davinci-002":
            return "Codex Davinci"
        case "code-cushman-001":
            return "Codex Cushman"
        default:
            return "ChatGPT Davinci"
        }
        
    }

    func returnModelDescription (index : Int) -> String {
        return allOpenAISwiftModels[index].1
    }
    
    let allOpenAISwiftModels : [(OpenAIModelType, String)]  = [
        (.gpt3(.davinci), "Most capable GPT-3 model. Can do any task the other models can do, often with higher quality, longer output and better instruction-following. Also supports inserting completions within text."),
        (.gpt3(.ada), "Capable of very simple tasks, usually the fastest model in the GPT-3 series, and lowest cost."),
        (.gpt3(.babbage), "Capable of straightforward tasks, very fast, and lower cost."),
        (.gpt3(.curie), "Very capable, but faster and lower cost than GPT3 davinci"),
        (.codex(.davinci), "Most capable Codex model. Particularly good at translating natural language to code. In addition to completing code, also supports inserting completions within code."),
        (.codex(.cushman), "Almost as capable as davinci Codex, but slightly faster. This speed advantage may make it preferable for real-time applications.")
    ]
    
    func getLibraryFromString (string: String) -> AILibrary {
        switch string {
        case "OpenAISwift":
            return .OpenAISwift
        case "ChatGPT":
            return .ChatGPT
        default:
            return .OpenAISwift
        }
    }
    
    func changeLibrary (AILibrary : AILibrary) {
        self.selectedAILibrary = AILibrary
        UserDefaults.standard.set(AILibrary.rawValue, forKey: "AILibrary")
    }
    
    func getSelectedLibrary () -> AILibrary {
        return selectedAILibrary!
    }
        
}


enum AILibrary: String, CaseIterable, Identifiable {
    case OpenAISwift, ChatGPT
    var id: Self { self }
}


