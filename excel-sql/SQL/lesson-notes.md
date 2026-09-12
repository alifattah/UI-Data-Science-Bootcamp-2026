# درسنامه SQL / Database — Data Science Bootcamp 2026

> این فایل مرجع آموزشی جلسات SQL است. تمرکز دوره روی حل مسئله‌های تحلیلی و تبدیل سؤال کسب‌وکار به Query است.

---

# جلسه ۱ — مفاهیم Database و SELECT

## Database چیست؟
Database سیستمی برای ذخیره و مدیریت ساختاریافته داده است. در یک دیتابیس رابطه‌ای، داده‌ها معمولاً در **Table**ها قرار می‌گیرند.

مفاهیم اصلی:
- **Row:** یک رکورد
- **Column:** یک ویژگی
- **Primary Key:** شناسه یکتا برای رکورد
- **Foreign Key:** ستونی که به رکورد جدول دیگری اشاره می‌کند
- **Relationship:** ارتباط منطقی میان جدول‌ها

مثلاً در فروشگاه، Customer، Product و Order می‌توانند جدول‌های جداگانه باشند.

## SELECT

```sql
SELECT customer_id, city
FROM customers;
```

برای همه ستون‌ها می‌توان از `*` استفاده کرد، اما در تحلیل‌های حرفه‌ای بهتر است ستون‌های مورد نیاز را صریح انتخاب کنیم.

## WHERE

```sql
SELECT *
FROM orders
WHERE status = 'completed';
```

### تمرین
از جدول سفارش‌ها شناسه سفارش، مشتری و مبلغ را استخراج کنید و فقط سفارش‌های تکمیل‌شده را نمایش دهید.

---

# جلسه ۲ — Filtering و Sorting

## عملگرهای مقایسه
`=`, `<>`, `>`, `<`, `>=`, `<=`

## ترکیب شرط‌ها

```sql
SELECT *
FROM orders
WHERE status = 'completed'
  AND amount > 1000000;
```

`AND` همه شرط‌ها را لازم می‌داند؛ `OR` کافی‌بودن یکی از شرط‌ها را می‌پذیرد.

## IN و BETWEEN

```sql
WHERE city IN ('Tehran', 'Isfahan')
WHERE amount BETWEEN 500000 AND 2000000
```

## LIKE
برای Pattern Matching:

```sql
WHERE name LIKE 'Ali%'
```

## ORDER BY و LIMIT

```sql
SELECT *
FROM orders
ORDER BY amount DESC
LIMIT 10;
```

ترتیب کلی ساده Query:
`SELECT → FROM → WHERE → ORDER BY → LIMIT`

### تمرین
10 سفارش گران را پیدا کنید که در یک شهر مشخص ثبت شده‌اند و وضعیتشان Completed است.

---

# جلسه ۳ — Aggregation و KPI

وقتی سؤال درباره «چقدر؟ چندتا؟ میانگین چقدر؟» باشد، معمولاً به Aggregate Function نیاز داریم.

توابع اصلی:
`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`

```sql
SELECT
    COUNT(*) AS order_count,
    SUM(amount) AS total_revenue,
    AVG(amount) AS avg_order_value,
    MIN(amount) AS min_order,
    MAX(amount) AS max_order
FROM orders
WHERE status = 'completed';
```

## NULL
`COUNT(*)` تعداد Rowها را می‌شمارد؛ `COUNT(column)` مقادیر غیرNULL آن Column را می‌شمارد. NULL با صفر یا رشته خالی یکسان نیست.

## Alias
برای خوانایی خروجی از `AS` استفاده کنید.

### تمرین
KPIهای اصلی فروش را محاسبه کنید: تعداد سفارش، درآمد، میانگین مبلغ سفارش و بیشترین سفارش. سپس نتیجه را در قالب یک گزارش مدیریتی توضیح دهید.

---

# جلسه ۴ — GROUP BY و HAVING

اگر بخواهیم KPI را برای هر گروه جداگانه حساب کنیم، از `GROUP BY` استفاده می‌کنیم.

```sql
SELECT
    city,
    COUNT(*) AS orders,
    SUM(amount) AS revenue
FROM orders
GROUP BY city;
```

## HAVING
`WHERE` قبل از Grouping روی Rowها فیلتر می‌کند؛ `HAVING` بعد از Grouping روی گروه‌ها فیلتر می‌کند.

