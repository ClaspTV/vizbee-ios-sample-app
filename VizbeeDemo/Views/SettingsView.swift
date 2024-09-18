//
//  SettingsView.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        List {
            Section(header: Text(Constants.Labels.conversionFlows).foregroundColor(.secondary)) {
                Button(action: { viewModel.triggerSmartHelp(for: .castIntroduction) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Constants.Labels.castIntroduction)
                            .font(.headline)
                        Text(Constants.Labels.castIntroductionDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
                
                Button(action: {
                    viewModel.triggerSmartHelp(for: .smartInstall)
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Constants.Labels.smartInstall)
                            .font(.headline)
                        Text(Constants.Labels.smartInstallDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(Constants.Labels.smartInstallNote)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .foregroundColor(.primary)
            }
            
            Section(header: Text(Constants.Labels.mobileToTVMessage).foregroundColor(.secondary)) {
                Button(action: viewModel.sendMessageToTV) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Constants.Labels.sendMessageToTV)
                            .font(.headline)
                        Text(Constants.Labels.sendMessageToTVDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("\(Constants.Labels.demoAppHelp)", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: Constants.Images.backButton)
                    Text(Constants.Labels.back)
                }
                .foregroundColor(.blue)
            },
            trailing: CastButton()
        )
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text(Constants.Labels.message), message: Text(viewModel.alertMessage), dismissButton: .default(Text(Constants.Labels.ok)))
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SettingsView()
            }
            .previewDisplayName(Constants.Preview_Title.lightMode)
            
            NavigationView {
                SettingsView()
            }
            .preferredColorScheme(.dark)
            .previewDisplayName(Constants.Preview_Title.darkMode)
        }
    }
}
