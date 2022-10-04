//
//  ViewController.swift
//  NNJsonToModelTemplate
//
//  Created by olddevil on 2022/9/30.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var comboBox: NSComboBox!
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var validate: NSTextField!
    @IBOutlet var input: NSTextView!
    @IBOutlet var output: NSTextView!
    @IBOutlet weak var subModelInside: NSButton!
    
    var resString = ""
    var cache: [Model] = []
    let comboBoxData = ["swift-struct", "swift-class"]
    var fileType = ""
    var insideTab: String {
        get { subModelInside.state == .on ? "\t" : "" }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        comboBox.dataSource = self
        comboBox.delegate = self
        comboBox.selectItem(at: 0)
        input.becomeFirstResponder()
    }

    @IBAction func trans(_ sender: Any) {
        if input.string.isEmpty { return }
        let res = parseJson(jsonString: input.string)
        if res == nil { return }
        resString = ""
        let modelName = fileName.stringValue.isEmpty ? "xxx" : fileName.stringValue
        willParse(res as Any, name: modelName.formatEntityName(), isMain: true)
    }
    
    func willParse(_ res: Any, name: String, isMain: Bool) {
        if let res = res as? Array<Any> {
            if let dic = res.first as? [String: Any] {
                parse(dic, name: name, isMain: isMain)
            }
        }
        if let res = res as? [String: Any] {
            parse(res, name: name, isMain: isMain)
        }
    }
    
    func parse(_ parseDic: [String: Any], name: String, isMain: Bool) {
        let tab = isMain ? "" : insideTab
        var anEntity = ""
        var top = "\(tab)\(fileType) \(name.formatEntityName()): Codable {\n"
        var bottom = "\(tab)\tenum CodingKeys: String, CodingKey {\n"
        parseDic.keys.forEach { key in
            let v = parseDic[key]
            let t = CheckType.of(v as Any)
            if t == "__NSCFBoolean" {
                top.append("\(tab)\tlet \(key.snakeToCamel()): Bool?\n")
                bottom.append(tab + key.handleCase())
            } else if t == "__NSCFNumber" {
                if let _ = v as? Int {
                    top.append("\(tab)\tlet \(key.snakeToCamel()): Int?\n")
                    bottom.append(tab + key.handleCase())
                } else {
                    top.append("\(tab)\tlet \(key.snakeToCamel()): Double?\n")
                    bottom.append(tab + key.handleCase())
                }
            } else if t == "NSTaggedPointerString" || t == "__NSCFString" {
                top.append("\(tab)\tlet \(key.snakeToCamel()): String?\n")
                bottom.append(tab + key.handleCase())
            }
            
            if let av = v as? Array<Any> {
                if av.isEmpty {
                    let alert = NSAlert()
                    alert.messageText = "\(key) 字段对应数组为空数组，默认用String类型填充"
                    alert.beginSheetModal(for: view.window!)
                }
                var first = av.first
                var prefix = "["
                var suffix = "]"
                while (first as? Array<Any>) != nil {
                    prefix.append("[")
                    suffix.append("]")
                    first = (first as! Array<Any>).first
                }
                let ft = CheckType.of(first as Any)
                if ft == "__NSCFBoolean" {
                    top.append("\(tab)\tlet \(key.snakeToCamel()): \(prefix)Bool\(suffix)?\n")
                    bottom.append(tab + key.handleCase())
                } else if ft == "__NSCFNumber" {
                    if let _ = first as? Int {
                        top.append("\(tab)\tlet \(key.snakeToCamel()): \(prefix)Int\(suffix)?\n")
                        bottom.append(tab + key.handleCase())
                    } else {
                        top.append("\(tab)\tlet \(key.snakeToCamel()): \(prefix)Double\(suffix)?\n")
                        bottom.append(tab + key.handleCase())
                    }
                } else if ft == "NSTaggedPointerString" || ft == "__NSCFString" || av.isEmpty {
                    top.append("\(tab)\tlet \(key.snakeToCamel()): \(prefix)String\(suffix)?\n")
                    bottom.append(tab + key.handleCase())
                }
                if let fv = first as? [String: Any] {
                    top.append("\(tab)\tlet \(key.snakeToCamel()): \(prefix)\(key.formatEntityName())\(suffix)?\n")
                    bottom.append(tab + key.handleCase())
                    let entity = Model()
                    entity.name = key
                    entity.data = fv
                    cache.append(entity)
                }
            }
            if let dv = v as? [String: Any] {
                top.append("\(tab)\tlet \(key.snakeToCamel()): \(key.formatEntityName())?\n")
                bottom.append(tab + key.handleCase())
                let entity = Model()
                entity.name = key
                entity.data = dv
                cache.append(entity)
            }
        }
        bottom.append("\(tab)\t}")
        anEntity.append(top)
        anEntity.append("\n")
        anEntity.append(bottom)
        if subModelInside.state != .on || !isMain {
            anEntity.append("\n")
            anEntity.append("\(tab)}")
        }
        resString.append(anEntity)
        resString.append("\n")
        if cache.isEmpty {
            if subModelInside.state == .on {
                resString.append("}")
            }
            output.string = resString
        } else {
            resString.append("\n")
            let first = cache.first!
            cache.removeFirst()
            
            willParse(first.data as Any, name: first.name, isMain: false)
        }
    }
    
    func parseJson(jsonString:String) -> Any? {
        let jsonData:Data = jsonString.replacingOccurrences(of: ".0", with: ".1").data(using: .utf8)!
        do {
            let obj = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            validate.stringValue = "✅ 正确的JSON格式"
            return obj
        } catch {
            validate.stringValue = "❌ 错误的JSON格式"
            return nil
        }
    }
}

extension ViewController: NSComboBoxDataSource ,NSComboBoxDelegate {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return comboBoxData.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return comboBoxData[index]
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let index = comboBox.indexOfSelectedItem
        let str = comboBoxData[index]
        fileType = str.replacingOccurrences(of: "swift-", with: "")
    }
}

class Model {
    var name: String = ""
    var data: [String: Any] = [:]
}

extension String {
    func formatEntityName() -> String {
        let camel = self.snakeToCamel()
        let str = camel.prefix(1).uppercased() + camel.dropFirst()
        return str
    }
    
    func snakeToCamel() -> String {
        if self.contains("_") {
            let arr = self.components(separatedBy: "_")
            if arr.count <= 1 { return self }
            let upper = arr.map { $0.prefix(1).uppercased() + $0.dropFirst() }
            let joined = upper.joined(separator: "")
            return joined.prefix(1).lowercased() + joined.dropFirst()
        }
        return self
    }
    
    func handleCase() -> String {
        if self.contains("_") {
            let arr = self.components(separatedBy: "_")
            if arr.count <= 1 { return "\t\tcase " + self + "\n" }
            return "\t\tcase \(self.snakeToCamel()) = \"\(self)\"\n"
        }
        return "\t\tcase " + self + "\n"
    }
}

