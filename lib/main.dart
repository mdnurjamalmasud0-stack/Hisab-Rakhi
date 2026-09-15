import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db.dart';

const green = Color(0xFF008A4C);
const darkGreen = Color(0xFF006B3C);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDB.init();
  runApp(const HisabRakhiApp());
}

class HisabRakhiApp extends StatelessWidget {
  const HisabRakhiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'হিসাব রাখি',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF5FAF7),
        fontFamily: 'sans',
      ),
      home: const AuthGate(),
    );
  }
}

String hashPass(String value) => sha256.convert(utf8.encode(value)).toString();

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  bool loading = true;
  bool logged = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() { logged = p.getBool('logged') ?? false; loading = false; });
  }
  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return logged ? const HomePage() : const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool hide = true;
  String error = '';
  Future<void> login() async {
    final user = await AppDB.getUser(phone.text.trim());
    if (user != null && user['password'] == hashPass(pass.text)) {
      final p = await SharedPreferences.getInstance();
      await p.setBool('logged', true);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      setState(() => error = 'মোবাইল নম্বর বা পাসওয়ার্ড ভুল।');
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.account_balance_wallet_rounded, size: 78, color: green),
        const SizedBox(height: 12),
        const Text('হিসাব রাখি', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: darkGreen)),
        const Text('সহজে রাখুন আপনার সব হিসাব'),
        const SizedBox(height: 30),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'মোবাইল নম্বর', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: pass, obscureText: hide, decoration: InputDecoration(labelText: 'পাসওয়ার্ড', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility : Icons.visibility_off)), border: const OutlineInputBorder())),
        if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: login, child: const Text('লগইন'))),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())), child: const Text('নতুন অ্যাকাউন্ট তৈরি করুন')),
      ]),
    )),
  );
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override State<SignupPage> createState() => _SignupPageState();
}
class _SignupPageState extends State<SignupPage> {
  final name=TextEditingController(), phone=TextEditingController(), pass=TextEditingController(), confirm=TextEditingController();
  String error='';
  Future<void> signup() async {
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty || pass.text.length < 6) {
      setState(() => error='সব তথ্য দিন এবং কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন।'); return;
    }
    if (pass.text != confirm.text) { setState(() => error='পাসওয়ার্ড মিলছে না।'); return; }
    if (await AppDB.getUser(phone.text.trim()) != null) { setState(() => error='এই মোবাইল নম্বরে অ্যাকাউন্ট আছে।'); return; }
    await AppDB.addUser(name.text.trim(), phone.text.trim(), hashPass(pass.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অ্যাকাউন্ট তৈরি হয়েছে। এখন লগইন করুন।')));
      Navigator.pop(context);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('সাইন আপ')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('নতুন অ্যাকাউন্ট তৈরি করুন', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      TextField(controller:name, decoration: const InputDecoration(labelText:'আপনার নাম', border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:phone, keyboardType:TextInputType.phone, decoration: const InputDecoration(labelText:'মোবাইল নম্বর', border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:pass, obscureText:true, decoration: const InputDecoration(labelText:'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)', border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:confirm, obscureText:true, decoration: const InputDecoration(labelText:'পাসওয়ার্ড নিশ্চিত করুন', border:OutlineInputBorder())),
      if(error.isNotEmpty) Padding(padding:const EdgeInsets.all(8), child:Text(error,style:const TextStyle(color:Colors.red))),
      const SizedBox(height:12),
      FilledButton(onPressed:signup, child:const Text('সাইন আপ করুন')),
    ]),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab=0;
  Future<void> logout() async {
    final p=await SharedPreferences.getInstance(); await p.setBool('logged',false);
    if(mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);
  }
  @override Widget build(BuildContext context) {
    final pages=[const Dashboard(), const CustomersPage(), const ReportsPage(), SettingsPage(onLogout:logout)];
    return Scaffold(
      appBar: AppBar(title: const Text('হিসাব রাখি'), backgroundColor: green, foregroundColor: Colors.white),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v), destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'হোম'),
        NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:'কাস্টমার'),
        NavigationDestination(icon:Icon(Icons.bar_chart_outlined),selectedIcon:Icon(Icons.bar_chart),label:'রিপোর্ট'),
        NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'সেটিংস'),
      ]),
      floatingActionButton: tab==1 ? FloatingActionButton(backgroundColor:green,foregroundColor:Colors.white,onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AddCustomerPage())).then((_)=>setState((){})),child:const Icon(Icons.add)) : null,
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override State<Dashboard> createState()=>_DashboardState();
}
class _DashboardState extends State<Dashboard>{
  List<Map<String,dynamic>> customers=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{customers=await AppDB.customers();setState((){});}
  @override Widget build(BuildContext context){
    double due=customers.fold(0,(s,c)=>s+(c['due'] as num).toDouble());
    return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
        const CircleAvatar(radius:28,child:Icon(Icons.person)),const SizedBox(width:12),
        Expanded(child:Text('স্বাগতম!\\nআপনার ব্যবসার হিসাব এক জায়গায়',style:TextStyle(fontWeight:FontWeight.w600))),
      ]))),
      Row(children:[
        Expanded(child:StatCard(title:'মোট পাওনা',value:'৳ ${due.toStringAsFixed(0)}',icon:Icons.arrow_downward,color:Colors.green)),
        const SizedBox(width:12),
        Expanded(child:StatCard(title:'কাস্টমার',value:'${customers.length}',icon:Icons.people,color:Colors.blue)),
      ]),
      const SizedBox(height:16),
      const Text('সাম্প্রতিক কাস্টমার',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      ...customers.take(5).map((c)=>CustomerTile(c:onOpen:(){Navigator.push(context,MaterialPageRoute(builder:(_)=>CustomerDetail(id:c['id']))).then((_)=>load());})),
      if(customers.isEmpty) const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('এখনও কোনো কাস্টমার যোগ করা হয়নি।'))),
    ]));
  }
}
class StatCard extends StatelessWidget{
  final String title,value;final IconData icon;final Color color;
  const StatCard({super.key,required this.title,required this.value,required this.icon,required this.color});
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:color),const SizedBox(height:8),Text(title),Text(value,style:TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:color))])));
}

