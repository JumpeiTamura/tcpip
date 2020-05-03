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
ip netns exec ns1 tcpdump -tnel -i ns1-veth0 icmp or arp
```
