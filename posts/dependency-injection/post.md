---
date: 2014-08-29
title: Dependency Injection
---

# 摘要 #

在任何的程式裡面，上至模組，下至函式，每個元素為了達成自己的工作，或多或少都會依賴其他的元素來完成不是自己責任的工作；也因此不同的元素之間存在著一種相依性，這種彼此依賴的程度多寡，決定了一個程式幾個重要的面向：如可測試性、可維護性。隨著程式的規模和複雜度增加，相依性越高的程式碼，問題也會更加明顯。

Dependency Injection，中文被譯為相依性注入 (以下稱 DI)， 是一個為了減低程式間相依性而被廣泛應用的 pattern 之一。這篇文章將會就以下幾點來介紹這個 pattern：

  1. 何謂 Dependency
  2. 為什麼要在乎 Dependency
  3. 什麼是 DI
  4. DI 的優點
  5. DI 的缺點

# 何謂 Dependency #

A 完成一個動作之前，需要依賴 B 去做特定事情才能算完成，這種時候就可以講 B 是 A 的 Dependency。

舉個例子來講，一個更換使用者密碼的程式可能長的這個樣子：

    public class UserService {

      private MysqlDatabaseClient dbClient = new MysqlDatabaseClient();

      private SmsMessenger messenger = new SmsMessenger();

      // ...

      public void changePassword(User user, String newPassword) {
        try {
          dbClient.updatePassword(user.getId(), newPassword);
          messenger.send(user, TextTemplate.PASSWORD_CHANGE_NOTICE);
        } catch (OperationException e) {
          throw new AppRuntimeException("Cannot change password", e);
        }
      }
    }

client code 只需要透過 `UserService` 的 `changePassword()`，就可以做完整個更改密碼的流程；而這個程式可觀察到以下幾個相依性的存在：

1. `changePassword()` 這個方法會呼叫資料庫去更新密碼，並透過簡訊伺服器通知使用者。這些動作要透過 `MysqlDatabaseClient` 和  `SmsMessenger` 兩個物件才能完成，因此這個方法對兩個物件有相依。
2. `UserService` 本身在建構時同時建立這兩個物件，因此 `UserService` 本身執行時也同樣依賴於上述兩個物件。
3. 除了 Runtime Dependency 外，在如 Java 一樣需要編譯的語言裡，上述的例子還有所謂的 Compile-time Dependency ；也就是指當要編譯 `UserService` 時，`MysqlDatabaseClient` 和 `SmsMessenger` 兩個類別也一定要編譯完成，而且存在於 classpath 內，才有辦法編譯。
4. 程式需要資料庫和簡訊伺服器才能儲存資料和傳送簡訊，因此這個程式又和這兩個外部資源有相依。如果有任何一個沒啟動，程式就無法正常執行。

Dependency 無所不存在。

# 為什麼要在乎 Dependency #

因為相依性越高的程式，越難以去維護和修改。這些程式通常都會有以下的問題存在：

1. **漣漪效應**: 相依性越高的程式，通常代表著彼此間分享太多的細節，而細節通常都會隨著產品需要而修改。一旦修改，相依於它的程式通常也得一起處理；而這些程式又造成依賴在於它們的另一批程式需要更動；到最後可能一個修改卻造成系統從上到下都需要更動的狀況。在中、大型的專案中，如果擴散到模組間的話，更會嚴重影響編譯和建置的時間還有改版的方式。
2. **難以測試**：以上面的例子來說，不修改程式的狀況下想要寫單元測試幾乎是不可能的，或者得要花上很多功夫去準備測試環境。一旦系統到處都是這種難以測試的程式碼，自然也不會有足夠自動測試來保護程式。
3. **難以重複使用**: 相依性高，呼叫該程式的其他程式可能得面臨不得不跟著相依的狀況，因此難以被利用；這等於間接鼓勵開發者多寫一份一樣的程式碼好繞過這些問題。

這些症狀都不是大家樂意在自己維護的程式裡看到的，因此管理相依性是很重要的。DI 就是一種緩和物件間相依性常見的 Design Pattern。

