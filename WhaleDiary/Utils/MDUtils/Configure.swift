//
//  Configure.swift
//  Markdown
//
//  Created by zhubch on 2017/7/1.
//  Copyright © 2017年 zhubch. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Zip

enum SortOption: String {
    case modifyDate
    case name
    case type

    var displayName: String {
        switch self {
        case .type:
            return "SortByType"
        case .name:
            return "SortByName"
        case .modifyDate:
            return "SortByModifyDate"
        }
    }
    
    var next: SortOption {
        switch self {
        case .type:
            return .modifyDate
        case .name:
            return .type
        case .modifyDate:
            return .name
        }
    }
}

enum DarkModeOption: String {
    case dark
    case light
    case system

    var displayName: String {
        switch self {
        case .dark:
            return "KeepDarkMode"
        case .light:
            return "DisableDarkMode"
        case .system:
            return "FollowSystem"
        }
    }
    
    static var defaultDarkOption: DarkModeOption = {
        if #available(iOS 13.0, *) {
            return .system
        }
        return .light
    }()
}

enum ImageStorageOption: String {
    case local
    case remote
    case ask

    var displayName: String {
        switch self {
        case .local:
            return "ImageStorageLocal"
        case .remote:
            return "ImageStorageRemote"
        case .ask:
            return "ImageStorageAsk"
        }
    }
}

enum FileOpenOption: String {
    case edit
    case preview

    var displayName: String {
        switch self {
        case .edit:
            return "FileOpenOptionEdit"
        case .preview:
            return "FileOpenOptionPreview"
        }
    }
}

class Configure: NSObject, NSCoding {
    
    static let configureFile = configPath + "/Configure.plist"
            
    var currentVerion: String?
    var rateAlertDate = Date().daysAgo(19)
    var expireDate = Date.longlongAgo()
    var showExtensionName = false
    var impactFeedback = true
    var darkAppIcon = false
    let fontSize = BehaviorRelay(value:17)
    let isAssistBarEnabled = BehaviorRelay(value: true)
    let markdownStyle = BehaviorRelay(value: "GitHub")
    let highlightStyle = BehaviorRelay(value:"tomorrow")
    let theme = BehaviorRelay(value:Theme.pink)
    var sortOption = SortOption.modifyDate
    var imageStorage = ImageStorageOption.ask
    var openOption = FileOpenOption.edit
    let darkOption = BehaviorRelay(value:DarkModeOption.defaultDarkOption)
    var keyboardBarItems = ["-","`","$","/","\"","?","@","(",")","[","]","|","#","*","=","+","<",">"]
    var imageCaches = [String:String]()
    var showedTips = [String]()
    let automaticSplit = BehaviorRelay(value:false)
    let autoHideNavigationBar = BehaviorRelay(value:true)
    
    var isPro: Bool {
        return true
        //return expireDate.isFuture
    }
    
    override init() {
        super.init()
    }
    
    static let shared: Configure = {

        if let old = NSKeyedUnarchiver.unarchiveObject(withFile: configureFile) as? Configure {
            old.setup()
            return old
        }
        
        let configure = Configure()
        configure.reset()
        return configure
    }()
    
    func setup() {
        checkProAvailable()
        if appVersion != currentVerion {
            upgrade()
        }
        currentVerion = appVersion
    }
    
    func reset() {
        currentVerion = appVersion
        markdownStyle.accept("GitHub")
        highlightStyle.accept("tomorrow")
        theme.accept(.pink)
        sortOption = .modifyDate
        darkOption.accept(DarkModeOption.defaultDarkOption)
        imageStorage = .ask
        openOption = .edit
        showExtensionName = false
        impactFeedback = true
        isAssistBarEnabled.accept(true)
        automaticSplit.accept(false)
        autoHideNavigationBar.accept(true)
        fontSize.accept(17)
        showedTips = []
        
        let destStylePath = URL(fileURLWithPath: supportPath)
        try! Zip.unzipFile(Bundle.main.url(forResource: "Resources", withExtension: "zip")!, destination: destStylePath, overwrite: true, password: nil, progress: nil)
        
        if let path = Bundle.main.path(forResource: /"Instructions", ofType: "md") {
            let newPath = documentPath + "/" + "Instructions" + ".md"
            try? FileManager.default.copyItem(atPath: path, toPath: newPath)
        }
        if let path = Bundle.main.path(forResource: /"Syntax", ofType: "md") {
            let newPath = documentPath + "/" + "Syntax" + ".md"
            try? FileManager.default.copyItem(atPath: path, toPath: newPath)
        }
        
        setup()
    }

    func upgrade() {

        let tempPathURL = URL(fileURLWithPath: tempPath)
        try! Zip.unzipFile(Bundle.main.url(forResource: "Resources", withExtension: "zip")!, destination: tempPathURL, overwrite: true, password: nil, progress: nil)
        let tempStylePath = tempPath + "/Resources/Styles"
        let destStylePath = supportPath + "/Resources/Styles"
        
        FileManager.default.subpaths(atPath: tempStylePath)?.filter{ $0.hasSuffix(".css") }.forEach{ subpath in
            let fullPath = tempStylePath + "/" + subpath
            let newPath = destStylePath + "/" + subpath
            try? FileManager.default.removeItem(atPath: newPath)
            try? FileManager.default.moveItem(atPath: fullPath, toPath: newPath)
        }
        
        if let path = Bundle.main.path(forResource: "Instructions", ofType: "md") {
            let newPath = documentPath + "/" + "Instructions" + ".md"
            if FileManager.default.fileExists(atPath: newPath) {
                try? FileManager.default.removeItem(atPath: newPath)
                try? FileManager.default.copyItem(atPath: path, toPath: newPath)
            }
        }
        if let path = Bundle.main.path(forResource: "Syntax", ofType: "md") {
            let newPath = documentPath + "/" + "Syntax" + ".md"
            if FileManager.default.fileExists(atPath: newPath) {
                try? FileManager.default.removeItem(atPath: newPath)
                try? FileManager.default.copyItem(atPath: path, toPath: newPath)
            }
        }        
    }
    
