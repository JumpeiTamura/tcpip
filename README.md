# 目次
- [Network Namespace(netns)の使い方](#network-namespacenetnsの使い方)
- [netnsを使ったネットワーク構築方法](#netnsを使ったネットワーク構築方法)
- [routerを使った通信](#routerを使った通信)
- [routerを2つ使った通信](#routerを2つ使った通信)
- [イーサネットに関するコマンド](#イーサネットに関するコマンド)
- [bridgeを使ったネットワーク構築方法](#bridgeを使ったネットワーク構築方法)
- [DHCPを使ったネットワーク設定](#dhcpを使ったネットワーク設定)
- [NATについて](#natについて)
- [Source NATでIPアドレスの書き換え](#source-natでipアドレスの書き換え)
- [Destinaton NATでIPアドレスの書き換え](#destinaton-natでipアドレスの書き換え)

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
![veth](https://github.com/JumpeiTamura/tcpip/blob/master/img/ns-veth.png "veth")

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

# routerを使った通信
## 目標の構成図
![router](https://github.com/JumpeiTamura/tcpip/blob/master/img/ns-router.png "router")

## netns作成
```
ip netns add ns1
ip netns add ns2
ip netns add router
ip netns list
```

## veth作成
```
ip link add ns1-veth0 type veth peer name gw-veth0
ip link add ns2-veth0 type veth peer name gw-veth1
```

## 作成したvethをnetnsに割り当て
```
ip link set ns1-veth0 netns ns1
ip link set gw-veth0 netns router
ip link set gw-veth1 netns router
ip link set ns2-veth0 netns ns2
```

## vethにIPアドレスを割り当て
```
ip netns exec ns1 ip addr add 192.0.2.1/24 dev ns1-veth0
ip netns exec router ip addr add 192.0.2.254/24 dev gw-veth0
ip netns exec router ip addr add 198.51.100.254/24 dev gw-veth1
ip netns exec ns2 ip addr add 198.51.100.1/24 dev ns2-veth0
```

## vethのステータスをUP
```
ip netns exec ns1 ip link set ns1-veth0 up
ip netns exec router ip link set gw-veth0 up
ip netns exec router ip link set gw-veth1 up
ip netns exec ns2 ip link set ns2-veth0 up
```

## routerの有効化
```
ip netns exec router sysctl net.ipv4.ip_forward=1
```

## デフォルトルートの設定
```
ip netns exec ns1 ip route add default via 192.0.2.254
ip netns exec ns2 ip route add default via 198.51.100.254
```

## 疎通確認
### ns1 -> router
```
ip netns exec ns1 ping -c 3 192.0.2.254
```
### ns2 -> router
```
ip netns exec ns2 ping -c 3 198.51.100.254
```
### ns1 -> ns2
```
ip netns exec ns1 ping -c 3 198.51.100.1
```

# routerを2つ使った通信
## 目標の構成図
![router2](https://github.com/JumpeiTamura/tcpip/blob/master/img/ns-router2.png "router2")

## netns作成
```
ip netns add ns1
ip netns add ns2
ip netns add router1
ip netns add router2
ip netns list
```

## veth作成
```
ip link add ns1-veth0 type veth peer name gw1-veth0
ip link add gw1-veth1 type veth peer name gw2-veth0
ip link add gw2-veth1 type veth peer name ns2-veth0
```

## 作成したvethをnetnsに割り当て
```
ip link set ns1-veth0 netns ns1
ip link set gw1-veth0 netns router1
ip link set gw1-veth1 netns router1
ip link set gw2-veth0 netns router2
ip link set gw2-veth1 netns router2
ip link set ns2-veth0 netns ns2
```

## vethにIPアドレスを割り当て
```
ip netns exec ns1 ip addr add 192.0.2.1/24 dev ns1-veth0
ip netns exec router1 ip addr add 192.0.2.254/24 dev gw1-veth0
ip netns exec router1 ip addr add 203.0.113.1/24 dev gw1-veth1
ip netns exec router2 ip addr add 203.0.113.2/24 dev gw2-veth0
ip netns exec router2 ip addr add 198.51.100.254/24 dev gw2-veth1
ip netns exec ns2 ip addr add 198.51.100.1/24 dev ns2-veth0
```

## vethのステータスをUP
```
ip netns exec ns1 ip link set ns1-veth0 up
ip netns exec router1 ip link set gw1-veth0 up
ip netns exec router1 ip link set gw1-veth1 up
ip netns exec router2 ip link set gw2-veth0 up
ip netns exec router2 ip link set gw2-veth1 up
ip netns exec ns2 ip link set ns2-veth0 up
```

## routerの有効化
```
ip netns exec router1 sysctl net.ipv4.ip_forward=1
ip netns exec router2 sysctl net.ipv4.ip_forward=1
```

## ルーティングテーブルの設定
```
ip netns exec ns1 ip route add default via 192.0.2.254
ip netns exec router1 ip route add 198.51.100.0/24 via 203.0.113.2
ip netns exec router2 ip route add 192.0.2.0/24 via 203.0.113.1
ip netns exec ns2 ip route add default via 198.51.100.254
```

## 疎通確認
### ns1 -> ns2
```
ip netns exec ns1 ping -c 3 198.51.100.1
```

# イーサネットに関するコマンド
## MACアドレスの変更
```
ip netns exec [ns-name] ip link set dev [veth-name] address [mac-address]
ip netns exec [ns-name] ip link show
```

## ARP(Address Resolution Protocol)キャッシュの削除
```
ip netns exec [ns-name] ip neigh flush all
```

## MACアドレスとARPを含めたtcpdump
```
ip netns exec [ns-name] tcpdump -tnel -i [veth-name] icmp or arp
ip netns exec [ns-name] ping -c 3 [ip-address]
```

## ARPキャッシュの表示
```
ip netns exec [ns-name] ip neigh
```

# bridgeを使ったネットワーク構築方法
## 目標の構成図
![br](https://github.com/JumpeiTamura/tcpip/blob/master/img/ns-br.png "br")

## netns作成
```
ip netns add ns1
ip netns add ns2
ip netns add ns3
```

## veth作成
```
ip link add ns1-veth0 type veth peer name ns1-br0
ip link add ns2-veth0 type veth peer name ns2-br0
ip link add ns3-veth0 type veth peer name ns3-br0
```

## 作成したvethをnetnsに割り当て
```
ip link set ns1-veth0 netns ns1
ip link set ns2-veth0 netns ns2
ip link set ns3-veth0 netns ns3
```

## vethにIPアドレスを割り当て
```
ip netns exec ns1 ip addr add 192.0.2.1/24 dev ns1-veth0
ip netns exec ns2 ip addr add 192.0.2.2/24 dev ns2-veth0
ip netns exec ns3 ip addr add 192.0.2.3/24 dev ns3-veth0
```

## vethにMACアドレスを割り当て
```
ip netns exec ns1 ip link set ns1-veth0 address 00:00:5E:00:53:01
ip netns exec ns2 ip link set ns2-veth0 address 00:00:5E:00:53:02
ip netns exec ns3 ip link set ns3-veth0 address 00:00:5E:00:53:03
```

## vethのステータスをUP
```
ip netns exec ns1 ip link set ns1-veth0 up
ip netns exec ns2 ip link set ns2-veth0 up
ip netns exec ns3 ip link set ns3-veth0 up
```

## bridgeの作成
```
ip link add br0 type bridge
ip link set br0 up
```

## vethをbridgeに接続
```
ip link set ns1-br0 master br0
ip link set ns2-br0 master br0
ip link set ns3-br0 master br0

ip link set ns1-br0 up
ip link set ns2-br0 up
ip link set ns3-br0 up
```

## 疎通確認
```
ip netns exec ns1 ping -c 3 192.0.2.2
ip netns exec ns1 ping -c 3 192.0.2.3
```

## bridgeのMACアドレステーブルの確認
```
bridge fdb show br br0 | grep -i 00:00:5e
```

# DHCPを使ったネットワーク設定
## やってくれること
- IPアドレスの割り当て
- ルーティングテーブルの設定
- DNSサーバの設定
- NTPサーバの設定

## 目標の構成図
![dhcp](https://github.com/JumpeiTamura/tcpip/blob/master/img/ns-dhcp.png "dhcp")
※dockerだとdhclientが使えなかったのでホストマシン上に直に構築した。

## netns作成
```
ip netns add client
ip netns add server
```
## veth作成
```
ip link add c-veth0 type veth peer name s-veth0
```
## 作成したvethをnetnsに割り当て
```
ip link set c-veth0 netns client
ip link set s-veth0 netns server
```
## vethにIPアドレスを割り当て
```
ip netns exec server ip addr add 192.0.2.254/24 dev s-veth0
```
## vethのステータスをUP
```
ip netns exec client ip link set c-veth0 up
ip netns exec server ip link set s-veth0 up
```

## DHCPサーバの起動
```
ip netns exec server dnsmasq \
--dhcp-range=192.0.2.100,192.0.2.200,255.255.255.0 \
--interface=s-veth0 \
--no-daemon
```

## clientからserverにアクセス
```
ip netns exec client dhclient c-veth0
```

## 設定内容確認
```
# IPアドレス
ip netns exec client ip addr show | grep "inet"
# ルーティングテーブル
ip netns exec client ip route show
```

## 疎通確認
```
ip netns exec server ping -c 3 [設定されたclientのIPアドレス]
```

# NATについて
## NATとは
- Network Address Translation 
- ローカルIPはそのままだと使えない（グローバルと違って一意に特定できないので、パケットを送れない）
- ローカルIPを何らかの方法でグローバルIPに変換する必要がある
- IPだけでなくPortも書き換えるのでNAPTとも言う
- Source NATとDestination NATがある
- Source NAT : Source（送信元）を書き換えるよ
- Destination NAT : Destination（送信先）を書き換えるよ

# Source NATでIPアドレスの書き換え
## Source NATとは
- LAN内から送られたパケットのローカルIPとPortをグローバル（ルータのIPとPort）に書き換える
- 書き換え前後の対応表（セッション）を管理
- 受信時は逆にグローバルをローカルに変換

## 目標の構成図
![snat](https://github.com/JumpeiTamura/tcpip/blob/master/img/ns-snat.png "snat")

## netns作成
```
ip netns add lan
ip netns add wan
ip netns add router
```

## veth作成
```
ip link add lan-veth0 type veth peer name gw-veth0
ip link add wan-veth0 type veth peer name gw-veth1
```

## 作成したvethをnetnsに割り当て
```
ip link set lan-veth0 netns lan
ip link set gw-veth0 netns router
ip link set gw-veth1 netns router
ip link set wan-veth0 netns wan
```

## vethにIPアドレスを割り当て
```
ip netns exec lan ip addr add 192.0.2.1/24 dev lan-veth0
ip netns exec router ip addr add 192.0.2.254/24 dev gw-veth0
ip netns exec router ip addr add 203.0.113.254/24 dev gw-veth1
ip netns exec wan ip addr add 203.0.113.1/24 dev ns2-veth0
```

## vethのステータスをUP
```
ip netns exec lan ip link set lan-veth0 up
ip netns exec router ip link set gw-veth0 up
ip netns exec router ip link set gw-veth1 up
ip netns exec wan ip link set wan-veth0 up
```

## routerの有効化
```
ip netns exec router sysctl net.ipv4.ip_forward=1
```

## デフォルトルートの設定
```
ip netns exec lan ip route add default via 192.0.2.254
ip netns exec wan ip route add default via 203.0.113.254
```

## iptablesの設定
```
ip netns exec router iptables -t nat \
-A POSTROUTING \  # パケットが出ていく直前のタイミングで
-s 192.0.2.0/24 \ # 送信元IPアドレスの範囲はこれ
-o gw-veth1 \ # 出力先のインターフェースはgw-veth1
-j MASQUERADE # ルールはマスカレード(Source NAT)
```

## iptablesの確認
```
ip netns exec router iptables -t nat -L
```

## 疎通確認
### ns1 -> ns2
```
ip netns exec ns1 ping 203.0.113.1
```

### lan側のtcpdump
```
ip netns exec lan tcpdump -tnl -i lan-veth0 icmp
# lan <-> wan のIPアドレスが表示される
```

### wan側のtcpdump
```
ip netns exec wan tcpdump -tnl -i wan-veth0 icmp
# router <-> wan のIPアドレスが表示される
# IPアドレスが書き換えられた！
```

# Destinaton NATでIPアドレスの書き換え
## Destination NAT(DNAT)とは
- サーバ用途で使われるノードはグローバルから通信できる必要がある
- このため、Source NATとは逆にグローバルIPをローカルIPに変換する必要がある
- 具体的にはポート番号とローカルIPを対応させる
- 一般的にポート開放と言われてるやつはこれ

## 目標の構成図
※Source NATのときと同じ構成を利用するので引き続きやる場合は設定不要
![snat](https://github.com/JumpeiTamura/tcpip/blob/master/img/ns-snat.png "snat")

## DNATの設定
```
ip netns exec router iptables -t nat \
-A PREROUTING \ # パケットが入ってきたタイミングで
-p tcp \  # TCPプロトコルで
--dport 54321 \ # 54321ポートで
-d 203.0.113.254 \  # 送信先IPがこれの場合
-j DNAT \ # ルールはDNATで
--to-destination 192.0.2.1  # 送信先はこれに変換する
```

## iptablesの確認
```
ip netns exec router iptables -t nat -L
```

## サーバ起動
```
ip netns exec lan nc -lnv 54321
```

## クライアントからアクセス
```
ip netns exec wan nc 203.0.113.254 54321
```

## クライアント側をtcpdump
```
ip netns exec wan tcpdump -tnl -i wan-veth0 "tcp and port 54321"
# wan <-> router のIPアドレスが表示される
```

## サーバ側をtcpdump
```
ip netns exec lan tcpdump -tnl -i lan-veth0 "tcp and port 54321"
# wan <-> lan のIPアドレスが表示される
# IPアドレスが書き換えられた！
```
