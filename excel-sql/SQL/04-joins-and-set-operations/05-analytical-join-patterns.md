# درس ۵ — الگوهای تحلیلی با JOIN

حالا که با INNER JOIN، LEFT JOIN و اتصال چند جدول آشنا شدیم، چند مسئله‌ی رایج تحلیل داده را حل می‌کنیم. هدف این است که از یک سؤال کسب‌وکار به منطق Query برسیم.

## الگوی اول — شناسایی مشتریان فعال در یک بازه زمانی

**سؤال کسب‌وکار:** کدام مشتریان در فروردین ۱۴۰۴ حداقل یک سفارش معتبر ثبت کرده‌اند؟

برای پاسخ، به جدول مشتریان و سفارش‌ها نیاز داریم. چون هر مشتری ممکن است چند سفارش داشته باشد، از DISTINCT استفاده می‌کنیم تا هر مشتری فقط یک بار برگردد.

~~~sql
SELECT DISTINCT
    c.customer_id,
    c.full_name,
    c.city
FROM customers AS c
JOIN orders AS o
    ON o.customer_id = c.customer_id
WHERE o.order_date >= '2025-03-01'
  AND o.order_date <  '2025-04-01'
  AND o.status IN ('completed', 'shipped')
ORDER BY c.customer_id;
~~~

**چرا بازه را به شکل ابتدا شامل و انتها غیرشامل نوشتیم؟**

این الگو برای ستون‌های DATETIME مطمئن‌تر است. اگر فقط بنویسیم `<= '2025-03-31'`، ممکن است رکوردهای روز آخر با ساعت بعد از نیمه‌شب از دست بروند.

## الگوی دوم — محاسبه نرخ تبدیل بین دو مرحله

در قیف تبدیل (Conversion Funnel)، کاربران در چند مرحله حرکت می‌کنند. برای مثال:

~~~mermaid
flowchart TD
    A["همه کاربران"] --> B["حداقل یک سبد خرید"]
    B --> C["حداقل یک پرداخت"]
~~~

فرض کنید سه جدول `users`، `carts` و `payments` داریم:

- `carts.user_id` به کاربر سازنده سبد اشاره می‌کند.
- `payments.cart_id` به سبد پرداخت‌شده اشاره می‌کند.

می‌خواهیم نسبت کاربران دارای حداقل یک سبد و کاربران دارای حداقل یک پرداخت را نسبت به کل کاربران محاسبه کنیم.

~~~sql
WITH user_count AS (
    SELECT COUNT(*) AS total_users
    FROM users
),
cart_users AS (
    SELECT COUNT(DISTINCT user_id) AS users_with_cart
    FROM carts
),
payment_users AS (
    SELECT COUNT(DISTINCT c.user_id) AS users_with_payment
    FROM carts AS c
    JOIN payments AS p
        ON p.cart_id = c.id
)
SELECT
    'cart' AS funnel_stage,
    ROUND(
        cart_users.users_with_cart / NULLIF(user_count.total_users, 0),
        4
    ) AS conversion_rate
FROM user_count
CROSS JOIN cart_users

UNION ALL

SELECT
    'payment' AS funnel_stage,
    ROUND(
        payment_users.users_with_payment / NULLIF(user_count.total_users, 0),
        4
    ) AS conversion_rate
FROM user_count
CROSS JOIN payment_users;
~~~

چند نکته‌ی تحلیلی:

- از `COUNT(DISTINCT user_id)` استفاده کردیم؛ چون ممکن است یک کاربر چند سبد خرید داشته باشد.
- در مرحله پرداخت هم کاربر را می‌شماریم، نه تعداد پرداخت‌ها را.
- `NULLIF(total_users, 0)` از تقسیم بر صفر جلوگیری می‌کند.
- خروجی به‌صورت دو ردیف ساخته شده است؛ برای همین از UNION ALL استفاده شده است.

> این مثال از جدول‌های فرضی users، carts و payments استفاده می‌کند و بخشی از دیتابیس تمرینی retail نیست.

## الگوی سوم — زمان دریافت اولین پاسخ به یک سؤال

**سؤال کسب‌وکار:** کدام تیکت‌ها یا پرسش‌ها دیرتر از بقیه پاسخ گرفته‌اند؟

