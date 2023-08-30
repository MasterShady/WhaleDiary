//
//  MemeVC.swift
//  WhaleDiary
//
//  Created by 刘思源 on 2023/8/30.
//

import UIKit
import HandyJSON


class Meme: HandyJSON{
    var date: Date!
    var username: String!
    lazy var fakeName: String = {
        randomName()
    }()
    var meme: String!
    
    static var 造个数据 : [Meme]{
        let path = Bundle.main.path(forScaledResource: "Meme.json", ofType: nil)!
        let data =  try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        if let json = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? NSArray {
            return [Meme].deserialize(from: json)!.compactMap({$0}).sorted(by: \.date).reversed()
        }
        return .init()
    }
    
    lazy var color: UIColor = {
        let hue = CGFloat.random(in: 0.0...1.0)
        let saturation = CGFloat.random(in: 0.1...0.4) // 控制饱和度在低值范围内
        let brightness = CGFloat.random(in: 0.7...0.9) // 控制亮度在较高值范围内
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }()
    
    required init(){
        
    }
    
    func randomName() -> String{
        let names = [
            "糖果巨TM甜",
            "哥本哈根达斯",
            "你小哥我",
            "Catherine",
            "吉米的吉",
            "凡尔赛安保队长",
            "秋天不离开",
            "T34重型仙女",
            "查无此人",
            "LastWhisper",
            "赵金山",
            "Lucas99_",
            "嘚嘚那个嘚嘚",
            "Young Kobe",
            "Mia",
            "我是人间happy客",
            "彪彪TheHunter",
            "爱上章吴记",
            "老板,不要香菜",
            "智慧树下智慧果",
            "八十万水军总教头",
            "番茄蛋炒饭之歌",
            "小郭小郭_福气多多_",
            "XQ30",
            "刘后浪TheCoolBoy",
            "-NWGS-",
            "Lumkkk",
            "emooo____",
            "王艺xuan07",
            "是我啊,宝"
        ]
        
        return names.random()
    }
    
    
    func mapping(mapper: HelpingMapper) {
        mapper <<< self.date <-- CustomDateFormatTransform(formatString: "YYYY-MM-dd")
        
    }
}



class MemeCell : UICollectionViewCell{
    
    var meme: Meme?{
        didSet{
            guard let meme = meme else { return }
            self.nameLabel.text = meme.fakeName
            self.memeLabel.text = meme.meme
            self.backgroundColor = meme.color
            let dayDiff = meme.date.getDateInterval(date: Date()).day!
            if dayDiff == 0{
                self.dateLabel.text = "今天"
            }
            else if dayDiff < 7{
                self.dateLabel.text = "\(dayDiff) 天前"
            }else{
                self.dateLabel.text = meme.date.dateString()
            }
            
        }
    }
    
    var nameLabel: UILabel!
    var memeLabel: UILabel!
    var dateLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configSubViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configSubViews() {
        nameLabel = UILabel()
        self.chain.clipsToBounds(true).corner(radius: 5)
        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.left.equalTo(14)
        }
        nameLabel.chain.text(color: .white).font(.systemFont(ofSize: 14))
        
        memeLabel = UILabel()
        contentView.addSubview(memeLabel)
        memeLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.bottom.lessThanOrEqualTo(-14)
        }
        memeLabel.chain.text(color: .white).font(.systemFont(ofSize: 14)).numberOfLines(0)
        
        dateLabel = UILabel()
        contentView.addSubview(dateLabel)
        
        dateLabel.snp.makeConstraints { make in
            make.bottom.equalTo(-5)
            make.left.equalTo(memeLabel)
        }
        dateLabel.chain.text(color: .white).font(.systemFont(ofSize: 12))
    }
}


class MemeVC: BaseVC, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var collectionView: UICollectionView!
    var memes = [Meme]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "迷因"
        view.backgroundColor = .white
        
        let collectionViewFlowLayout = UICollectionViewFlowLayout()
        let itemHW = (kScreenWidth - 14 * 2 - 20) / 2
        collectionViewFlowLayout.itemSize = CGSize(width: itemHW, height: itemHW)
        collectionViewFlowLayout.minimumLineSpacing = 20
        collectionViewFlowLayout.minimumInteritemSpacing = 20
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewFlowLayout)
        
        collectionView.register(MemeCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        memes = Meme.造个数据
        
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return memes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(MemeCell.self, indexPath: indexPath)
        cell.meme = memes[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIPasteboard.general.string = memes[indexPath.row].meme
        ActivityIndicator.showMessage(message: "已复制到剪贴板。")
    }

}
