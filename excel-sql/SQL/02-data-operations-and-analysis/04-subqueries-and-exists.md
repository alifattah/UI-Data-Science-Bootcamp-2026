# درس ۴ — Subquery و EXISTS

در تحلیل داده، گاهی پاسخ یک سؤال به نتیجه سؤال دیگری وابسته است. برای نمونه، اگر بخواهیم سفارش‌هایی را پیدا کنیم که مبلغشان از میانگین سفارش‌ها بیشتر است، ابتدا باید میانگین را به دست آوریم و سپس سفارش‌ها را با آن مقایسه کنیم.

**Subquery** یا پرس‌وجوی تو‌در‌تو، Queryای است که داخل Query دیگری استفاده می‌شود.

## ۱. Subquery تک‌مقداری (Scalar Subquery)

در مثال زیر ابتدا مبلغ هر سفارش را محاسبه می‌کنیم، سپس سفارش‌هایی را پیدا می‌کنیم که از میانگین مبلغ سفارش‌ها بیشترند.

```sql
SELECT
    order_totals.order_id,
    order_totals.order_total
FROM (
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY o.order_id
) AS order_totals
WHERE order_totals.order_total > (
    SELECT AVG(order_total)
    FROM (
        SELECT
            SUM(oi.quantity * oi.unit_price) AS order_total
        FROM orders AS o
        JOIN order_items AS oi
            ON oi.order_id = o.order_id
        WHERE o.status IN ('completed', 'shipped')
        GROUP BY o.order_id
    ) AS averages
);
```

Subquery داخل پرانتز مقدار یا مجموعه موردنیاز Query بیرونی را می‌سازد. در MySQL، جدول مشتق‌شده در بخش FROM باید Alias داشته باشد.

## ۲. Subquery همراه IN

وقتی یک Subquery چند مقدار برمی‌گرداند، می‌توان از `IN` برای بررسی عضویت استفاده کرد.

مثال: مشتریانی که دست‌کم یک سفارش تکمیل‌شده دارند:

```sql
SELECT customer_id, full_name, city
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    WHERE status = 'completed'
);
```

خروجی Subquery، شناسه مشتریان دارای سفارش تکمیل‌شده است؛ Query بیرونی مشخصات آن مشتریان را بازیابی می‌کند.

## ۳. EXISTS و NOT EXISTS

گاهی مهم نیست Subquery چه مقداری برمی‌گرداند؛ فقط می‌خواهیم بدانیم آیا دست‌کم یک ردیف مرتبط وجود دارد یا خیر.

### EXISTS

```sql
SELECT
    c.customer_id,
    c.full_name
FROM customers AS c
WHERE EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.customer_id
);
```

این Query مشتریانی را برمی‌گرداند که حداقل یک سفارش دارند.

### NOT EXISTS

```sql
SELECT
    c.customer_id,
    c.full_name
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.customer_id
);
```

این Query مشتریانی را پیدا می‌کند که هنوز هیچ سفارشی ثبت نکرده‌اند.

Subquery در این مثال به Query بیرونی وابسته است؛ به همین دلیل به آن **Correlated Subquery** گفته می‌شود. برای هر مشتری، وجود سفارش مرتبط بررسی می‌شود.

## ۴. Subquery در FROM؛ ساخت جدول موقت در دل Query

می‌توانیم ابتدا درآمد هر مشتری را محاسبه کنیم و سپس از نتیجه مثل یک جدول استفاده کنیم:

```sql
SELECT
    customer_sales.customer_id,
    customer_sales.revenue
FROM (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY o.customer_id
) AS customer_sales
WHERE customer_sales.revenue > 3000000
ORDER BY customer_sales.revenue DESC;
```

این روش برای شکستن مسئله به دو مرحله کاربردی است:
1. ساخت شاخص در سطح مشتری.
2. فیلتر کردن مشتری‌ها بر اساس شاخص محاسبه‌شده.

در درس CTE همین ایده را با ساختاری خواناتر پیاده‌سازی می‌کنیم.

## ۵. Subquery یا JOIN؟

این دو روش گاهی می‌توانند به نتیجه مشابه برسند، اما هدف و شکل بیانشان فرق دارد:

- اگر به ستون‌های جدول دیگر نیاز داریم، JOIN معمولاً طبیعی‌تر است.
- اگر فقط وجود یا عدم وجود رکورد مرتبط را بررسی می‌کنیم، EXISTS/NOT EXISTS بسیار گویاست.
- اگر لازم است یک مقدار محاسبه‌شده را با هر ردیف مقایسه کنیم، Scalar Subquery می‌تواند مناسب باشد.
- از Subqueryهای چندلایه و تکراری بدون نیاز پرهیز کنید؛ ممکن است CTE خوانایی بهتری داشته باشد.

## ۶. نکته‌های مهم و خطاهای رایج

### Subquery تک‌مقداری باید یک مقدار برگرداند

اگر از Subquery در مقایسه‌ای مانند `>` استفاده می‌کنید، انتظار می‌رود یک مقدار سازگار برگرداند. اگر چند ردیف برگردد، MySQL خطا می‌دهد.

### تفاوت NULL با مقدار عادی

در استفاده از `NOT IN` اگر خروجی Subquery شامل NULL باشد، نتیجه می‌تواند غیرمنتظره شود. برای سناریوهای «رکورد متناظر وجود ندارد»، اغلب `NOT EXISTS` انتخاب امن‌تری است.

### Alias برای جدول مشتق‌شده

هر Subquery که در FROM به شکل یک جدول قرار می‌گیرد باید نام مستعار داشته باشد:

```sql
SELECT *
FROM (
    SELECT city, COUNT(*) AS customer_count
    FROM customers
    GROUP BY city
) AS city_summary;
```

## تمرین

1. مشتریانی را پیدا کنید که سفارش با وضعیت `shipped` داشته‌اند.
2. مشتریانی را پیدا کنید که هیچ سفارشی ندارند.
3. محصولاتی را پیدا کنید که حداقل یک‌بار در سفارش‌ها استفاده شده‌اند.
4. سفارش‌هایی را پیدا کنید که مجموع اقلام آن‌ها از میانگین ارزش سفارش بیشتر است.

## چالش تحلیلی

می‌خواهیم «مشتریانی که درآمد آن‌ها بیشتر از میانگین درآمد مشتریان فعال است» را پیدا کنیم. ابتدا باید درآمد هر مشتری را بسازید، سپس میانگین درآمد مشتریان را محاسبه کنید و در نهایت مشتریان بالاتر از میانگین را نمایش دهید. راه‌حل را با Subquery در FROM بنویسید.

## جمع‌بندی

Subquery راهی برای استفاده از نتیجه یک Query در Query دیگر است. `IN` برای بررسی عضویت، `EXISTS` برای بررسی وجود، و جدول مشتق‌شده برای استفاده از یک نتیجه محاسبه‌شده در FROM مفید است.

## مطالعه بیشتر

- [MySQL 8.4 — Subqueries](https://dev.mysql.com/doc/refman/8.4/en/subqueries.html)
- [MySQL 8.4 — EXISTS and NOT EXISTS](https://dev.mysql.com/doc/refman/8.4/en/exists-and-not-exists-subqueries.html)
