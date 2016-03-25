// SwiftGridView.swift
// Copyright (c) 2016 Nathan Lampi (http://nathanlampi.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import UIKit


/**
 Swift Grid View Index Path
 */
public extension NSIndexPath {
    /**
        Init Swift Grid View Index Path
     
        - Parameter row: Row for the data grid
        - Parameter column: Column for the data grid
        - Paramter section: Section for the data grid
    */
    convenience init(forSGRow row: Int, atColumn column: Int, inSection section: Int) {
        let indexes: [Int] = [section, column, row]
        
        self.init(indexes: indexes, length: indexes.count)
    }
    
    /// Swift Grid View Section
    var sgSection: Int { get {
        
            return self.indexAtPosition(0)
        }
    }
    
    /// Swift Grid View Row
    var sgRow: Int { get {
        
            return self.indexAtPosition(2)
        }
    }
    
    /// Swift Grid View Column
    var sgColumn: Int { get {
        
            return self.indexAtPosition(1)
        }
    }
}

public let SwiftGridElementKindHeader: String = "SwiftGridElementKindHeader"
public let SwiftGridElementKindSectionHeader: String = UICollectionElementKindSectionHeader
public let SwiftGridElementKindFooter: String = "SwiftGridElementKindFooter"
public let SwiftGridElementKindSectionFooter: String = UICollectionElementKindSectionFooter


@objc public protocol SwiftGridViewDataSource {
    func numberOfSectionsInDataGridView(dataGridView: SwiftGridView) -> Int
    func numberOfColumnsInDataGridView(dataGridView: SwiftGridView) -> Int
    func dataGridView(dataGridView: SwiftGridView, numberOfRowsInSection section: Int) -> Int
    
    /// Cell that is returned must be dequeued and of Swift Grid Cell type
    func dataGridView(dataGridView: SwiftGridView, cellAtIndexPath indexPath: NSIndexPath) -> SwiftGridCell
    
    /// Provide the number of columns which will be frozen and not scroll horizontally out of view.
    optional func numberOfFrozenColumnsInDataGridView(dataGridView: SwiftGridView) -> Int
    
    // Grid Header
    optional func dataGridView(dataGridView: SwiftGridView, gridHeaderViewForColumn column: NSInteger) -> SwiftGridReusableView
    
    // Grid Footer
    optional func dataGridView(dataGridView: SwiftGridView, gridFooterViewForColumn column: NSInteger) -> SwiftGridReusableView
    
    // Section Header
    optional func dataGridView(dataGridView: SwiftGridView, sectionHeaderCellAtIndexPath indexPath: NSIndexPath) -> SwiftGridReusableView
    
    // Section Footer
    optional func dataGridView(dataGridView: SwiftGridView, sectionFooterCellAtIndexPath indexPath: NSIndexPath) -> SwiftGridReusableView
}


