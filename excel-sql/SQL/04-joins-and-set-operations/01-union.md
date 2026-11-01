# درس ۱ — UNION؛ کنار هم قرار دادن خروجی چند Query

گاهی داده‌های هم‌نوع در چند منبع جدا نگهداری می‌شوند؛ مثلاً بخشی از ثبت‌نام‌ها از وب‌سایت و بخشی از رویدادهای حضوری آمده‌اند. برای تحلیل یکپارچه، می‌خواهیم خروجی این دو منبع را **زیر هم** قرار دهیم. عملگر `UNION` برای همین کار است.

## UNION چه کاری انجام می‌دهد؟

`UNION` نتیجه‌ی چند دستور `SELECT` را در یک مجموعه‌ی واحد ترکیب می‌کند. برخلاف JOIN که ستون‌ها را کنار هم قرار می‌دهد، UNION ردیف‌های نتیجه‌ها را روی هم می‌گذارد.

~~~mermaid
flowchart TB
    A["SELECT از منبع A"] --> C["UNION"]
    B["SELECT از منبع B"] --> C
    C --> D["یک Result Set واحد"]
    D --> E["ردیف‌های تکراری حذف می‌شوند"]
~~~

## شرط‌های سازگاری دو خروجی

برای ترکیب دو SELECT باید:

1. تعداد ستون‌های خروجی برابر باشد.
2. ستون‌های متناظر از نظر معنا و نوع داده با هم سازگار باشند.
3. ترتیب ستون‌ها در تمام SELECTها یکسان باشد.

نام ستون‌ها لازم نیست یکی باشد؛ نام ستون‌های خروجی نهایی از SELECT اول گرفته می‌شود.

## مثال ساده: یکسان‌سازی فهرست مشتریان چند کانال

فرض کنید دو منبع جدا برای سرنخ‌های فروش داریم:

~~~sql
SELECT
    full_name,
    email,
    'website' AS acquisition_channel
FROM website_leads

UNION

SELECT
    full_name,
    email,
    'event' AS acquisition_channel
FROM event_leads;
~~~

نتیجه شامل سه ستون هم‌ساختار است. چون از UNION استفاده کرده‌ایم، ردیف‌های کاملاً یکسان در خروجی نهایی یک بار نمایش داده می‌شوند.

**توجه:** یکتایی بر اساس تمام ستون‌های خروجی سنجیده می‌شود، نه فقط ایمیل. اگر ایمیل یکسان ولی کانال متفاوت باشد، دو ردیف جدا باقی می‌ماند.

## تفاوت UNION و UNION ALL

| عملگر | رفتار |
|---|---|
| `UNION` یا `UNION DISTINCT` | ردیف‌های تکراری را حذف می‌کند |
| `UNION ALL` | همه‌ی ردیف‌ها، از جمله تکراری‌ها، را نگه می‌دارد |

اگر هدف، ساخت یک رویدادنگار از فعالیت‌ها یا جمع کردن رکوردهای دو بازه زمانی باشد، معمولاً `UNION ALL` انتخاب مناسب‌تری است؛ چون نمی‌خواهیم دو رخداد مستقل فقط به دلیل یکسان بودن مقادیرشان یکی شوند.

~~~sql
SELECT
    'order' AS event_type,
    order_id AS event_id,
    customer_id,
    order_date AS event_time
FROM orders

UNION ALL

SELECT
    'signup' AS event_type,
    customer_id AS event_id,
    customer_id,
    CAST(signup_date AS DATETIME) AS event_time
FROM customers;
~~~

این Query یک خروجی یکپارچه از ثبت سفارش و ثبت‌نام تولید می‌کند. ستون `event_type` کمک می‌کند بفهمیم هر ردیف از کدام منبع آمده است.

## چرا SELECT * انتخاب خوبی نیست؟

در Queryهای UNION بهتر است ستون‌ها را صریح بنویسید. اگر ساختار یکی از جدول‌ها تغییر کند، استفاده از `SELECT *` ممکن است ترتیب یا تعداد ستون‌ها را به هم بزند.

~~~sql
-- روشن و قابل نگهداری
SELECT customer_id, full_name, city
FROM customers

UNION ALL

SELECT lead_id, lead_name, city
FROM archived_leads;
~~~

