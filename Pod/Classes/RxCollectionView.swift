import UIKit
import RxSwift
import RxCocoa

public extension Observable {
    
    public func toCollectionView (withBag bag: DisposeBag) -> RxCollectionView {
        
        let rx = RxCollectionView.create()
        
        self.subscribe(onNext: { (element) in
            
            if let e = element as? [Any] {
                rx.initialData = e
                _ = rx.update()
            }
            
        }, onError: { (error) in
            
        }, onCompleted: { 
            
        }, onDisposed: {
            
        })
        .addDisposableTo(bag)
        
        return rx 
        
    }
    
}

public class RxCollectionView: NSObject,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UIScrollViewDelegate {
    
    private let kDEFAULT_REUSE_ID: String = "RxCollectionView_ID"
    private let kDEFAULT_CELL_SIZE: CGSize = CGSize(width: 50, height: 50)
    
    private var cellSize: CGSize?
    private var modelToRow: [String : RxCell] = [:]
    var initialData: [Any] = []
    private var data: [Any] = []
    
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
    
    public func cellSize(_ width: Int, _ height: Int) -> RxCollectionView {
        self.cellSize = CGSize(width: width, height: height)
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Customize Row
    ////////////////////////////////////////////////////////////////////////////
    
    public func customiseCell <Cell : UICollectionViewCell, Model> (forReuseIdentifier identifier: String,
                                                                    andNibName nibName: String,
                                                                    _ customise: @escaping (IndexPath, Cell, Model) -> Void ) -> RxCollectionView {
        
        return customiseCell(forReuseIdentifier: identifier,
                             andNibName: nibName,
                             andCellWithType: Cell.self,
                             representedByModelWithType: Model.self,
                             customise)
    }
    
    public func customiseCell <Cell: UICollectionViewCell, Model>  (forReuseIdentifier identifier: String,
                                                                    andNibName nibName: String,
                                                                    andCellWithType cellType: Cell.Type,
                                                                    representedByModelWithType modelType: Model.Type,
                                                                    _ customise: @escaping (IndexPath, Cell, Model) -> Void) -> RxCollectionView {
    
        collectionView?.register(UINib(nibName: nibName, bundle: nil), forCellWithReuseIdentifier: identifier)
        
        return customiseCell(forReuseIdentifier: identifier,
                             andCellWithType: cellType,
                             representedByModelWithType: modelType,
                             customise)
    }
    
    public func customiseCell <Cell : UICollectionViewCell, Model> (forReuseIdentifier identifier: String,
                                                                    _ customise: @escaping (IndexPath, Cell, Model) -> Void ) -> RxCollectionView {
        
        return customiseCell(forReuseIdentifier: identifier,
                             andCellWithType: Cell.self,
                             representedByModelWithType: Model.self,
                             customise)
    }
    
    public func customiseCell <Cell: UICollectionViewCell, Model>  (forReuseIdentifier identifier: String,
                                                                    andCellWithType cellType: Cell.Type,
                                                                    representedByModelWithType modelType: Model.Type,
                                                                    _ customise: @escaping (IndexPath, Cell, Model) -> Void) -> RxCollectionView {
        
        var row = RxCell()
        row.identifier = identifier
        row.customise = { i, cell, model in
            if let c = cell as? Cell, let m = model as? Model  {
                customise (i, c, m)
            }
        }
        
        let key = String(describing: modelType)
        modelToRow[key] = row
        
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Final Update method
    ////////////////////////////////////////////////////////////////////////////
    
    public func update (_ data: [Any])  {
    
        self.initialData = data
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        self.data = initialData.filter { element -> Bool in
            let key = String(describing: type(of: element))
            return self.modelToRow[key] != nil
        }
        
        self.collectionView?.reloadData()
    }
    
    public func update () -> RxCollectionView {
        update(initialData)
        return self
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
}

private struct RxCell  {
    var identifier: String?
    var customise: ((IndexPath, UICollectionViewCell, Any) -> Void)?
}
