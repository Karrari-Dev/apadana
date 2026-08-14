# Apadana

VPN control panel for your own server.  
**OpenVPN** · **WireGuard** · **Cisco AnyConnect** · **L2TP/IPsec**

Manage users, traffic, sessions, connection limits, remote nodes, resellers, and the customer subscription page from one dashboard.

| | |
|--|--|
| OS | Ubuntu **22.04** / **24.04** (amd64) |
| License | Commercial — one key, one panel, one public IP |

---

## English

### Install

On a clean Ubuntu host, as `root`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/apadana-vpn/apadana-panel/main/get-apadana.sh) --yes
```

This downloads the latest [Release](https://github.com/apadana-vpn/apadana-panel/releases) and installs the panel.

Then:

1. Open `http://SERVER_IP:3000/login` and create the admin account  
2. Activate your license in the UI, or run `apadana-panel license activate KEY`  
3. Optional server menu: `apadana`

Admin UI port: **3000** · subscription portal: **3001**

### Update

```bash
apadana-panel panel-host backup-create
bash <(curl -fsSL https://raw.githubusercontent.com/apadana-vpn/apadana-panel/main/get-apadana.sh) --yes
```

### Support

- Channel: [t.me/YOUR_CHANNEL](https://t.me/panel_apadana)  
- Support: [t.me/YOUR_SUPPORT](https://t.me/G0dline)

---

## فارسی

پنل مدیریت VPN روی سرور خودتان. کاربران، ترافیک، محدودیت اتصال، نودهای جدا، نمایندگی و صفحهٔ اشتراک مشتری از یک داشبورد.

### نصب

روی Ubuntu تمیز، با `root`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/apadana-vpn/apadana-panel/main/get-apadana.sh) --yes
```

آخرین [Release](https://github.com/apadana-vpn/apadana-panel/releases) دانلود و نصب می‌شود.

بعد:

1. `http://IP_SERVER:3000/login` — ساخت حساب مدیر  
2. فعال‌سازی لایسنس در پنل، یا `apadana-panel license activate KEY`  
3. منوی سرور (اختیاری): `apadana`

پورت پنل: **3000** · پرتال اشتراک: **3001**

### به‌روزرسانی

```bash
apadana-panel panel-host backup-create
bash <(curl -fsSL https://raw.githubusercontent.com/apadana-vpn/apadana-panel/main/get-apadana.sh) --yes
```

### پشتیبانی

- کانال: [t.me/YOUR_CHANNEL](https://t.me/YOUR_CHANNEL)  
- پشتیبانی: [t.me/YOUR_SUPPORT](https://t.me/YOUR_SUPPORT)
