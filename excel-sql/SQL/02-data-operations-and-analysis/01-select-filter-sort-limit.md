# درس ۱ — خواندن و انتخاب داده با SELECT

## مسئله‌ای که حل می‌کنیم

فرض کنید مدیر فروش می‌خواهد فهرست سفارش‌های تکمیل‌شده هفته گذشته را ببیند؛ اما نیازی به تمام ستون‌های دیتابیس ندارد. ما باید فقط اطلاعات مورد نیاز را استخراج کنیم و نتیجه را به شکل قابل بررسی تحویل دهیم.

برای اجرای مثال‌ها دیتابیس تمرینی فروشگاه را فعال کنید:

```sql
USE bootcamp_retail;
```

## ۱. ساختار پایه SELECT

```sql
SELECT column_name
FROM table_name;
```

برای مثال، نام شهر و تاریخ ثبت‌نام مشتریان:

```sql
SELECT full_name, city, signup_date
FROM customers;
```

اگر واقعاً به همه ستون‌ها نیاز داشته باشیم می‌توانیم از `*` استفاده کنیم:

```sql
SELECT *
FROM products;
```

اما در Queryهای تحلیلی بهتر است ستون‌های مورد نیاز را صریح بنویسیم؛ خروجی خواناتر می‌شود و از انتقال داده‌های اضافی جلوگیری می‌کنیم.

### نام مستعار برای ستون‌ها

با `AS` می‌توانیم عنوان مناسب‌تری برای خروجی بسازیم:

```sql
SELECT
    product_name AS product,
    unit_price AS current_price
FROM products;
```

Alias فقط نامی است که در نتیجه Query نمایش داده می‌شود؛ نام واقعی ستون در جدول تغییر نمی‌کند.

## ۲. فیلتر ردیف‌ها با WHERE

`WHERE` مشخص می‌کند کدام ردیف‌ها در نتیجه باقی بمانند.

```sql
SELECT order_id, customer_id, order_date, status
FROM orders
WHERE status = 'completed';
```

### عملگرهای مقایسه

| عملگر | معنی |
|---|---|
| `=` | مساوی |
| `<>` یا `!=` | نامساوی |
| `>` و `<` | بزرگ‌تر و کوچک‌تر |
| `>=` و `<=` | بزرگ‌تر/کوچک‌تر یا مساوی |

مثال: محصولات با قیمت حداقل یک میلیون:

```sql
SELECT product_name, unit_price
FROM products
WHERE unit_price >= 1000000;
```

### ترکیب شرط‌ها

- `AND`: همه شرط‌ها باید درست باشند.
- `OR`: درست بودن حداقل یکی از شرط‌ها کافی است.
- `NOT`: نتیجه یک شرط را معکوس می‌کند.

```sql
SELECT order_id, order_date, status
FROM orders
WHERE status = 'completed'
  AND order_date >= '2025-04-01';
```

برای ترکیب AND و OR از پرانتز استفاده کنید تا اولویت شرط‌ها روشن باشد:

```sql
SELECT *
FROM products
WHERE active = TRUE
  AND (category = 'Office' OR category = 'Stationery');
```

## ۳. فیلترهای پرکاربرد

### IN و NOT IN

وقتی یک ستون باید با یکی از چند مقدار برابر باشد، `IN` خواناتر از چند OR است:

```sql
SELECT customer_id, full_name, city
FROM customers
WHERE city IN ('Isfahan', 'Shiraz');
```

### BETWEEN

برای بررسی قرار گرفتن در یک بازه استفاده می‌شود. دو سر بازه نیز شامل می‌شوند:

```sql
SELECT product_name, unit_price
FROM products
WHERE unit_price BETWEEN 500000 AND 2000000;
```

برای تاریخ و زمان، بهتر است در بازه‌های روزانه از مرز شروع و مرز پایانِ انحصاری استفاده کنیم تا ساعت‌های روز آخر از قلم نیفتند:

```sql
SELECT order_id, order_date
FROM orders
WHERE order_date >= '2025-04-01'
  AND order_date <  '2025-05-01';
```

### LIKE

برای جست‌وجوی الگو در متن از `LIKE` استفاده می‌کنیم:

| الگو | معنی |
|---|---|
| `'A%'` | شروع متن با A |
| `'%son'` | پایان متن با son |
| `'%book%'` | وجود book در هر جای متن |
| `'A_'` | دو کاراکتر که اولی A است |

```sql
SELECT full_name, email
FROM customers
WHERE email LIKE '%@example.com';
```

