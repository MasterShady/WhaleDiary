//
//  SettingsVC.swift
//  WhaleDiary
//
//  Created by 刘思源 on 2023/8/28.
//

import UIKit

class SettingsVC: BaseVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "设置"
        
        let themeItems = [Theme.white,.black,.pink,.green,.blue,.purple,.red]
        let index = themeItems.firstIndex{ Configure.shared.theme.value == $0 }

        let wraper = OptionsWraper(selectedIndex: index, editable: false, title: "Theme", items: themeItems) {
            Configure.shared.theme.accept($0 as! Theme)
        }
        let vc = OptionsViewController()
        vc.options = wraper
        

        let items = [("主题色", vc)]
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let stackView = UIStackView()
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(kScreenWidth)
        }
        stackView.axis = .vertical
        stackView.spacing = 0
        
        for (index , item) in items.enumerated(){
            let itemView = UIView()
            itemView.snp.makeConstraints { make in
                make.height.equalTo(44)
            }
            
            let title = UILabel()
            itemView.addSubview(title)
            title.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(16)
            }
            
            title.text = item.0
            title.setTextColor(.primary)
            
            let arrow = UIImageView(image: .init(named: "icon_forward"))
            itemView.addSubview(arrow)
            arrow.setTintColor(.secondary)
            arrow.snp.makeConstraints { make in
                make.right.equalTo(-16)
                make.centerY.equalToSuperview()
            }
            
            itemView.addGestureRecognizer(UITapGestureRecognizer(actionBlock: {[weak self] _ in
                self?.navigationController?.pushViewController(item.1, animated: true)
            }))
            
            stackView.addArrangedSubview(itemView)
        }
    }

}