```sql
SELECT city, SUM(amount) AS revenue
FROM orders
GROUP BY city
HAVING SUM(amount) > 10000000;
```

### اشتباه رایج
شرطی که مربوط به رکورد است معمولاً در WHERE قرار می‌گیرد؛ شرطی که مربوط به نتیجه Aggregate یک گروه است در HAVING.

### تمرین
فروش هر شهر را محاسبه کنید و فقط شهرهایی را نمایش دهید که حداقل 100 سفارش و بیش از یک آستانه مشخص درآمد دارند.

---

# جلسه ۵ — JOINها

داده‌های واقعی معمولاً در چند جدول قرار دارند. JOIN آن‌ها را بر اساس Key مرتبط می‌کند.

## INNER JOIN
فقط رکوردهای دارای Match را برمی‌گرداند.

```sql
SELECT o.order_id, c.city, o.amount
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id;
```

## LEFT JOIN
همه رکوردهای جدول سمت چپ را نگه می‌دارد، حتی اگر Match وجود نداشته باشد.

```sql
SELECT c.customer_id, o.order_id
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id;
```

RIGHT و FULL JOIN نیز در سیستم‌های پشتیبان‌شده کاربرد دارند؛ در عمل LEFT JOIN بسیار رایج است و می‌توان بسیاری از مسائل را با جابه‌جایی سمت جدول حل کرد.

## خطاهای رایج
- Join روی ستون اشتباه
- چندبرابرشدن رکوردها به‌علت رابطه One-to-Many
- فراموش‌کردن شرط Join
- تبدیل ناخواسته LEFT JOIN به INNER JOIN با شرط WHERE روی جدول سمت راست

### تمرین
Orders، Customers و Products را متصل کنید و یک خروجی شامل Customer City، Product Category، Order Date و Revenue بسازید.

---

# جلسه ۶ — Subquery

Subquery یک Query داخل Query دیگر است.

مثلاً پیدا کردن سفارش‌هایی که از میانگین مبلغ سفارش بزرگ‌ترند:

```sql
SELECT order_id, amount
FROM orders
WHERE amount > (
    SELECT AVG(amount)
    FROM orders
);
```

## IN

```sql
SELECT *
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    WHERE amount > 5000000
);
```

## EXISTS
برای بررسی وجود رکورد مرتبط کاربرد دارد و در بسیاری از مسائل منطقی خوانا است.

Subquery می‌تواند در `WHERE`, `FROM` یا بخش‌های دیگر قرار بگیرد، اما اگر Query بیش از حد پیچیده شد، CTE معمولاً خوانایی بهتری ایجاد می‌کند.

### تمرین
مشتریانی را پیدا کنید که حداقل یک سفارش بالاتر از صدک یا میانگین مشخص داشته‌اند. سپس راه‌حل را با JOIN مقایسه کنید.

---

# جلسه ۷ — Data Cleaning و Transformation

SQL فقط برای استخراج داده نیست؛ می‌توان بخشی از Cleaning و Transformation را نیز در آن انجام داد.

## CASE

```sql
SELECT
    order_id,
    CASE
        WHEN amount >= 5000000 THEN 'High'
        WHEN amount >= 1000000 THEN 'Medium'
        ELSE 'Low'
    END AS order_segment
FROM orders;
```

## NULL Handling
بسته به DBMS از `COALESCE` برای جایگزین‌کردن NULL استفاده می‌شود:

```sql
SELECT COALESCE(discount, 0)
FROM orders;
```

## Type Conversion
نوع داده اشتباه می‌تواند محاسبات را خراب کند. برای تبدیل نوع داده از ابزارهای DBMS مانند `CAST` استفاده کنید.

## String و Date
توابع متن و تاریخ بین PostgreSQL، MySQL، SQL Server و سایر DBMSها متفاوت‌اند. بنابراین Syntax مورد استفاده باید با DBMS دوره مشخص شود.

### تمرین
یک Dataset دارای NULL، Categoryهای ناسازگار و مقادیر عددی ذخیره‌شده به شکل متن را پاک‌سازی و استاندارد کنید.

---

# جلسه ۸ — CTE / WITH

CTE به ما اجازه می‌دهد یک Query را به مراحل منطقی تقسیم کنیم.

```sql
WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(amount) AS revenue
    FROM orders
    GROUP BY customer_id
)
SELECT *
FROM customer_sales
WHERE revenue > 10000000;
```