حساس بودن یا نبودن جست‌وجوی متنی به Collation ستون و عبارت وابسته است؛ در محیط‌های مختلف ممکن است رفتار بزرگی و کوچکی حروف متفاوت باشد.

### بررسی NULL

برای مقادیر ناموجود از `IS NULL` و `IS NOT NULL` استفاده کنید:

```sql
SELECT *
FROM customers
WHERE city IS NULL;
```

این عبارت درست نیست: `city = NULL`. مقدار NULL با عملگر مساوی معمولی مقایسه نمی‌شود؛ زیرا به معنی مقدار نامعلوم است.

## ۴. مرتب‌سازی با ORDER BY

```sql
SELECT product_name, category, unit_price
FROM products
ORDER BY unit_price DESC;
```

- `ASC`: صعودی؛ مقدار کوچک‌تر زودتر می‌آید.
- `DESC`: نزولی؛ مقدار بزرگ‌تر زودتر می‌آید.
- اگر جهت مشخص نشود، ترتیب پیش‌فرض صعودی است.

مرتب‌سازی چندستونی:

```sql
SELECT product_name, category, unit_price
FROM products
ORDER BY category ASC, unit_price DESC;
```

ابتدا دسته‌بندی مرتب می‌شود و داخل هر دسته، کالاها از گران به ارزان قرار می‌گیرند.

## ۵. محدود کردن نتیجه با LIMIT

```sql
SELECT product_name, unit_price
FROM products
ORDER BY unit_price DESC
LIMIT 3;
```

این Query سه محصول گران‌تر را نشان می‌دهد.

برای صفحه‌بندی می‌توان از Offset استفاده کرد:

```sql
SELECT order_id, order_date
FROM orders
ORDER BY order_date DESC, order_id DESC
LIMIT 10 OFFSET 10;
```

این دستور ۱۰ ردیف پس از ۱۰ ردیف اول را برمی‌گرداند. وجود `ORDER BY` هنگام استفاده از LIMIT مهم است؛ بدون ترتیب مشخص، نمی‌توان تضمین کرد کدام ردیف‌ها در هر اجرا انتخاب می‌شوند.

## ۶. ترتیب نوشتن بخش‌های اصلی Query

```sql
SELECT ...
FROM ...
WHERE ...
GROUP BY ...
HAVING ...
ORDER BY ...
LIMIT ...;
```

این ترتیب نوشتن Query است. درک تفاوت فیلتر کردن ردیف‌ها با فیلتر کردن گروه‌ها، در درس بعدی هنگام یادگیری GROUP BY اهمیت پیدا می‌کند.

## یک تمرین کوتاه

با جدول‌های دیتابیس فروشگاه Queryهایی بنویسید که:

1. فقط سفارش‌های `completed` و `shipped` را نمایش دهند.
2. سفارش‌های ثبت‌شده در ماه آوریل ۲۰۲۵ را پیدا کنند.
3. مشتریان شهرهای اصفهان و شیراز را نمایش دهند.
4. سه محصول ارزان‌تر را پیدا کنند.
5. محصولاتی را بیابند که نام آن‌ها شامل واژه `USB` است.

## چالش تحلیلی

مدیر فروش می‌خواهد «پنج سفارش اخیرِ تکمیل‌شده» را ببیند. فقط شناسه سفارش، تاریخ سفارش و شناسه مشتری باید در خروجی باشد. Query را بنویسید و توضیح دهید چرا `ORDER BY` پیش از `LIMIT` ضروری است.

## خطاهای رایج

- استفاده از `= NULL` به‌جای `IS NULL`
- فراموش کردن پرانتز در ترکیب شرط‌های AND و OR
- استفاده از LIMIT بدون ORDER BY در گزارش Top N
- استفاده از `SELECT *` در خروجی‌هایی که فقط چند ستون لازم دارند
- فرض کردن اینکه BETWEEN در تاریخ‌ها، انتهای بازه را شامل نمی‌شود؛ در حالی که دو سر بازه شامل‌اند

## جمع‌بندی

با `SELECT` ستون‌ها را انتخاب می‌کنیم، با `WHERE` ردیف‌ها را فیلتر می‌کنیم، با `ORDER BY` ترتیب می‌دهیم و با `LIMIT` تعداد خروجی را کنترل می‌کنیم. این چهار ابزار پایه تقریباً در تمام Queryهای تحلیلی حضور دارند.

## مطالعه بیشتر

- [MySQL 8.4 — SELECT](https://dev.mysql.com/doc/refman/8.4/en/select.html)
