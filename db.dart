import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDB {
  static late Database db;
  static Future<void> init() async {
    final p = join(await getDatabasesPath(), 'hisab_rakhi.db');
    db = await openDatabase(p, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT UNIQUE, password TEXT)');
      await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, address TEXT, photo TEXT, due REAL DEFAULT 0)');
      await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, amount REAL, received INTEGER, note TEXT, date TEXT)');
    });
  }
  static Future<void> addUser(String name,String phone,String password) async =>
      db.insert('users', {'name':name,'phone':phone,'password':password});
  static Future<Map<String,dynamic>?> getUser(String phone) async {
    final x=await db.query('users',where:'phone=?',whereArgs:[phone],limit:1);
    return x.isEmpty?null:x.first;
  }
  static Future<int> addCustomer(String name,String phone,String address,String? photo) =>
      db.insert('customers', {'name':name,'phone':phone,'address':address,'photo':photo,'due':0});
  static Future<List<Map<String,dynamic>>> customers() => db.query('customers',orderBy:'id DESC');
  static Future<Map<String,dynamic>?> customer(int id) async {final x=await db.query('customers',where:'id=?',whereArgs:[id],limit:1);return x.isEmpty?null:x.first;}
  static Future<void> addTransaction(int id,double amount,bool received,String note) async {
    await db.insert('transactions', {'customer_id':id,'amount':amount,'received':received?1:0,'note':note,'date':DateTime.now().toString()});
    // received = money paid to the business, so customer due increases.
    await db.rawUpdate('UPDATE customers SET due = due + ? WHERE id=?',[received?amount:-amount,id]);
  }
  static Future<List<Map<String,dynamic>>> transactions(int id) => db.query('transactions',where:'customer_id=?',whereArgs:[id],orderBy:'id DESC');
}
