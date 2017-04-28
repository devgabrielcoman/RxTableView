import UIKit
import RxSwift
import RxCocoa

public class RxCollectionView: NSObject,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UIScrollViewDelegate {
    
    private let kDEFAULT_REUSE_ID: String = "RxCollectionView_ID"
    private let kDEFAULT_CELL_SIZE: CGSize = CGSize(width: 50, height: 50)
    private let kDEFAULT_EDGE_INSETS: UIEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
    
    private var edgeIndsets: UIEdgeInsets?
    private var cellSize: CGSize?
    
    private var data: [Any] = []
    
    private var modelToRow: [String : RxCell] = [:]
    private var clicks: [String : (IndexPath, Any) -> Void] = [:]
    private var reachEnd: (() -> Void)?
    
    private var collectionView: UICollectionView?
    
    override init () {
        // do nothing
    }
    
    init (collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
    public static func create() -> RxCollectionView {
        return RxCollectionView()
    }
    
    public func bind (toCollection collection: UICollectionView) -> RxCollectionView {
        self.collectionView = collection
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Set Cell Size
    ////////////////////////////////////////////////////////////////////////////
    
    public func set(cellSize size: CGSize) -> RxCollectionView {
        self.cellSize = size
        return self
    }
    
    public func set(cellWidth width: Int, andHeight height: Int) -> RxCollectionView {
        self.cellSize = CGSize(width: width, height: height)
        return self
    }
    
    public func set(edgeInsets insets: UIEdgeInsets) -> RxCollectionView {
        self.edgeIndsets = insets
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Customize Row
    ////////////////////////////////////////////////////////////////////////////
    
    public func customise <Cell: UICollectionViewCell, Model> (cellForReuseIdentifier identifier: String,
                           _ callback: @escaping (IndexPath, Cell, Model) -> Void) -> RxCollectionView {
        
        return customise(cellForReuseIdentifier: identifier,
                         withNibName: nil,
                         andType: Cell.self,
                         representedByModelOfType: Model.self,
                         customisedBy: callback)
    }
    
    public func customise <Cell: UICollectionViewCell, Model> (cellForReuseIdentifier identifier: String,
                                                               withNibName nibName: String,
                                                               _ callback: @escaping (IndexPath, Cell, Model) -> Void) -> RxCollectionView {
        
        return customise(cellForReuseIdentifier: identifier,
                         withNibName: nibName,
                         andType: Cell.self,
                         representedByModelOfType: Model.self,
                         customisedBy: callback)
    }
    
    private func customise <Cell: UICollectionViewCell, Model> (cellForReuseIdentifier identifier: String,
                                                                withNibName nibName: String?,
                                                                andType cellType: Cell.Type,
                                                                representedByModelOfType modelType: Model.Type,
                                                                customisedBy callback: @escaping (IndexPath, Cell, Model) -> Void) -> RxCollectionView {
        
        if let nib = nibName {
            collectionView?.register(UINib(nibName: nib, bundle: nil), forCellWithReuseIdentifier: identifier)
        }
        
        var row = RxCell()
        row.identifier = identifier
        row.customise = { i, cell, model in
            if let c = cell as? Cell, let m = model as? Model  {
                callback (i, c, m)
            }
        }
        
        let key = String(describing: modelType)
        modelToRow[key] = row
        
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // On Methods
    ////////////////////////////////////////////////////////////////////////////
    
    public func did <Model> (clickOnCellWithReuseIdentifier identifier: String,
                             _ action: @escaping (IndexPath, Model) -> Void) -> RxCollectionView {
        
        let key = String(describing: Model.self)
        clicks[key] = { index, model in
            if let m = model as? Model {
                action (index, m)
            }
        }
        
        return self
    }
    
    public func did (reachEnd action: @escaping () -> Void) -> RxCollectionView {
        reachEnd = action
        return self
    }

    
    ////////////////////////////////////////////////////////////////////////////
    // Final Update method
    ////////////////////////////////////////////////////////////////////////////
    
    public func update (withData data: [Any])  {
    
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        self.data = data.filter { element -> Bool in
            let key = String(describing: type(of: element))
            return self.modelToRow[key] != nil
        }
        
        self.collectionView?.reloadData()
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Collection View Delegate
    ////////////////////////////////////////////////////////////////////////////
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = data[indexPath.row]
        let key = String(describing: type(of: item))
        let row = modelToRow [key]
        
        let cellId = row?.identifier ?? kDEFAULT_REUSE_ID
        let customise = row?.customise
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
        customise? (indexPath, cell, item)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize ?? kDEFAULT_CELL_SIZE
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = data[indexPath.row]
        let key = String(describing: type(of: item))
        let click = clicks[key]
        
        click? (indexPath, item)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return edgeIndsets ?? kDEFAULT_EDGE_INSETS
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x,
            offsetY = scrollView.contentOffset.y
        let contentWidth = scrollView.contentSize.width,
            contentHeight = scrollView.contentSize.height
        let diffX = contentWidth - scrollView.frame.size.width,
            diffY = contentHeight - scrollView.frame.size.height
        
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            
            let direction = layout.scrollDirection
            
            if direction == .horizontal && offsetX >= diffX {
                reachEnd?()
            }
            if direction == .vertical && offsetY >= diffY {
                reachEnd?()
            }
        }
    }
}

private struct RxCell  {
    var identifier: String?
    var customise: ((IndexPath, UICollectionViewCell, Any) -> Void)?
}
