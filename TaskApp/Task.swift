//
//  Task.swift
//  TaskApp
//
//  Created by 黒木龍介 on 2018/07/10.
//  Copyright © 2018年 Ryusuke.Kuroki. All rights reserved.
//

import Foundation
import RealmSwift

//MVCの概念において、モデルがデータを表現するものであった
//今回はそのモデルを「タスク」クラスが相当することになる
class Task: Object {
    //管理用 ID プライマリーキー
    //プライマリーキーとはデータベースにおいてそれぞれのデータを一意に識別するためのID
    //今回使用するデータベースのライブラリであるRealmはKVOというプロパティ変更管理システムを採用
    //そのため、 @objc dynamic という修飾子が必要となる
    @objc dynamic var id = 0
    
    //タイトル
    @objc dynamic var title = ""
    
    //内容
    @objc dynamic var contents = ""
    
    //カテゴリー
    @objc dynamic var category = ""
    
    //日時
    @objc dynamic var date = Date()
    
    //IDをプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}






































