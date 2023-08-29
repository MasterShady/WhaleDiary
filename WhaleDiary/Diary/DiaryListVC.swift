//
//  DiaryListVC.swift
//  WhaleDairy
//
//  Created by 刘思源 on 2023/8/28.
//

import UIKit




class DiaryListVC: BaseVC, UITableViewDelegate, UITableViewDataSource {

    
    var diarys = [Diary.fake()]
    
    var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        self.reloadData()
    }
    
    override func configNavigationBar() {
        let item = UIBarButtonItem(image: .init(named: "settings"), style: .plain, target: nil, action: nil)
        item.actionBlock = {[weak self] _ in
            self?.navigationController?.pushViewController(SettingsVC(), animated: true)
        }
        self.navigationItem.leftBarButtonItem = item
        
        let diaryItem = UIBarButtonItem(image: .init(named: "editing"), style: .plain, target: nil, action: nil)
        diaryItem.actionBlock = {[weak self] _ in
            DiaryTool.shared.createDiary()
        }
        self.navigationItem.rightBarButtonItem = diaryItem
    }
    
    override func configSubViews() {
        view.setBackgroundColor(.background)
        self.navigationItem.title = "日记"
        
        tableView = UITableView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.setBackgroundColor(.tableBackground)
        tableView.register(DiaryCell.self)
        
    }
    
    func reloadData(){
        diarys = DiaryTool.shared.diarys
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        diarys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(DiaryCell.self, indexPath: indexPath)
        cell.diary = diarys[indexPath.row]
        return cell
    }
    
}
