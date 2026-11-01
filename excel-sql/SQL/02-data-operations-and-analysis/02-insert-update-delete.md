# درس ۲ — درج، به‌روزرسانی و حذف داده‌ها

این سه دستور برای تغییر ردیف‌های جدول استفاده می‌شوند. تحلیلگر داده معمولاً بیشتر با SELECT کار می‌کند؛ با این حال، شناخت DML برای آماده‌سازی جدول‌های موقت، اصلاح داده آزمایشی و درک چرخه داده ضروری است.

> **هشدار عملی:** مثال‌های این درس را روی دیتابیس تمرینی اجرا کنید. اجرای UPDATE یا DELETE بدون شرط مناسب می‌تواند تمام ردیف‌های جدول را تغییر دهد یا حذف کند.

## ۱. درج داده با INSERT

ساختار پایه:

```sql
INSERT INTO table_name (column1, column2, ...)
VALUES (value1, value2, ...);
```

برای افزودن یک مشتری:

```sql
INSERT INTO customers
    (full_name, email, city, signup_date)
VALUES
    ('Kian Moradi', 'kian@example.com', 'Tabriz', '2025-05-03');
```

ستون `customer_id` به دلیل `AUTO_INCREMENT` به‌صورت خودکار مقدار می‌گیرد.

### درج چند ردیف در یک دستور

```sql
INSERT INTO customers
    (full_name, email, city, signup_date)
VALUES
    ('Roya Etemadi', 'roya@example.com', 'Tehran', '2025-05-04'),
    ('Peyman Sadeghi', 'peyman@example.com', 'Shiraz', '2025-05-05');
```

در درج داده، بهتر است نام ستون‌ها را صریح مشخص کنید. در این صورت اگر ترتیب ستون‌ها در Schema تغییر کند، Query همچنان روشن‌تر و قابل نگهداری‌تر خواهد بود.

### استفاده از DEFAULT و NULL

اگر ستونی مقدار پیش‌فرض داشته باشد، می‌توان آن را حذف کرد یا صریحاً `DEFAULT` فرستاد. اما `NULL` به معنی ناموجود بودن مقدار است و با DEFAULT یکی نیست.

### درج داده از یک Query دیگر

برای ساخت جدول تحلیلی یا انتقال نتیجه به جدول مرحله‌ای، از `INSERT ... SELECT` استفاده می‌شود:

```sql
CREATE TABLE IF NOT EXISTS completed_orders_snapshot (
    order_id BIGINT UNSIGNED PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    order_date DATETIME NOT NULL
);

INSERT INTO completed_orders_snapshot
    (order_id, customer_id, order_date)
SELECT order_id, customer_id, order_date
FROM orders
WHERE status = 'completed';
```

این الگو زمانی کاربرد دارد که بخواهیم نتیجه Query را در جدول دیگری ذخیره کنیم. پیش از اجرای دوباره باید سیاست جلوگیری از درج رکوردهای تکراری را مشخص کنیم.

## ۲. به‌روزرسانی با UPDATE

قالب کلی:

```sql
UPDATE table_name
SET column1 = value1,
    column2 = value2
WHERE condition;
```

مثال: تغییر شهر یک مشتری مشخص:

```sql
UPDATE customers
SET city = 'Karaj'
WHERE customer_id = 5;
```

اگر `WHERE` حذف شود، همه ردیف‌های جدول به‌روزرسانی می‌شوند.

### روش امن‌تر برای UPDATE

قبل از اجرای تغییر، ابتدا همان شرط را با SELECT بررسی کنید:

```sql
-- 1) ابتدا ردیف هدف را ببینید
SELECT customer_id, full_name, city
FROM customers
WHERE customer_id = 5;

-- 2) سپس تغییر را اجرا کنید
UPDATE customers
SET city = 'Karaj'
WHERE customer_id = 5;

-- 3) نتیجه را دوباره بررسی کنید
SELECT customer_id, full_name, city
FROM customers
WHERE customer_id = 5;
```

اگر لازم است چند تغییر به‌صورت یک واحد انجام شوند، در InnoDB می‌توان از تراکنش استفاده کرد:

```sql
START TRANSACTION;

UPDATE customers
SET city = 'Karaj'
WHERE customer_id = 5;

-- اگر نتیجه درست بود:
COMMIT;

-- اگر نتیجه اشتباه بود، به‌جای COMMIT:
-- ROLLBACK;
```

در محیطی که Auto Commit فعال است، تراکنش را با دستورهای صریح مدیریت کنید. توجه داشته باشید که دستورهای DDL مانند بعضی عملیات تغییر ساختار جدول رفتار تراکنشی متفاوتی دارند.

## ۳. حذف داده با DELETE

```sql
DELETE FROM customers
WHERE customer_id = 5;
```

