# جلسه ۶ — ترکیب داده‌ها با Append و Merge

## 🎯 هدف جلسه

در پروژه‌های واقعی، داده‌ها اغلب در یک جدول واحد قرار ندارند. ممکن است فروش فروردین در یک فایل، فروش اردیبهشت در فایل دیگری و اطلاعات مشتری در یک جدول جدا باشد.

در این جلسه یاد می‌گیریم دو مسئله‌ی متفاوت را از هم تشخیص دهیم:

- **Append:** اضافه کردن Rowهای چند Dataset مشابه به یکدیگر
- **Merge:** وصل کردن Columnهای دو Dataset بر اساس یک Key مشترک

این تفاوت یکی از مهم‌ترین مفاهیم کار با داده در Excel و Power Query است.

---

# ۱. Append یعنی چه؟

فرض کنید سه فایل مشابه داریم:

```text
sales_jan.csv
sales_feb.csv
sales_mar.csv
```

و هر سه ساختار یکسان دارند:

| Date | Product | Quantity | Revenue |
|---|---|---:|---:|
| ... | ... | ... | ... |

هدف ما این است که Rowهای هر سه فایل زیر یکدیگر قرار بگیرند.

```text
January
  ↓
February
  ↓
March
  ↓
All Sales
```

این عملیات **Append** است.

> راه ساده برای به خاطر سپردن: **Append = Table A + Table B از نظر Row**

---

# ۲. شرط مهم Append

برای Append بهتر است ساختار جدول‌ها تا حد امکان مشابه باشد.

مثلاً اگر جدول اول این ستون‌ها را داشته باشد:

```text
Date | Product | Revenue
```

و جدول دوم:

```text
Date | Product | Revenue
```

ترکیب ساده و منطقی است.

اما اگر جدول دوم این باشد:

```text
Date | Product_Name | Amount
```

باید ابتدا تفاوت نام و ساختار ستون‌ها را بررسی کنیم.

---

# ۳. چرا قبل از Append نام منبع را نگه داریم؟

فرض کنید داده‌ی سه شرکت را ترکیب می‌کنیم:

```text
Apple.csv
Microsoft.csv
Google.csv
```

اگر فقط Rowها را روی هم قرار دهیم، بعداً ممکن است نفهمیم هر رکورد متعلق به کدام شرکت بوده است.

بهتر است یک Column مثل:

```text
Company
```

اضافه کنیم و مقدار آن را برای هر Source مشخص کنیم.

نتیجه:

| Company | Date | Price | Volume |
|---|---|---:|---:|
| Apple | ... | ... | ... |
| Apple | ... | ... | ... |
| Microsoft | ... | ... | ... |
| Google | ... | ... | ... |

این Column در تحلیل‌های بعدی بسیار ارزشمند خواهد بود.

---

# ۴. Append در Power Query

وقتی Sourceهای خود را وارد کردیم، می‌توانیم در Power Query از مسیر کلی زیر استفاده کنیم:

```text
Home
→ Combine
→ Append Queries
```

در پنجره Append می‌توان:

- دو Query را با هم ترکیب کرد؛
- یا چند Query را هم‌زمان انتخاب کرد.

بعد از تأیید، یک Query جدید با Rowهای ترکیب‌شده ایجاد می‌شود.

---

# ۵. Merge یعنی چه؟

حالا مسئله دیگری را در نظر بگیرید.

جدول سفارش داریم:

| Order_ID | Customer_ID | Product_ID | Quantity |
|---|---|---|---:|
| 1001 | C10 | P20 | 2 |
| 1002 | C12 | P11 | 1 |

و جدول Products:

| Product_ID | Product_Name | Category |
|---|---|---|
| P20 | Mouse | Accessories |
| P11 | Keyboard | Accessories |

می‌خواهیم `Product_Name` و `Category` را به جدول سفارش اضافه کنیم.

اینجا Row جدیدی اضافه نمی‌کنیم؛ می‌خواهیم **اطلاعات Columnهای جدول دوم را به جدول اول متصل کنیم.**

این عملیات **Merge** است.

> راه ساده برای به خاطر سپردن: **Merge = Join جدول‌ها از طریق Key**

---

# ۶. Join Key چیست؟

برای Merge باید مشخص کنیم کدام ستون دو جدول را به هم مرتبط می‌کند.

در مثال بالا:

```text
Orders.Product_ID
        ↕
Products.Product_ID
```

این Column همان **Join Key** است.

اگر Key اشتباه باشد، ممکن است اطلاعات اشتباه کنار سفارش‌ها قرار بگیرد.

---

# ۷. مراحل Merge

در Power Query:

1. Query اصلی را انتخاب کنید.
2. `Merge Queries` را اجرا کنید.
3. جدول دوم را انتخاب کنید.
4. Columnهای مرتبط را در هر دو جدول انتخاب کنید.
5. نوع Join را مشخص کنید.
6. نتیجه‌ی Merge را بررسی کنید.
7. Columnهای لازم را Expand کنید.

