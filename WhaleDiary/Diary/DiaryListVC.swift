//
//  DiaryListVC.swift
//  WhaleDairy
//
//  Created by 刘思源 on 2023/8/28.
//

import UIKit
import KDCalendar

class DiaryListVC: BaseVC, UITableViewDelegate, UITableViewDataSource {
    
    
    var diarys = [File]()
    var textField : UITextField?
    var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        self.reloadData()
    }
    
    override func configNavigationBar() {
        let item = UIBarButtonItem(image: .init(named: "settings"), style: .plain, target: nil, action: nil)
        item.actionBlock = {[weak self] _ in
            let themeItems = [Theme.white,.black,.pink,.green,.blue,.purple,.red]
            let index = themeItems.firstIndex{ Configure.shared.theme.value == $0 }
            let wraper = OptionsWraper(selectedIndex: index, editable: false, title: /"Theme", items: themeItems) {
                Configure.shared.theme.accept($0 as! Theme)
            }
            let vc = OptionsViewController()
            vc.options = wraper
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        self.navigationItem.leftBarButtonItem = item
        
        let diaryItem = UIBarButtonItem(image: .init(named: "editing"), style: .plain, target: nil, action: nil)
        diaryItem.actionBlock = {[weak self] _ in
            self?.showAlert(title: nil, message: /"CreateTips", actionTitles: ["CreateNote".localizations,"Cancel".localizations], textFieldconfigurationHandler: {[weak self] textField in
                textField.clearButtonMode = .whileEditing
                textField.placeholder = /"FileNamePlaceHolder"
                textField.text = Date().toString(format: "YYYY-MM-dd") + "日记"
                self?.textField = textField
            }) { index in
                let name = self?.textField?.text ?? ""
                if name.count == 0 || index == 1 {
                    return
                }
                if !name.isValidFileName {
                    ActivityIndicator.showError(withStatus: /"FileNameError")
                    return
                }
                DiaryTool.shared.createDiary(withName: name)
            }
            
            
        }
        self.navigationItem.rightBarButtonItems = [item, diaryItem]
        
        
        let calendar = UIBarButtonItem(image: .init(named: "calendar"), style: .plain, target: nil, action: nil)
        calendar.actionBlock = { [weak self] _ in
            guard let self = self else {return}
            GEPopTool.popViewFormBottom(view: self.datePicker)
        }
        self.navigationItem.leftBarButtonItem = calendar
        
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
        
        NotificationCenter.addObserver(forName: .localFileLoadCompleted) {[weak self] _ in
            self?.reloadData()
        }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let diary = diarys[indexPath.row]
        DiaryTool.shared.openAndEditFile(diary)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let diary = self.diarys[indexPath.row]
            diarys.remove(at: indexPath.row)
            diary.trash()
            tableView.reloadData()
        }
    }
    
//    lazy var calendarView : CalendarView = {
//        let calendarView = CalendarView()
//        calendarView.snp.makeConstraints { make in
//            make.width.equalTo(kScreenWidth)
//            make.height.equalTo(200)
//        }
//        let style = CalendarView.Style()
//
//        style.cellShape                = .bevel(8.0)
//        style.cellColorDefault         = UIColor.clear
//        style.cellColorToday           = UIColor(red:1.00, green:0.84, blue:0.64, alpha:1.00)
//        style.cellSelectedBorderColor  = UIColor(red:1.00, green:0.63, blue:0.24, alpha:1.00)
//        style.cellEventColor           = UIColor(red:1.00, green:0.63, blue:0.24, alpha:1.00)
//        style.headerTextColor          = UIColor.gray
//
//        style.cellTextColorDefault     = UIColor(red: 249/255, green: 180/255, blue: 139/255, alpha: 1.0)
//        style.cellTextColorToday       = UIColor.orange
//        style.cellTextColorWeekend     = UIColor(red: 237/255, green: 103/255, blue: 73/255, alpha: 1.0)
//        style.cellColorOutOfRange      = UIColor(red: 249/255, green: 226/255, blue: 212/255, alpha: 1.0)
//
//        style.headerBackgroundColor    = UIColor.white
//        style.weekdaysBackgroundColor  = UIColor.white
//        style.firstWeekday             = .sunday
//
//        style.locale                   = Locale(identifier: "en_US")
//
//        style.cellFont = UIFont(name: "Helvetica", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0)
//        style.headerFont = UIFont(name: "Helvetica", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0)
//        style.weekdaysFont = UIFont(name: "Helvetica", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
//
//        calendarView.style = style
//
//        calendarView.dataSource = self
//        calendarView.delegate = self
//
//        calendarView.direction = .horizontal
//        calendarView.multipleSelectionEnable = false
//        calendarView.marksWeekends = true
//
//
//        calendarView.backgroundColor = UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1.0)
//        return calendarView
//    }()
    
    lazy var datePicker: DatePicker = {
        let title = NSMutableAttributedString(string:"选择日期")
        title.setAttributes([
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18),
            NSAttributedString.Key.foregroundColor: UIColor.kBlack,
        ], range: title.range)
        
        //
        
        let fromDate = Date(string: "2010/01/01", format: "YYYY/MM/dd")!
        let toDate = Date(string: "2030/12/31", format: "YYYY/MM/dd")!
        let picker = DatePicker(title: title, fromDate: fromDate, toDate: toDate) { [weak self] date in
            GEPopTool.dismissPopView()
            guard let self = self else {return}
            //self.date = date
        }
        picker.setSelectedData(Date())
        picker.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: kScreenWidth, height: 290 + kBottomSafeInset))
        };

        return picker
    }()
}