این دستور فقط ردیف‌هایی را حذف می‌کند که شرط WHERE برای آن‌ها درست باشد.

پیش از حذف:

```sql
SELECT *
FROM customers
WHERE customer_id = 5;
```

اگر شرط را حذف کنید، تمام ردیف‌های جدول حذف می‌شوند:

```sql
-- این دستور همه مشتریان را حذف می‌کند؛ روی جدول واقعی اجرا نکنید.
-- DELETE FROM customers;
```

### تفاوت DELETE و TRUNCATE

| دستور | رفتار |
|---|---|
| `DELETE FROM table WHERE ...` | حذف ردیف‌های مطابق شرط |
| `DELETE FROM table` | حذف همه ردیف‌ها با منطق DML |
| `TRUNCATE TABLE table` | خالی‌کردن کامل جدول با عملیات DDL |

در MySQL، `TRUNCATE` معمولاً سریع‌تر است، مقدار AUTO_INCREMENT را از نو آغاز می‌کند، Triggerهای DELETE را اجرا نمی‌کند و مانند DELETE داخل یک تراکنش قابل Rollback نیست. همچنین محدودیت‌های Foreign Key می‌توانند مانع اجرای آن شوند. بنابراین این دو دستور را معادل کامل هم در نظر نگیرید.

## ۴. آیا REPLACE همان UPDATE است؟

خیر. در MySQL، `REPLACE` اگر با Primary Key یا Unique Key تکراری برخورد کند، ردیف قبلی را حذف و ردیف جدید را درج می‌کند. در نتیجه ستون‌هایی که در دستور مشخص نشده‌اند ممکن است مقدار پیش‌فرض بگیرند یا NULL شوند و رفتار Foreign Key یا Trigger نیز اهمیت پیدا می‌کند.

برای بسیاری از سناریوهای درج یا به‌روزرسانی در صورت تکراری بودن کلید، `INSERT ... ON DUPLICATE KEY UPDATE` انتخاب روشن‌تری است:

```sql
INSERT INTO products
    (product_id, product_name, category, unit_price, active)
VALUES
    (106, 'Laptop Sleeve', 'Accessories', 690000, TRUE)
AS new
ON DUPLICATE KEY UPDATE
    product_name = new.product_name,
    category = new.category,
    unit_price = new.unit_price,
    active = new.active;
```

در این مثال اگر شناسه محصول از قبل وجود داشته باشد، ستون‌های مشخص‌شده به‌روزرسانی می‌شوند؛ اگر وجود نداشته باشد، ردیف جدید ساخته می‌شود.

## ۵. چک‌لیست ایمنی عملیات تغییردهنده

قبل از اجرای INSERT، UPDATE یا DELETE روی داده‌های مهم:

1. نام دیتابیس و محیط اجرا را بررسی کنید.
2. شرط UPDATE یا DELETE را با SELECT آزمایش کنید.
3. تعداد ردیف‌های هدف را بسنجید.
4. از داده‌های مهم نسخه پشتیبان داشته باشید.
5. در صورت امکان از تراکنش استفاده کنید.
6. پس از اجرا، نتیجه و تعداد ردیف‌های اثرپذیرفته را بررسی کنید.

## تمرین

روی دیتابیس تمرینی:

1. یک مشتری آزمایشی جدید درج کنید.
2. شهر همان مشتری را تغییر دهید.
3. پیش از حذف، ردیف آن را با SELECT بررسی کنید.
4. فقط همان مشتری آزمایشی را حذف کنید.
5. توضیح دهید چرا حذف بدون WHERE خطرناک است.
6. تفاوت REPLACE و INSERT ... ON DUPLICATE KEY UPDATE را با یک مثال توضیح دهید.

## جمع‌بندی

- `INSERT` ردیف جدید اضافه می‌کند.
- `UPDATE` مقدار ستون‌های ردیف‌های موجود را تغییر می‌دهد.
- `DELETE` ردیف‌ها را حذف می‌کند.
- `TRUNCATE` کل جدول را خالی می‌کند و ویژگی‌های تراکنشی متفاوتی دارد.
- `REPLACE` در صورت تعارض کلید، رفتار حذف و درج مجدد دارد؛ با UPDATE ساده یکی نیست.

## مطالعه بیشتر

- [MySQL 8.4 — INSERT](https://dev.mysql.com/doc/refman/8.4/en/insert.html)
- [MySQL 8.4 — UPDATE](https://dev.mysql.com/doc/refman/8.4/en/update.html)
- [MySQL 8.4 — DELETE](https://dev.mysql.com/doc/refman/8.4/en/delete.html)
- [MySQL 8.4 — REPLACE](https://dev.mysql.com/doc/refman/8.4/en/replace.html)
- [MySQL 8.4 — TRUNCATE TABLE](https://dev.mysql.com/doc/refman/8.4/en/truncate-table.html)
