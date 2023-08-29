//
//  DiaryCell.swift
//  WhaleDiary
//
//  Created by 刘思源 on 2023/8/29.
//

import UIKit
import RxCocoa
import RxSwift

class Diary{
    var date: Date!
    var title = "先来半杯小鸟伏特加"
    var icon = ""
    var location = "北京市昌平区太平庄中二街通天苑3区"
    var file: File!
    
    static func fake() -> Diary {
        let diray = Diary()
        diray.date = Date()
        return diray
    }
}

class ChatBubbleView: UIView {
    
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let _ = UIGraphicsGetCurrentContext() else { return }
        
        // Set bubble color
        let bubbleColor = UIColor.clear
        ColorCenter.shared.colorVariable(with: .background).value.setFill()
        ColorCenter.shared.colorVariable(with: .primary).value.setStroke()
        
        // Draw bubble path
        let bubblePath = UIBezierPath()
        let cornerRadius: CGFloat = 10.0
        let arrowWidth: CGFloat = 10.0
        let arrowHeight: CGFloat = 20.0
        let bubbleRect = CGRect(x: arrowWidth, y: 0, width: rect.width - arrowWidth, height: rect.height)
        
        bubblePath.move(to: CGPoint(x: arrowWidth + cornerRadius, y: 0))
        bubblePath.addLine(to: CGPoint(x: bubbleRect.maxX - cornerRadius, y: 0))
        bubblePath.addArc(withCenter: CGPoint(x: bubbleRect.maxX - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        bubblePath.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - cornerRadius))
        bubblePath.addArc(withCenter: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        bubblePath.addLine(to: CGPoint(x: bubbleRect.minX + cornerRadius , y: bubbleRect.maxY))
        bubblePath.addArc(withCenter: CGPoint(x: bubbleRect.minX + cornerRadius , y: bubbleRect.maxY - cornerRadius), radius: cornerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        bubblePath.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.midY - 20 + arrowHeight/2))
        bubblePath.addLine(to: CGPoint(x: 0, y: bubbleRect.midY - 20))
        bubblePath.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.midY - 20 - arrowHeight/2))
        bubblePath.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + cornerRadius))
        bubblePath.addArc(withCenter: CGPoint(x: bubbleRect.minX + cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .pi, endAngle: -.pi / 2, clockwise: true)
        
        bubblePath.close()
        bubblePath.fill()
        bubblePath.stroke()
        
    }
}

class DiaryCell: UITableViewCell {
    
    var weekLabel: UILabel!
    var dateLabel: UILabel!
    var headerLabel: UILabel!
    var photo: UIImageView!
    var timeLabel: UILabel!
    var locationLabel: UILabel!
    
    var diary: Diary?{
        didSet{
            guard let diary = diary else {return}
            headerLabel.text = diary.title
            weekLabel.text = "\(diary.date.day) \(diary.date.weekdayString)"
            dateLabel.text = diary.date.dateString()
            timeLabel.text = diary.date.dateString(withFormat: "hh:mm")
            locationLabel.text = diary.location
        }
    }


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configSubViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configSubViews(){
        weekLabel = UILabel()
        contentView.addSubview(weekLabel)
        weekLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-20)
            make.width.equalTo(70)
            make.left.equalTo(14)
            
        }
        weekLabel.chain.numberOfLines(0).font(.systemFont(ofSize: 14))
        weekLabel.setTextColor(.primary)
        
        dateLabel = UILabel()
        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(weekLabel.snp.bottom).offset(5)
            make.left.equalTo(weekLabel)
        }
        dateLabel.chain.font(.systemFont(ofSize: 12))
        dateLabel.setTextColor(.secondary)
        
        let upperLine = UIView()
        contentView.addSubview(upperLine)
        upperLine.snp.makeConstraints { make in
            make.left.equalTo(weekLabel.snp.right).offset(10)
            make.top.equalTo(0)
            make.width.equalTo(1)
        }
        upperLine.setBackgroundColor(.primary)
        
        let dot = UIView()
        contentView.addSubview(dot)
        dot.snp.makeConstraints { make in
            make.top.equalTo(upperLine.snp.bottom)
            make.centerX.equalTo(upperLine)
            make.width.height.equalTo(10)
            make.centerY.equalToSuperview().offset(-20)
        }
        dot.chain.corner(radius: 5).border(width: 1).clipsToBounds(true)
        dot.setBorderColor(.primary)
        
        let lowerLine = UIView()
        contentView.addSubview(lowerLine)
        lowerLine.snp.makeConstraints { make in
            make.top.equalTo(dot.snp.bottom)
            make.width.equalTo(1)
            make.centerX.equalTo(dot)
            make.bottom.equalToSuperview()
        }
        lowerLine.setBackgroundColor(.primary)
        
        
        let bubbleView = ChatBubbleView()
        bubbleView.setBackgroundColor(.background)
        contentView.addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.top.equalTo(14)
            make.right.equalTo(-14)
            make.bottom.equalTo(-14)
            make.height.equalTo(150)
            make.left.equalTo(dot.snp.right).offset(15)
        }
        
        
        headerLabel = UILabel()
        bubbleView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(5)
            make.left.equalTo(25)
            make.bottom.equalTo(-30)
        }
        headerLabel.chain.font(.systemFont(ofSize: 14)).numberOfLines(0)
        headerLabel.setTextColor(.primary)
        
        timeLabel = UILabel()
        bubbleView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(25)
            make.bottom.equalTo(-5)
        }
        timeLabel.chain.font(.systemFont(ofSize: 10))
        timeLabel.setTextColor(.secondary)
        
        locationLabel = UILabel()
        bubbleView.addSubview(locationLabel)
        locationLabel.snp.makeConstraints { make in
            make.left.equalTo(timeLabel.snp.right).offset(20)
            make.bottom.right.equalTo(-5)
            
        }
        locationLabel.chain.font(.systemFont(ofSize: 12))
        locationLabel.setTextColor(.secondary)
        
        photo = UIImageView()
        bubbleView.addSubview(photo)
        photo.snp.makeConstraints { make in
            make.top.equalTo(5)
            make.bottom.right.equalTo(-5)
        }
        photo.backgroundColor = .random()
        
        
        _ = Observable.combineLatest(ColorCenter.shared.colorVariable(with: .primary), ColorCenter.shared.colorVariable(with: .background)).take(until: rx.deallocated).subscribe { _ in
            bubbleView.setNeedsDisplay()
        }
        

        
    }

}
