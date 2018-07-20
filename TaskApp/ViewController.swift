//
//  ViewController.swift
//  TaskApp
//
//  Created by 黒木龍介 on 2018/07/08.
//  Copyright © 2018年 Ryusuke.Kuroki. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

//継承クラス(UIViewController)の後に２つのプロトコル(約束)を記述
//UITableViewDataSource には、表示内容に関する約束が詰まっている
//UITableViewDelegate には、ユーザ操作(タップ)に関する約束
//プロトコルの中には実装してほしいメソッド名が記述されているので、それを順次実装していくこととなる
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    
//下準備-------------------------------------------------------------------------------
    //メインとなるTableViewをアウトレット接続
    @IBOutlet weak var tableView: UITableView!
    
    //Realmインスタンス(クラスを使用するための「実体」)を取得する
    let realm = try! Realm()
    
    //検索バーをアウトレット接続
    @IBOutlet weak var SearchBar: UISearchBar!
    
    //DB内のタスクが格納されるリスト
    //日付近い順でソート
    //移行内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
//------------------------------------------------------------------------------------
    

//ViewDidLoad-------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //デリゲード(移譲)はViewController自身に
        //表示データと挙動に関しては、tableViewは自分で解決せずViewControllerをデリゲードとして指定して実装を任せる
        tableView.delegate = self
        tableView.dataSource = self
        
        //テストサーチバー、デリゲードを自分に設定する
        SearchBar.delegate = self
        
        //背景をタップしたらdismissKeyboardメソッドを呼ぶようにする
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        //リターンはいつでも押せるようにしておく
        SearchBar.enablesReturnKeyAutomatically = false
        //検索バーには「カテゴリー名を入力して下さい」と表示しておく
        SearchBar.placeholder = "カテゴリー名を入力して下さい"
    }
//------------------------------------------------------------------------------------

    
//MemoryWarning-----------------------------------------------------------------------
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//------------------------------------------------------------------------------------

    
//MARK: UITableViewDataSourceプロトコルのメソッド-----------------------------------------
    //「numberOfRowsInSection」はテーブル内に何列並べるかを記述するメソッド
    //これは、表示内容に関する約束が詰め込まれているDataSourceプロトコルの方に入っている
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
//------------------------------------------------------------------------------------
    

//各セルの内容を返すメソッド---------------------------------------------------------------
    //「cellForRowAt」はテーブル内の１つ１つの列に対して、どのような内容を表示するかを返すメソッド
    //これは、表示内容に関する約束が詰め込まれているDataSourceプロトコルの方に入っている
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //cellに値を設定する
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title + " | " + task.category
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        //cellにreturn
        return cell
    }
//------------------------------------------------------------------------------------
    
    
//Mark: UITableViewDelegateプロトコルのメソッド-------------------------------------------
    //セルをタップした時にタスク入力画面に遷移させるための「didSelectRowAt」を導入 - UITableVieDelegateプロトコルのメソッド
    //各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //SegueのIDを指定して遷移させるperformSegue(withIdentifier:sender)メソッドを呼びだす
        //セルをタップした時のSegueには前もって「CellSegue」というIDを付加している
        performSegue(withIdentifier: "cellSegue", sender: nil)
        //これで、タスク一覧画面で+ボタンをタップした時、また説をタップした時にタスク作成/編集画面に遷移可能に
    }
//------------------------------------------------------------------------------------
    
    
//セルが削除可能なことを伝えるメソッド-------------------------------------------------------
    //セルが削除可能なことを伝えるための「editingStyleForRowAt」を導入 - UITableVieDelegateプロトコルのメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
//------------------------------------------------------------------------------------
    
    
//Deleteボタンが押された時に呼ばれるメソッド-------------------------------------------------
    //Deleteボタンが押されたときにローカル通知をキャンセルし、データベースからタスクを削除する「(_:commit:forRowAt)」
    //これはUITableViewDataSourceプロトコルのメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            //ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            //データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            //未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/-------------")
                    print(request)
                    print("-------------/")
                }
            }
        }
    }
//------------------------------------------------------------------------------------
    
    
//segueで画面遷移する時に呼ばれるメソッド----------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //画面遷移メソッド
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        //画面遷移は今回2パターン
        //まず、セルがタップされた時、cellSegueというIDを持つsegueが実行される
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            //+ボタンが押された場合の遷移
            let task =  Task()
            task.date = Date()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
            
        }
    }
//-------------------------------------------------------------------------------------
    
    
//入力画面から戻ってきたときにTableViewを更新させる--------------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
//-------------------------------------------------------------------------------------


//検索ボタン(SearchBar)を押した時の呼び出しメソッド--------------------------------------------
//検索結果の配列は「SearchResult」
    func searchBar(_ SearchBar: UISearchBar, textDidChange searchText: String) {
    //SearchBar.endEditing(true)
        
    if(SearchBar.text!.isEmpty) {
        taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        tableView.reloadData()
    } else {
        taskArray = try! realm.objects(Task.self).sorted(byKeyPath: "date", ascending:true).filter("category CONTAINS %@", SearchBar.text)
            tableView.reloadData()
        }
    }
//--------------------------------------------------------------------------------------
    
////検索ボタン(SearchBar)を押した時の呼び出しメソッド--------------------------------------------
//    //検索結果の配列は「SearchResult」
//    func searchBarSearchButtonClicked(_ SearchBar: UISearchBar) {
//        SearchBar.endEditing(true)
//
//        if(SearchBar.text!.isEmpty) {
//            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
//            tableView.reloadData()
//        } else {
//            taskArray = try! realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true).filter("category CONTAINS %@", SearchBar.text)
//            tableView.reloadData()
//        }
//    }
////--------------------------------------------------------------------------------------
    
    
//dismissKeyboard-----------------------------------------------------------------------
    @objc func dismissKeyboard() {
        //キーボードを閉じる
        view.endEditing(true)
    }
//--------------------------------------------------------------------------------------
}






































