//
//  PreviewViewController.swift
//  Markdown
//
//  Created by zhubch on 2017/6/28.
//  Copyright © 2017年 zhubch. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa
import SnapKit

class PreviewViewController: UIViewController, UIScrollViewDelegate, WKNavigationDelegate {
    
    let webView = WKWebView(frame: CGRect())
    
    var contentOffset: CGPoint = CGPoint()
    
    var offset: CGFloat = 0 {
        didSet {
            var y = offset * (webHeight - webView.h)
            if y > webHeight - webView.h  {
                y = webHeight - webView.h
            }
            if y < 0 {
                y = 0
            }
            webView.scrollView.contentOffset = CGPoint(x: 0,y: y)
        }
    }
    
    var webHeight: CGFloat {
        return webView.scrollView.contentSize.height
    }
    
    var isLoading = false {
        didSet {
            if isLoading {
                if initialed {
                    if let snapshot = webView.snapshotView(afterScreenUpdates: true) {
                        snapshot.frame = webView.frame
                        snapshot.tag = 4654
                        view.addSubview(snapshot)
                    }
                    webView.stopLoading()
                }
                if webView.scrollView.contentOffset.y > 10 {
                    contentOffset = webView.scrollView.contentOffset
                }
                webView.loadHTMLString(html, baseURL: htmlURL)
                shouldRefresh = false
                delayTimer?.invalidate()
                delayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    if self.isLoading == true {
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if let snapshot = self.view.viewWithTag(4654) {
                        snapshot.tag = 0
                        snapshot.removeFromSuperview()
                    }
                    if self.isLoading == false && self.shouldRefresh {
                        self.isLoading = true
                    }
                }
                webView.scrollView.contentOffset = self.contentOffset
            }
        }
    }
    
    var delayTimer: Timer?
    
    var shouldRefresh = false
    
    var initialed = false
            
    var html: String = "" {
        didSet {
            if html == oldValue {
                return
            }
                
            if html.length > 0 {
                refresh()
            }
        }
    }
        
    var htmlURL: URL!
        
    var didScrollHandler: ((CGFloat)->Void)?
    
    let disposeBag = DisposeBag()
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.backgroundColor = .clear
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.isDirectionalLockEnabled = true
        webView.setBackgroundColor(.background)
        if #available(iOS 13.0, *) {
            webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        view.addSubview(webView)
        
        webView.snp.makeConstraints { maker in
            maker.centerX.top.bottom.equalToSuperview()
            maker.left.equalTo(0)
        }

        view.setBackgroundColor(.background)
        
        ActivityIndicator.show(on: self.view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let this = self else { return }
            ActivityIndicator.dismissOnView(this.view)
            this.initialed = true
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let inset = max((self.view.w - 500) * 0.3,0)
        self.webView.snp.updateConstraints { maker in
            maker.left.equalTo(inset)
        }
    }
    
    func showTOC(_ toc: TOCItem) {
        let js = "location.href=\"#toc_\(toc.idx)\""
        self.webView.evaluateJavaScript(js) { (_,error) in

        }
    }
    
    func refresh() {
        if isLoading == false {
            isLoading = true
        } else {
            shouldRefresh = true
        }
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            let offset = scrollView.contentOffset.y
            if webHeight - scrollView.h > 0 {
                didScrollHandler?(offset / (webHeight - scrollView.h))
            }
        }
        
        if Configure.shared.autoHideNavigationBar.value == false {
            return
        }
        
        let pan = scrollView.panGestureRecognizer
        let velocity = pan.velocity(in: scrollView).y
        if velocity < -800 {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        } else if velocity > 800 {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoading = false
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoading = false
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if navigationAction.navigationType == .linkActivated && url.isFileURL == false {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    deinit {
        webView.stopLoading()
        delayTimer?.invalidate()
        print("deinit web_vc")
    }
}