در مثال بالا فرض شده جدول دوم ستون‌های متناظر با نوع و معنای سازگار دارد.

## مرتب‌سازی نتیجه‌ی UNION

برای مرتب‌سازی کل خروجی، `ORDER BY` را در انتهای مجموعه‌ی UNION قرار دهید:

~~~sql
SELECT full_name, city
FROM customers

UNION

SELECT lead_name, city
FROM archived_leads

ORDER BY city, full_name;
~~~

مرتب‌سازی نهایی روی نتیجه‌ی ترکیب‌شده اعمال می‌شود، نه اینکه صرفاً یکی از SELECTها را مرتب کند.

## یک کاربرد تحلیلی: ساخت چند سطح از گزارش حقوق

فرض کنید جدول `employees` دارای ستون‌های `job_id`، `squad_id` و `salary` است. می‌خواهیم چهار نوع جمع را در یک خروجی داشته باشیم:

- جمع حقوق به تفکیک سمت و تیم
- جمع حقوق به تفکیک سمت
- جمع حقوق به تفکیک تیم
- جمع حقوق کل شرکت

در MySQL می‌توان این چهار سطح را با `UNION ALL` کنار هم قرار داد:

~~~sql
SELECT job_id, squad_id, salary
FROM (
    SELECT
        job_id,
        squad_id,
        SUM(salary) AS salary,
        1 AS sort_level
    FROM employees
    GROUP BY job_id, squad_id

    UNION ALL

    SELECT
        job_id,
        NULL AS squad_id,
        SUM(salary) AS salary,
        2 AS sort_level
    FROM employees
    GROUP BY job_id

    UNION ALL

    SELECT
        NULL AS job_id,
        squad_id,
        SUM(salary) AS salary,
        3 AS sort_level
    FROM employees
    GROUP BY squad_id

    UNION ALL

    SELECT
        NULL AS job_id,
        NULL AS squad_id,
        SUM(salary) AS salary,
        4 AS sort_level
    FROM employees
) AS salary_report
ORDER BY sort_level, job_id, squad_id;
~~~

این مثال از `NULL` برای نشان دادن سطح تجمیع استفاده می‌کند؛ در این گزارش، NULL در ردیف‌های subtotal به معنی «همه‌ی سمت‌ها» یا «همه‌ی تیم‌ها» است، نه لزوماً داده‌ی نامشخص.

> در MySQL عبارت `WITH ROLLUP` هم برای تولید برخی جمع‌های میانی وجود دارد؛ اما وقتی دقیقاً به چند نوع subtotal مستقل نیاز داریم، UNION ALL کنترل بیشتری روی شکل خروجی می‌دهد.

## خطاهای رایج

- تعداد ستون‌ها در دو SELECT برابر نیست.
- ترتیب ستون‌ها جابه‌جا شده است.
- نوع داده‌ی ستون‌های متناظر سازگار نیست.
- استفاده از UNION در جایی که حفظ ردیف‌های تکراری اهمیت دارد.
- قرار دادن ORDER BY در جای اشتباه.
- فراموش کردن ستون منبع در خروجی‌هایی که باید منشاء هر ردیف مشخص باشد.

## تمرین کلاسی

1. دو فهرست از مشتریان فعال و مشتریان آرشیوی را با UNION ترکیب کنید.
2. همان Query را با UNION ALL اجرا کنید و تفاوت تعداد ردیف‌ها را بررسی کنید.
3. یک ستون ثابت به نام `source_name` به هر خروجی اضافه کنید تا منبع هر رکورد مشخص شود.
4. از دو گروه‌بندی متفاوت یک گزارش بسازید و ردیف‌های جمع کل را با مقدار NULL مشخص کنید.

## جمع‌بندی

- UNION نتایج SELECT را از نظر ردیف‌ها ترکیب می‌کند.
- UNION ردیف‌های کاملاً تکراری را حذف می‌کند.
- UNION ALL ردیف‌های تکراری را نگه می‌دارد و برای تجمیع رخدادها اغلب مناسب‌تر است.
- برای Query قابل اتکا، ستون‌ها را صریح انتخاب کنید و به ترتیب و نوع آن‌ها دقت داشته باشید.

---

[بازگشت به نقشه ماژول ۴](./README.md)
