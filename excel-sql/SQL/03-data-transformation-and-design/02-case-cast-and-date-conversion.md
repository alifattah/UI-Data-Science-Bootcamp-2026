# درس ۲ — دسته‌بندی و تبدیل داده با CASE و CAST

گاهی داده‌ها از نظر فنی قابل ذخیره‌سازی‌اند، اما برای تحلیل به شکل دیگری نیاز داریم. ممکن است بخواهیم مبلغ سفارش را به چند سطح تقسیم کنیم یا متنی را که شبیه تاریخ است به نوع DATE تبدیل کنیم.

در این درس دو ابزار مهم را می‌آموزیم: `CASE` برای ساخت مقدارهای شرطی و `CAST` برای تبدیل نوع داده.

## ۱. CASE؛ منطق شرطی در SQL

ساختار کلی:

```sql
CASE
    WHEN condition_1 THEN result_1
    WHEN condition_2 THEN result_2
    ELSE default_result
END
```

مثال: دسته‌بندی قیمت محصولات:

```sql
SELECT
    product_name,
    unit_price,
    CASE
        WHEN unit_price >= 2000000 THEN 'Premium'
        WHEN unit_price >= 1000000 THEN 'Standard'
        ELSE 'Budget'
    END AS price_segment
FROM products;
```

شرط‌ها به ترتیب بررسی می‌شوند و اولین شرطی که برقرار باشد نتیجه را تعیین می‌کند؛ به همین دلیل ترتیب شرط‌ها مهم است.

### CASE برای تبدیل کد به برچسب

```sql
SELECT
    order_id,
    status,
    CASE status
        WHEN 'completed' THEN 'Finalized'
        WHEN 'shipped' THEN 'In Transit'
        WHEN 'cancelled' THEN 'Cancelled'
        ELSE 'Other'
    END AS status_label
FROM orders;
```

در این فرم، یک عبارت با چند مقدار مقایسه می‌شود. وقتی شرط‌ها پیچیده‌ترند، فرم اول `CASE WHEN` انعطاف بیشتری دارد.

## ۲. CASE برای محاسبه شاخص‌های شرطی

یکی از کاربردهای مهم CASE، محاسبه شاخص برای گروه خاصی از ردیف‌هاست.

مثال: تعداد سفارش تکمیل‌شده و تعداد سفارش لغوشده در یک گزارش:

```sql
SELECT
    COUNT(*) AS all_orders,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders
FROM orders;
```

این تکنیک را **Conditional Aggregation** می‌نامند و در ساخت KPIهای چندگانه کاربرد زیادی دارد.

## ۳. CAST؛ تبدیل نوع داده

`CAST` یک عبارت را به نوع داده دیگری تبدیل می‌کند:

```sql
CAST(expression AS target_type)
```

مثال‌ها:

```sql
SELECT
    CAST('2025-04-18' AS DATE) AS parsed_date,
    CAST('1250.75' AS DECIMAL(10,2)) AS amount,
    CAST(42 AS CHAR) AS text_code;
```

تبدیل نوع داده زمانی اهمیت دارد که فایل ورودی یک مقدار عددی یا تاریخ را به شکل متن وارد کرده باشد.

## ۴. تبدیل متن به تاریخ با STR_TO_DATE

اگر قالب تاریخ ورودی با فرمت استاندارد MySQL متفاوت باشد، `STR_TO_DATE` کمک می‌کند آن را تفسیر کنیم.

فرض کنید تاریخ در قالب `18/04/2025` ذخیره شده است:

```sql
SELECT STR_TO_DATE('18/04/2025', '%d/%m/%Y') AS parsed_date;
```

چند نماد پرکاربرد:

| نماد | معنا |
|---|---|
| `%Y` | سال چهاررقمی |
| `%y` | سال دورقمی |
| `%m` | ماه عددی |
| `%d` | روز ماه |
| `%H` | ساعت ۲۴ ساعته |
| `%i` | دقیقه |
| `%s` | ثانیه |

