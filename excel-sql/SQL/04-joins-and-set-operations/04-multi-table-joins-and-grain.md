# درس ۴ — اتصال چند جدول و کنترل سطح داده (Grain)

در مسائل واقعی، اطلاعات موردنیاز معمولاً در دو جدول خلاصه نمی‌شود. برای ساخت یک گزارش فروش ممکن است به اطلاعات مشتری، سفارش، اقلام سفارش و مشخصات محصول احتیاج داشته باشیم.

اتصال چند جدول از نظر Syntax دشوار نیست؛ چالش اصلی این است که بدانیم بعد از هر اتصال، هر ردیف خروجی چه چیزی را نمایش می‌دهد.

## زنجیره‌ی ارتباط جدول‌های فروشگاه

~~~mermaid
flowchart LR
    C["customers"] -->|"customer_id"| O["orders"]
    O -->|"order_id"| I["order_items"]
    P["products"] -->|"product_id"| I
~~~

- هر مشتری می‌تواند سفارش‌های متعددی داشته باشد.
- هر سفارش می‌تواند چند قلم کالا داشته باشد.
- هر محصول ممکن است در سفارش‌های مختلف تکرار شود.
- جدول `order_items` جزئیات هر قلم از سفارش را ثبت می‌کند.

## اتصال چهار جدول

می‌خواهیم جزئیات هر قلم خرید را همراه با نام مشتری و محصول ببینیم:

~~~sql
SELECT
    o.order_id,
    o.order_date,
    c.full_name,
    c.city,
    p.product_name,
    p.category,
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
WHERE o.status IN ('completed', 'shipped')
ORDER BY o.order_date, o.order_id;
~~~

در این خروجی هر ردیف نشان‌دهنده‌ی **یک قلم سفارش** است؛ نه یک سفارش کامل و نه یک مشتری.

## Grain یا سطح هر ردیف چیست؟

Grain پاسخ این سؤال است:

> هر ردیف از جدول یا نتیجه‌ی Query دقیقاً نماینده‌ی چیست؟

چند نمونه:

| داده | Grain |
|---|---|
| customers | یک ردیف برای هر مشتری |
| orders | یک ردیف برای هر سفارش |
| order_items | یک ردیف برای هر قلم سفارش |
| گزارش درآمد ماهانه | یک ردیف برای هر ماه |

قبل از JOIN و Aggregation، Grain را مشخص کنید. اگر سطح داده را ندانید، ممکن است یک مقدار را چند بار بشمارید.

## خطر دوباره‌شماری (Fanout)

فرض کنید سفارش شماره ۱۰۰۱ شامل دو قلم کالا باشد. پس از اتصال orders به order_items، اطلاعات سفارش در دو ردیف تکرار می‌شود:

| order_id | product | line_revenue |
|---:|---|---:|
| 1001 | Wireless Mouse | 1,700,000 |
| 1001 | Notebook Set | 840,000 |

این دو ردیف درست هستند؛ چون سفارش دو قلم دارد. اما اگر بعد از JOIN از `COUNT(*)` استفاده کنیم و نام آن را تعداد سفارش بگذاریم، تعداد قلم‌ها را شمرده‌ایم، نه تعداد سفارش‌ها.

~~~sql
SELECT
    c.city,
    COUNT(*) AS order_item_rows,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers AS c
JOIN orders AS o
    ON o.customer_id = c.customer_id
JOIN order_items AS oi
    ON oi.order_id = o.order_id
WHERE o.status IN ('completed', 'shipped')
GROUP BY c.city
ORDER BY revenue DESC;
~~~

چهار شاخص بالا چهار مفهوم متفاوت دارند:

- `order_item_rows`: تعداد ردیف‌های جزئیات سفارش
- `order_count`: تعداد سفارش‌های یکتا
- `units_sold`: تعداد واحدهای فروخته‌شده
- `revenue`: درآمد حاصل از اقلام سفارش

## محاسبه میانگین مبلغ سفارش؛ ابتدا Grain را درست کنید

یک اشتباه رایج این است که میانگین `line_revenue` را به‌عنوان میانگین مبلغ سفارش گزارش کنیم. این دو شاخص یکسان نیستند.

برای Average Order Value باید ابتدا مبلغ هر سفارش را حساب کنیم و سپس میانگین سفارش‌ها را به دست آوریم:

~~~sql
WITH order_totals AS (
    SELECT
        o.order_id,
        c.city,
        SUM(oi.quantity * oi.unit_price) AS order_revenue
    FROM orders AS o
    JOIN customers AS c
        ON c.customer_id = o.customer_id
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status IN ('completed', 'shipped')
    GROUP BY o.order_id, c.city
)
SELECT
    city,
    COUNT(*) AS order_count,
    ROUND(AVG(order_revenue), 2) AS average_order_value,
    SUM(order_revenue) AS total_revenue
FROM order_totals
GROUP BY city
ORDER BY total_revenue DESC;
~~~

در این مثال از CTE استفاده شده تا ابتدا داده را در سطح سفارش خلاصه کنیم و سپس در سطح شهر تحلیل انجام دهیم. اگر هنوز با CTE آشنا نشده‌اید، فعلاً منطق دو مرحله‌ای را دنبال کنید؛ جزئیات CTE در بخش SQL پیشرفته آمده است.

## آیا همیشه باید JOIN کنیم؟

خیر. گاهی می‌توانیم از کلیدهای موجود در یک جدول برای تحلیل استفاده کنیم؛ گاهی هم Subquery یا CTE خواناتر است. مهم، صحت منطق و سطح داده است، نه تعداد JOINهای Query.

## چک‌لیست کنترل صحت JOIN

بعد از نوشتن Query از خودتان بپرسید:

1. کلید اتصال در هر دو جدول چیست؟
2. رابطه یک‌به‌یک، یک‌به‌چند یا چندبه‌چند است؟
3. هر ردیف خروجی چه چیزی را نمایندگی می‌کند؟
4. آیا اتصال باعث زیاد شدن تعداد ردیف‌ها شده است؟
5. آیا شاخصی مانند تعداد سفارش را باید با DISTINCT محاسبه کنم؟
6. آیا جدول جزئیات باعث تکرار مبلغ سفارش شده است؟
7. آیا فیلتر وضعیت سفارش در جای درست قرار گرفته است؟

## تمرین

1. گزارش درآمد هر شهر را با تعداد سفارش یکتا و تعداد واحد فروخته‌شده تهیه کنید.
2. میانگین مبلغ سفارش را برای هر شهر محاسبه کنید.
3. درآمد هر دسته محصول را به دست آورید.
4. خروجی جزئیات سفارش را با خروجی سطح سفارش مقایسه کنید و توضیح دهید چرا تعداد ردیف‌ها متفاوت است.

## جمع‌بندی

- JOIN چندجدولی با زنجیره‌کردن JOINها انجام می‌شود.
- مهم‌ترین مسئله در تحلیل چندجدولی شناخت Grain است.
- یک رابطه یک‌به‌چند تعداد ردیف‌ها را افزایش می‌دهد؛ این رفتار لزوماً خطا نیست.
- برای تعداد موجودیت‌های یکتا از `COUNT(DISTINCT ...)` استفاده کنید.
- برای میانگین در سطح سفارش، ابتدا باید مبلغ هر سفارش را محاسبه کنید.

---

[بازگشت به نقشه ماژول ۴](./README.md)
