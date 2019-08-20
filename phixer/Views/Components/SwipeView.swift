/*
 SwipeView.swift
 
 Version 1.2, January 2, 2015
 Adapted for Swift by David Hirsch on 12/27/14 from:
 SwipeView 1.3.2 ( https://github.com/nicklockwood/SwipeView )
 Updated to Swift 4 by Phil Price on 07/24/2019
 
 This version Copyright (C) 2014, David Hirsch, licensed under MIT License.
 */

import UIKit

internal extension Array {
    //  Extracted from:
    //  Array.swift
    //  ExSwift
    //
    //  Created by pNre on 03/06/14.
    //  Copyright (c) 2014 pNre. All rights reserved.
    //
    
    /**
     Checks if self contains a list of items.
     
     :param: items Items to search for
     :returns: true if self contains all the items
     */
    func contains <T: Equatable> (items: T...) -> Bool {
        return items.all { self.indexOf(item: $0)! >= 0 }
    }
    
    /**
     Index of the first occurrence of item, if found.
     
     :param: item The item to search for
     :returns: Index of the matched item or nil
     */
    func indexOf <U: Equatable> (item: U) -> Int? {
        if item is Element {
            //return find(unsafeBitCast(self, [U].self), item)
            return unsafeBitCast(self, to: [U].self).firstIndex(of: item)
        }
        
        return nil
    }
    
    /**
     Checks if test returns true for all the elements in self
     
     :param: test Function to call for each element
     :returns: True if test returns true for all the elements in self
     */
    func all (test: (Element) -> Bool) -> Bool {
        for item in self {
            if !test(item) {
                return false
            }
        }
        
        return true
    }
}

enum SwipeViewAlignment {
    case Edge
    case Center
}

protocol SwipeViewDataSource {
    func numberOfItemsInSwipeView(swipeView: SwipeView) -> Int
    func viewForItemAtIndex(index: Int, swipeView:SwipeView, reusingView:UIView?) -> UIView?
}

@objc protocol SwipeViewDelegate {
    @objc optional func swipeViewItemSize(swipeView: SwipeView) -> CGSize
    @objc optional func swipeViewDidScroll(swipeView: SwipeView) -> Void
    @objc optional func swipeViewCurrentItemIndexDidChange(swipeView: SwipeView) -> Void
    @objc optional func swipeViewWillBeginDragging(swipeView: SwipeView) -> Void
    @objc optional func swipeViewDidEndDragging(swipeView: SwipeView, willDecelerate:Bool) -> Void
    @objc optional func swipeViewWillBeginDecelerating(swipeView: SwipeView) -> Void
    @objc optional func swipeViewDidEndDecelerating(swipeView: SwipeView) -> Void
    @objc optional func swipeViewDidEndScrollingAnimation(swipeView: SwipeView) -> Void
    @objc optional func shouldSelectItemAtIndex(index: Int, swipeView: SwipeView) -> Bool
    @objc optional func didSelectItemAtIndex(index: Int, swipeView: SwipeView) -> Void
}