class CustomersPage extends StatefulWidget{const CustomersPage({super.key});@override State<CustomersPage> createState()=>_CustomersPageState();}
class _CustomersPageState extends State<CustomersPage>{
  List<Map<String,dynamic>> list=[];String q='';
  @override void initState(){super.initState();load();}
  Future<void> load()async{list=await AppDB.customers();setState((){});}
  @override Widget build(BuildContext context){
    final filtered=list.where((c)=>(c['name']??'').toString().contains(q)||(c['phone']??'').toString().contains(q)).toList();
    return Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'কাস্টমার খুঁজুন...',border:OutlineInputBorder()))),
      Expanded(child:ListView(children:filtered.map((c)=>CustomerTile(c:c,onOpen:(){Navigator.push(context,MaterialPageRoute(builder:(_)=>CustomerDetail(id:c['id']))).then((_)=>load());})).toList())),
    ]);
  }
}
class CustomerTile extends StatelessWidget{
  final Map<String,dynamic> c;final VoidCallback onOpen;
  const CustomerTile({super.key,required this.c,required this.onOpen});
  @override Widget build(BuildContext context){
    final path=c['photo'] as String?;
    return Card(child:ListTile(onTap:onOpen,leading:CircleAvatar(backgroundImage:path!=null&&File(path).existsSync()?FileImage(File(path)):null,child:path==null?const Icon(Icons.person):null),title:Text(c['name']),subtitle:Text(c['phone']),trailing:Text('৳ ${c['due']}',style:TextStyle(fontWeight:FontWeight.bold,color:(c['due'] as num)>0?green:Colors.red))));
  }
}

class AddCustomerPage extends StatefulWidget{const AddCustomerPage({super.key});@override State<AddCustomerPage> createState()=>_AddCustomerPageState();}
class _AddCustomerPageState extends State<AddCustomerPage>{
  final name=TextEditingController(),phone=TextEditingController(),address=TextEditingController();
  String? photo;
  Future<void> pick()async{final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:80);if(x!=null)setState(()=>photo=x.path);}
  Future<void> save()async{if(name.text.trim().isEmpty||phone.text.trim().isEmpty)return;await AppDB.addCustomer(name.text.trim(),phone.text.trim(),address.text.trim(),photo);if(mounted)Navigator.pop(context);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('নতুন কাস্টমার')),body:ListView(padding:const EdgeInsets.all(20),children:[
    Center(child:Stack(children:[CircleAvatar(radius:52,backgroundImage:photo!=null?FileImage(File(photo!)):null,child:photo==null?const Icon(Icons.person,size:50):null),Positioned(right:0,bottom:0,child:IconButton.filled(onPressed:pick,icon:const Icon(Icons.camera_alt)))])),
    const SizedBox(height:18),TextField(controller:name,decoration:const InputDecoration(labelText:'নাম *',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর *',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:address,maxLines:2,decoration:const InputDecoration(labelText:'ঠিকানা',border:OutlineInputBorder())),
    const SizedBox(height:18),FilledButton(onPressed:save,child:const Text('কাস্টমার সংরক্ষণ করুন')),
  ]));
}

