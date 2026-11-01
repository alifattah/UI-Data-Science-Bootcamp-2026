# درسنامه‌های تکمیلی SQL — اتصال و تحلیل پیشرفته

این فایل ادامه مسیر SQL است. پیش از شروع، این سه بخش را مطالعه و دیتابیس تمرینی را اجرا کنید:

- [ماژول ۱ — مبانی پایگاه داده](./01-database-foundations/README.md)
- [ماژول ۲ — کار با داده‌ها و Queryنویسی](./02-data-operations-and-analysis/README.md)
- [ماژول ۳ — توابع و تبدیل داده](./03-data-transformation-and-design/README.md)
- [فایل ساخت دیتابیس فروشگاه](./practice/retail_schema.sql)

تمام مثال‌های این فایل بر اساس **MySQL 8.4** و همان دیتابیس فروشگاه نوشته شده‌اند. در مثال‌ها، مبلغ فروش از ضرب تعداد در قیمت ثبت‌شده هنگام خرید محاسبه می‌شود؛ جدول `orders` به‌تنهایی ستون مبلغ ندارد.

---

# درس ۱ — اتصال جدول‌ها با JOIN

اطلاعات یک کسب‌وکار معمولاً در چند جدول ذخیره می‌شود. برای مثال نام مشتری در `customers`، وضعیت سفارش در `orders` و اقلام سفارش در `order_items` قرار دارد. با JOIN این اطلاعات را بر اساس کلیدهای مرتبط کنار هم قرار می‌دهیم.

## INNER JOIN

فقط ردیف‌هایی را نگه می‌دارد که در هر دو طرف اتصال، مقدار متناظر داشته باشند.

```sql
SELECT
    o.order_id,
    c.full_name,
    c.city,
    o.order_date,
    o.status
FROM orders AS o
INNER JOIN customers AS c
    ON c.customer_id = o.customer_id;
```

برای اضافه کردن نام کالا و مبلغ هر قلم:

```sql
SELECT
    o.order_id,
    c.city,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_revenue
FROM orders AS o
JOIN customers AS c
    ON c.customer_id = o.customer_id
JOIN order_items AS oi
    ON oi.order_id = o.order_id
JOIN products AS p
    ON p.product_id = oi.product_id
WHERE o.status IN ('completed', 'shipped');
```

## LEFT JOIN

تمام ردیف‌های جدول سمت چپ را حفظ می‌کند؛ حتی اگر در جدول سمت راست رکورد متناظری وجود نداشته باشد. در این حالت ستون‌های سمت راست برای رکوردهای بدون تطبیق NULL خواهند بود.

مثال: پیدا کردن مشتریانی که هیچ سفارشی ثبت نکرده‌اند:

```sql
SELECT
    c.customer_id,
    c.full_name
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;
```

## رابطه یک‌به‌چند و افزایش تعداد ردیف‌ها

هر مشتری ممکن است چند سفارش داشته باشد و هر سفارش نیز ممکن است چند قلم کالا داشته باشد. بنابراین پس از JOIN ممکن است تعداد ردیف‌ها بیشتر از تعداد سفارش‌ها شود.

این افزایش لزوماً خطا نیست؛ نتیجه طبیعی رابطه یک‌به‌چند است. اما باید شاخص را متناسب با سطح ردیف محاسبه کنیم:

- تعداد ردیف‌های نتیجه: `COUNT(*)`
- تعداد سفارش‌های یکتا: `COUNT(DISTINCT o.order_id)`
- تعداد واحدهای فروخته‌شده: `SUM(oi.quantity)`
- درآمد: `SUM(oi.quantity * oi.unit_price)`

## خطاهای متداول JOIN

1. اتصال روی ستون نامرتبط یا کلید اشتباه.
2. فراموش کردن شرط ON و ایجاد حاصل‌ضرب ناخواسته ردیف‌ها.
3. استفاده از COUNT(*) برای شمارش سفارش در نتیجه‌ای که چند ردیف برای هر سفارش دارد.
4. قرار دادن شرط جدول سمت راست در WHERE پس از LEFT JOIN و حذف ناخواسته ردیف‌های بدون Match.

### تمرین

گزارشی با ستون‌های شناسه سفارش، نام مشتری، شهر، نام کالا، تعداد و درآمد هر قلم بسازید. سپس بررسی کنید تعداد ردیف خروجی با تعداد سفارش‌ها چه تفاوتی دارد.

---

# درس ۲ — CTE و ساخت Queryهای چندمرحله‌ای

وقتی Query طولانی می‌شود، بهتر است مسئله را به چند مرحله قابل فهم تقسیم کنیم. **CTE** یا Common Table Expression با عبارت `WITH` یک نتیجه موقت و نام‌گذاری‌شده در همان Query ایجاد می‌کند.

## مثال: محاسبه درآمد هر سفارش

