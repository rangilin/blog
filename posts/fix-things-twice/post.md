---
date: 2015-06-18
title: Fix things twice
---

[Four Million to One (Or How I Handle Trello Support)](http://blog.fogcreek.com/four-million-to-one/)

Trello 會員數已經超過四百萬人了，但 Trello Team 的客服只有一個人。四百萬個會員，每週平均的 e-mail support case 卻只有三百多件。雖然說產業、客群不同，比例也會有影響，但這個數字還是頗讓我驚訝。綜合文章內容和我的理解，整理出了一些感想：

**1. 一個真的能解決問題的 help 網站**

也許是借用了經營 StackExchange 的經驗，他們似乎很明白要如何滿足急著找出解答的使用者。也因此 http://help.trello.com/ 是我看過最容易使用的 help 網站。先根據主題分類，再列出解答疑難雜症的文章；標題清晰扼要，內容圖文並茂。使用者通常能在三個步驟內找到自己想要看的文章。

除此之外，利用評分系統讓使用者反應文件的品質、使用 Google Analytics 分析使用者在網站上的行為；這些指標都成為了改善網站內容的依據。

於是，這個網站就成為了客服的第一道的防線。就算使用者沒有看到，也能引導有疑問的使用者來閱讀這些資訊。

**2. 團隊良好的習慣**

客服每個禮拜整理問題，一旦有 bug，或是不斷地被提出的 issue 與 feature request，團隊每個人都會知道。有了來自使用者的回饋，團隊就有施力點來改善服務。開發團隊維持著一定的 release cycle，每個月都至少有一次 release，因此問題不會石沉大海，也不會每次更新都要等個一年半載。

新的 release 一旦上線，客服又會繼續收集資訊，周而復始，一個會不斷地改善自己的服務就這樣形成了。有了這樣子的團隊和產品品質，客服的負擔自然也降低了許多。

-----

但是，追根究底，一個團隊能夠這樣子運作，究竟是怎麼做到的 ? 我想起了過去同樣在 Fog Creek Blog 上看到的一篇文章：[Scaling Customer Service by Fixing Things Twice](http://blog.fogcreek.com/scaling-customer-service-by-fixing-things-twice/)

# Fix things twice #

他們是這樣定義的：

> When a customer has a problem, don’t simply resolve their issue and move on – but rather take advantage of the issue to resolve its underlying cause. This is Fixing Things Twice.

簡單來說就是：

  * 解決當下問題
  * 防止問題再度出現

在我看來，這就是一個客服可以撐起四百萬個會員的主要原因。只解決浮出水面上的問題，一天能處理再多的客訴都沒有用。也許回答一個問題只需要五分鐘，但是花三個小時寫一篇文章在 help 網站在可以減少問題出現的次數。也許修一個 bug 只需要改一行程式，但是花一個小時把測試補齊可以讓這個問題不會再以別的形態出現在系統內。一旦持續的用這種態度來做事，自然而然團隊就會有更多的資源可以投入其他地方。

追本溯源，找出問題產生的原因，才能夠真正解決問題。
