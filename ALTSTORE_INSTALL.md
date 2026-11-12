# 用 AltStore 把 TrailLog 装到 iPhone 上

## 需要准备的东西

- 一台电脑（Mac 或 Windows），第一次装的时候要用
- 你的 iPhone 和一根数据线
- 一个 Apple ID（免费的就行，不用充开发者会员）
- 从 GitHub Actions 下载到的 `TrailLog.ipa`

## 第一次安装 AltStore

1. 在电脑上打开 altstore.io，下载 AltServer，装好并打开。
2. 手机连上电脑，在 AltServer 的菜单里选你的手机，点安装 AltStore。
3. 按提示输入你的 Apple ID 和密码。密码只发给苹果的服务器，用来签名，不会存到别的地方。
4. 装好后，在手机上打开 设置、通用、VPN 与设备管理，找到你的 Apple ID 点信任。

## 装 TrailLog

1. 把 `TrailLog.ipa` 传到手机上（微信文件传输助手、隔空投送都行）。
2. 在手机上点开这个文件，选“用 AltStore 打开”。
3. AltStore 会用你的 Apple ID 给它签名，装好后主屏幕就有 TrailLog 了。
4. 第一次打开 TrailLog，定位权限选“始终允许”。选“使用期间”的话，锁屏后就记不了轨迹了。

## 证书每 7 天要刷新一次

免费 Apple ID 签的 App 只能用 7 天，到期前打开 AltStore 点一下刷新就行。电脑开着并且和手机在同一个 Wi-Fi 下时，AltStore 会自动刷；不在电脑边上就手动打开 AltStore 刷一下。刷新不会丢轨迹。

## 如果不想用电脑刷新

也可以用 SideStore，第一次设置麻烦一点，但之后不用电脑也能在手机上自己刷新。TrailLog 的安装包两种工具都认。