```sql
WITH order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price) AS order_revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY
        o.order_id,
        o.customer_id,
        o.order_date
)
SELECT
    order_id,
    customer_id,
    order_date,
    order_revenue
FROM order_totals
WHERE order_revenue > 2000000
ORDER BY order_revenue DESC;
```

در این Query ابتدا CTE مبلغ سفارش را محاسبه می‌کند؛ سپس Query اصلی روی خروجی مرحله اول فیلتر انجام می‌دهد.

## چند CTE در یک Query

```sql
WITH order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS order_revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY o.order_id, o.customer_id
),
customer_revenue AS (
    SELECT
        customer_id,
        SUM(order_revenue) AS total_revenue,
        COUNT(*) AS order_count
    FROM order_totals
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_revenue,
    order_count
FROM customer_revenue
ORDER BY total_revenue DESC;
```

هر CTE یک مرحله از منطق تحلیلی را مشخص می‌کند و مرحله بعد می‌تواند از آن استفاده کند.

## چرا CTE مفید است؟

- Queryهای پیچیده را به مراحل کوچک‌تر تبدیل می‌کند.
- از تکرار یک منطق محاسباتی جلوگیری می‌کند.
- نام‌گذاری مراحل، بررسی و Debug کردن را ساده‌تر می‌کند.
- برای توضیح منطق تحلیل به همکاران مناسب است.

> CTE الزاماً باعث سریع‌تر شدن Query نمی‌شود؛ مزیت اصلی آن در سازمان‌دهی و خوانایی است. نحوه اجرای آن به Optimizer و نسخه DBMS بستگی دارد.

### تمرین

ابتدا درآمد هر قلم سفارش را محاسبه کنید، سپس درآمد هر سفارش و در مرحله بعد درآمد کل هر مشتری را بسازید. در خروجی نهایی مشتریان را از بیشترین درآمد مرتب کنید.

---

# درس ۳ — Window Functions

توابع پنجره‌ای (Window Functions) برای محاسبه شاخص روی مجموعه‌ای از ردیف‌های مرتبط استفاده می‌شوند، اما برخلاف GROUP BY ردیف‌ها را به یک ردیف خلاصه تبدیل نمی‌کنند.

## تفاوت GROUP BY و Window Function

- GROUP BY معمولاً تعداد ردیف‌ها را به تعداد گروه‌ها کاهش می‌دهد.
- Window Function مقدار محاسبه‌شده را به هر ردیف مرتبط اضافه می‌کند و جزئیات ردیف‌ها باقی می‌مانند.

## ROW_NUMBER

به هر ردیف در هر گروه یک شماره ترتیبی می‌دهد:

```sql
SELECT
    customer_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY order_date DESC, order_id DESC
    ) AS order_sequence
FROM orders;
```

در این مثال، سفارش‌های هر مشتری از جدیدترین به قدیمی‌ترین شماره‌گذاری می‌شوند.

## RANK و DENSE_RANK

هر دو برای رتبه‌بندی مقادیر استفاده می‌شوند؛ تفاوت آن‌ها در برخورد با مقدارهای مساوی است.

| مقدارها | ROW_NUMBER | RANK | DENSE_RANK |
|---|---:|---:|---:|
| ۹۰ | ۱ | ۱ | ۱ |
| ۸۵ | ۲ | ۲ | ۲ |
| ۸۵ | ۳ | ۲ | ۲ |
| ۷۰ | ۴ | ۴ | ۳ |

- ROW_NUMBER برای هر ردیف شماره جدا می‌دهد.
- RANK رتبه‌های مساوی می‌دهد و بعد از تساوی، در رتبه‌ها فاصله ایجاد می‌کند.
- DENSE_RANK رتبه‌های مساوی می‌دهد، اما فاصله ایجاد نمی‌کند.

## Top N در هر گروه

فرض کنید می‌خواهیم محصولات پرفروش هر دسته را رتبه‌بندی کنیم:

```sql
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products AS p
    JOIN order_items AS oi
        ON oi.product_id = p.product_id
    JOIN orders AS o
        ON o.order_id = oi.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),
ranked_products AS (
    SELECT
        product_id,
        product_name,
        category,
        revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS category_rank
    FROM product_revenue
)
SELECT *
FROM ranked_products
WHERE category_rank <= 3
ORDER BY category, category_rank;
```

در مرحله اول فروش هر محصول محاسبه می‌شود؛ سپس محصولات در هر دسته رتبه می‌گیرند.

## اجزای اصلی Window

```sql
FUNCTION() OVER (
    PARTITION BY group_column
    ORDER BY sort_column
)
```

- `PARTITION BY` گروه‌های مستقل محاسبه را مشخص می‌کند.
- `ORDER BY` ترتیب ردیف‌ها را در هر پنجره تعیین می‌کند.
- برخی توابع تجمعی می‌توانند با Window Frame برای محاسبات تجمعی استفاده شوند.

### تمرین

برای هر مشتری سفارش‌ها را از جدیدترین به قدیمی‌ترین مرتب کنید. سپس سه محصول برتر هر دسته را بر اساس درآمد به دست آورید.