فرض کنید دو جدول `questions` و `answers` داریم و هر پاسخ با `question_id` به سؤال مربوط است. ابتدا زمان اولین پاسخ هر سؤال را استخراج می‌کنیم، سپس اختلاف آن با زمان ایجاد سؤال را به ثانیه به دست می‌آوریم.

~~~sql
WITH first_answer AS (
    SELECT
        question_id,
        MIN(creation_date) AS first_answer_at
    FROM answers
    GROUP BY question_id
)
SELECT
    q.id AS question_id,
    TIMESTAMPDIFF(
        SECOND,
        q.creation_date,
        fa.first_answer_at
    ) AS time_to_first_answer_seconds
FROM questions AS q
JOIN first_answer AS fa
    ON fa.question_id = q.id
ORDER BY
    time_to_first_answer_seconds DESC,
    q.id ASC
LIMIT 500;
~~~

چرا در CTE از `MIN(creation_date)` استفاده کردیم؟ چون برای هر سؤال ممکن است چند پاسخ وجود داشته باشد، اما زمان موردنظر ما زمان اولین پاسخ است.

در این Query از INNER JOIN استفاده شده؛ یعنی سؤال‌های بدون پاسخ وارد نتیجه نمی‌شوند. اگر هدف تحلیل جداگانه‌ی سؤال‌های بی‌پاسخ باشد، باید از LEFT JOIN استفاده کنیم و آن‌ها را با NULL مشخص کنیم.

## الگوی چهارم — گزارش تجمیعی از چند جدول

فرض کنید می‌خواهیم برای هر شهر درآمد، تعداد سفارش یکتا و تعداد مشتریان خریدار را گزارش کنیم.

~~~sql
SELECT
    c.city,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT c.customer_id) AS active_customers,
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

در این خروجی Grain برابر شهر است؛ یعنی به ازای هر شهر یک ردیف می‌بینیم.

## الگوی پنجم — گزارش کشورها با UNION و رتبه‌بندی

گاهی داده‌ی روزانه‌ی کشورها در جدول جداگانه قرار دارد و می‌خواهیم مجموع موارد را به تفکیک کشور بسازیم. بخش تجمیع با JOIN یا UNION حل نمی‌شود؛ ابتدا باید بر اساس کشور GROUP BY کنیم. سپس می‌توانیم از Window Function برای رتبه‌بندی استفاده کنیم.

~~~sql
WITH country_totals AS (
    SELECT
        country,
        SUM(new_cases) AS total_cases,
        SUM(new_deaths) AS total_deaths
    FROM covid
    GROUP BY country
)
SELECT
    country,
    total_cases,
    total_deaths,
    RANK() OVER (ORDER BY total_deaths DESC) AS death_rank
FROM country_totals
ORDER BY death_rank, country;
~~~

این Query یک پیش‌نمایش از Window Function است. در ماژول SQL پیشرفته، تفاوت `RANK`، `DENSE_RANK` و `ROW_NUMBER` را به‌صورت کامل بررسی می‌کنیم.

## تمرین تحلیلی

برای هر سناریو ابتدا جدول‌ها، کلید اتصال و Grain خروجی را مشخص کنید؛ بعد Query را بنویسید.

1. مشتریانی را پیدا کنید که در یک بازه‌ی زمانی مشخص سفارش تکمیل‌شده داشته‌اند.
2. مشتریانی را بیابید که هیچ سفارش تکمیل‌شده‌ای ثبت نکرده‌اند.
3. نرخ تبدیل کاربر به خریدار را از روی جدول‌های users، carts و payments محاسبه کنید.
4. برای هر سؤال، زمان اولین پاسخ را محاسبه کنید و ۲۰ سؤال با بیشترین زمان انتظار را نمایش دهید.
5. درآمد هر شهر را به همراه تعداد سفارش‌های یکتا محاسبه کنید.

## نکات پایانی

- برای سنجش فعالیت، رخداد را دقیق تعریف کنید؛ «فعال» می‌تواند خرید، ورود، لایک یا هر رویداد دیگری باشد.
- در Funnel، واحد شمارش باید کاربر یکتا باشد، نه تعداد رخداد.
- در تحلیل زمان پاسخ، معمولاً اولین پاسخ معیار مناسب‌تری از آخرین پاسخ است.
- در گزارش‌های چندجدولی، Grain و Fanout را پیش از جمع‌زدن بررسی کنید.

---

[بازگشت به نقشه ماژول ۴](./README.md)