### مثال پاک‌سازی تاریخ متنی

فرض کنید در جدول staging ستونی به نام `order_date_text` داریم:

```sql
SELECT
    order_date_text,
    STR_TO_DATE(order_date_text, '%d/%m/%Y') AS order_date
FROM raw_orders;
```

مقادیر نامعتبر ممکن است به NULL تبدیل شوند یا هشدار/خطا ایجاد کنند. قبل از تبدیل کل ستون، نمونه‌های داده را بررسی کنید و تعداد تبدیل‌های ناموفق را بسنجید.

## ۵. تفاوت CAST و STR_TO_DATE

- `CAST` زمانی مناسب است که مقدار از نظر قالب با نوع مقصد سازگار باشد.
- `STR_TO_DATE` زمانی استفاده می‌شود که بخواهیم یک رشته را با الگوی مشخص به تاریخ یا زمان تبدیل کنیم.

برای مثال، `CAST('2025-04-18' AS DATE)` برای قالب استاندارد مناسب است؛ اما رشته `18/04/2025` را باید با الگوی مربوطه تفسیر کرد.

## ۶. ترکیب CASE، CAST و توابع دیگر

مثال: ساخت گزارش از مقادیر متنیِ مبلغ در یک جدول مرحله‌ای:

```sql
SELECT
    CASE
        WHEN raw_amount IS NULL OR TRIM(raw_amount) = '' THEN 'Missing'
        WHEN CAST(raw_amount AS DECIMAL(12,2)) < 0 THEN 'Invalid'
        ELSE 'Available'
    END AS amount_quality
FROM raw_transactions;
```

این مثال فقط زمانی امن است که مقدارهای غیرخالی واقعاً قابل تبدیل به عدد باشند. در داده‌های خام ممکن است متن‌هایی مانند `unknown` یا جداکننده‌های ناسازگار وجود داشته باشد؛ بنابراین قبل از CAST باید قواعد اعتبارسنجی و تبدیل را تعریف کنیم.

## تمرین

1. سفارش‌ها را بر اساس وضعیت به برچسب‌های فارسی یا انگلیسی قابل فهم تبدیل کنید.
2. تعداد سفارش‌های هر وضعیت را با Conditional Aggregation در یک ردیف محاسبه کنید.
3. یک رشته تاریخ با قالب `DD/MM/YYYY` را به DATE تبدیل کنید.
4. تفاوت CAST و STR_TO_DATE را با یک مثال توضیح دهید.

## چالش تحلیلی

فرض کنید فایل خام فروش دو ستون متنی دارد: مبلغ و تاریخ. برخی مبالغ خالی‌اند و تاریخ‌ها با قالب `DD/MM/YYYY` آمده‌اند. یک Query طراحی کنید که:
- تاریخ را به نوع DATE تبدیل کند؛
- مبلغ را به DECIMAL تبدیل کند؛
- ردیف‌های دارای مقدار ناقص را با یک برچسب مشخص کند؛
- مبلغ هر ردیف را به سه بازه Low، Medium و High دسته‌بندی کند.

## جمع‌بندی

CASE برای ساخت خروجی شرطی و دسته‌بندی رکوردها مناسب است. CAST نوع داده را تبدیل می‌کند و STR_TO_DATE برای تفسیر تاریخ متنی با فرمت مشخص استفاده می‌شود. در پاک‌سازی داده، تبدیل موفق را با کنترل کیفیت همراه کنید.

## مطالعه بیشتر

- [MySQL 8.4 — Flow Control Functions](https://dev.mysql.com/doc/refman/8.4/en/flow-control-functions.html)
- [MySQL 8.4 — CAST Functions and Operators](https://dev.mysql.com/doc/refman/8.4/en/cast-functions.html)
- [MySQL 8.4 — STR_TO_DATE](https://dev.mysql.com/doc/refman/8.4/en/date-and-time-functions.html)
