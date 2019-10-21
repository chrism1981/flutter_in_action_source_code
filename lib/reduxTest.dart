import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// One simple action: Increment
enum Actions { Increment }

// The reducer, which takes the previous count and increments it in response
// to an Increment action.
int counterReducer(int state, dynamic action) {
  if (action == Actions.Increment) {
    return state + 1;
  }

  return state;
}

void main() {
  // Create your store as a final variable in the main function or inside a
  // State object. This works better with Hot Reload than creating it directly
  // in the `build` function.

//  final store = Store<int>(counterReducer, initialState: 0);

  final store = Store<int>((state, action) {
    if(action == Actions.Increment){
      state++;
    }
    return state;
  }, initialState: 0);

  runApp(FlutterReduxApp(
    title: 'Flutter Redux Demo',
    store: store,
  ));
}

class FlutterReduxApp extends StatelessWidget {
  final Store<int> store;
  final String title;

  FlutterReduxApp({Key key, this.store, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The StoreProvider should wrap your MaterialApp or WidgetsApp. This will
    // ensure all routes have access to the store.
    return StoreProvider<int>(
      //包装App类，其中的child就是改应用的app
      // Pass the store to the StoreProvider. Any ancestor `StoreConnector`
      // Widgets will find and use this value as the `Store`.
      store: store,
      child: MaterialApp(
        theme: ThemeData.dark(),
        title: title,
        home: Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You have pushed the button this many times:',
                ),
                // Connect the Store to a Text Widget that renders the current
                // count.
                //
                // We'll wrap the Text Widget in a `StoreConnector` Widget. The
                // `StoreConnector` will find the `Store` from the nearest-
                // `StoreProvider` ancestor, convert it into a String of the
                // latest count, and pass that String  to the `builder` function
                // as the `count`.
                //
                // Every time the button is tapped, an action is dispatched and
                // run through the reducer. After the reducer updates the state,
                // the Widget will be automatically rebuilt with the latest
                // count. No need to manually manage subscriptions or Streams!
                /***
                 * 这个connector是用来取数据，下面的是来修改数据
                 */
                StoreConnector<int, String>(
                  converter: (store) => store.state.toString(),
                  builder: (context, count) {//convertor函数执行后的结果被作为实参传递到count参数。
                    return Text(
                      count,
                      style: Theme.of(context).textTheme.display1,
                    );
                  },
                )
              ],
            ),
          ),
//          Connect the Store to a FloatingActionButton. In this case, we'll
//              use the Store to build a callback that with dispatch an Increment
//              Action.
//              Then, we'll pass this callback to the button's `onPressed` handler.
          /**
           *
              connector解析：其中泛型的含义  S- State的类型 ViewModel - 将state的类型，转换成任意想要用的一种数据类型
              StoreConnector<S, ViewModel> 其中构造函数需要builder：ViewModelBuilder<ViewModel> builder;
              和 converter：StoreConverter<S, ViewModel> converter;对应如下2个参数。

              重点是：
              1。convertor ：

              typedef StoreConverter<S, ViewModel> = ViewModel Function(
              Store<S> store,
              );
              --》 convertor的类型实际上是一个函数对象，返回值是state转换为viewmodel的类型，函数的参数是Store(S)
              对应的本例子的 convertor的类型实际上就是一个函数： 参数为store<int> 返回值为 VoidCallback：
              converter: (store) {//参数为Store<int>
              return () => store.dispatch(Actions.Increment);返回值构造了一个无参数，无返回值的函数
              }
              --》 也就是说 convertor的参数，返回值 对应了StoreConnector<S, ViewModel> 的泛型，然后convertor实际是一个回掉函数。
              由redux框架将你创建的store<S>的实例作为实参，来调用你自己构造出的convertor函数

              2.builder：

              typedef ViewModelBuilder<ViewModel> = Widget Function(
              BuildContext context,
              ViewModel vm,
              );
              理解了convertor 就容易明白builder，其中builder也是一个回掉函数对象，函数的第二个参数就是上面convertor的返回值，也就是
              redux根据你的策略函数(convertor)把State转化成你设定的viewmodel类型，然后用这个转换后的viewmodel值作为实参再去调用你
              的builder函数。 返回值是一个widget，可以是实际的ui控件

              ！！！！最后，这和flutter的思想一致，仍然是包装模式。本例子中的2个connector实际上都是用来包装2个ui对象，一个是text，一个是floatingbutton
              connector不是以继承的方式来变成text或者button，而是包装了text 和button，而它包装的text能够被渲染，得力于StoreConnector继承了StatelessWidget，
              一切都是widget，这样把connector作为参数传递给Colunm的是child数组的时候，系统在渲染StoreConnector对象时候，会调用它继承自StatelessWidget
              的 Widget build(BuildContext context)函数，而框架只需要在这个build中来想办法构造一个text控件，就可以实现把StoreConnector当作text来用。
              实际上redux是内部有一个statefull的connector 和一个stateless的connector类，statefull的最终内部是在build函数中用streamBuilder来让text(本例子中)能渲染
           * */

          /***
           * 总结，任何可以有任意个connecctor，既可以用来读store的数据，也可以用来改变数据，在需要与数据联动的 ui widget处，用connector来包装具体的ui widget
           * 通常在读取数据的时候，viewmodel是一个数据类型， 需要改变数据时候，viewmodel是一个回调函数，在函数中dispatch事件,reducer中根据事件来改变数据。
           * 由于state只能读，write state的值。
           */

          floatingActionButton: StoreConnector<int, VoidCallback>(
            converter: (store) {
              //框架将provider中的store实例传递给你，框架调用convertor函数
              // Return a `VoidCallback`, which is a fancy name for a function
              // with no parameters. It only dispatches an Increment action.
              return () => store.dispatch(
                  Actions.Increment); // 你负责创建一个策略函数，告诉框架怎么把int转化为VoidCallback
            },
            builder: (context, callback) {
              return FloatingActionButton(
                // Attach the `callback` to the `onPressed` attribute
                onPressed: callback,
                tooltip: 'asdasdasd',
                child: Icon(Icons.add),
              );
            },
          ),
        ),
      ),
    );
  }
}