class CustomerDetail extends StatefulWidget{final int id;const CustomerDetail({super.key,required this.id});@override State<CustomerDetail> createState()=>_CustomerDetailState();}
class _CustomerDetailState extends State<CustomerDetail>{
  Map<String,dynamic>? c;List<Map<String,dynamic>> tx=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{c=await AppDB.customer(widget.id);tx=await AppDB.transactions(widget.id);setState((){});}
  Future<void> addTx(bool received)async{
    final amount=TextEditingController();final note=TextEditingController();
    await showDialog(context:context,builder:(_)=>AlertDialog(title:Text(received?'টাকা পেয়েছি':'টাকা দিয়েছি'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'পরিমাণ')),TextField(controller:note,decoration:const InputDecoration(labelText:'বিবরণ'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('বাতিল')),FilledButton(onPressed:()async{final a=double.tryParse(amount.text)??0;if(a>0){await AppDB.addTransaction(widget.id,a,received,note.text);Navigator.pop(context);load();}},child:const Text('সংরক্ষণ'))]));
  }
  @override Widget build(BuildContext context){if(c==null)return const Scaffold(body:Center(child:CircularProgressIndicator()));final path=c!['photo'] as String?;
    return Scaffold(appBar:AppBar(title:const Text('কাস্টমারের বিস্তারিত')),body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[CircleAvatar(radius:36,backgroundImage:path!=null&&File(path).existsSync()?FileImage(File(path)):null,child:path==null?const Icon(Icons.person,size:36):null),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c!['name'],style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text(c!['phone']),Text(c!['address']??'')]))]))),
      Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>addTx(true),icon:const Icon(Icons.add),label:const Text('টাকা পেয়েছি'))),const SizedBox(width:10),Expanded(child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:Colors.red),onPressed:()=>addTx(false),icon:const Icon(Icons.remove),label:const Text('টাকা দিয়েছি')))]),
      const SizedBox(height:18),const Text('লেনদেনের ইতিহাস',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      ...tx.map((t)=>ListTile(leading:CircleAvatar(child:Icon(t['received']==1?Icons.arrow_downward:Icons.arrow_upward)),title:Text('৳ ${t['amount']}'),subtitle:Text('${t['note']??''}\\n${t['date']}'),isThreeLine:true,trailing:Text(t['received']==1?'পাওয়া':'পরিশোধ',style:TextStyle(color:t['received']==1?green:Colors.red)))),
    ]));}
}

class ReportsPage extends StatelessWidget{const ReportsPage({super.key});@override Widget build(BuildContext context)=>FutureBuilder<List<Map<String,dynamic>>>(future:AppDB.customers(),builder:(c,s){final l=s.data??[];final due=l.fold<double>(0,(a,x)=>a+(x['due'] as num).toDouble());return ListView(padding:const EdgeInsets.all(16),children:[const Text('রিপোর্ট',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:18),StatCard(title:'মোট পাওনা',value:'৳ ${due.toStringAsFixed(0)}',icon:Icons.account_balance_wallet,color:green),StatCard(title:'মোট কাস্টমার',value:'${l.length}',icon:Icons.people,color:Colors.blue)]);});}}
class SettingsPage extends StatelessWidget{final VoidCallback onLogout;const SettingsPage({super.key,required this.onLogout});@override Widget build(BuildContext context)=>ListView(children:[const ListTile(title:Text('প্রোফাইল',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold))),const ListTile(leading:Icon(Icons.lock),title:Text('PIN লক')),const ListTile(leading:Icon(Icons.backup),title:Text('ব্যাকআপ')),const ListTile(leading:Icon(Icons.language),title:Text('ভাষা: বাংলা')),ListTile(leading:const Icon(Icons.logout,color:Colors.red),title:const Text('লগআউট'),onTap:onLogout)]);}
