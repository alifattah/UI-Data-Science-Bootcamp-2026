# درس ۱ — توابع پرکاربرد MySQL برای آماده‌سازی داده

توابع داخلی MySQL کمک می‌کنند داده را هنگام Query تغییر شکل دهیم؛ بدون آنکه الزاماً مقدار ذخیره‌شده در جدول را تغییر بدهیم. این قابلیت در گزارش‌گیری، استانداردسازی متن، تحلیل تاریخ و محاسبه شاخص‌ها بسیار کاربردی است.

## ۱. توابع رشته‌ای (String Functions)

### CONCAT و CONCAT_WS

برای اتصال چند متن از `CONCAT` استفاده می‌کنیم:

```sql
SELECT
    CONCAT(full_name, ' - ', city) AS customer_label
FROM customers;
```

اگر بخواهیم جداکننده را فقط یک‌بار تعیین کنیم، `CONCAT_WS` مناسب است:

```sql
SELECT
    CONCAT_WS(' | ', full_name, city, email) AS customer_summary
FROM customers;
```

در MySQL، اگر یکی از آرگومان‌های CONCAT برابر NULL باشد، نتیجه CONCAT نیز NULL می‌شود. در صورت نیاز می‌توان مقدار جایگزین را با COALESCE مشخص کرد.

### TRIM، LTRIM و RTRIM

این توابع فاصله‌های اضافی ابتدا و انتهای متن را پاک می‌کنند:

```sql
SELECT
    TRIM('   Data Analyst   ') AS cleaned_text,
    LTRIM('   Data Analyst') AS left_cleaned,
    RTRIM('Data Analyst   ') AS right_cleaned;
```

این کار برای استانداردسازی مقدارهای متنی قبل از گروه‌بندی یا مقایسه مفید است.

### UPPER، LOWER و REPLACE

```sql
SELECT
    UPPER(city) AS city_upper,
    LOWER(email) AS normalized_email,
    REPLACE(product_name, 'USB-C', 'USB Type-C') AS revised_name
FROM products;
```

`REPLACE()` در این مثال یک تابع رشته‌ای است و بخشی از متن را جایگزین می‌کند؛ با دستور `REPLACE INTO` که برای درج/جایگزینی ردیف استفاده می‌شود متفاوت است.

### CHAR_LENGTH در برابر LENGTH

`CHAR_LENGTH` تعداد کاراکترها را می‌شمارد، درحالی‌که `LENGTH` تعداد بایت‌ها را برمی‌گرداند. در متن‌های چندبایتی مثل فارسی این دو مقدار می‌توانند متفاوت باشند:

```sql
SELECT
    CHAR_LENGTH('سلام') AS character_count,
    LENGTH('سلام') AS byte_count;
```

برای تحلیل طول متن معمولاً CHAR_LENGTH معنای مورد انتظار را دارد.

## ۲. توابع عددی (Numeric Functions)

| تابع | کاربرد |
|---|---|
| `ABS(x)` | قدرمطلق |
| `ROUND(x, d)` | گرد کردن تا d رقم اعشار |
| `CEIL(x)` | گرد کردن به سمت بالا |
| `FLOOR(x)` | گرد کردن به سمت پایین |
| `MOD(x, y)` | باقیمانده تقسیم |

مثال:

```sql
SELECT
    unit_price,
    ROUND(unit_price * 1.09, 2) AS price_with_tax,
    CEIL(unit_price / 100000) AS price_band,
    ABS(unit_price - 1000000) AS distance_from_one_million
FROM products;
```

> نکته: گرد کردن مقدار فقط شکل نمایش نیست؛ اگر نتیجه گرد شده را در محاسبات بعدی استفاده کنید، ممکن است روی جمع کل اثر بگذارد. برای تحلیل مالی بهتر است تا مرحله نهایی دقت مورد نیاز را حفظ کنید.

## ۳. توابع تاریخ و زمان

داده‌های زمانی در تحلیل فروش، نگهداشت مشتری و روندهای ماهانه نقش مهمی دارند.

### استخراج بخش‌های تاریخ

```sql
SELECT
    order_id,
    DATE(order_date) AS order_day,
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    QUARTER(order_date) AS order_quarter
FROM orders;
```

### EXTRACT

