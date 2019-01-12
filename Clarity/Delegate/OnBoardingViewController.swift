//
//  OnBoardingViewController.swift
//  Clarity
//
//  Created by Celine Pena on 8/19/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class OnBoardingViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    var imgTwo: UIImageView!
    @IBOutlet weak var page1: UIView!
    @IBOutlet weak var page2: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        self.scrollView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

        let scrollViewWidth = UIScreen.main.bounds.width
        //let palceholder = UIImageView(frame: CGRect(x: scrollViewWidth, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        //palceholder.isHidden = true
        
        imgTwo = UIImageView(frame: CGRect(x:scrollViewWidth/2-90, y: 60, width: UIScreen.main.bounds.width-90, height: (UIScreen.main.bounds.width-90)*1.28))
        imgTwo.image = #imageLiteral(resourceName: "Labels")
        imgTwo.alpha = 0.0
        imgTwo.contentMode = .center
        
        
        //self.scrollView.addSubview(palceholder)
        self.view.addSubview(imgTwo)
        self.scrollView.contentSize = CGSize(width:self.scrollView.frame.width * 2, height:self.scrollView.frame.height)

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y>0 {
            scrollView.contentOffset.y = 0
        }
        
        let pageWidth:CGFloat = scrollView.frame.width
        let currentPage:CGFloat = floor((scrollView.contentOffset.x-pageWidth/2)/pageWidth)+1
        self.pageControl.currentPage = Int(currentPage) // Change the indicator
        
        print(self.scrollView.contentOffset.x)
        self.imgTwo.alpha = self.scrollView.contentOffset.x / pageWidth
        self.imgTwo.frame.origin.x = (UIScreen.main.bounds.width/2-90) - (15/100 * (scrollView.contentOffset.x))
        
        self.page1.alpha = 1.0 / self.scrollView.contentOffset.x
    }
}
