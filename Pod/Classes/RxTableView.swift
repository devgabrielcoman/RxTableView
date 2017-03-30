import UIKit
import RxSwift
import RxCocoa

public class RxTableView: NSObject, UITableViewDelegate, UITableViewDataSource {

    private let kDEFAULT_REUSE_ID: String = "RxTableView_ID"
    private let kDEFAULT_ROW_HEIGHT: CGFloat = 44
    
    private var table: UITableView?
    private var estimatedRowHeight: CGFloat?
    private var modelToRow: [String : RxRow] = [:]
    private var clicks: [String : (IndexPath, Any) -> Void] = [:]
    private var data: [Any] = []
    
    override init () {
        //
    }
    
    init (table: UITableView) {
        self.table = table
    }
    
    public func bindTable (_ table: UITableView) -> RxTableView {
        self.table = table
        return self
    }
    
    public static func create () -> RxTableView {
        return RxTableView ()
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Estimate full table height
    ////////////////////////////////////////////////////////////////////////////
    
    func estimateRowHeight (_ height: CGFloat) -> RxTableView {
        
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
    
    //
    // case #1: reuse id + simple array of strings (height either default or autsize)
    public func customiseRow <Cell : UITableViewCell, Model> (forReuseIdentifier identifier: String,
                                                              _ customise: @escaping (IndexPath, Cell, Model) -> Void ) -> RxTableView {
        
        return customiseRow(forReuseIdentifier: identifier,
                            andCellWithType: Cell.self,
                            andHeight: estimatedRowHeight ?? kDEFAULT_ROW_HEIGHT,
                            representedByModelWithType: Model.self,
                            customise)
    }
    
    //
    // case #1.1: reuse id + simple array of strings + height
    public func customiseRow <Cell : UITableViewCell, Model> (forReuseIdentifier identifier: String,
                                                              andHeight height: CGFloat,
                                                              _ customise: @escaping (IndexPath, Cell, Model) -> Void ) -> RxTableView {
        
        return customiseRow(forReuseIdentifier: identifier,
                            andCellWithType: Cell.self,
                            andHeight: height,
                            representedByModelWithType: Model.self,
                            customise)
    }
    
    //
    // case #2: reuse id + model & one type of cell that you explicitly call (height either default or autsize)
    public func customiseRow <Cell : UITableViewCell, Model> (forReuseIdentifier identifier: String,
                                                              representedByModelWithType modelType: Model.Type,
                                                              _ customise: @escaping (IndexPath, Cell, Model) -> Void ) -> RxTableView {
        
        return customiseRow(forReuseIdentifier: identifier,
                            andCellWithType: Cell.self,
                            andHeight: estimatedRowHeight ?? kDEFAULT_ROW_HEIGHT,
                            representedByModelWithType: modelType,
                            customise)
    }
    
    //
    // case #2.1: reuse id + model (height either default or autsize)
    public func customiseRow <Cell : UITableViewCell, Model> (forReuseIdentifier identifier: String,
                                                              andHeight height: CGFloat,
                                                              representedByModelWithType modelType: Model.Type,
                                                              _ customise: @escaping (IndexPath, Cell, Model) -> Void ) -> RxTableView {
        
        return customiseRow(forReuseIdentifier: identifier,
                            andCellWithType: Cell.self,
                            andHeight: height,
                            representedByModelWithType: modelType,
                            customise)
    }
    
    //
    // case #3: reuse id + model (height either default or autsize)
    public func customiseRow <Cell : UITableViewCell, Model> (forReuseIdentifier identifier: String,
                                                              andCellWithType cellType: Cell.Type,
                                                              representedByModelWithType modelType: Model.Type,
                                                              _ customise: @escaping (IndexPath, Cell, Model) -> Void ) -> RxTableView {
        
        return customiseRow(forReuseIdentifier: identifier,
                            andCellWithType: cellType,
                            andHeight: estimatedRowHeight ?? kDEFAULT_ROW_HEIGHT,
                            representedByModelWithType: modelType,
                            customise)
    }
    
    //
    // case #3.1: reuse id + model + cell + height
    public func customiseRow <Cell : UITableViewCell, Model> (forReuseIdentifier identifier: String,
                                                              andCellWithType cellType: Cell.Type,
                                                              andHeight height: CGFloat,
                                                              representedByModelWithType modelType: Model.Type,
                                                              _ customise: @escaping (IndexPath, Cell, Model) -> Void ) -> RxTableView {
        
        var row = RxRow()
        row.identifier = identifier
        row.height = height
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
    // Row Clicks
    ////////////////////////////////////////////////////////////////////////////
    
    public func clickRow <Model> (forReuseIdentifier identifier: String,
                                  _ action: @escaping (IndexPath, Model) -> Void) -> RxTableView {
        
        let key = String(describing: Model.self)
        clicks[key] = { index, model in
            if let m = model as? Model {
                action (index, m)
            }
        }
        
        return self
    }
    
    public func clickRow <Model> (forReuseIdentifier identifier: String,
                                  representedByModelWithType type: Model.Type,
                                  _ action: @escaping (IndexPath, Model) -> Void) -> RxTableView {
        
        let key = String(describing: type)
        clicks[key] = { index, model in
            if let m = model as? Model {
                action (index, m)
            }
        }
        
        return self
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Final Update method
    ////////////////////////////////////////////////////////////////////////////
    
    public func update (_ data: [Any])  {
        
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
    
}

private struct RxRow  {
    var identifier: String?
    var height: CGFloat?
    var customise: ((IndexPath, UITableViewCell, Any) -> Void)?
}
