//
//  AppDelegate.swift
//  WhaleDairy
//
//  Created by 刘思源 on 2023/8/28.
//

import UIKit
import IQKeyboardManagerSwift
import CYLTabBarController

@main

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        _ = DiaryTool.shared
        setup()
        MDURLProtocol.startRegister()
        
        
        
//        IQKeyboardManager.shared.enable = true
//        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        if window == nil{
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        window?.rootViewController = TabbarVC()
        window?.makeKeyAndVisible()
        
        
        return true
    }

    
    func setup() {
        let navigationBar = UINavigationBar.appearance()
        navigationBar.isTranslucent = false
        //navigationBar.setTintColor(.navTint)
        
        
        Configure.shared.setup()
        Configure.shared.imageStorage = .local
        
        _ = Configure.shared.theme.asObservable().subscribe(onNext: { (theme) in
            ColorCenter.shared.theme = theme
            self.window?.tintColor = ColorCenter.shared.tint.value
            if theme == .black {
                if Configure.shared.markdownStyle.value == "GitHub" {
                    Configure.shared.markdownStyle.accept("GitHub Dark")
                }
                if Configure.shared.highlightStyle.value == "tomorrow" {
                    Configure.shared.highlightStyle.accept("tomorrow-night")
                }
            } else {
                if Configure.shared.markdownStyle.value == "GitHub Dark" {
                    Configure.shared.markdownStyle.accept("GitHub")
                }
                if Configure.shared.highlightStyle.value == "tomorrow-night" {
                    Configure.shared.highlightStyle.accept("tomorrow")
                }
            }
        })
        
        _ = Configure.shared.darkOption.asObservable().subscribe(onNext: { (darkOption) in
            var value = Configure.shared.theme.value
            switch darkOption {
                case .dark:
                    value = .black
                case .light:
                    if value == .black {
                        value = .white
                    }
                case .system:
                    if #available(iOS 13.0, *) {
                        if UITraitCollection.current.userInterfaceStyle == .dark {
                            value = .black
                        } else if Configure.shared.theme.value == .black {
                            value = .white
                        }
                    } else {
                        ActivityIndicator.showError(withStatus: "Only Work on iPad OS / iOS 13")
                    }
            }
            if Configure.shared.theme.value != value {
                Configure.shared.theme.accept(value)
            }
        })
        
        
    }
    
}

