//
//  DiaryTool.swift
//  WhaleDiary
//
//  Created by 刘思源 on 2023/8/29.
//

import Foundation

class DiaryTool{
    static let shared = DiaryTool()
    
    
    init() {
        File.loadLocal { local in
            self.root = local
        }
    }
    
    var diarys: [Diary] {
        root.children.map { file in
            let diary = Diary()
            diary.title = file.name
            diary.date = file.modifyDate
            diary.file = file
            return diary
        }
    }
    
    var root = File.local
    
    func createDiary(){
        let date = Date()
        let name = date.dateString(withFormat: "YYYYMMddHHmmss")
        guard let file = self.root.createFile(name: name , type: .text) else {
            return
        }
        
        File.current?.close()
        print("file \(file.displayName) tap open")
        ActivityIndicator.show()
        file.open { success in
            ActivityIndicator.dismiss()
            if success {
                self.editFile(file)
            } else {
                self.editFile(nil)
                ActivityIndicator.showError(withStatus: "CanNotAccesseThisFile")
            }
        }
    }
    
    
    func openAndEditFile(_ file:File){
        File.current?.close()
        print("file \(file.displayName) tap open")
        ActivityIndicator.show()
        file.open { success in
            ActivityIndicator.dismiss()
            if success {
                self.editFile(file)
            } else {
                self.editFile(nil)
                ActivityIndicator.showError(withStatus: "CanNotAccesseThisFile")
            }
        }
    }
    
    func editFile(_ file: File?) {
        if file == nil && (File.current == nil || isPad == false) {
            return
        }
        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
                if let viewController = storyboard.instantiateViewController(withIdentifier: "EditViewController") as? EditViewController {
                    viewController.file = file
                    UIViewController.getCurrentNav().pushViewController(viewController, animated: true)
                   
                }
        
       

    }
    
}
