# درس ۳ — LEFT JOIN و پیدا کردن رکوردهای بدون تطبیق

در تحلیل داده، فقط مواردی که ارتباط موفق دارند مهم نیستند. گاهی دقیقاً می‌خواهیم بدانیم چه کسانی هنوز خرید نکرده‌اند، کدام محصولات فروش نداشته‌اند یا کدام سفارش‌ها اطلاعات تکمیلی ندارند.

برای این نوع سؤال‌ها، `LEFT JOIN` یکی از ابزارهای اصلی ماست.

## LEFT JOIN چه تفاوتی با INNER JOIN دارد؟

در LEFT JOIN تمام ردیف‌های جدول سمت چپ حفظ می‌شوند. اگر برای یک ردیف، در جدول سمت راست رکورد متناظر پیدا نشود، ستون‌های جدول سمت راست با مقدار `NULL` پر می‌شوند.

~~~mermaid
flowchart LR
    A["جدول چپ: همه ردیف‌ها"] --> C["LEFT JOIN"]
    B["جدول راست: ردیف‌های متناظر"] --> C
    C --> D["همه ردیف‌های چپ + اطلاعات موجود از راست"]
~~~

## ساختار پایه

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    o.order_id,
    o.order_date
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.customer_id;
~~~

در این Query حتی مشتریانی که هیچ سفارشی ندارند نیز در خروجی دیده می‌شوند. برای آن‌ها `order_id` و `order_date` برابر NULL است.

## پیدا کردن مشتریان بدون سفارش

این الگو را معمولاً **Anti Join** می‌نامیم: می‌خواهیم ردیف‌های جدول چپ را پیدا کنیم که در جدول راست هیچ تطبیقی ندارند.

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    c.city
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;
~~~

چرا `o.order_id IS NULL`؟

چون `order_id` کلید اصلی جدول سفارش است و برای یک سفارش واقعی NULL نمی‌شود. پس NULL بودن آن در نتیجه‌ی LEFT JOIN یعنی سفارشی برای مشتری پیدا نشده است.

## شمارش ردیف‌های متناظر، حتی برای مقدار صفر

یکی از کاربردهای مهم LEFT JOIN این است که بتوانیم همه مشتریان را در گزارش نگه داریم و تعداد سفارش‌هایشان را هم بشماریم:

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS order_count
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.full_name
ORDER BY order_count DESC;
~~~

در اینجا از `COUNT(o.order_id)` استفاده کردیم، نه `COUNT(*)`.

- برای مشتری دارای سفارش، تعداد شناسه‌های سفارش شمرده می‌شود.
- برای مشتری بدون سفارش، مقدار ستون سمت راست NULL است و COUNT آن را نمی‌شمارد؛ بنابراین عدد صفر به دست می‌آید.
- `COUNT(*)` حتی ردیف حفظ‌شده‌ی مشتری بدون سفارش را هم می‌شمارد و ممکن است عدد ۱ بدهد.

## پیدا کردن محصولاتی که هیچ‌وقت فروخته نشده‌اند

~~~sql
SELECT
    p.product_id,
    p.product_name,
    p.category
FROM products AS p
LEFT JOIN order_items AS oi
    ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL;
~~~

این Query برای کنترل موجودی کاتالوگ و شناسایی کالاهای بدون فروش مفید است.

## نکته بسیار مهم: شرط را در ON بگذاریم یا WHERE؟

فرض کنید می‌خواهیم همه مشتریان را نمایش دهیم، اما فقط سفارش‌های تکمیل‌شده را کنار آن‌ها بیاوریم.

**حالت اول — شرط وضعیت در ON:**

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    o.order_id,
    o.status
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.customer_id
   AND o.status = 'completed';
~~~

در این حالت همه مشتریان حفظ می‌شوند؛ سفارش‌های غیرتکمیل‌شده به‌عنوان Match در نظر گرفته نمی‌شوند.

**حالت دوم — شرط وضعیت در WHERE:**

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    o.order_id,
    o.status
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.customer_id
WHERE o.status = 'completed';
~~~

در این حالت ردیف‌هایی که سفارش ندارند، مقدار NULL در `o.status` خواهند داشت و شرط WHERE آن‌ها را حذف می‌کند. نتیجه عملاً شبیه INNER JOIN برای سفارش‌های تکمیل‌شده می‌شود.

> قاعده‌ی ذهنی: اگر می‌خواهید تمام ردیف‌های جدول چپ حفظ شوند، شرط مربوط به جدول راست را با دقت در ON قرار دهید. شرط WHERE را برای فیلتر کردن نتیجه‌ی نهایی به‌کار ببرید.

## الگوی تمرین: دانشجویانی که یک درس مشخص را نگرفته‌اند

فرض کنید جدول `students` و جدول واسط `student_courses` داریم. برای پیدا کردن دانشجویانی که درس شماره ۷ را انتخاب نکرده‌اند:

~~~sql
SELECT
    s.id,
    s.name
FROM students AS s
LEFT JOIN student_courses AS sc
    ON sc.student_id = s.id
   AND sc.course_id = 7
WHERE sc.student_id IS NULL
ORDER BY s.id;
~~~

این الگو بدون Subquery کار می‌کند. قرار دادن شرط درس در ON مهم است؛ اگر آن را در WHERE قرار دهیم، منطق موردنظر از بین می‌رود.

## تمرین

1. نام همه مشتریان را همراه با تعداد سفارش‌هایشان نمایش دهید؛ مشتریان بدون سفارش نیز باید حضور داشته باشند.
2. محصولاتی را پیدا کنید که در هیچ قلم سفارشی استفاده نشده‌اند.
3. مشتریانی را نمایش دهید که در ماه آوریل ۲۰۲۵ هیچ سفارش تکمیل‌شده‌ای نداشته‌اند.
4. گزارش تعداد سفارش‌های تکمیل‌شده‌ی هر مشتری را بسازید و مشتریان بدون چنین سفارشی را با عدد صفر نشان دهید.

## جمع‌بندی

- LEFT JOIN همه ردیف‌های جدول سمت چپ را حفظ می‌کند.
- نبود تطبیق در جدول راست با NULL نمایش داده می‌شود.
- Anti Join با الگوی LEFT JOIN و سپس `IS NULL` پیاده‌سازی می‌شود.
- برای شمارش رکوردهای سمت راست از COUNT روی یک ستون غیرقابل NULL استفاده کنید.
- جای شرط در ON و WHERE می‌تواند نتیجه را کاملاً تغییر دهد.

---

[بازگشت به نقشه ماژول ۴](./README.md)