class SwipeView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    private static let defaultScrollDuration = 1.0
    
    private(set) var scrollView: UIScrollView
    private(set) var itemViews: [Int: UIView]?
    private(set) var itemViewPool: [UIView]?
    private(set) var previousItemIndex = 0
    private(set) var previousContentOffset = CGPoint.zero
    private(set) var itemSize = CGSize.zero
    private(set) var suppressScrollEvent = false
    //private(set) var scrollDuration = 0.0
    private(set) var scrollDuration = defaultScrollDuration
    private(set) var scrolling = false
    private(set) var startTime = 0.0
    private(set) var lastTime = 0.0
    private(set) var startOffset = 0.0 as CGFloat
    private(set) var endOffset = 0.0 as CGFloat
    private(set) var lastUpdateOffset = 0.0 as CGFloat
    private(set) var timer: Timer?
    private(set) var numberOfItems = 0
    private(set) var scrollOffset = 0.0 as CGFloat
    private(set) var currentItemIndex = 0
    var numberOfPages : Int {
        return Int(ceil(Double(numberOfItems) / Double(itemsPerPage)))
    }
    
    //MARK: - Settable properties:
    
    var defersItemViewLoading = false
    
    var dataSource: SwipeViewDataSource? {   // cannot be connected in IB at this time; must do it in code
        didSet {
            if (dataSource != nil) {
                reloadData()
            }
        }
    }
    var delegate: SwipeViewDelegate? {  // cannot be connected in IB at this time; must do it in code
        didSet {
            if (delegate != nil) {
                setNeedsLayout()
            }
        }
    }
    var itemsPerPage: Int = 1 {
        didSet {
            if (itemsPerPage != oldValue) {
                setNeedsLayout()
            }
        }
    }
    var truncateFinalPage: Bool = false {
        didSet {
            if (truncateFinalPage != oldValue) {
                setNeedsLayout()
            }
        }
    }
    var alignment: SwipeViewAlignment = SwipeViewAlignment.Center {
        didSet {
            if (alignment != oldValue) {
                setNeedsLayout()
            }
        }
    }
    var pagingEnabled: Bool = true {
        didSet {
            if (pagingEnabled != oldValue) {
                self.scrollView.isPagingEnabled = pagingEnabled
                self.setNeedsLayout()
            }
        }
    }
    var scrollEnabled: Bool = true {
        didSet {
            if (scrollEnabled != oldValue) {
                self.scrollView.isScrollEnabled = scrollEnabled
            }
        }
    }
    var wrapEnabled: Bool = false {
        didSet {
            if (wrapEnabled != oldValue) {
                let previousOffset = self.clampedOffset(offset: self.scrollOffset)
                scrollView.bounces = self.bounces && !wrapEnabled
                self.setNeedsLayout()
                self.setScrollOffset(scrollOffset: previousOffset)
            }
        }
    }
    var delaysContentTouches: Bool = true {
        didSet {
            if (delaysContentTouches != oldValue) {
                scrollView.delaysContentTouches = delaysContentTouches
            }
        }
    }
    var bounces: Bool = true {
        didSet {
            if (bounces != oldValue) {
                scrollView.alwaysBounceHorizontal = !self.vertical && self.bounces
                scrollView.alwaysBounceVertical = self.vertical && self.bounces
                scrollView.bounces = self.bounces && !self.wrapEnabled
            }
        }
    }
    var decelerationRate: CGFloat = UIScrollView.DecelerationRate.normal.rawValue {
        didSet {
            if (abs(self.decelerationRate - oldValue) > 0.001) {
                //scrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: decelerationRate)
                if self.decelerationRate > 1.0 {
                    scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
                } else {
                    scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
               }
            }
        }
    }
    var autoscroll: CGFloat = 0.0 {
        didSet {
            if (abs(self.autoscroll - oldValue) > 0.001) {
                if (autoscroll != 0) {
                    self.startAnimation()
                }
            }
        }
    }
    var vertical: Bool = false {
        didSet {
            if (vertical != oldValue) {
                scrollView.alwaysBounceHorizontal = !self.vertical && self.bounces
                scrollView.alwaysBounceVertical = self.vertical && self.bounces
                self.setNeedsLayout()
            }
        }
    }
    
    
    //MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        self.scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))    // will be modified later
        super.init(coder: aDecoder)
        setUp()
    }
    
    required override init(frame: CGRect) {
        self.scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))    // will be modified later
        super.init(frame: frame)
        setUp()
    }
    
    func setUp() {
        
        itemViews = Dictionary(minimumCapacity: 4)
        itemViewPool = Array()
        
        self.clipsToBounds = true
        
        scrollView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleHeight.rawValue | UIView.AutoresizingMask.flexibleWidth.rawValue)
        scrollView.autoresizesSubviews = true
        scrollView.delegate = self
        scrollView.delaysContentTouches = delaysContentTouches
        scrollView.bounces = bounces && !wrapEnabled
        scrollView.alwaysBounceHorizontal = !vertical && bounces
        scrollView.alwaysBounceVertical = vertical && bounces
        scrollView.isPagingEnabled = pagingEnabled
        scrollView.isScrollEnabled = scrollEnabled
        //scrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: self.decelerationRate)
        scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollsToTop = false
        scrollView.clipsToBounds = false
        
        decelerationRate = scrollView.decelerationRate.rawValue
        previousContentOffset = scrollView.contentOffset
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapGesture.delegate = self
        scrollView.addGestureRecognizer(tapGesture)
        //scrollView.isUserInteractionEnabled = true

        //place scrollview at bottom of hierarchy
        self.insertSubview(scrollView, at: 0)
        
        if self.dataSource != nil {
            reloadData()
        }
        
    }
    
    deinit {
        if self.timer != nil {
            timer?.invalidate()
        }
    }
    
    func isDragging() -> Bool? {
        return scrollView.isDragging
    }
    
    func isDecelerating() -> Bool? {
        return scrollView.isDecelerating
    }
    
    //MARK: - View management
    
    func indexesForVisibleItems() -> Array<Int> {
        if let unsortedIndexes = itemViews?.keys {
            return unsortedIndexes.sorted(by: { (n1: Int, n2: Int) -> Bool in
                return n1 < n2
            })
        }
        return Array()
    }
    
    func visibleItemViews() -> Array<UIView> {
        let indexesSorted = self.indexesForVisibleItems()
        var resultArrayOfViews:[UIView] = Array()
        for thisIndex in indexesSorted {
            if let foundView = itemViews![thisIndex] {
                resultArrayOfViews.append(foundView)
            }
        }
        return resultArrayOfViews
    }
    
    func itemViewAtIndex(index: Int) -> UIView? {
        return self.itemViews?[index]
    }
    
    func currentItemView() -> UIView? {
        return self.itemViewAtIndex(index: currentItemIndex)
    }
    
    /* This function gets the "index" of a view, but it's not the index in the context of any array, it's the "index" stored as a key in the dictionary, so we need to find the correct view and return the key.  There's probably a good way to do this with filter() and map(), but the set of elements in the dictionary is likely to be small, so we'll just iterate manually. */
    func indexOfItemView(view:UIView) -> Int? {
        if self.itemViews == nil {
            return nil
        }
        
        for (theKey, theValue) in self.itemViews! {
            if theValue === view {
                return theKey
            }
        }
        return nil
    }
    
    func indexOfItemViewOrSubview(view: UIView) -> Int? {
        let index = self.indexOfItemView(view: view)
        if (index == nil && view != scrollView) {
            // we didn't find the index, but the view is a valid view other than the scrollView, so maybe it's a subview of the indexed view.  Let's try to look up its superview instead:
            if let newViewToFind = view.superview {
                return self.indexOfItemViewOrSubview(view: newViewToFind)
            } else {
                return nil
            }
        }
        return index;
    }
    
    
    func setItemView(view: UIView, forIndex theIndex:Int) {
        if (self.itemViews != nil) {
            itemViews![theIndex] = view
        }
    }
    
    
    //MARK: - View layout
    func updateScrollOffset () {
        
        if (wrapEnabled)
        {
            let itemsWide = (numberOfItems == 1) ? 1.0: 3.0
            
            if (vertical)
            {
                let scrollHeight = scrollView.contentSize.height / CGFloat(itemsWide);
                if (scrollView.contentOffset.y < scrollHeight)
                {
                    previousContentOffset.y += scrollHeight;
                    setContentOffsetWithoutEvent(contentOffset: CGPoint(x: 0.0, y: scrollView.contentOffset.y + scrollHeight))
                }
                else if (scrollView.contentOffset.y >= scrollHeight * 2.0)
                {
                    previousContentOffset.y -= scrollHeight;
                    setContentOffsetWithoutEvent(contentOffset: CGPoint(x: 0.0, y: scrollView.contentOffset.y - scrollHeight))
                }
                scrollOffset = clampedOffset(offset: scrollOffset)
            }
            else
            {
                let scrollWidth = scrollView.contentSize.width / CGFloat(itemsWide)
                if (scrollView.contentOffset.x < scrollWidth)
                {
                    previousContentOffset.x += scrollWidth;
                    setContentOffsetWithoutEvent(contentOffset: CGPoint(x: scrollView.contentOffset.x + scrollWidth, y: 0.0))
                }
                else if (scrollView.contentOffset.x >= scrollWidth * 2.0)
                {
                    previousContentOffset.x -= scrollWidth;
                    setContentOffsetWithoutEvent(contentOffset: CGPoint(x: scrollView.contentOffset.x - scrollWidth, y: 0.0))
                }
                scrollOffset = clampedOffset(offset: scrollOffset)
            }
        }
        if (vertical && abs(scrollView.contentOffset.x) > 0.0001)
        {
            setContentOffsetWithoutEvent(contentOffset: CGPoint(x: 0.0, y: scrollView.contentOffset.y))
        }
        else if (!vertical && abs(scrollView.contentOffset.y) > 0.0001)
        {
            setContentOffsetWithoutEvent(contentOffset: CGPoint(x: scrollView.contentOffset.x, y: 0.0))
        }
    }
    
    func updateScrollViewDimensions () {
        
        var frame = self.bounds
        var contentSize = frame.size
        
        if (vertical)
        {
            contentSize.width -= (scrollView.contentInset.left + scrollView.contentInset.right);
        }
        else
        {
            contentSize.height -= (scrollView.contentInset.top + scrollView.contentInset.bottom);
        }
        
        
        switch (alignment) {
        case .Center:
            if (vertical)
            {
                frame = CGRect(x:0.0, y:(self.bounds.size.height - itemSize.height * CGFloat(itemsPerPage))/2.0,
                               width:self.bounds.size.width, height:itemSize.height * CGFloat(itemsPerPage))
                contentSize.height = itemSize.height * CGFloat(numberOfItems)
            }
            else
            {
                frame = CGRect(x: (self.bounds.size.width - itemSize.width * CGFloat(itemsPerPage))/2.0,
                               y: 0.0, width: itemSize.width * CGFloat(itemsPerPage), height: self.bounds.size.height);
                contentSize.width = itemSize.width * CGFloat(numberOfItems)
            }
            
        case .Edge:
            if (vertical)
            {
                frame = CGRect(x: 0.0, y: 0.0, width: self.bounds.size.width, height: itemSize.height * CGFloat(itemsPerPage))
                contentSize.height = itemSize.height * CGFloat(numberOfItems) - (self.bounds.size.height - frame.size.height);
            }
            else
            {
                frame = CGRect(x: 0.0, y: 0.0, width: itemSize.width * CGFloat(itemsPerPage), height: self.bounds.size.height);
                contentSize.width = itemSize.width * CGFloat(numberOfItems) - (self.bounds.size.width - frame.size.width)
            }
        }
        
        if (wrapEnabled)
        {
            let itemsWide = CGFloat((numberOfItems == 1) ? 1.0 : Double(numberOfItems) * 3.0)
            if (vertical)
            {
                contentSize.height = itemSize.height * itemsWide;
            }
            else
            {
                contentSize.width = itemSize.width * itemsWide;
            }
        }
        else if (pagingEnabled && !truncateFinalPage)
        {
            if (vertical)
            {
                contentSize.height = ceil(contentSize.height / frame.size.height) * frame.size.height;
            }
            else
            {
                contentSize.width = ceil(contentSize.width / frame.size.width) * frame.size.width;
            }
        }
        
        if (!scrollView.frame.equalTo(frame))
        {
            scrollView.frame = frame;
        }
        
        if (!scrollView.contentSize.equalTo(contentSize))
        {
            scrollView.contentSize = contentSize;
        }
    }
    
    func offsetForItemAtIndex(index:Int) -> CGFloat {
        
        //calculate relative position
        var offset = CGFloat(index) - scrollOffset
        if (wrapEnabled) {
            if (alignment == SwipeViewAlignment.Center) {
                if (offset > CGFloat(numberOfItems)/2.0) {
                    offset -= CGFloat(numberOfItems)
                }
                else if (offset < -CGFloat(numberOfItems)/2.0) {
                    offset += CGFloat(numberOfItems)
                }
            } else {
                let width = vertical ? self.bounds.size.height : self.bounds.size.width
                let x = vertical ? scrollView.frame.origin.y : scrollView.frame.origin.x
                let itemWidth = vertical ? itemSize.height : itemSize.width
                if (offset * itemWidth + x > width) {
                    offset -= CGFloat(numberOfItems)
                }
                else if (offset * itemWidth + x < -itemWidth) {
                    offset += CGFloat(numberOfItems)
                }
            }
        }
        return offset;
    }
    
    func setFrameForView(view: UIView, atIndex index:Int) {
        
        if ((self.window) != nil) {
            var center = view.center
            if (vertical) {
                center.y = (offsetForItemAtIndex(index: index) + 0.5) * itemSize.height + scrollView.contentOffset.y;
            } else {
                center.x = (offsetForItemAtIndex(index: index) + 0.5) * itemSize.width + scrollView.contentOffset.x;
            }
            
            let disableAnimation = !center.equalTo(view.center)
            let animationEnabled = UIView.areAnimationsEnabled
            if (disableAnimation && animationEnabled) {
                UIView.setAnimationsEnabled(false)
            }
            if (vertical) {
                view.center = CGPoint(x: scrollView.frame.size.width/2.0, y: center.y)
            } else {
                view.center = CGPoint(x: center.x, y: scrollView.frame.size.height/2.0)
            }
            
            view.bounds = CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height)
            
            if (disableAnimation && animationEnabled) {
                UIView.setAnimationsEnabled(true)
            }
        }
    }
    
    func layOutItemViews()  {
        let visibleViews = self.visibleItemViews()
        for view in visibleViews {
            if let theIndex = self.indexOfItemView(view: view) {
                setFrameForView(view: view, atIndex:theIndex)
            }
        }
    }
    
    func updateLayout() {
        updateScrollOffset()
        loadUnloadViews()
        layOutItemViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateItemSizeAndCount()
        updateScrollViewDimensions()
        updateLayout()
        if pagingEnabled && !scrolling {
            //scrollToItemAtIndex(index: self.currentItemIndex, duration:0.25)
            scrollToItemAtIndex(index: self.currentItemIndex, duration:SwipeView.defaultScrollDuration)
        }
    }
    
    //MARK: - View queing
    
    func queueItemView(view: UIView) {
        itemViewPool?.append(view)
    }
    
    func dequeueItemView() -> UIView? {
        if itemViewPool == nil {
            return nil
        }
        if itemViewPool!.count <= 0 {
            return nil
        }
        let view = itemViewPool!.removeLast()
        return view;
    }
    
    //MARK: - Scrolling
    
    func didScroll() {
        //handle wrap
        updateScrollOffset()
        
        //update view
        layOutItemViews()
        delegate?.swipeViewDidScroll?(swipeView: self)
        
        if (!defersItemViewLoading || (abs(minScrollDistanceFromOffset(fromOffset: lastUpdateOffset, toOffset:scrollOffset)) >= 1.0)) {
            //update item index
            currentItemIndex = clampedIndex(index: Int(roundf(Float(scrollOffset))))
            
            //load views
            lastUpdateOffset = CGFloat(currentItemIndex)
            loadUnloadViews()
            
            //send index update event
            if (previousItemIndex != currentItemIndex) {
                previousItemIndex = currentItemIndex
                delegate?.swipeViewCurrentItemIndexDidChange?(swipeView: self)
            }
        }
    }
    
    func easeInOut(time: CGFloat) -> CGFloat {
        return (time < 0.5) ? 0.5 * pow(time * 2.0, 3.0) : 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0
    }
    
    @objc func step() {
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        var delta = CGFloat(lastTime - currentTime)
        self.lastTime = currentTime
        
        if (scrolling) {
            let time = CGFloat(fmin(1.0, (currentTime - startTime) / scrollDuration))
            delta = easeInOut(time: time)
            scrollOffset = clampedOffset(offset: startOffset + (endOffset - startOffset) * delta)
            if (vertical) {
                setContentOffsetWithoutEvent(contentOffset: CGPoint(x: 0.0, y: scrollOffset * itemSize.height))
            } else {
                setContentOffsetWithoutEvent(contentOffset: CGPoint(x: scrollOffset * itemSize.width, y: 0.0))
            }
            didScroll()
            if (time >= 1.0) {
            //if abs(time - CGFloat(self.scrollDuration)) < 0.001  {
                scrolling = false
                didScroll()
                delegate?.swipeViewDidEndScrollingAnimation?(swipeView: self)
            }
        } else if (autoscroll != 0.0) {
            if (!scrollView.isDragging) {
                self.setScrollOffset(scrollOffset: clampedOffset(offset: scrollOffset + delta * autoscroll))
            }
        } else {
            stopAnimation()
        }
    }
    
    func startAnimation() {
        if (timer == nil) {
            self.timer = Timer(timeInterval: 1.0/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode:RunLoop.Mode.default)
            RunLoop.main.add(timer!, forMode:RunLoop.Mode.tracking)
        }
    }
    
    func stopAnimation() {
        if timer != nil {
            timer!.invalidate()
            self.timer = nil;
        }
    }
    
    func clampedIndex(index: Int) -> Int {
        if (wrapEnabled) {
            if numberOfItems != 0 {
                return index - Int(CGFloat(floor(CGFloat(index) / CGFloat(numberOfItems))) * CGFloat(numberOfItems))
            } else {
                return 0
            }
        } else {
            return min(max(0, index), max(0, numberOfItems - 1))
        }
    }
    
    func clampedOffset(offset: CGFloat) -> CGFloat {
        var returnValue = CGFloat(0)
        if (wrapEnabled) {
            if numberOfItems != 0 {
                returnValue =  (offset - floor(offset / CGFloat(numberOfItems)) * CGFloat(numberOfItems))
            } else {
                returnValue = 0.0
            }
        } else {
            returnValue = fmin(fmax(0.0, offset), fmax(0.0, CGFloat(numberOfItems) - 1.0))
        }
        return returnValue;
    }
    
    func setContentOffsetWithoutEvent(contentOffset:CGPoint) {
        
        if (!scrollView.contentOffset.equalTo(contentOffset))
        {
            let animationEnabled = UIView.areAnimationsEnabled
            if (animationEnabled) {
                UIView.setAnimationsEnabled(false)
            }
            suppressScrollEvent = true
            scrollView.contentOffset = contentOffset
            suppressScrollEvent = false
            if (animationEnabled) {
                UIView.setAnimationsEnabled(true)
            }
        }
    }
    
    func currentPage() -> Int {
        if (itemsPerPage > 1
            && truncateFinalPage
            && !wrapEnabled
            && currentItemIndex > (numberOfItems / itemsPerPage - 1) * itemsPerPage) {
            return numberOfPages - 1
        }
        return Int(round(Double(currentItemIndex) / Double(itemsPerPage)))
    }
    
    
    func minScrollDistanceFromIndex(fromIndex: Int, toIndex:Int) -> Int {
        let directDistance = toIndex - fromIndex
        if (wrapEnabled) {
            var wrappedDistance = min(toIndex, fromIndex) + numberOfItems - max(toIndex, fromIndex)
            if (fromIndex < toIndex) {
                wrappedDistance = -wrappedDistance
            }
            return (abs(directDistance) <= abs(wrappedDistance)) ? directDistance : wrappedDistance
        }
        return directDistance;
    }
    
    func minScrollDistanceFromOffset(fromOffset:CGFloat, toOffset:CGFloat) -> CGFloat {
        let directDistance = toOffset - fromOffset
        if (wrapEnabled) {
            var wrappedDistance = min(toOffset, fromOffset) + CGFloat(numberOfItems) - max(toOffset, fromOffset)
            if (fromOffset < toOffset) {
                wrappedDistance = -wrappedDistance
            }
            return (abs(directDistance) <= abs(wrappedDistance)) ? directDistance : wrappedDistance
        }
        return directDistance;
    }
    
    func setCurrentItemIndex(currentItemIndex: Int) {
        self.currentItemIndex = currentItemIndex
        setScrollOffset(scrollOffset: CGFloat(currentItemIndex))
    }
    
    func setCurrentPage(currentPage: Int) {
        if (currentPage * itemsPerPage != currentItemIndex) {
            //scrollToPage(page: currentPage, duration:0.0)
            scrollToPage(page: currentPage, duration:SwipeView.defaultScrollDuration)
        }
    }
    
    func setScrollOffset(scrollOffset:CGFloat) {
        if (abs(self.scrollOffset - scrollOffset) > 0.0001) {
            self.scrollOffset = scrollOffset
            lastUpdateOffset = self.scrollOffset - 1.0; //force refresh
            scrolling = false; //stop scrolling
            updateItemSizeAndCount()
            updateScrollViewDimensions()
            updateLayout()
            let contentOffset = vertical
                ? CGPoint(x: 0.0, y: clampedOffset(offset: scrollOffset) * itemSize.height)
                : CGPoint(x: clampedOffset(offset: scrollOffset) * itemSize.width, y: 0.0)
            setContentOffsetWithoutEvent(contentOffset: contentOffset)
            didScroll()
        }
    }
    
    func scrollByOffset(offset: CGFloat, duration:TimeInterval) {
        if (duration > 0.0) {
            scrolling = true
            startTime = NSDate.timeIntervalSinceReferenceDate
            startOffset = scrollOffset
            scrollDuration = duration
            endOffset = startOffset + offset
            if (!wrapEnabled) {
                endOffset = clampedOffset(offset: endOffset)
            }
            startAnimation()
        } else {
            self.setScrollOffset(scrollOffset: self.scrollOffset + offset)
        }
    }
    
    func scrollToOffset(offset: CGFloat, duration:TimeInterval) {
        scrollByOffset(offset: minScrollDistanceFromOffset(fromOffset: scrollOffset, toOffset:offset), duration:duration)
    }
    
    func scrollByNumberOfItems(itemCount: Int, duration:TimeInterval) {
        if (duration > 0.0) {
            var offset = Float(0.0)
            if (itemCount > 0) {
                offset = floorf(Float(scrollOffset)) + Float(itemCount) - Float(scrollOffset)
            } else if (itemCount < 0) {
                offset = ceilf(Float(scrollOffset)) + Float(itemCount) - Float(scrollOffset)
            } else {
                offset = roundf(Float(scrollOffset)) - Float(scrollOffset)
            }
            scrollByOffset(offset: CGFloat(offset), duration:duration)
        } else {
            self.setScrollOffset(scrollOffset: CGFloat(clampedIndex(index: previousItemIndex + itemCount)))
        }
    }
    
    
    func scrollToItemAtIndex(index:Int, duration:TimeInterval) {
        scrollToOffset(offset: CGFloat(index), duration:duration)
    }
    
    func scrollToPage(page: Int, duration:TimeInterval) {
        var index = page * itemsPerPage
        if (truncateFinalPage) {
            index = min(index, numberOfItems - itemsPerPage)
        }
        scrollToItemAtIndex(index: index, duration:duration)
    }
    
    //MARK: - View loading
    
    func loadViewAtIndex(index: Int) -> UIView {
        
        var view = dataSource?.viewForItemAtIndex(index: index, swipeView: self, reusingView: dequeueItemView())
        if (view == nil) {
            view = UIView()
        }
        
        let oldView = itemViewAtIndex(index: index)
        if (oldView != nil) {
            queueItemView(view: oldView!)
            oldView!.removeFromSuperview()
        }
        
        setItemView(view: view!, forIndex:index)
        setFrameForView(view: view!, atIndex:index)
        view!.isUserInteractionEnabled = true
        scrollView.addSubview(view!)
        
        return view!;
    }
    
    func updateItemSizeAndCount() {
        guard dataSource != nil else {
            numberOfItems = 0
            itemSize.width = 1
            itemSize.height = 1
            return
        }
        
        //get number of items
        numberOfItems = (dataSource?.numberOfItemsInSwipeView(swipeView: self))!
        
        //get item size
        if let size = delegate?.swipeViewItemSize?(swipeView: self) {
            
            if (!size.equalTo(CGSize.zero)) {
                itemSize = size
            } else if (numberOfItems > 0) {
                if self.visibleItemViews().count <= 0 {
                    let view = dataSource?.viewForItemAtIndex(index: 0, swipeView: self, reusingView: dequeueItemView())
                    itemSize = view!.frame.size
                }
            }
            
            //prevent crashes
            if (itemSize.width < 0.0001) { itemSize.width = 1 }
            if (itemSize.height < 0.0001) { itemSize.height = 1 }
        }
    }
    
    func loadUnloadViews() {
        
        //check that item size is known
        let itemWidth = vertical ? itemSize.height : itemSize.width
        if (itemWidth != 0) {
            //calculate offset and bounds
            let width = vertical ? self.bounds.size.height : self.bounds.size.width
            let x = vertical ? scrollView.frame.origin.y : scrollView.frame.origin.x
            
            //calculate range
            let startOffset = clampedOffset(offset: scrollOffset - x / itemWidth)
            var startIndex = Int(floor(startOffset))
            var numberOfVisibleItems = Int(ceil(width / itemWidth + (startOffset - CGFloat(startIndex))))
            if (defersItemViewLoading) {
                startIndex = currentItemIndex - Int(ceil(x / itemWidth)) - 1
                numberOfVisibleItems = Int(ceil(width / itemWidth) + 3)
            }
            
            //create indices
            numberOfVisibleItems = min(numberOfVisibleItems, numberOfItems)
            var visibleIndices = [Int]()
            
            //for (var i = 0; i < numberOfVisibleItems; i++) {
            if numberOfVisibleItems > 0 {
                for i in 0...(numberOfVisibleItems-1) {
                    let index = clampedIndex(index: i + startIndex)
                    visibleIndices.append(index)
                }
            }
            
            //remove offscreen views
            //for number in itemViews!.keys.array {
            for number in itemViews!.keys {
                if (!visibleIndices.contains(number)) {
                    if (itemViews != nil) {
                        let view = itemViews![number]
                        if (view != nil) {
                            queueItemView(view: view!)
                            view!.removeFromSuperview()
                            //itemViews!.removeValueForKey(number)
                           itemViews?.removeValue(forKey: number)
                        }
                    }
                }
            }
            
            //add onscreen views
            for number in visibleIndices {
                let view = itemViews![number]
                if (view == nil) {
                    loadViewAtIndex(index: number)
                }
            }
        }
    }
    
    func reloadItemAtIndex(index:Int) {
        //if view is visible
        if (itemViewAtIndex(index: index) != nil) {
            //reload view
            loadViewAtIndex(index: index)
        }
    }
    
    func reloadData() {
        //remove old views
        for view in self.visibleItemViews() {
            view.removeFromSuperview()
        }
        
        //reset view pools
        itemViews = Dictionary(minimumCapacity: 4)
        itemViewPool = Array()
        
        //get number of items
        updateItemSizeAndCount()
        
        //layout views
        setNeedsLayout()
        
        //fix scroll offset
        if (numberOfItems > 0 && scrollOffset < 0.0) {
            self.setScrollOffset(scrollOffset: 0)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        var view = super.hitTest(point, with:event)
        if (view == nil) {
            return view
        }
        if (view!.isEqual(self)) {
            for subview in scrollView.subviews {
                let offset = CGPoint(x: point.x - scrollView.frame.origin.x + scrollView.contentOffset.x - subview.frame.origin.x,
                                     y: point.y - scrollView.frame.origin.y + scrollView.contentOffset.y - subview.frame.origin.y);
                view = subview.hitTest(offset, with:event)
                if (view != nil)
                {
                    return view;
                }
            }
            return scrollView;
        }
        return view;
    }
    
    override func didMoveToSuperview() {
        if (self.superview != nil) {
            self.setNeedsLayout()
            if scrolling {
                startAnimation()
            }
        } else {
            stopAnimation()
        }
    }
    
    //MARK: - Gestures and taps
    
    func viewOrSuperviewIndex(view: UIView) -> Int? {
        
        if (view == scrollView) {
            return nil
        }
        let index = self.indexOfItemView(view: view)
        if (index == nil)
        {
            if (view.superview == nil) {
                return nil
            }
            return viewOrSuperviewIndex(view: view.superview!)
        }
        return index;
    }
    
    func viewOrSuperviewHandlesTouches(view:UIView) -> Bool {
        // This implementation is pretty different from the original, because many of the class-exposure methods are not present in Swift.  The original seems needlessly complex, checking all the superclasses of the view as well.

        //if view.respondsToSelector(Selector("touchesBegan:withEvent:")) {
        if view.responds(to: #selector(touchesBegan(_:with:))) {
            return true
        } else {
            if let theSuperView = view.superview {
                return self.viewOrSuperviewHandlesTouches(view: theSuperView)
            } else {
                // there's no superview to check, so nothing in the hierarchy can respond.
                return false
            }
        }
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldReceive touch:UITouch) -> Bool {
        if (gesture is UITapGestureRecognizer) {
            //handle tap
            let index = viewOrSuperviewIndex(view: touch.view!)
            if (index != nil) {
                var delegateExistsAndDeclinesSelection = false
                if (delegate != nil) {
                    if let delegateWantsItemSelection = delegate!.shouldSelectItemAtIndex?(index: index!, swipeView: self) {
                        // delegate is valid and responded to the shouldSelectItemAtIndex selector
                        delegateExistsAndDeclinesSelection = !delegateWantsItemSelection
                    }
                }
                
                // if the delegate wants the touch, then let it have it...
                if !delegateExistsAndDeclinesSelection {
                    return true
                }
                
                if delegateExistsAndDeclinesSelection || self.viewOrSuperviewHandlesTouches(view: touch.view!) {
                    return false
                } else {
                    return true
                }
            }
        }
        return false
    }
    
    @objc func didTap (tapGesture: UITapGestureRecognizer) {
        let point = tapGesture.location(in: scrollView)
        var index = Int(vertical ? (point.y / (itemSize.height)) : (point.x / (itemSize.width)))
        if (wrapEnabled) {
            index = index % numberOfItems
        }
        if (index >= 0 && index < numberOfItems) {
            delegate?.didSelectItemAtIndex?(index: index, swipeView: self)
        }
    }
    
    //MARK: - UIScrollViewDelegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!suppressScrollEvent) {
            //stop scrolling animation
            scrolling = false
            
            //update scrollOffset
            let delta = vertical ? (scrollView.contentOffset.y - previousContentOffset.y) : (scrollView.contentOffset.x - previousContentOffset.x)
            previousContentOffset = scrollView.contentOffset
            scrollOffset += delta / (vertical ? itemSize.height : itemSize.width)
            
            //update view and call delegate
            didScroll()
        } else {
            previousContentOffset = scrollView.contentOffset
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.swipeViewWillBeginDragging?(swipeView: self)
        
        //force refresh
        lastUpdateOffset = self.scrollOffset - 1.0
        didScroll()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate:Bool) {
        if (!decelerate) {
            //force refresh
            lastUpdateOffset = self.scrollOffset - 1.0
            didScroll()
        }
        delegate?.swipeViewDidEndDragging?(swipeView: self, willDecelerate:decelerate)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        delegate?.swipeViewWillBeginDecelerating?(swipeView: self)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //prevent rounding errors from accumulating
        let integerOffset = CGFloat(round(scrollOffset))
        if (abs(scrollOffset - integerOffset) < 0.01) {
            scrollOffset = integerOffset
        }
        
        //force refresh
        lastUpdateOffset = self.scrollOffset - 1.0
        didScroll()
        
        delegate?.swipeViewDidEndDecelerating?(swipeView: self)
    }

}