# 什麼是 DI #

DI 是指將一個程式的相依關係改由呼叫它的外部程式來決定的方法。白話一點就是指程式自己不主動產生相依性，把決定權交給呼叫它的程式。來看看將前面的例子修改後的結果：

    public class UserService {

      private DatabaseClient dbClient;
      private Messenger messenger;

      public UserService(DatabaseClient dbClient, Messenger messenger) {
        this.dbClient = dbClient;
        this.messenger = messenger;
      }

      // ...  changePassword method 不變
    }

在這個例子裡，`UserService` 改為使用 `DatabaseClient` 和 `Messenger` 這兩個 interface；同時不再自己建立出 `MysqlDatabaseClient` 和 `SmsMessenger` 物件，而是要求 client code 在 constructor 裡代入物件。透過這個方式，`UserService` 不再知道自己使用的資料庫是什麼，以及通知使用者的手段為何；因為這些都交由 client code 來決定。原本的相依狀況，透過這個方式也只剩下和 `DatabaseClient` 及 `Messenger` 相依。

這樣子的作法就是一種 DI。

雖然根據語言不同，達成的方式可能不同，但常見是有以下的幾種方式：

### Constructor Injection ###

在 Constructor 執行時就得要把 Dependency 放進物件內，上述的例子就是標準的 Constructor Injection 作法。這種作法的好處在於，Constructor 本身的宣告就可以讓 client code 了解這個物件所需要的 Dependency，而減少執行時發生沒有設定 Dependency 的狀況。

### Setter Injection ###

