//
//  main.swift
//  appstore-update-appinfo
//
//  Created by Daniel Bedrich on 08.02.26.
//

import Foundation
import ArgumentParser
@preconcurrency import AppStoreConnect_Swift_SDK

let provider = APIProvider(configuration: APPSTORE_CONFIGURATION)

@main
struct UpdateAppInfo: AsyncParsableCommand {
    @Argument(help: "The path to the folder where the '.json' files are.")
    var localizationsPath: String
    
    @Option(name: .long, help: "The bundle id of the app to update the metadata for.")
    var bundleId: String

    mutating func run() async throws {
        await updateMetadata(forBundleId: bundleId)
    }
    
    func updateMetadata(forBundleId bundleId: String) async {
        let app = await requestApp(bundleId: bundleId)
        let appInfoLocalizations = await requestAppInfoLocalization(app)
        
        for localization in appInfoLocalizations {
            let appStoreLocale = localization.attributes!.locale!
            let fileManage = FileManager.default
            let doesAppStoreLocaleFileExist = fileManage.fileExists(atPath: "\(localizationsPath)/\(appStoreLocale).json")
            
            let backupLocale = getBackupLocale(appStoreLocale)
            let doesBackupLocaleFileExist = fileManage.fileExists(atPath: "\(localizationsPath)/\(backupLocale).json")

            var locale: String? {
                if doesAppStoreLocaleFileExist { return appStoreLocale }
                if doesBackupLocaleFileExist { return backupLocale }
                return nil
            }
            
            guard let locale else {
                print("No localization file found for '\(appStoreLocale).json' or '\(backupLocale).json'. Continuing")
                
                continue
            }
            
            print("🌐 Updating \(appStoreLocale)")
            
            let url = URL(string: "file://\(localizationsPath)/\(locale).json")
            guard let url else { UpdateAppInfo.exit() }
            
            let jsonData = try! Data(contentsOf: url)
            let attributes = try! JSONDecoder().decode(
                AppInfoLocalizationUpdateRequest.Data.Attributes.self,
                from: jsonData
            )
            
            let isNameValid = validateAttribute(attributes.name, maxCount: 30)
            let isSubtitleValid = validateAttribute(attributes.subtitle, maxCount: 30)
            let isPrivacyChoicesURLValid = validateAttribute(attributes.privacyChoicesURL, maxCount: 255)
            let isPrivacyPolicyURLValid = validateAttribute(attributes.privacyPolicyURL, maxCount: 255)
            let isPrivacyPolicyTextValid = validateAttribute(attributes.privacyPolicyText, maxCount: 4000)
            
            if !isNameValid { print("The attribute 'name' is longer than 30 characters.") }
            if !isSubtitleValid { print("The attribute 'subtitle' is longer than 30 characters.") }
            if !isPrivacyChoicesURLValid { print("The attribute 'privacyChoicesURL' is longer than 255 characters.") }
            if !isPrivacyPolicyURLValid { print("The attribute 'privacyPolicyURL' is longer than 255 characters.") }
            if !isPrivacyPolicyTextValid { print("The attribute 'privacyPolicyText' is longer than 4000 characters.") }
            
            if
                !isNameValid ||
                !isSubtitleValid ||
                !isPrivacyPolicyTextValid ||
                !isPrivacyPolicyURLValid ||
                !isPrivacyPolicyTextValid
            {
                print("Some attributes are invalid. Continuing...")
                
                continue
            }

            let _ = await requestUpdateAppInfoLocalization(localization.id, attributes: attributes)
        }
        
    }
    
    func getBackupLocale(_ locale: String) -> String {
        if locale == "no" { return "nb" }
        
        return String(locale.split(separator: "-").first ?? "")
    }
    
    func validateAttribute(_ attribute: String?, maxCount: Int) -> Bool {
        attribute?.count ?? 0 < maxCount
    }

    func requestApp(bundleId: String) async -> App {
        let appRequest = APIEndpoint.v1
            .apps
            .get(parameters: .init(filterBundleID: [bundleId], include: [.appInfos, .appStoreVersions]))
        let app: App = try! await provider.request(appRequest).data.first!
        
        return app
    }
    
    func requestAppInfoLocalization(_ app: App) async -> [AppInfoLocalization] {
        let versionId = app.relationships!.appInfos!.data!.first!.id
        let versionRequest = APIEndpoint.v1
            .appInfos
            .id(versionId)
            .appInfoLocalizations
            .get()
        let appInfoLocalization: [AppInfoLocalization] = try! await provider.request(versionRequest).data
        
        return appInfoLocalization
    }
    
    func requestUpdateAppInfoLocalization(_ id: String, attributes: AppInfoLocalizationUpdateRequest.Data.Attributes) async -> AppInfoLocalization {
        let updateLocalizationRequest = APIEndpoint.v1
            .appInfoLocalizations
            .id(id)
            .patch(.init(data: .init(type: .appInfoLocalizations, id: id, attributes: attributes)))
        let localization: AppInfoLocalization = try! await provider.request(
            updateLocalizationRequest
        ).data
        
        return localization
    }
}