---

# ۸. Expand چیست؟

بعد از Merge معمولاً یک Column جدید ایجاد می‌شود که داخل هر Cell آن یک Table کوچک قرار دارد.

یعنی مثلاً:

```text
Orders
└── ProductInfo
      └── Product_Name
      └── Category
```

با گزینه‌ی Expand مشخص می‌کنیم کدام Columnها را از جدول دوم وارد جدول اصلی کنیم.

برای مثال:

```text
☑ Product_Name
☑ Category
☐ Internal_Note
```

این کار کمک می‌کند فقط داده‌ی موردنیاز را وارد خروجی کنیم.

---

# ۹. نوع Join مهم است

Merge فقط یک نوع اتصال ندارد. بسته به مسئله می‌توان نوع Join را تغییر داد.

مهم‌ترین حالت‌ها:

| Join | معنی ساده |
|---|---|
| Inner | فقط رکوردهایی که در هر دو جدول Match دارند |
| Left | همه رکوردهای جدول اول + Matchهای جدول دوم |
| Right | همه رکوردهای جدول دوم + Matchهای جدول اول |
| Full | همه رکوردهای هر دو طرف |

در تحلیل داده، **Left Join** بسیار پرکاربرد است؛ مثلاً می‌خواهیم همه سفارش‌ها را نگه داریم و در صورت وجود، اطلاعات مشتری را به آن‌ها اضافه کنیم.

---

# ۱۰. Missing Match

فرض کنید در Orders مقدار `P99` وجود دارد ولی در Products چنین محصولی نداریم.

اگر Left Join انجام دهیم، سفارش باقی می‌ماند ولی اطلاعات محصول برای آن خالی خواهد بود.

این وضعیت اتفاقاً یک سرنخ مهم برای Data Quality است.

یعنی Merge علاوه بر ترکیب داده، می‌تواند مشکل‌های Dataset را هم آشکار کند.

---

# ۱۱. یک مثال کامل

سه منبع داریم:

```text
Orders
Customers
Products
```

می‌خواهیم گزارش نهایی شامل این ستون‌ها باشد:

```text
Order_ID
Customer_Name
City
Product_Name
Category
Quantity
Amount
```

Workflow:

```text
Orders
   ↓ Merge on Customer_ID
Customers
   ↓ Expand Name, City
   ↓ Merge on Product_ID
Products
   ↓ Expand Product_Name, Category
   ↓
Final Sales Dataset
```

این یکی از مهم‌ترین الگوهایی است که در پروژه‌های واقعی تحلیل داده با آن مواجه خواهید شد.

---

# ۱۲. تفاوت Append و Merge در یک جدول

| سؤال | عملیات |
|---|---|
| «می‌خواهم ردیف‌های دو جدول مشابه را زیر هم قرار دهم.» | Append |
| «می‌خواهم اطلاعات جدول دوم را بر اساس یک ID به جدول اول اضافه کنم.» | Merge |

مثال:

```text
January + February → Append
Orders + Customers → Merge
```

---

# 🧩 تمرین عملی

سه فایل CSV با ساختار زیر بسازید:

### File 1
```text
sales_jan.csv
```

### File 2
```text
sales_feb.csv
```

### File 3
```text
sales_mar.csv
```

هر سه شامل:

```text
Date
Customer_ID
Product_ID
Quantity
Amount
```

سپس دو فایل مستقل برای اطلاعات مشتری و محصول بسازید.

### کارها

1. سه فایل فروش را Import کنید.
2. یک Column به نام `Month` به هر Query اضافه کنید.
3. سه Query را Append کنید.
4. Orders را با Customers بر اساس Customer_ID Merge کنید.
5. Orders را با Products بر اساس Product_ID Merge کنید.
6. فقط Columnهای موردنیاز را Expand کنید.
7. رکوردهایی را پیدا کنید که Product_ID آن‌ها در Products وجود ندارد.

### Challenge
یک مثال پیدا کنید که در آن Append انتخاب اشتباهی باشد و Merge راه‌حل درست باشد؛ سپس برعکس.

---

# 🧠 نکات کلیدی

> **Append برای روی هم گذاشتن Rowهای چند Dataset است.**

> **Merge برای وصل کردن اطلاعات بر اساس یک Key مشترک است.**

> **Before Merge, Join Key را بررسی کنید.**

> **یک Match ناقص در Merge می‌تواند نشانه‌ی مشکل Data Quality باشد.**

> **بهتر است هنگام Append منبع هر رکورد را هم حفظ کنیم.**

---

## جلسه بعد

در جلسه‌ی بعد با **Consolidate** آشنا می‌شویم؛ ابزاری مناسب برای بعضی سناریوهایی که چند محدوده‌ی مشابه داریم و می‌خواهیم نتیجه‌ی تجمیعی مانند Sum یا Average از آن‌ها بسازیم.
