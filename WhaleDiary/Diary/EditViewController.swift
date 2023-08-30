//
//  EditViewController.swift
//  Markdown
//
//  Created by zhubch on 2017/6/23.
//  Copyright © 2017年 zhubch. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit



class EditViewController: UIViewController, UIScrollViewDelegate,UIPopoverPresentationControllerDelegate, TocListDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyImageView: UIImageView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var seperator: UIView!

    @IBOutlet weak var themBtn: UIButton!
    
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    @IBOutlet var editViewWidth: NSLayoutConstraint!

    var keyboardHeight: CGFloat = windowHeight {
        didSet {
            if keyboardHeight == oldValue {
                return
            }
            
            bottomSpace.constant = max(keyboardHeight - bottomInset - 49,0)
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    var file: File? {
        didSet {
            if let file = file{
                title = file.displayName.localizations
            }
            setup()
        }
    }
    
    var landscape: Bool {
        return windowWidth > windowHeight * 0.8
    }
    
    var shouldFullscreen = false
    var isInitial = true
            
    var previewVC: PreviewViewController!
    var textVC: TextViewController!
    
    var autoSaveTimer: Timer?

    let bag = DisposeBag()
    
    let markdownRenderer = MarkdownRender.shared()
    let pdfRender = PDFRender()
    
    var shouldRender = false
    
    var isRendering = false {
        didSet {
            if isRendering {
                DispatchQueue.global().async { [weak self] in
                    let html = self?.markdownRenderer?.renderMarkdown(self?.file?.text) ?? ""
                    DispatchQueue.main.async {
                        self?.previewVC.html = html
                        self?.isRendering = false
                    }
                }
                shouldRender = false
            } else {
                if shouldRender {
                    DispatchQueue.main.async {
                        self.isRendering = true
                    }
                }
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Configure.shared.theme.value == .white ? .default : .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
                
        if file == nil {
            if landscape == false {
                splitViewController?.preferredDisplayMode = .primaryOverlay
            }
        } else {
            setup()
        }
        
        bottomBar.setBackgroundColor(.background)
        bottomBar.setTintColor(.tint)
        navBar?.setTintColor(.navTint)
        navBar?.setBackgroundColor(.navBar)
        navBar?.setTitleColor(.navTitle)
        emptyImageView.tintImage = emptyImageView.image
        emptyImageView.setTintColor(.secondary)
        emptyLabel.setTextColor(.secondary)
        emptyLabel.text = /"NoEditingFile"
        emptyView.setBackgroundColor(.background)
        view.setBackgroundColor(.background)
        
        themBtn.isHidden = true
        
        addNotificationObserver(UIDevice.orientationDidChangeNotification.rawValue, selector: #selector(deviceOrientationDidChange))
        addNotificationObserver(UIResponder.keyboardWillChangeFrameNotification.rawValue, selector: #selector(keyboardHeightWillChange(_:)))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if splitViewController?.isCollapsed ?? false {
            navigationItem.leftBarButtonItem = nil
        } else {
            //navigationItem.leftBarButtonItem = landscape ? fullscreenButton : filelistButton
        }
        
        if Configure.shared.automaticSplit.value {
            editViewWidth.isActive = self.view.w > self.view.h * 0.8
            seperator.isHidden = editViewWidth.isActive.toggled
        } else {
            seperator.isHidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isInitial && editViewWidth.isActive.toggled && Configure.shared.openOption == .preview && (file?.text?.length ?? 0) > 0 {
            scrollView.setContentOffset(CGPoint(x:self.view.w , y:0), animated: false)
        }
        isInitial = false
    }
    
    func autoSave() {
        file?.reopen { success in
            if success {
                
            } else {
                let exception = NSException(name: NSExceptionName(rawValue: "Auto Save Failed!") , reason: "Auto Save Failed!", userInfo: nil)
                self.showAlert(title: /"Auto Save Failed!", message: /"AutoSaveFailedTips", actionTitles: [
                    "Restart".toString]) { index in
                        exit(0)
                }
            }
        }
    }
    
    func render() {
        if isRendering == false {
            isRendering = true
        } else {
            shouldRender = true
        }
    }
    
    func setup() {
        guard let file = self.file else {
            return
        }
            
        if isViewLoaded == false {
            return
        }
                
        emptyView.isHidden = true

        previewVC.htmlURL = URL(fileURLWithPath: file.path).deletingLastPathComponent().appendingPathComponent("\(file.displayName).html")
            
        textVC.editView.file = file
        
        textVC.textChangedHandler = { [weak self] (text) in
            file.text = text
            self?.redoButton.isEnabled = self?.textVC.editView.undoManager?.canRedo ?? false
            self?.undoButton.isEnabled = self?.textVC.editView.undoManager?.canUndo ?? false
            self?.render()
        }
        
        textVC.didScrollHandler = { [weak self] offset in
            self?.previewVC.offset = offset
        }
        
        previewVC.didScrollHandler = { [weak self] offset in
            self?.textVC.offset = offset
        }
        
        Configure.shared.markdownStyle.asObservable().subscribe(onNext: { [weak self] (style) in
            self?.markdownRenderer?.styleName = style
            self?.render()
        }).disposed(by: bag)
        
        Configure.shared.fontSize.asObservable().subscribe(onNext: { [weak self] fontSize in
            self?.markdownRenderer?.fontSize = fontSize
            self?.render()
        }).disposed(by: bag)
        
        Configure.shared.highlightStyle.asObservable().subscribe(onNext: { [weak self] (style) in
            self?.markdownRenderer?.highlightName = style
            self?.render()
        }).disposed(by: bag)
        
        Configure.shared.automaticSplit.asObservable().subscribe(onNext: { [weak self] (split) in
            guard let this = self else { return }
            this.editViewWidth.isActive = split ? this.view.w > this.view.h * 0.8 : false
            this.seperator.isHidden = this.editViewWidth.isActive.toggled
        }).disposed(by: bag)
        
        Configure.shared.autoHideNavigationBar.asObservable().subscribe(onNext: { [weak self] (autoHide) in
            if !autoHide {
                self?.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }).disposed(by: bag)
        
        let line = UIView()
        line.backgroundColor = rgba("262626",0.4)
        view.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.bottomBar)
            maker.height.equalTo(0.3)
        }
        
        textVC.loadText(file.text!)
    }
    
    @objc func keyboardHeightWillChange(_ noti: NSNotification) {
        guard let frame = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        keyboardHeight = textVC.editView.isFirstResponder ? (windowHeight - frame.y) : 0
    }
    
    @objc func deviceOrientationDidChange() {
        DispatchQueue.main.async {
            if self.landscape {
                self.splitViewController?.preferredDisplayMode = self.shouldFullscreen ? .primaryHidden : .automatic
            } else {
                self.splitViewController?.preferredDisplayMode = .automatic
            }
        }
    }
        
    @objc func fileLoadFinished(_ noti: Notification) {
        guard let file = noti.object as? File else { return }
        self.file = file
    }
    
    @objc func showFileList() {
        impactIfAllow()
        splitViewController?.preferredDisplayMode = .primaryOverlay
    }
    
    @objc func fullscreen() {
        impactIfAllow()
        UIView.animate(withDuration: 0.5) {
            if self.splitViewController?.preferredDisplayMode != .primaryHidden {
                self.splitViewController?.preferredDisplayMode = .primaryHidden
                self.navigationItem.leftBarButtonItem = self.exitFullscreenButton
                self.shouldFullscreen = true
            } else {
                self.splitViewController?.preferredDisplayMode = .allVisible
                self.navigationItem.leftBarButtonItem = self.fullscreenButton
                self.shouldFullscreen = false
            }
        }
    }
    
    @IBAction func showTocList(_ sender: UIBarButtonItem) {
        impactIfAllow()

        guard let toc = markdownRenderer?.tocHeader(file?.text) else { return }
        textVC.editView.resignFirstResponder()
        
        let vc = TocListViewController()
        vc.toc = toc
        vc.textCount = ((file?.text ?? "") as NSString).length
        vc.delegate = self
        
        let nav = NavVC(rootViewController: vc)
        nav.preferredContentSize = CGSize(width:300, height:400)
        nav.modalPresentationStyle = .popover
        guard let popoverVC = nav.popoverPresentationController else {
            return
        }
        popoverVC.backgroundColor = UIColor.white
        popoverVC.delegate = self
        popoverVC.barButtonItem = sender
        present(nav, animated: true, completion: nil)
    }
    
    @IBAction func undo(_ sender: UIButton) {
        textVC.editView.undoManager?.undo()
        impactIfAllow()
    }
    
    @IBAction func redo(_ sender: UIButton) {
        textVC.editView.undoManager?.redo()
        impactIfAllow()
    }
    
    @IBAction func preview(_ sender: Any) {
        impactIfAllow()
        if self.view.w != self.textVC.editView.w {
            return
        }
        if previewButton.tag == 0 {
            scrollView.setContentOffset(CGPoint(x:self.view.w , y:0), animated: true)
        } else {
            scrollView.setContentOffset(CGPoint(), animated: true)
        }
        if !Configure.shared.showedTips.contains("1") {
            showAlert(title: /"Tips", message: /"SlideTips", actionTitles: ["GotIt".localizations])
            Configure.shared.showedTips.append("1")
        }
    }
    
    @IBAction func showStylesView(_ sender: UIButton) {
//        impactIfAllow()
//
//        let vc = AppearanceViewController()
//
//        let nav = NavigationViewController(rootViewController: vc)
//        nav.preferredContentSize = CGSize(width:300, height:400)
//        nav.modalPresentationStyle = .popover
//        guard let popoverVC = nav.popoverPresentationController else {
//            return
//        }
//        popoverVC.backgroundColor = UIColor.white
//        popoverVC.delegate = self
//        popoverVC.sourceView = sender
//        popoverVC.sourceRect = sender.bounds
//        present(nav, animated: true, completion: nil)
    }
    
    @IBAction func showExportMenu(_ sender: UIButton) {
        impactIfAllow()
        textVC.editView.resignFirstResponder()
        
        let point = sender.convert(CGPoint(), to: UIApplication.shared.keyWindow)
        let pos = CGPoint(x: point.x - 100, y: point.y - 170)
        let types = [ExportType.markdown,.pdf,.html,.image]

        MenuView(items: types.map{($0.displayName,!($0 == .markdown || Configure.shared.isPro))},
                 postion: pos) { (index) in
                    if index > 0 {
                        self.doIfPro {
                            self.export(type: types[index], sender: sender)
                        }
                    } else {
                        self.export(type: types[index], sender: sender)
                    }
            }.show()
    }
    
    func doIfPro(_ task: (() -> Void)) {
        if Configure.shared.isPro {
            task()
            return
        }
        showAlert(title: "PremiumOnly", message: "PremiumTips", actionTitles: ["SubscribeNow","Cancel"], textFieldconfigurationHandler: nil) { (index) in
            if index == 0 {
//                let sb = UIStoryboard(name: "Settings", bundle: Bundle.main)
//                let vc = sb.instantiateVC(PurchaseViewController.self)!
//                let nav = NavigationViewController(rootViewController: vc)
//                nav.modalPresentationStyle = .formSheet
//                self.presentVC(nav)
            }
        }
    }
    
    func export(type: ExportType, sender: UIButton) {
        guard let file = self.file else { return }
        var item: Any?
        switch type {
        case .pdf:
            let data = pdfRender.render(formatter: self.previewVC.webView.viewPrintFormatter())
            let path = tempPath + "/" + file.displayName + ".pdf"
            try? FileManager.default.removeItem(atPath: path)
            FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
            item = URL(fileURLWithPath: path)
        case .markdown:
            item = URL(fileURLWithPath: file.path)
        case .html:
            let path = tempPath + "/" + file.displayName + ".html"
            let url = URL(fileURLWithPath: path)
            guard let data = previewVC.html.data(using: String.Encoding.utf8) else { return }
            try? data.write(to: url)
            item = url
        case .image:
            if self.view.w == self.textVC.editView.w {
                self.scrollView.setContentOffset(CGPoint(x: self.view.w, y: 0), animated: true)
            }
            ActivityIndicator.show()
            previewVC.webView.takeSnapshot(delay: 0.3, progress: { percentage in
                
            }, completion: {  image in
                ActivityIndicator.dismiss()
                guard let image = image else { return }
                let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                vc.popoverPresentationController?.sourceView = sender
                vc.popoverPresentationController?.sourceRect = sender.bounds
                self.presentVC(vc)
            })
        }
        
        if let item = item {
            let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = sender
            vc.popoverPresentationController?.sourceRect = sender.bounds
            self.presentVC(vc)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TextViewController {
            textVC = vc
        } else if let vc = segue.destination as? PreviewViewController {
            previewVC = vc
        }
    }
    
    func didSelectTOC(_ toc: TOCItem, fromListVC: TocListViewController) {
        fromListVC.dismiss(animated: true, completion: nil)
        textVC.showTOC(toc)
        previewVC.showTOC(toc)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        previewButton.tag = scrollView.contentOffset.x < view.w * 0.5 ? 0 : 1
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        impactIfAllow()
        previewButton.tag = scrollView.contentOffset.x < view.w * 0.5 ? 0 : 1
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        autoSave()
    }
        
    deinit {
        autoSaveTimer?.invalidate()
        removeNotificationObserver()
        print("deinit edit_vc")
    }
    
    override var title: String? {
           didSet {
               markdownRenderer?.title = title
           }
       }
       
    lazy var fullscreenButton: UIBarButtonItem = {
           let button = UIBarButtonItem(image: #imageLiteral(resourceName: "fullscreen"), style: .plain, target: self, action: #selector(fullscreen))
           return button
       }()
       
    lazy var exitFullscreenButton: UIBarButtonItem = {
           let button = UIBarButtonItem(image: #imageLiteral(resourceName: "nav_files"), style: .plain, target: self, action: #selector(fullscreen))
           return button
       }()
       
    lazy var filelistButton: UIBarButtonItem = {
           let export = UIBarButtonItem(image: #imageLiteral(resourceName: "nav_files"),
                       landscapeImagePhone: #imageLiteral(resourceName: "nav_files"),
                       style: .plain,
                       target: self,
                       action: #selector(showFileList))
           return export
       }()
       
}


//extension EditViewController {
//
//    override var keyCommands: [UIKeyCommand]? {
//        return [
//            UIKeyCommand(input: "P", modifierFlags: .command, action: #selector(preview(_:)), discoverabilityTitle: "Preview/Edit"),
//        ]
//    }
//    
//    override var canBecomeFirstResponder: Bool {
//        return true
//    }
//}