@objc public protocol SwiftGridViewDelegate {
    // Grid Row and Column Sizing
    func dataGridView(dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat
    func dataGridView(dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    
    // Grid Header
    optional func heightForGridHeaderInDataGridView(dataGridView: SwiftGridView) -> CGFloat
    optional func dataGridView(dataGridView: SwiftGridView, didSelectHeaderAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectHeaderAtIndexPath indexPath: NSIndexPath)
    
    // Grid Footer
    optional func heightForGridFooterInDataGridView(dataGridView: SwiftGridView) -> CGFloat
    optional func dataGridView(dataGridView: SwiftGridView, didSelectFooterAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectFooterAtIndexPath indexPath: NSIndexPath)
    
    // Section Header
    optional func dataGridView(dataGridView: SwiftGridView, heightOfHeaderInSection section: Int) -> CGFloat
    optional func dataGridView(dataGridView: SwiftGridView, didSelectSectionHeaderAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectSectionHeaderAtIndexPath indexPath: NSIndexPath)
    
    // Section Footer
    optional func dataGridView(dataGridView: SwiftGridView, heightOfFooterInSection section: Int) -> CGFloat
    optional func dataGridView(dataGridView: SwiftGridView, didSelectSectionFooterAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectSectionFooterAtIndexPath indexPath: NSIndexPath)
    
    // Cell selection
    optional func dataGridView(dataGridView: SwiftGridView, didSelectCellAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectCellAtIndexPath indexPath: NSIndexPath)
}


public class SwiftGridView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, SwiftGridLayoutDelegate, SwiftGridReusableViewDelegate {
    
    // MARK: - Init
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initDefaults()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initDefaults()
    }
    
    private func initDefaults() {
        sgCollectionViewLayout = SwiftGridLayout()
        
        // FIXME: Use constraints!?
        self.sgCollectionView = UICollectionView(frame: self.bounds, collectionViewLayout: sgCollectionViewLayout)
        self.sgCollectionView.dataSource = self // TODO: Separate DataSource/Delegate?
        self.sgCollectionView.delegate = self
        self.sgCollectionView.backgroundColor = UIColor.whiteColor()
        self.sgCollectionView.allowsMultipleSelection = true
        
        self.addSubview(self.sgCollectionView)
    }
    
    
    // MARK: - Public Variables
    
    public weak var dataSource: SwiftGridViewDataSource?
    public weak var delegate: SwiftGridViewDelegate?
    
    public var allowsSelection: Bool {
        set(allowsSelection) {
            self.sgCollectionView.allowsSelection = allowsSelection
        }
        get {
            return self.sgCollectionView.allowsSelection
        }
    }
    
    private var _allowsMultipleSelection: Bool = false
    public var allowsMultipleSelection: Bool {
        set(allowsMultipleSelection) {
            _allowsMultipleSelection = allowsMultipleSelection
        }
        get {
            return _allowsMultipleSelection
        }
    }
    
    private var _rowSelectionEnabled: Bool = false
    public var rowSelectionEnabled: Bool {
        set(rowSelectionEnabled) {
            _rowSelectionEnabled = rowSelectionEnabled
        }
        get {
            return _rowSelectionEnabled
        }
    }
    
    public var bounces: Bool {
        set(bounces) {
            self.sgCollectionView.bounces = bounces
        }
        get {
            return self.sgCollectionView.bounces
        }
    }
    
    /// Determines whether section headers will stick while scrolling vertically or scroll off screen.
    public var stickySectionHeaders: Bool {
        set(stickySectionHeaders) {
            self.sgCollectionViewLayout.stickySectionHeaders = stickySectionHeaders
        }
        get {
            return self.sgCollectionViewLayout.stickySectionHeaders
        }
    }
    
    public var alwaysBounceVertical: Bool {
        set(alwaysBounceVertical) {
            self.sgCollectionView.alwaysBounceVertical = alwaysBounceVertical
        }
        get {
            return self.sgCollectionView.alwaysBounceVertical
        }
    }
    
    public var alwaysBounceHorizontal: Bool {
        set(alwaysBounceHorizontal) {
            self.sgCollectionView.alwaysBounceHorizontal = alwaysBounceHorizontal
        }
        get {
            return self.sgCollectionView.alwaysBounceHorizontal
        }
    }
    
    public var showsHorizontalScrollIndicator: Bool {
        set(showsHorizontalScrollIndicator) {
            self.sgCollectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        }
        get {
            return self.sgCollectionView.showsHorizontalScrollIndicator
        }
    }
    
    public var showsVerticalScrollIndicator: Bool {
        set(showsVerticalScrollIndicator) {
            self.sgCollectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
        get {
            return self.sgCollectionView.showsVerticalScrollIndicator
        }
    }
    
    private var _pinchExpandEnabled: Bool = false
    
    /// Pinch to expand increases the size of the columns. Experimental feature.
    public var pinchExpandEnabled: Bool {
        set(pinchExpandEnabled) {
            if(_pinchExpandEnabled) {
                if(!pinchExpandEnabled) {
                    self.sgCollectionView.removeGestureRecognizer(self.sgPinchGestureRecognizer)
                    self.sgCollectionView.removeGestureRecognizer(self.sgTwoTapGestureRecognizer)
                }
            } else {
                self.sgCollectionView.addGestureRecognizer(self.sgPinchGestureRecognizer)
                self.sgTwoTapGestureRecognizer.numberOfTouchesRequired = 2
                self.sgCollectionView.addGestureRecognizer(self.sgTwoTapGestureRecognizer)
            }
            
            _pinchExpandEnabled = pinchExpandEnabled
        }
        get {
            return _pinchExpandEnabled
        }
    }
    
    
    // MARK: - Private Variables
    
    private var sgCollectionView: UICollectionView!
    private var sgCollectionViewLayout: SwiftGridLayout!
    private lazy var sgPinchGestureRecognizer:UIPinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(SwiftGridView.handlePinchGesture(_:)))
    private lazy var sgTwoTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(SwiftGridView.handleTwoFingerTapGesture(_:)))
    
