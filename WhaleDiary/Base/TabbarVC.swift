//
//  TabbarVC.swift
//  gerental
//
//  Created by 刘思源 on 2022/12/8.
//

import Foundation
import UIKit


@objcMembers class TabbarVC : UITabBarController{
    
    
//    private let initializer: Void = {
//        let selectedAttributes: [NSAttributedString.Key: Any] = [
//            .font: UIFont.boldSystemFont(ofSize: 10),
//            .foregroundColor: UIColor.init(hexColor: "#333333")
//        ]
//        UITabBarItem.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)
//
//        let normalAttributes: [NSAttributedString.Key: Any] = [
//            .font: UIFont.boldSystemFont(ofSize: 10),
//            .foregroundColor: UIColor.red
//        ]
//        UITabBarItem.appearance().setTitleTextAttributes(normalAttributes, for: .normal)
//
//
//    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        tabBar.isTranslucent = false
//        tabBar.tintColor = .init(hexColor: "#333333")
//        tabBar.backgroundColor =
//        tabBar.shadowImage = nil
        
       
        tabBar.updateAppearance {
            $0.configureWithOpaqueBackground()
            $0.backgroundColor = .kExLightGray
        }
                
        self.addChilds()
        
        

    }
    
        func addChilds(){
            let childs : [(String,String,BaseVC)] = [
                ("notebook","日记",DiaryListVC()),
                ("wind","世界",MemeVC()),
            ]
    
            for child in childs {
                let image =  UIImage(named: child.0)!.byResize(to: CGSize(width: 28, height: 28))!
                let vc = NavVC(rootViewController: child.2)
                vc.tabBarItem.image = image.withRenderingMode(.alwaysOriginal)
                vc.tabBarItem.selectedImage = image
                
                _ = ColorCenter.shared.colorVariable(with: .primary).take(until: rx.deallocated).subscribe { [weak self, weak vc] color in
                    guard let self = self else {return}
                    self.tabBar.barTintColor = color
                    self.tabBar.updateAppearance {
                        $0.stackedLayoutAppearance.selected.titleTextAttributes = [
                            .font: UIFont.boldSystemFont(ofSize: 10),
                            .foregroundColor: color
                        ]
                    }
                    
                }
                vc.tabBarItem.title = child.1
                tabBar.updateAppearance {
                    $0.stackedLayoutAppearance.disabled.titleTextAttributes = [
                        .font: UIFont.boldSystemFont(ofSize: 10),
                        .foregroundColor: UIColor.kTextDrakGray
                    ]
                    
                }

                
                
                self.addChild(vc)
    
            }
    
        }
    
    
    
}
