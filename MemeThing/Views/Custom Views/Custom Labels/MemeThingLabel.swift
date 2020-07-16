//
//  MemeThingLabel.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/9/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UILabel {
    func setUpViews(cornerRadius: CGFloat = 8, borderWidth: CGFloat = 0, borderColor: UIColor = .border, backgroundColor: UIColor? = .purpleAccent, opacity: CGFloat = 0.6, textColor: UIColor = .mainText, fontSize: CGFloat = 20, fontName: String = FontNames.mainFont) {
        addCornerRadius(cornerRadius)
        addBorder(width: borderWidth, color: borderColor)
        numberOfLines = 0
        if let backgroundColor = backgroundColor {
            self.backgroundColor = backgroundColor.withAlphaComponent(opacity)
        }
        self.textColor = textColor
        font = UIFont(name: fontName, size: fontSize)
    }
}

class MemeThingLabelBackground: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews()
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize { return addInsets(to: super.intrinsicContentSize) }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return addInsets(to: super.sizeThatFits(size))
    }
    
    private func addInsets(to size: CGSize) -> CGSize {
        let width = size.width + 12
        let height = size.height + 6
        return CGSize(width: width, height: height)
    }
}

class MemeThingLabelBackgroundLight: MemeThingLabelBackground {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(borderWidth: 2, backgroundColor: .lightBlueAccent, opacity: 1, textColor: .border)
    }
}

class MemeThingCaption: MemeThingLabelBackground {
    override func awakeFromNib() {
        super.awakeFromNib()
        addBorder()
    }
}

class MemeThingLabel: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: nil)
    }
}

class MemeThingLabelDark: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: nil, textColor: .border)
    }
}