    private var _sgSectionCount: Int = 0
    private var sgSectionCount: Int {
        get {
            if(_sgSectionCount == 0) {
                _sgSectionCount = self.dataSource!.numberOfSectionsInDataGridView(self)
            }
            
            return _sgSectionCount;
        }
    }
    
    private var _sgColumnCount: Int = 0
    private var sgColumnCount: Int {
        get {
            if(_sgColumnCount == 0) {
                _sgColumnCount = self.dataSource!.numberOfColumnsInDataGridView(self)
            }
            
            return _sgColumnCount;
        }
    }
    
    private var _sgColumnWidth: CGFloat = 0
    private var sgColumnWidth: CGFloat {
        get {
            if(_sgColumnWidth == 0) {
                
                for columnIndex in 0 ..< self.sgColumnCount {
                    _sgColumnWidth += self.delegate!.dataGridView(self, widthOfColumnAtIndex: columnIndex);
                }
            }
            
            return _sgColumnWidth;
        }
    }
    
    // Cache selected items.
    private var selectedHeaders: NSMutableDictionary = NSMutableDictionary()
    private var selectedSectionHeaders: NSMutableDictionary = NSMutableDictionary()
    private var selectedSectionFooters: NSMutableDictionary = NSMutableDictionary()
    private var selectedFooters: NSMutableDictionary = NSMutableDictionary()
    
    
    // MARK: - Layout Subviews
    
    // TODO: Is this how resize should be handled?
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if(self.sgCollectionView.frame != self.bounds) {
            self.sgCollectionView.frame = self.bounds
        }
    }
    
    
    // MARK: - Public Methods
    
    public func reloadData() {
        _sgSectionCount = 0
        _sgColumnCount = 0
        _sgColumnWidth = 0
        
        self.selectedHeaders = NSMutableDictionary()
        self.selectedSectionHeaders = NSMutableDictionary()
        self.selectedSectionFooters = NSMutableDictionary()
        self.selectedFooters = NSMutableDictionary()
        
        sgCollectionViewLayout.resetCachedParameters();
        
        self.sgCollectionView.reloadData()
    }
    
    public func reloadCellsAtIndexPaths(indexPaths: [NSIndexPath], animated: Bool) {
        self.reloadCellsAtIndexPaths(indexPaths, animated: animated, completion: nil)
    }
    
    public func reloadCellsAtIndexPaths(indexPaths: [NSIndexPath], animated: Bool, completion: ((Bool) -> Void)?) {
        let convertedPaths = self.reverseIndexPathConversionForIndexPaths(indexPaths)
        
        if(animated) {
            self.sgCollectionView.performBatchUpdates({
                self.sgCollectionView.reloadItemsAtIndexPaths(convertedPaths)
                }, completion: { completed in
                    completion?(completed)
            })
        } else {
            self.sgCollectionView.reloadItemsAtIndexPaths(convertedPaths)
            completion?(true) // TODO: Fix!
        }
        
    }
    
    // Doesn't work as intended.