透過物件的 [Setter](http://en.wikipedia.org/wiki/Mutator_method) methods 來達成。舉例來講：

    public class UserService {

      private DatabaseClient dbClient;
      private Messenger messenger;

      public void setDatabaseClient(DatabaseClient dbClient) {
        this.dbClient = dbClient;
      }

      public void setMessenger(Messenger messenger) {
        this.messenger = messenger;
      }

      // ...
    }

這種方式的好處是當參數較多時，不會讓 Constructor 過度龐大，而且可以選擇式地決定使用哪些 Dependency。但這個方式也有一些缺點，例如 client code 可能會少放入 Dependency，或者應該要是 Immutable 的 field 因為 setter 而暴露在可能被更動的風險下。

### Field Injection ###

這個作法是物件本身不提供任何注入機制，client code 利用語言的特性將所需要的 dependency 變成物件的 instance member 內。在 Java 的環境中，通常會利用到 Reflection API 來做到這點。

    public class UserService {

      // 使用 Annotation 讓 client code 能辨視出這個 field 需要被注入
      @Inject
      private DatabaseClient dbClient;

      @Inject
      private Messenger messenger;
    }

這個方法大幅度的減少了實作時所需要寫的程式，通常會在 DI framework 中看到。只是這個作法有一些缺點：

1. 缺少如上述兩種例子方便簡單地注入 Dependency 的能力。
2. 使用時沒有辦法在不看 source code 的狀況下知道物件的 dependency。
3. 測試時可能需要靠 framework 或多花時間準備測試環境的程式。

因此這種方式也有反對的聲音，認為它並沒有真的滿足 DI 的目的。

### Interface Injection ###

這個作法是事先定義出代表需要 injection 的 interface，例如：

    public interface InjectDatabaseClient {
        void inject(DatabaseClient client);
    }

    public interface InjectMessenger {
        void inject(Messenger messenger);
    }

然後實作此 interface。

    public class UserService implements InjectDatabaseClient, InjectMessenger {

      private DatabaseClient dbClient;
      private Messenger messenger;

      @Override
      public void inject(DatabaseClient dbClient) {
        this.dbClient = dbClient;
      }

      @Override
      public void inject(Messenger messenger) {
        this.messenger = messenger;
      }
    }

乍看之下和 Setter Injection 沒有兩樣，甚至多做了兩個 Interface 畫蛇添足。但這個方法的好處在於達成了 [Interface Segregation Principle](http://en.wikipedia.org/wiki/Interface_segregation_principle) 。所以負責 injection 的程式，可以不需要和 `UserService` 或任何其他實作這些 Interface 的 class 有相依性，只要有實作就能呼叫 `inject()` 把需要的物件放進來。只是這個方式實作上比較複雜，通常會在 framework 內看到。

# DI 的優點 #

DI 的最大目的，就是在於可以將相依性的決定權反轉到外部去，藉此減少物件間的相依。而這就是物件導向 SOLID 原則裡的 [Dependency Inversion Principal](http://en.wikipedia.org/wiki/Dependency_inversion_principle) 想要強調的事情。現在更改過後的 `UserService` 就可以用下面的方式來測試：

    public class UserServiceTest {

      @Test
      public void testChangePassword() {
        DatabaseClient dbClient = new MockDatabaseClient();
        Messenger messenger = new MockMessenger();

        UserService service = new UserService(dbClient, messenger);

        // test something
      }
    }

原本的程式被綁死在 `MysqlDatabaseClient` 和 `SmsMessenger` 上，因此測試得要準備好資料庫和簡訊伺服器才有可能執行；但透過使用 interface，並將 dependency 從外部放進來的方式，測試如今可以利用假的 `DatabsaeClient` 和 `Messenger` 來對 `UserService` 做測試。

從 `UserService` 自己決定變成由測試來決定，這種將控制權反轉的概念，就叫 [Inversion of Control](http://en.wikipedia.org/wiki/Inversion_of_control) 。

現在回頭看看前面提到 dependency 過多的缺點是如何被避免的：

  1. **漣漪效應**：現在 `UserService` 相依於 `DatabaseClient` 和 `Messenger` 這兩個 interface，因此只要 interface 的 API 不更動，實作怎麼改都不會影響到 `UserService`。在中、大型的專案內，這代表 `MysqlDatabaseClient` 被更改，也不需要重新編譯、建置 `UserService`，更不需要跟著一起改版；進而達到可以多組人馬平行開發卻不會互相影響。
  2. **難以測試**：現在可以在測試裡放入測試專用的 `DatabaseClient`, `Messenger`，測試可以不需要依靠外部資源。
  3. **難以重複利用**：因為只相依於 interface，因此實作只要正常運作，UserService 可以搭配各種 `DatabaseClient` 和 `Messenger` 的組合使用。

例如 :

     DatabaseClient dbClient = new PostgresqlDatabaseClient();
     Messenger messenger = new TwitterMessenger();
     UserService service = new UserService(dbClient, messenger);

就變成了用 PostgreSQL 資料庫，然後透過 Twitter 通知使用者的程式；而 `UserService` 完全不需要更改。

# DI 的缺點 #

乍看之下 DI 似乎只有優點，但實作 DI 時也有一些需要考慮的地方。

  1. **系統架構的複雜度增加**：由於程式不再和實作的 class 相關，因此開發者追程式碼時會比較困難，實作的 class 是什麼沒辦法直接看出來的。這需要花時間來熟悉整體系統的運作才會上手。
  2. **所需寫的程式碼變多**：為了這個架構，得要多寫一些程式；這會直接的影響到開發的速度。在簡單的程式裡套用 DI，可能造成寫了許多程式結果都和商業邏輯沒有任何關係的狀況。

# 結論 #

現在有許多語言環境都會有 DI 的 framework，或者是本身就使用此 pattern 的 web application framework。但不管是在什麼環境用什麼工具，**使用 DI 目的都是在於減少程式間的耦合度**；因此如果用了這些 framework 卻沒有抓到重點所在，不但沒有減少相依性，還讓程式變複雜，反而會比不用造成更多傷害。

# References #

1. Inversion of Control Containers and the Dependency Injection pattern. By Martin Fowler. http://www.martinfowler.com/articles/injection.html
2. Wikipedia : Coupling. http://en.wikipedia.org/wiki/Coupling_%28computer_programming%29
3. Clean Coders. By Robert Martin (Uncle Bob). https://cleancoders.com/