---

# درس ۴ — تحلیل روند زمانی با LAG، LEAD و Running Total

در تحلیل کسب‌وکار، دانستن مقدار فعلی کافی نیست؛ معمولاً می‌خواهیم آن را با دوره قبل مقایسه کنیم یا روند تجمعی را ببینیم.

## آماده‌سازی فروش ماهانه

ابتدا درآمد را در سطح ماه محاسبه می‌کنیم:

```sql
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT *
FROM monthly_revenue
ORDER BY month_start;
```

## LAG؛ مشاهده دوره قبل

`LAG` مقدار ردیف قبلی را در ترتیب تعریف‌شده برمی‌گرداند:

```sql
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT
    month_start,
    revenue,
    LAG(revenue) OVER (ORDER BY month_start) AS previous_month_revenue
FROM monthly_revenue
ORDER BY month_start;
```

## محاسبه رشد نسبت به ماه قبل

```sql
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01')
),
monthly_comparison AS (
    SELECT
        month_start,
        revenue,
        LAG(revenue) OVER (ORDER BY month_start) AS previous_revenue
    FROM monthly_revenue
)
SELECT
    month_start,
    revenue,
    previous_revenue,
    ROUND(
        100 * (revenue - previous_revenue) / NULLIF(previous_revenue, 0),
        2
    ) AS growth_percent
FROM monthly_comparison
ORDER BY month_start;
```

از `NULLIF(previous_revenue, 0)` استفاده کرده‌ایم تا در صورت صفر بودن مقدار دوره قبل، تقسیم بر صفر رخ ندهد. اگر دوره قبلی وجود نداشته باشد، رشد نیز NULL خواهد بود.

## Running Total؛ مجموع تجمعی

```sql
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT
    month_start,
    revenue,
    SUM(revenue) OVER (
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_revenue
FROM monthly_revenue
ORDER BY month_start;
```

## نکته تحلیلی

قبل از محاسبه رشد باید تعریف کنید که «دوره قبل» دقیقاً چیست. LAG ردیف قبلی را بر اساس ترتیب می‌گیرد؛ اگر ماهی در داده وجود نداشته باشد، ردیف قبلی الزاماً ماه تقویمی قبل نیست. برای گزارش ماه‌به‌ماه دقیق، باید تقویم کامل ماه‌ها را در نظر بگیریم.

### تمرین

درآمد ماهانه، درآمد ماه قبل، درصد رشد و مجموع تجمعی را محاسبه کنید. نتیجه را در یک نمودار خطی نمایش دهید و دو نکته از روند استخراج کنید.

---

# درس ۵ — پروژه تحلیلی پایانی SQL

## سناریو

شما تحلیلگر داده یک فروشگاه آنلاین هستید. مدیران می‌خواهند بدانند فروش در کدام شهرها و دسته‌های محصول بهتر است، چه مشتریانی فعال‌ترند و عملکرد فروش در طول زمان چه تغییری داشته است.

## سؤال‌های پروژه

1. تعداد سفارش‌های معتبر و درآمد کل را محاسبه کنید.
2. درآمد هر شهر را گزارش کنید.
3. ۵ محصول برتر را بر اساس درآمد پیدا کنید.
4. درآمد و تعداد سفارش هر مشتری را محاسبه کنید.
5. مشتریانی را پیدا کنید که هنوز هیچ سفارشی ندارند.
6. محصولات استفاده‌نشده در سفارش‌ها را شناسایی کنید.
7. سه محصول برتر هر دسته را با Window Function رتبه‌بندی کنید.
8. درآمد ماهانه و رشد نسبت به ماه قبل را محاسبه کنید.
9. مجموع تجمعی درآمد را به تفکیک ماه بسازید.

## الزام‌های فنی

در فایل نهایی باید حداقل از این موارد استفاده شود:

- SELECT، WHERE، ORDER BY و LIMIT
- Aggregate Functions و GROUP BY
- HAVING
- حداقل دو نوع JOIN
- یک Subquery یا EXISTS
- CASE یا توابع تبدیل داده
- CTE
- یک Window Function

## معیار ارزیابی

| معیار | پرسش ارزیابی |
|---|---|
| صحت | آیا عددها با تعریف شاخص سازگارند؟ |
| Grain | آیا سطح هر ردیف را درست تشخیص داده‌اید؟ |
| JOIN | آیا اتصال باعث Duplicate ناخواسته نشده است؟ |
| خوانایی | آیا Queryها ساختار و Alias مناسب دارند؟ |
| تفسیر | آیا می‌توانید خروجی را به زبان کسب‌وکار توضیح دهید؟ |

فایل نهایی را با نام `sql_final_project.sql` ذخیره کنید. هر Query را با کامنت و عنوان سؤال مشخص کنید.

> هدف این پروژه نوشتن طولانی‌ترین Query نیست؛ باید با Queryهای روشن و قابل دفاع به سؤال‌های مشخص کسب‌وکار پاسخ دهید.