مزیت‌ها:
- خوانایی
- شکستن مسئله پیچیده
- امکان استفاده مجدد در همان Query
- ساده‌ترشدن Debug

CTE لزوماً به معنی سریع‌ترشدن Query نیست؛ بیشتر یک ابزار ساختاری و خوانایی است و به Optimizer و DBMS وابسته است.

### تمرین
ابتدا درآمد هر مشتری را بسازید، سپس Segment مشتری را مشخص کنید و در مرحله نهایی Top Customers را استخراج کنید.

---

# جلسه ۹ — Window Functions

Window Function محاسبه را روی مجموعه‌ای از Rowهای مرتبط انجام می‌دهد، بدون اینکه Rowها را مثل GROUP BY به یک Row تبدیل کند.

## ROW_NUMBER

```sql
SELECT
    customer_id,
    order_id,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY amount DESC
    ) AS order_rank
FROM orders;
```

## RANK و DENSE_RANK
برای رتبه‌بندی استفاده می‌شوند و در برخورد با مقادیر مساوی رفتار متفاوتی دارند.

`PARTITION BY` محدوده محاسبه را مشخص می‌کند و `ORDER BY` ترتیب را تعیین می‌کند.

### کاربردهای مهم
- Top N داخل هر گروه
- اولین/آخرین رکورد
- رتبه‌بندی مشتریان
- مقایسه رکورد با رکوردهای دیگر همان گروه

### تمرین
سه سفارش بزرگ هر مشتری را پیدا کنید. سپس با RANK بررسی کنید اگر دو سفارش مبلغ یکسان داشته باشند چه تفاوتی با ROW_NUMBER ایجاد می‌شود.

---

# جلسه ۱۰ — Trend و تحلیل پیشرفته

Window Function فقط برای Rank نیست. می‌توان برای مقایسه زمانی و محاسبات تجمعی نیز از آن استفاده کرد.

## LAG و LEAD

```sql
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_revenue
FROM monthly_sales;
```

با این ساختار می‌توان تغییر ماه‌به‌ماه را محاسبه کرد.

## Running Total
با Window Frame می‌توان مجموع تجمعی ساخت:

```sql
SUM(revenue) OVER (
    ORDER BY month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

## نکته تحلیلی
قبل از نوشتن Query دقیقاً تعریف کنید «روند»، «ماه قبل» یا «رتبه» بر چه مبنایی است. بسیاری از خطاهای تحلیلی از ابهام در تعریف Metric می‌آیند، نه Syntax SQL.

### تمرین
Revenue ماهانه، Revenue ماه قبل، Growth و Running Total را تولید کنید.

---

# جلسه ۱۱ — پروژه پایانی SQL

## سناریو
یک فروشگاه آنلاین دارای جدول‌های Customers، Products، Orders و Order Items است. مدیریت می‌خواهد عملکرد فروش را تحلیل کند.

## سؤالات پروژه
1. درآمد کل و تعداد سفارش‌ها چقدر است؟
2. فروش هر شهر چقدر است؟
3. Top 10 محصولات چیست؟
4. مشتریان ارزشمند چه کسانی هستند؟
5. میانگین مبلغ سفارش چقدر است؟
6. کدام محصولات در هر Category رتبه بالاتری دارند؟
7. روند ماهانه فروش چگونه است؟
8. رشد نسبت به ماه قبل چقدر است؟
9. مشتریانی که خرید نکرده‌اند چه کسانی هستند؟
10. سه سفارش بزرگ هر مشتری چیست؟

## الزام فنی
در پروژه باید حداقل از موارد زیر استفاده شود:
- SELECT / WHERE / ORDER BY / LIMIT
- Aggregate Functions
- GROUP BY / HAVING
- حداقل دو نوع JOIN
- Subquery
- CASE یا Data Transformation
- CTE
- Window Function

## معیار ارزیابی
- صحت نتیجه
- انتخاب درست Grain داده
- خوانایی Query
- نام‌گذاری مناسب
- جلوگیری از Duplicate ناخواسته
- توانایی توضیح منطق Query
- تبدیل نتیجه فنی به Insight قابل‌فهم برای کسب‌وکار

> هدف نهایی SQL این نیست که Query طولانی بنویسیم؛ هدف این است که از داده، پاسخ درست و قابل دفاع استخراج کنیم.