برای استخراج یک بخش مشخص از تاریخ:

```sql
SELECT
    EXTRACT(YEAR FROM order_date) AS order_year,
    EXTRACT(MONTH FROM order_date) AS order_month
FROM orders;
```

### DATE_ADD و DATEDIFF

برای جابه‌جایی در زمان و محاسبه فاصله روزها:

```sql
SELECT
    order_id,
    DATE_ADD(order_date, INTERVAL 7 DAY) AS followup_date,
    DATEDIFF('2025-05-01', DATE(order_date)) AS days_until_may
FROM orders;
```

### تاریخ و زمان جاری

- `CURRENT_DATE()` یا `CURDATE()`: تاریخ جاری
- `NOW()`: تاریخ و ساعت جاری

```sql
SELECT
    CURDATE() AS today,
    NOW() AS current_timestamp;
```

### DATE_FORMAT

برای ساخت برچسب ماهانه در گزارش:

```sql
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(*) AS order_count
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;
```

در این مثال قالب `%Y-%m` سال و ماه را به شکل 2025-04 نمایش می‌دهد. این نوع قالب برای نمودار روند ماهانه مناسب است.

## ۴. مدیریت مقدارهای NULL با COALESCE

`COALESCE` اولین مقدار غیر NULL را از فهرست ورودی برمی‌گرداند:

```sql
SELECT
    customer_id,
    COALESCE(city, 'Unknown') AS city_label
FROM customers;
```

این تابع برای گزارش‌ها مفید است؛ اما پیش از جایگزینی NULL باید معنای آن را بشناسیم. اگر نبودن مقدار نشان‌دهنده ثبت نشدن اطلاعات است، تبدیل آن به مقدار پیش‌فرض ممکن است کیفیت داده را پنهان کند.

## ۵. ترکیب توابع برای یک مسئله واقعی

فرض کنید داده متنی نام شهرها فاصله اضافی دارد و می‌خواهیم خلاصه فروش را بر اساس شهر بسازیم. می‌توانیم قبل از گروه‌بندی مقدار متنی را استاندارد کنیم:

```sql
SELECT
    UPPER(TRIM(c.city)) AS normalized_city,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers AS c
JOIN orders AS o
    ON o.customer_id = c.customer_id
JOIN order_items AS oi
    ON oi.order_id = o.order_id
WHERE o.status IN ('completed', 'shipped')
GROUP BY UPPER(TRIM(c.city))
ORDER BY revenue DESC;
```

اگر در داده‌های اصلی چند شکل نوشتاری متفاوت برای یک شهر وجود داشته باشد، این تبدیل می‌تواند بخشی از اختلاف را برطرف کند. برای پاک‌سازی پایدار، بهتر است استانداردسازی در مرحله مشخص و قابل تکرار انجام شود، نه اینکه هر Query قواعد متفاوتی داشته باشد.

## تمرین

1. نام کالاها را به حروف بزرگ تبدیل کنید.
2. طول نام هر کالا را با CHAR_LENGTH محاسبه کنید.
3. قیمت کالاها را با ۸ درصد افزایش محاسبه و تا دو رقم اعشار گرد کنید.
4. تعداد سفارش‌ها را به تفکیک ماه گزارش کنید.
5. نام مشتری و شهر را با یک جداکننده مناسب در یک ستون ترکیب کنید.

## جمع‌بندی

توابع رشته‌ای برای یکدست کردن متن، توابع عددی برای محاسبات، توابع تاریخ برای تحلیل زمانی و COALESCE برای کنترل NULL کاربرد دارند. این ابزارها بخش مهمی از آماده‌سازی داده پیش از تحلیل هستند.

## مطالعه بیشتر

- [MySQL 8.4 — String Functions](https://dev.mysql.com/doc/refman/8.4/en/string-functions.html)
- [MySQL 8.4 — Numeric Functions](https://dev.mysql.com/doc/refman/8.4/en/numeric-functions.html)
- [MySQL 8.4 — Date and Time Functions](https://dev.mysql.com/doc/refman/8.4/en/date-and-time-functions.html)
- [MySQL 8.4 — Comparison and Flow Control Functions](https://dev.mysql.com/doc/refman/8.4/en/comparison-operators.html)
