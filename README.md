# injection

###大体流程
1. 当我们修改一个文件并进行保存时，InjectionServer 就会执行 rebuildClass ，重新编译（编译后会动态生成一个相同的新类，在新类中存有新增的函数以及修改后的函数），打包成动态库 (提示：每次保存时，不管内容是否发生改变，都会生成一个动态库)！打包成动态库后调用 writeSting(路径地址) 方法 

2.通过 Socket 通知运行的 App调用inject(tmpfile: String)，tmpfile为动态库的文件路径。然后通过SwiftEval.instance.loadAndInject(tmpfile: tmpfile)，使用dlopen把动态库装载到App中，获取动态库的符号地址，使用dlsym找到编译时新生成的类，并返回
```
@objc func loadAndInject(tmpfile: String, oldClass: AnyClass? = nil) throws -> [AnyClass] {

        print("💉 Loading .dylib ...")
        // load patched .dylib into process with new version of class
        guard let dl = dlopen("\(tmpfile).dylib", RTLD_NOW) else {
            let error = String(cString: dlerror())
            if error.contains("___llvm_profile_runtime") {
                print("💉 Loading .dylib has failed, try turning off collection of test coverage in your scheme")
            }
            throw evalError("dlopen() error: \(error)")
        }
        print("💉 Loaded .dylib - Ignore any duplicate class warning ^")

        if oldClass != nil {
            // find patched version of class using symbol for existing

            var info = Dl_info()
            guard dladdr(unsafeBitCast(oldClass, to: UnsafeRawPointer.self), &info) != 0 else {
                throw evalError("Could not locate class symbol")
            }

            debug(String(cString: info.dli_sname))
            guard let newSymbol = dlsym(dl, info.dli_sname) else {
                throw evalError("Could not locate newly loaded class symbol")
            }

            return [unsafeBitCast(newSymbol, to: AnyClass.self)]
        }
        else {
            // grep out symbols for classes being injected from object file

            try injectGenerics(tmpfile: tmpfile, handle: dl)

            guard shell(command: """
                \(xcodeDev)/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm \(tmpfile).o | grep -E ' S _OBJC_CLASS_\\$_| _(_T0|\\$S|\\$s).*CN$' | awk '{print $3}' >\(tmpfile).classes
                """) else {
                throw evalError("Could not list class symbols")
            }
            guard var symbols = (try? String(contentsOfFile: "\(tmpfile).classes"))?.components(separatedBy: "\n") else {
                throw evalError("Could not load class symbol list")
            }
            symbols.removeLast()

            return Set(symbols.flatMap { dlsym(dl, String($0.dropFirst())) }).map { unsafeBitCast($0, to: AnyClass.self) }
        }
    }
```
3.通过runtime把新旧两个类中的方法全部替换掉！然后再调用SwiftInjected.injected函数，回调ViewController中的injected函数，大体流程结束！为了方便各位查看，以下只是贴出相应源码，全部源码请移致项目中（SwiftInjection）查看
```
@objc
    public class func inject(tmpfile: String) throws {
        let newClasses = try SwiftEval.instance.loadAndInject(tmpfile: tmpfile)
        let oldClasses = //oldClass != nil ? [oldClass!] :
            newClasses.map { objc_getClass(class_getName($0)) as! AnyClass }
        var testClasses = [AnyClass]()
        for i in 0..<oldClasses.count {
            let oldClass: AnyClass = oldClasses[i], newClass: AnyClass = newClasses[i]

            // 把新旧两类中的函数全部替换
            injection(swizzle: object_getClass(newClass), onto: object_getClass(oldClass))
            injection(swizzle: newClass, onto: oldClass)

            // overwrite Swift vtable of existing class with implementations from new class
            let existingClass = unsafeBitCast(oldClass, to: UnsafeMutablePointer<ClassMetadataSwift>.self)
            let classMetadata = unsafeBitCast(newClass, to: UnsafeMutablePointer<ClassMetadataSwift>.self)

            if !injectedClasses.isEmpty {
                #if os(iOS) || os(tvOS)
                let app = UIApplication.shared
                #else
                let app = NSApplication.shared
                #endif
                let seeds: [Any] =  [app.delegate as Any] + app.windows
                SwiftSweeper(instanceTask: {
                    (instance: AnyObject) in
                    if injectedClasses.contains(where: { $0 == object_getClass(instance) }) {
                        let proto = unsafeBitCast(instance, to: SwiftInjected.self)
                        if SwiftEval.sharedInstance().vaccineEnabled {
                            performVaccineInjection(instance)
                            proto.injected?()
                            return
                        }
                        // 调用ViewController中的injected函数
                        proto.injected?()

                        #if os(iOS) || os(tvOS)
                        if let vc = instance as? UIViewController {
                            flash(vc: vc)
                        }
                        #endif
                    }
                }).sweepValue(seeds)
            }
        }
```
```
static func injection(swizzle newClass: AnyClass?, onto oldClass: AnyClass?) {
        var methodCount: UInt32 = 0
        if let methods = class_copyMethodList(newClass, &methodCount) {
            for i in 0 ..< Int(methodCount) {
                class_replaceMethod(oldClass, method_getName(methods[i]),
                                    method_getImplementation(methods[i]),
                                    method_getTypeEncoding(methods[i]))
            }
            free(methods)
        }

    }
```
4. 动态库的**注入**:在运行时使用dlopen，实现注入动态库。

###运行时解析
- 当我们通过LLDB指令:lldb image list -o -f,可以看到动态库列表中多了iOSInjection,这个库会负责和mac Injection通信![Injection.png](https://upload-images.jianshu.io/upload_images/4053175-0d013db8596b7566.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
- 通过源码可以看到Injection确实有负责即时通信的代码（InjectionServer，InjectionClient 中的runInBackground方法）,建立连接后Injection就可以和我们的App愉快的沟通了
- 当我们保存文件后,则会编译了本类文件,类文件被编译为了eval101.dylib动态库！在动态库中Collector(收集器)有两份一样的类，只是方法实现不同！当SwiftInjected.injected调用后，我们使用lldb image list -o -f 可见修改后的类文件以动态库的方式注入了我们的App内![新增动态库.png](https://upload-images.jianshu.io/upload_images/4053175-0672d9b82d9ae350.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



#####使用时需要注意:
- 该工具只可在模拟器上运行！因为模拟器可以加载Mac任意文件，不存在沙盒的说法，而真机设备如果加载动态库，只能加载App.content目录下的！
遗留实践问题:
- 回调时需注意:当A界面添加回调函数,B界面添加调用函数!两个界面都需要保存一遍,但模拟器界面必须要从A界面进入B界面,回调流程才能正常执行!否则在B界面中调用函数,会找不到A里面的回调函数!

##### 源码地址:  
https://github.com/johnno1962/injectionforxcode.git (老版：插件)
https://github.com/johnno1962/InjectionIII


##### 相关
```
//  InjectionServer.mm    runInBackground
for(NSString *source in lastInjected)
            if (![source hasSuffix:@"storyboard"] && ![source hasSuffix:@"xib"] &&
                mtime(source) > executableBuild)
                inject(source);
```


```
 // 1.把动态库 打进mach-o文件中  handle：返回符号指针
    void * handle = dlopen(LIB_CACULATE_PATH, RTLD_LAZY);
    
    // 2.symbol就是要求获取的函数的名称,返回值是void*,指向函数的地址
    CAC_FUNC cac_func = (CAC_FUNC)dlsym(handle, "sub");
    NSLog(@"%d",cac_func(7,2));
    
    clickFunc wx_click = (clickFunc)dlsym(handle, "showFunc");
    wx_click();
```
