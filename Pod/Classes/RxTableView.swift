import UIKit
import RxSwift
import RxCocoa

public class RxTableView: NSObject,
    UITableViewDelegate,
    UITableViewDataSource,
    UIScrollViewDelegate {

    private let kDEFAULT_REUSE_ID: String = "RxTableView_ID"
    private let kDEFAULT_ROW_HEIGHT: CGFloat = 44
    
    private var table: UITableView?
    private var estimatedRowHeight: CGFloat?
    private var modelToRow: [String : RxRow] = [:]
    private var clicks: [String : (IndexPath, Any) -> Void] = [:]
    private var data: [Any] = []
    private var reachEnd: (() -> Void)?
    
    override init () {
        //
    }
    
    init (table: UITableView) {
        self.table = table
    }
    
    public static func create () -> RxTableView {
        return RxTableView ()
    }
    
    public func bind (toTable table: UITableView) -> RxTableView {
        self.table = table
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Estimate full table height
    ////////////////////////////////////////////////////////////////////////////
    
    public func set(estimatedRowHeight height: CGFloat) -> RxTableView {
        
        estimatedRowHeight = height
        
        if let h = estimatedRowHeight, let table = table {
            table.estimatedRowHeight = h
            table.rowHeight = UITableViewAutomaticDimension
        }
        
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Customize Row
    ////////////////////////////////////////////////////////////////////////////
    
    public func customise <Row: UITableViewCell, Model> (rowForReuseIdentifier identifier: String,
                                                         _ callback: @escaping (IndexPath, Row, Model) -> Void) -> RxTableView {
        
        return customise(rowForReuseIdentifier: identifier,
                         withNibName: nil,
                         andType: Row.self,
                         andHeight: nil,
                         representedByModelOfType: Model.self,
                         customisedBy: callback)
    }
    
    public func customise <Row: UITableViewCell, Model> (rowForReuseIdentifier identifier: String,
                                                         andHeight height: CGFloat?,
                                                         _ callback: @escaping (IndexPath, Row, Model) -> Void) -> RxTableView {
        
        return customise(rowForReuseIdentifier: identifier,
                         withNibName: nil,
                         andType: Row.self,
                         andHeight: height,
                         representedByModelOfType: Model.self,
                         customisedBy: callback)
    }
    
    public func customise <Row: UITableViewCell, Model> (rowForReuseIdentifier identifier: String,
                                                         withNibName nibName: String?,
                                                         _ callback: @escaping (IndexPath, Row, Model) -> Void) -> RxTableView {
        
        return customise(rowForReuseIdentifier: identifier,
                         withNibName: nibName,
                         andType: Row.self,
                         andHeight: nil,
                         representedByModelOfType: Model.self,
                         customisedBy: callback)
    }
    
    public func customise <Row: UITableViewCell, Model> (rowForReuseIdentifier identifier: String,
                                                         withNibName nibName: String?,
                                                         andHeight height: CGFloat?,
                                                         _ callback: @escaping (IndexPath, Row, Model) -> Void) -> RxTableView {
        
        return customise(rowForReuseIdentifier: identifier,
                         withNibName: nibName,
                         andType: Row.self,
                         andHeight: height,
                         representedByModelOfType: Model.self,
                         customisedBy: callback)
    }
    
    private func customise <Row: UITableViewCell, Model> (rowForReuseIdentifier identifier: String,
                                                          withNibName nibName: String?,
                                                          andType rowType: Row.Type,
                                                          andHeight height: CGFloat?,
                                                          representedByModelOfType modelType: Model.Type,
                                                          customisedBy callback: @escaping (IndexPath, Row, Model) -> Void) -> RxTableView {
        
        if let nib = nibName {
            table?.register(UINib(nibName: nib, bundle: nil), forCellReuseIdentifier: identifier)
        }
        
        var row = RxRow()
        row.identifier = identifier
        row.height = height ?? (estimatedRowHeight ?? kDEFAULT_ROW_HEIGHT)
        row.customise = { i, cell, model in
            if let c = cell as? Row, let m = model as? Model  {
                callback (i, c, m)
            }
        }
        
        let key = String(describing: modelType)
        modelToRow[key] = row
        
        
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Row Clicks
    ////////////////////////////////////////////////////////////////////////////
    
    public func did <Model> (clickOnRowWithReuseIdentifier identifier: String,
                            _ action: @escaping (IndexPath, Model) -> Void) -> RxTableView {
        
        
        let key = String(describing: Model.self)
        clicks[key] = { index, model in
            if let m = model as? Model {
                action (index, m)
            }
        }
        
        return self
    }
    
    public func did (reachEnd action: @escaping () -> Void) -> RxTableView {
        reachEnd = action
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Final Update method
    ////////////////////////////////////////////////////////////////////////////
    
    public func update (withData data: [Any])  {
        
        table?.delegate = self
        table?.dataSource = self
        
        self.data = data.filter { element -> Bool in
            let key = String(describing: type(of: element))
            return self.modelToRow[key] != nil
        }
        
        self.table?.reloadData()
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Table View Delegate & Data Source
    ////////////////////////////////////////////////////////////////////////////
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if estimatedRowHeight != nil {
            return UITableViewAutomaticDimension
        }
        else {
            
            let item = data[indexPath.row]
            let key = String(describing: type(of: item))
            let row = modelToRow [key]
            let height = row?.height ?? kDEFAULT_ROW_HEIGHT
            
            return height
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = data[indexPath.row]
        let key = String(describing: type(of: item))
        let row = modelToRow [key]
        
        let cellId = row?.identifier ?? kDEFAULT_REUSE_ID
        let customise = row?.customise
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        customise? (indexPath, cell, item)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let item = data[indexPath.row]
        let key = String(describing: type(of: item))
        let click = clicks[key]
        
        click? (indexPath, item)
        
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let diffY = contentHeight - scrollView.frame.size.height
     
        if offsetY >= diffY {
            reachEnd?()
        }
    }
    
}

private struct RxRow  {
    var identifier: String?
    var height: CGFloat?
    var customise: ((IndexPath, UITableViewCell, Any) -> Void)?
}
