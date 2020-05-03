# Network Namespace(netns)の使い方
## 新規作成
```
ip netns add [name]
```
## 一覧
```
ip netns list
```
## コマンド
```
ip netns exec [name] [command]
```
## 削除
```
ip netns delete [name]
```
# netnsを使ったネットワーク構築方法
## 目標の構成図
![エビフライトライアングル](http://i.imgur.com/Jjwsc.jpg "サンプル")
## netns作成
```
ip netns add ns1
ip netns add ns2
ip netns list
```
## veth作成
```
ip link add ns1-veth0 type veth peer name ns2-veth0
ip link show | grep veth
```
## 作成したvethをnetnsに割り当て
```
ip link set ns1-veth0 netns ns1
ip link set ns2-veth0 netns ns2
ip link show | grep veth
ip netns exec ns1 ip link show | grep veth
ip netns exec ns2 ip link show | grep veth
```
## vethにIPアドレスを割り当て
```
ip netns exec ns1 ip addr add 192.0.2.1/24 dev ns1-veth0
ip netns exec ns2 ip addr add 192.0.2.2/24 dev ns2-veth0
```
## vethのステータスをUP
```
ip netns exec ns1 ip link set ns1-veth0 up
ip netns exec ns2 ip link set ns2-veth0 up
```
## 疎通確認
```
ip netns exec ns1 ping -c 3 192.0.2.2
```

