//
//  FilterTimeTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/15/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterTimeTableViewCell: FilterBaseTableViewCell {

    let titleLabel = UILabel()
    let sliderView = UISlider()
    let sliderLabel = UILabel()
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTitle()
        setupSlider()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupTitle() {
        titleLabel.text = NSLocalizedString("Time In Calling", comment: "")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.CWFGreyTextColor
        
        self.addSubview(titleLabel)
        
        let titleXConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let titleYConstraint = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        
        self.addConstraints([titleXConstraint, titleYConstraint])
    }

    func setupSlider () {
        sliderView.translatesAutoresizingMaskIntoConstraints = false
        sliderView.minimumValue = 0.0
        sliderView.maximumValue = 60.0
        sliderView.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        self.addSubview(sliderView)
        
        let yConstraint = NSLayoutConstraint(item: sliderView, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: sliderView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30)
        let lConstraint = NSLayoutConstraint(item: sliderView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let rConstraint = NSLayoutConstraint(item: sliderView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -15)
        
        self.addConstraints([yConstraint, hConstraint, lConstraint, rConstraint])
        
        sliderLabel.translatesAutoresizingMaskIntoConstraints = false
        sliderLabel.text = NSLocalizedString("\(String(sliderView.value)) Months", comment: "months in calling")
        sliderLabel.textColor = UIColor.CWFGreyTextColor
        sliderLabel.textAlignment = .center
        sliderLabel.font = UIFont(name: sliderLabel.font.fontName, size: 12)
        
        self.addSubview(sliderLabel)
        
        let labelYConstraint = NSLayoutConstraint(item: sliderLabel, attribute: .top, relatedBy: .equal, toItem: sliderView, attribute: .bottom, multiplier: 1, constant: 0)
        let labelXConstraint = NSLayoutConstraint(item: sliderLabel, attribute: .centerX, relatedBy: .equal, toItem: sliderView, attribute: .centerX, multiplier: 1, constant: 0)
        let labelWConstraint = NSLayoutConstraint(item: sliderLabel, attribute: .width, relatedBy: .equal, toItem: sliderView, attribute: .width, multiplier: 1, constant: 0)
        let labelHConstraint = NSLayoutConstraint(item: sliderLabel, attribute: .height, relatedBy: .equal, toItem: sliderView, attribute: .height, multiplier: 1, constant: 0)
        
        self.addConstraints([labelYConstraint, labelXConstraint, labelWConstraint, labelHConstraint])
    }
    
    func sliderValueChanged (sender: UISlider) {
        if sender.value < 12 {
            let valueAsInt = Int(sender.value)
            sender.setValue(Float(valueAsInt), animated: false)

            sliderLabel.text = NSLocalizedString("\(String(sliderView.value)) Months", comment: "months in calling")
        }
        else {
            // round to quarter year and reset the value - this is what causes the slider to snap to the next quarter value (1.75 years, rather than allowing 1.6 years)
            let valueAsInt = (Int((sender.value + 1.5) / 3.0)) * 3
            sender.setValue(Float(valueAsInt), animated: false)

            let valueInYears = sender.value / 12.0
            sliderLabel.text = NSLocalizedString("\(valueInYears)+ Years", comment: "years in calling")
        }
    }
    
    override func getCellHeight() -> CGFloat {
        return 85
    }
    
}

extension FilterTimeTableViewCell : UIFilterElement {
    func getSelectedOptions(filterOptions: FilterOptions) -> FilterOptions {
        var filterOptions = filterOptions
        filterOptions.minMonthsInCalling = Int(sliderView.value)
        return filterOptions
    }

    func setSelectedOptions(filterOptions: FilterOptions) {
        guard let monthsInCalling = filterOptions.minMonthsInCalling else {
            return
        }
        
        sliderView.value = Float( monthsInCalling )
        sliderValueChanged(sender: sliderView)
        
    }
}
