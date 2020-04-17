---
layout: post
title: "Node.jsの非同期処理についてPromiseから理解しようとしてみた"
description: "Promiseについて学習した内容をまとめました。"
author: Ryota
tags: ["JavaScript"]
image: "./img/michael-sum-LEpfefQf4rU-unsplash.jpg"
date: "2019-04-17"
draft: false
---

## はじめに

今回は、Node.jsの非同期処理について、自分の備忘録も兼ねて記事を作成しました。

私はJavaScriptの言語仕様なんかをあまり知らない状態でNode.jsを触ったせいで、非同期処理に関する部分ではまり、多くの時間を無駄にしてしまいました。

かなり初歩的な内容かもしれませんが、勉強した内容をまとめます。

## 同期処理とは？

**上から順番にプログラムが実行されていくこと**です。

「上から順番に」という言葉が適切かどうか分かりませんが、「一つ一つの処理が、一個前の処理の終了をまって処理されていく」っていう説明よりは個人的に分かりやすい気がします。

コードにすると、下記の通りです。

```js
console.log(1);
console.log(2);
console.log(3);
console.log(4);
console.log(5);
```

実行結果は、下記のようになります。

```js
1
2
3
4
5
```

## 非同期処理とは？

同期処理ではないものが非同期処理なので、**上から順番にプログラムを実行されないこと**と言えます。

JavaScriptでは、ユーザーの入力やAPIを叩いてデータを持ってくる時、それからファイルを操作する時などに、非同期処理になります。

これはJavaScriptがシングルスレッドなので、そういった「制約」を非同期で処理することによっってフォローしています。

コードにすると、下記の通りです。

ここでは例として、遅延処理を用いています。

```js
const three = () => {
  setTimeout(() => {
    console.log(3);
  }, 1000);
}

console.log(1);
console.log(2);
three();
console.log(4);
console.log(5);
```

実行結果は、下記のようになります。

```js
1
2
4
5
3
```

setTimeoutで処理の実行が1秒後に設定されたthree関数が呼び出されています。

これが同期処理であれば、実行結果としては順番に1から5までの数字が出力されますが、Node.jsではこういった処理は非同期になるので、three関数の終了を待たずに次の処理へ進み、最後にthree関数の結果が返されています。

これが非同期処理です。

## Promiseとは？

### なぜPromiseが必要か？

上記で述べた非同期処理ですが、何でもかんでも非同期処理にすると不都合なこともあります。

例えば、ファイルの内容を読み込んで、ファイルの中身を出力するような場合、

(hogeと書かれたhoge.txtというファイルが存在するとします)

```js
const fs = require('fs');

const result = fs.readFile('hoge.txt');
console.log(result);
```

上記のコードだと、hoge.txtを読み込む処理は非同期に処理されます。

しかし、hoge.txtを読み込み終わるより先にresultが出力されてしまうので、上記のようなコードでは想定する結果を得ることができません。

そんな時に使えるのが、Promiseです！

Promiseは、その名の通り、その処理を行うことを約束することができます。

もっと簡単にいうと、Promiseを使えば本来非同期に行われる処理を、同期処理のように書くことができます。

上記のようなケースを解決するためには、Promiseが必須なのです。

### Promiseの使い方

Promiseオブジェクトを返す関数を定義します。基本的にはそれだけです。

試しに先ほどのhoge.txtを読み込むコードのうち、実際にファイルを読み込む処理の部分をPromiseを使って同期的に処理できるように書き換えてみます。

```js
const fs = require('fs');

const readAsync = return new Promise((resolve, reject) => {
  resolve(fs.readFile('hoge.txt'));
})
```

これでPromiseオブジェクトを返す関数を作成できました。

あとはconsole.logで出力するタイミングを、この関数の処理が実行された後になるように全体のコードを書き換えます。

このような処理をするときは、非同期関数に.then節を記述します。

```js
const fs = require('fs');

const readAsync = return new Promise((resolve, reject) => {
  resolve(fs.readFile('hoge.txt'));
})

readAsync().then((result) => {
  console.log(result);
})
```

これでファイルが読み込まれるのを待ってからconsole.logでファイルの中身が出力されるようになります！

Promiseオブジェクト作成の際に引数に渡しているresolveとrejectですが、

resolveには非同期処理が成功した時に値が入り、失敗した時にはrejectに値が入ります。

例えば、存在しないfuga.txtというファイルを読み込もうとした場合、非同期関数の結果は失敗になるので、上記の例のようにresolveではなく、rejectに値が入ります。

```js
const fs = require('fs');

const readAsync = return new Promise((resolve, reject) => {
  reject('指定されたファイルは見つかりません');
})

readAsync().then((result) => {
  console.log(result);
}).catch((err) => {
  console.log(err);
})
```

Promiseオブジェクトを返す非同期関数の.catch節でエラーをハンドリングしています。

上記のコードの場合、下記のような出力になります。

```js
指定されたファイルは見つかりません
```

### Promise.allとPromise.raceについて

Promise.allとPromise.raceはどちらも複数の非同期関数を実行するためのものです。

それぞれの違いは、Promise.allは指定した全ての関数がresolveでもrejectでも全ての関数が実行されます。

Promise.raceは、指定した全ての関数の中で一つでもresolveまたはrejectになったら、その関数の結果のみを返して処理を終了します。

また、Promise.allでは実行の順番を保証するので、例えば下記のようなコードでも出力は順番通りになります。

```js
const a = return new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve(1);
  }, 10 * 1000); // 10秒待つ
})

const b = return new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve(2);
  }, 5 * 1000); // 5秒待つ
})

const c = return new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve(3);
  }, 1 * 1000); // 1秒待つ
})

Promise.all([a, b, c]).then((values) => {
  console.log(values[0]);
  console.log(values[1]);
  console.log(values[2]);
})
```

setTimeoutの値を見ると、出力される値の順番的には3, 2, 1となりそうですが、実際の出力は、

```js
1
2
3
```

となります。

Promise.raceのソースは下記のようになります。

返す値は関数一つ分なので、Promise.allのように配列で受け取る必要はありません。

```js
const a = return new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve(1);
  }, 10 * 1000); // 10秒待つ
})

const b = return new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve(2);
  }, 5 * 1000); // 5秒待つ
})

const c = return new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve(3);
  }, 1 * 1000); // 1秒待つ
})

Promise.race([a, b, c]).then((value) => {
  console.log(value);
})
```

上記のコードだと、一番早く処理が終わるのは非同期関数bなので、出力は、

```js
2
```

となります。

## おわりに

ジャバスクリプトムズカシイ。
