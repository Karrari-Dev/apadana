# Apadana — پنل مدیریت VPN چندپروتکلی (OpenVPN, WireGuard, Cisco AnyConnect, L2TP/IPsec)
# Apadana

VPN control panel for your own server.  
**OpenVPN** · **WireGuard** · **Cisco AnyConnect** · **L2TP/IPsec**
<img width="2540" height="1394" alt="Screenshot 2026-08-28 003550" src="https://github.com/user-attachments/assets/503cfb9b-325d-4406-b82c-986b7c2d9842" />

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
bash <(curl -fsSL https://raw.githubusercontent.com/Karrari-Dev/apadana/main/get-apadana.sh) --yes
```

This downloads the latest [Release](https://github.com/Karrari-Dev/apadana/releases) and installs the panel.

Then:

1. Open `http://SERVER_IP:3000/login` and create the admin account  
2. Activate your license in the UI, or run `apadana-panel license activate KEY`  
3. Optional server menu: `apadana`

Admin UI port: **3000** · subscription portal: **3001**

### Update

```bash
apadana-panel panel-host backup-create
bash <(curl -fsSL https://raw.githubusercontent.com/Karrari-Dev/apadana/main/get-apadana.sh) --yes
```

### Support

- Channel: [t.me/panel_apadana](https://t.me/panel_apadana)  
- Support: [t.me/G0dline](https://t.me/G0dline)

---

## فارسی

پنل مدیریت VPN روی سرور خودتان. کاربران، ترافیک، محدودیت اتصال، نودهای جدا، نمایندگی و صفحهٔ اشتراک مشتری از یک داشبورد.

### نصب

روی Ubuntu تمیز، با `root`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Karrari-Dev/apadana/main/get-apadana.sh) --yes
```

آخرین [Release](https://github.com/Karrari-Dev/apadana/releases) دانلود و نصب می‌شود.

بعد:

1. `http://IP_SERVER:3000/login` — ساخت حساب مدیر  
2. فعال‌سازی لایسنس در پنل، یا `apadana-panel license activate KEY`  
3. منوی سرور (اختیاری): `apadana`

پورت پنل: **3000** · پرتال اشتراک: **3001**

### به‌روزرسانی

```bash
apadana-panel panel-host backup-create
bash <(curl -fsSL https://raw.githubusercontent.com/Karrari-Dev/apadana/main/get-apadana.sh) --yes
```

### پشتیبانی

- کانال: [t.me/panel_apadana](https://t.me/panel_apadana)  
- پشتیبانی: [t.me/G0dline](https://t.me/G0dline)