    func save() {
        NSKeyedArchiver.archiveRootObject(self, toFile: Configure.configureFile)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(currentVerion, forKey: "currentVersion")
        aCoder.encode(automaticSplit.value, forKey: "automaticSplit")
        aCoder.encode(autoHideNavigationBar.value, forKey: "autoHideNavigationBar")
        aCoder.encode(impactFeedback, forKey: "impactFeedback")
        aCoder.encode(darkAppIcon, forKey: "darkAppIcon")
        aCoder.encode(showExtensionName, forKey: "showExtensionName")
        aCoder.encode(isAssistBarEnabled.value, forKey: "isAssistBarEnabled")
        aCoder.encode(markdownStyle.value, forKey: "markdownStyle")
        aCoder.encode(highlightStyle.value, forKey: "highlightStyle")
        aCoder.encode(theme.value.rawValue, forKey: "theme")
        aCoder.encode(fontSize.value, forKey: "fontSize")
        aCoder.encode(darkOption.value.rawValue, forKey: "darkOption")
        aCoder.encode(sortOption.rawValue, forKey: "sortOption")
        aCoder.encode(imageStorage.rawValue, forKey: "imageStorage")
        aCoder.encode(openOption.rawValue, forKey: "openOption")
        aCoder.encode(rateAlertDate, forKey: "rateAlertDate")
        aCoder.encode(expireDate, forKey: "expireDate")
        aCoder.encode(imageCaches, forKey: "imageCaches")
        aCoder.encode(showedTips, forKey: "showedTips")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        currentVerion = aDecoder.decodeObject(forKey: "currentVersion") as? String
        rateAlertDate = aDecoder.decodeObject(forKey: "rateAlertDate") as? Date ?? Date().daysAgo(19)
        expireDate = aDecoder.decodeObject(forKey: "expireDate") as? Date ?? Date.longlongAgo()
        imageCaches = aDecoder.decodeObject(forKey: "imageCaches") as? [String:String] ?? [:]
        showedTips = aDecoder.decodeObject(forKey: "showedTips") as? [String] ?? []
        impactFeedback = aDecoder.decodeBool(forKey: "impactFeedback")
        darkAppIcon = aDecoder.decodeBool(forKey: "darkAppIcon")
        showExtensionName = aDecoder.decodeBool(forKey: "showExtensionName")
        isAssistBarEnabled.accept(aDecoder.decodeBool(forKey: "isAssistBarEnabled"))
        autoHideNavigationBar.accept(aDecoder.decodeBool(forKey: "autoHideNavigationBar"))
        automaticSplit.accept(aDecoder.decodeBool(forKey: "automaticSplit"))
        markdownStyle.accept(aDecoder.decodeObject(forKey: "markdownStyle") as? String ?? "GitHub")
        highlightStyle.accept(aDecoder.decodeObject(forKey: "highlightStyle") as? String ?? "tomorrow")
        theme.accept(Theme(rawValue:aDecoder.decodeObject(forKey: "theme") as? String ?? "") ?? .white)
        let size = aDecoder.decodeInteger(forKey: "fontSize")
        fontSize.accept(size == 0 ? 17 : size)
        darkOption.accept(DarkModeOption(rawValue: aDecoder.decodeObject(forKey: "darkOption") as? String ?? "") ?? DarkModeOption.defaultDarkOption) 
        sortOption = SortOption(rawValue: aDecoder.decodeObject(forKey: "sortOption") as? String ?? "") ?? .modifyDate
        imageStorage = ImageStorageOption(rawValue: aDecoder.decodeObject(forKey: "imageStorage") as? String ?? "") ?? .ask
        openOption = FileOpenOption(rawValue: aDecoder.decodeObject(forKey: "openOption") as? String ?? "") ?? .edit
    }
    
    func checkProAvailable(_ completion:((Bool)->Void)? = nil){
//        #if DEBUG
//            self.expireDate = Date.distantFuture
//            completion?(self.isPro)
//            return
//        #endif

//        IAP.validateReceipt(itunesSecret) { (statusCode, products, json) in
//            defer {
//                DispatchQueue.main.async {
//                    print("会员到期\(self.expireDate.readableDate())")
//                    print("会员状态\(self.isPro)")
//                    completion?(self.isPro)
//                }
//            }
//            if let code = statusCode {
//                if code == ReceiptStatus.noRecipt.rawValue {
//                    self.expireDate = Date.longlongAgo()
//                    return
//                }
//            }
//            guard let products = products else {
//                return
//            }
//            print("products: \(products)")
//            let proIdentifier = [premiumForeverProductID,premiumYearlyProductID,premiumMonthlyProductID]
//            self.expireDate = proIdentifier.map{ products[$0] ?? Date(timeIntervalSince1970: 0) }.max() ?? Date(timeIntervalSince1970: 0)
//        }
    }
}