//    public func reloadSupplementaryViewsOfKind(elementKind: String, atIndexPaths indexPaths: [NSIndexPath]) {
//        let convertedPaths = self.reverseIndexPathConversionForIndexPaths(indexPaths)
//        let context = UICollectionViewLayoutInvalidationContext()
//        context.invalidateSupplementaryElementsOfKind(elementKind, atIndexPaths: convertedPaths)
//            
//        self.sgCollectionViewLayout.invalidateLayoutWithContext(context)
//    }
    
    public func registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.sgCollectionView.registerClass(cellClass, forCellWithReuseIdentifier:identifier)
    }
    
    public func registerClass(viewClass: AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        self.sgCollectionView.registerClass(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
    }
    
    public func dequeueReusableCellWithReuseIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath!) -> SwiftGridCell {
        let revertedPath: NSIndexPath = self.reverseIndexPathConversion(indexPath)
        
        return self.sgCollectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: revertedPath) as! SwiftGridCell
    }
    
    public func dequeueReusableSupplementaryViewOfKind(elementKind: String, withReuseIdentifier identifier: String, atColumn column: NSInteger) -> SwiftGridReusableView {
        let revertedPath: NSIndexPath = NSIndexPath(forItem: column, inSection: 0);
        
        return self.sgCollectionView.dequeueReusableSupplementaryViewOfKind(elementKind, withReuseIdentifier: identifier, forIndexPath: revertedPath) as! SwiftGridReusableView
    }
    
    public func dequeueReusableSupplementaryViewOfKind(elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: NSIndexPath) -> SwiftGridReusableView {
        let revertedPath: NSIndexPath = self.reverseIndexPathConversion(indexPath);
        
        return self.sgCollectionView.dequeueReusableSupplementaryViewOfKind(elementKind, withReuseIdentifier: identifier, forIndexPath: revertedPath) as! SwiftGridReusableView
    }
    
    public func selectCellAtIndexPath(indexPath:NSIndexPath, animated: Bool) {
        if(self.rowSelectionEnabled) {
            self.selectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            self.sgCollectionView.selectItemAtIndexPath(convertedPath, animated: animated, scrollPosition: UICollectionViewScrollPosition.None)
        }
    }
    
    public func deselectCellAtIndexPath(indexPath:NSIndexPath, animated: Bool) {
        
        if(self.rowSelectionEnabled) {
            self.deselectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            self.sgCollectionView.deselectItemAtIndexPath(convertedPath, animated: animated)
        }
    }
    
    public func selectSectionHeaderAtIndexPath(indexPath:NSIndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: true)
        } else {
            self.selectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    public func deselectSectionHeaderAtIndexPath(indexPath:NSIndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: false)
        } else {
            self.deselectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    public func selectSectionFooterAtIndexPath(indexPath:NSIndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: true)
        } else {
            self.selectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    public func deselectSectionFooterAtIndexPath(indexPath:NSIndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: false)
        } else {
            self.deselectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    public func scrollToCellAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        let convertedPath = self.reverseIndexPathConversion(indexPath)
        
        self.sgCollectionView.scrollToItemAtIndexPath(convertedPath, atScrollPosition: scrollPosition, animated: animated)
    }
    
    
    // MARK: - Private Pinch Recognizer
    
    internal func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        if (recognizer.numberOfTouches() != 2) {
            
            return
        }
        
        if (recognizer.scale > 0.35 && recognizer.scale < 5) {
            
            self.sgCollectionViewLayout.zoomScale = recognizer.scale
        }
    }
    
    internal func handleTwoFingerTapGesture(recognizer: UITapGestureRecognizer) {
        
        if(self.sgCollectionViewLayout.zoomScale != 1.0) {
            self.sgCollectionViewLayout.zoomScale = 1.0
        }
    }
    
    
    // MARK: - Private conversion Methods
    
    private func convertCVIndexPathToSGIndexPath(indexPath: NSIndexPath) -> NSIndexPath {
        let row: Int = indexPath.row / self.sgColumnCount
        let column: Int = indexPath.row % self.sgColumnCount
        
        let convertedPath: NSIndexPath = NSIndexPath(forSGRow: row, atColumn: column, inSection: indexPath.section)
        
        return convertedPath
    }
    
    private func reverseIndexPathConversion(indexPath: NSIndexPath) -> NSIndexPath {
        let item: Int = indexPath.sgRow * self.sgColumnCount + indexPath.sgColumn
        let revertedPath: NSIndexPath = NSIndexPath(forItem: item, inSection: indexPath.sgSection)
        
        return revertedPath
    }
    
    private func reverseIndexPathConversionForIndexPaths(indexPaths: [NSIndexPath]) -> [NSIndexPath] {
        let convertedPaths = NSMutableArray()
        
        for indexPath in indexPaths {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            convertedPaths.addObject(convertedPath)
        }
        
        return convertedPaths.copy() as! [NSIndexPath]
    }
    
    private func numberOfRowsInSection(section: Int) -> Int {
        
        return self.dataSource!.dataGridView(self, numberOfRowsInSection: section)
    }
    
    
    // MARK: - SwiftGridReusableViewDelegate Methods
    
    public func swiftGridReusableView(reusableView: SwiftGridReusableView, didSelectViewAtIndexPath indexPath: NSIndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: true)
            }
            
            self.delegate?.dataGridView?(self, didSelectSectionHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: true)
            }
            
            self.delegate?.dataGridView?(self, didSelectSectionFooterAtIndexPath: indexPath)
            break
        case SwiftGridElementKindHeader:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didSelectHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindFooter:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didSelectFooterAtIndexPath: indexPath)
            break
        default:
            break
        }
    }
    
    public func swiftGridReusableView(reusableView: SwiftGridReusableView, didDeselectViewAtIndexPath indexPath: NSIndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: false)
            }
            
            self.delegate?.dataGridView?(self, didDeselectSectionHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: false)
            }
            
            self.delegate?.dataGridView?(self, didDeselectSectionFooterAtIndexPath: indexPath)
            break
        case SwiftGridElementKindHeader:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didDeselectHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindFooter:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didDeselectFooterAtIndexPath: indexPath)
            break
        default:
            break
        }
    }
    
    public func swiftGridReusableView(reusableView: SwiftGridReusableView, didHighlightViewAtIndexPath indexPath: NSIndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            
            if(self.rowSelectionEnabled) {
                self.toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: true)
            }
            break
        case SwiftGridElementKindSectionFooter:
            
            if(self.rowSelectionEnabled) {
                self.toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: true)
            }
            break
        case SwiftGridElementKindHeader:
            break
        case SwiftGridElementKindFooter:
            break
        default:
            break
        }
    }
    
    public func swiftGridReusableView(reusableView: SwiftGridReusableView, didUnhighlightViewAtIndexPath indexPath: NSIndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            
            if(self.rowSelectionEnabled) {
                self.toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: false)
            }
            break
        case SwiftGridElementKindSectionFooter:
            
            if(self.rowSelectionEnabled) {
                self.toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: false)
            }
            break
        case SwiftGridElementKindHeader:
            break
        case SwiftGridElementKindFooter:
            break
        default:
            break
        }
    }
    
    private func toggleSelectedOnReusableViewRowOfKind(kind: String, atIndexPath indexPath: NSIndexPath, selected: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = NSIndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            
            if(selected) {
                self.selectReusableViewOfKind(kind, atIndexPath: sgPath)
            } else {
                self.deselectReusableViewOfKind(kind, atIndexPath: sgPath)
            }
            
            guard let reusableView = self.sgCollectionView.supplementaryViewForElementKind(kind, atIndexPath: itemPath) as? SwiftGridReusableView
                else {
                    continue;
            }
            
            reusableView.selected = selected
        }
    }
    
    private func selectReusableViewOfKind(kind: String, atIndexPath indexPath: NSIndexPath) {
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            self.selectedSectionHeaders[indexPath] = true
            break
        case SwiftGridElementKindSectionFooter:
            self.selectedSectionFooters[indexPath] = true
            break
        case SwiftGridElementKindHeader:
            self.selectedHeaders[indexPath] = true
            break
        case SwiftGridElementKindFooter:
            self.selectedFooters[indexPath] = true
            break
        default:
            break
        }
    }
    
    private func deselectReusableViewOfKind(kind: String, atIndexPath indexPath: NSIndexPath) {
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            self.selectedSectionHeaders.removeObjectForKey(indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.selectedSectionFooters.removeObjectForKey(indexPath)
            break
        case SwiftGridElementKindHeader:
            self.selectedHeaders.removeObjectForKey(indexPath)
            break
        case SwiftGridElementKindFooter:
            self.selectedFooters.removeObjectForKey(indexPath)
            break
        default:
            break
        }
    }
    
    private func toggleHighlightOnReusableViewRowOfKind(kind: String, atIndexPath indexPath: NSIndexPath, highlighted: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = NSIndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            guard let reusableView = self.sgCollectionView.supplementaryViewForElementKind(kind, atIndexPath: itemPath) as? SwiftGridReusableView
                else {
                    continue;
            }
            
            reusableView.highlighted = highlighted
        }
    }
    
    
    // MARK: - SwiftGridLayoutDelegate Methods
    
    internal func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let convertedPath: NSIndexPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        let colWidth: CGFloat = self.delegate!.dataGridView(self, widthOfColumnAtIndex: convertedPath.sgColumn)
        let rowHeight: CGFloat = self.delegate!.dataGridView(self, heightOfRowAtIndexPath: convertedPath)
        
        return CGSizeMake(colWidth, rowHeight)
    }
    
    internal func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForSupplementaryViewOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> CGSize {
        var colWidth: CGFloat = 0.0
        var rowHeight: CGFloat = 0
        
        if(indexPath.length != 0) {
            colWidth = self.delegate!.dataGridView(self, widthOfColumnAtIndex: indexPath.row)
        }
        
        switch(kind) {
        case SwiftGridElementKindHeader:
            let delegateHeight = self.delegate?.heightForGridHeaderInDataGridView?(self)
            
            if(delegateHeight > 0) {
                rowHeight = delegateHeight!
            }
            break;
        case SwiftGridElementKindFooter:
            let delegateHeight = self.delegate?.heightForGridFooterInDataGridView?(self)
            
            if(delegateHeight > 0) {
                rowHeight = delegateHeight!
            }
            break;
        case SwiftGridElementKindSectionHeader:
            let delegateHeight = self.delegate?.dataGridView?(self, heightOfHeaderInSection: indexPath.section)
            
            if(delegateHeight > 0) {
                rowHeight = delegateHeight!
            }
            break;
        case SwiftGridElementKindSectionFooter:
            let delegateHeight = self.delegate?.dataGridView?(self, heightOfFooterInSection: indexPath.section)
            
            if(delegateHeight > 0) {
                rowHeight = delegateHeight!
            }
            break;
        default:
            rowHeight = 0
            break;
        }
        
        return CGSizeMake(colWidth, rowHeight)
    }
    
    internal func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfRowsInSection sectionIndex: Int) -> Int {
        
        return self.numberOfRowsInSection(sectionIndex)
    }
    
    internal func collectionView(collectionView: UICollectionView, numberOfColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int {
        
        return self.sgColumnCount
    }
    
    internal func collectionView(collectionView: UICollectionView, numberOfFrozenColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int {
        
        if let frozenCount = self.dataSource?.numberOfFrozenColumnsInDataGridView?(self) {
            
            return frozenCount
        } else {
            
            return 0
        }
    }
    
    internal func collectionView(collectionView: UICollectionView, totalColumnWidthForLayout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
    
        return self.sgColumnWidth
    }
    
    internal func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {
        
        return self.delegate!.dataGridView(self, widthOfColumnAtIndex :columnIndex)
    }


    // MARK: - UICollectionView DataSource
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return self.sgSectionCount
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfCells: Int = self.sgColumnCount * self.numberOfRowsInSection(section)
        
        return numberOfCells
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.dataSource!.dataGridView(self, cellAtIndexPath: self.convertCVIndexPathToSGIndexPath(indexPath))
        
        return cell
    }
    
    // TODO: Make this more fail friendly?
    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableView: SwiftGridReusableView
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            reusableView = self.dataSource!.dataGridView!(self, sectionHeaderCellAtIndexPath: convertedPath)
            reusableView.selected = self.selectedSectionHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindSectionFooter:
            reusableView = self.dataSource!.dataGridView!(self, sectionFooterCellAtIndexPath: convertedPath)
            reusableView.selected = self.selectedSectionFooters[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindHeader:
            reusableView = self.dataSource!.dataGridView!(self, gridHeaderViewForColumn: convertedPath.sgColumn)
            reusableView.selected = self.selectedHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindFooter:
            reusableView = self.dataSource!.dataGridView!(self, gridFooterViewForColumn: convertedPath.sgColumn)
            reusableView.selected = self.selectedFooters[convertedPath] != nil ? true : false
            break
        default:
            reusableView = SwiftGridReusableView.init(frame:CGRectZero)
            break
        }
        
        reusableView.delegate = self
        reusableView.indexPath = convertedPath
        reusableView.elementKind = kind
        
        return reusableView
    }
    
    
    // MARK - UICollectionView Delegate
    
    private func selectRowAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = NSIndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.sgCollectionView.selectItemAtIndexPath(itemPath, animated: animated, scrollPosition: UICollectionViewScrollPosition.None)
        }
    }
    
    private func deselectRowAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = NSIndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.sgCollectionView.deselectItemAtIndexPath(itemPath, animated: animated)
        }
    }
    
    private func deselectAllItemsIgnoring(indexPath: NSIndexPath, animated: Bool) {
        for itemPath in self.sgCollectionView.indexPathsForSelectedItems() ?? [] {
            if(itemPath.item == indexPath.item) {
                continue
            }
            self.sgCollectionView.deselectItemAtIndexPath(itemPath, animated: animated)
        }
    }
    
    private func toggleHighlightOnRowAtIndexPath(indexPath: NSIndexPath, highlighted: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = NSIndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.sgCollectionView.cellForItemAtIndexPath(itemPath)?.highlighted = highlighted
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: true)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: false)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(!self.allowsMultipleSelection) {
            self.deselectAllItemsIgnoring(indexPath, animated: false)
        }
        
        if(self.rowSelectionEnabled) {
            self.selectRowAtIndexPath(convertedPath, animated: false)
        }
        
        self.delegate?.dataGridView?(self, didSelectCellAtIndexPath: convertedPath)
    }
    
    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.deselectRowAtIndexPath(convertedPath, animated: false)
        }
        
        self.delegate?.dataGridView?(self, didDeselectCellAtIndexPath: convertedPath)
    }
    
}