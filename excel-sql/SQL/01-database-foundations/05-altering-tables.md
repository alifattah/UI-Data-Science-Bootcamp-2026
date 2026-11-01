# درس ۵ — تغییر ساختار جدول با ALTER TABLE

ساختار داده در یک پروژه ممکن است با گذشت زمان تغییر کند. برای مثال، فروشگاه ابتدا فقط نام مشتری را نگهداری می‌کند؛ اما بعداً تصمیم می‌گیرد شهر، شماره تماس یا زمان آخرین به‌روزرسانی را هم ثبت کند.

برای تغییر Schema جدول در MySQL از `ALTER TABLE` استفاده می‌کنیم.

## ۱. افزودن ستون

```sql
ALTER TABLE customers
ADD COLUMN phone VARCHAR(20) NULL;
```

اگر لازم است ستون در موقعیت مشخصی قرار بگیرد:

```sql
ALTER TABLE customers
ADD COLUMN customer_type VARCHAR(20) NOT NULL DEFAULT 'regular'
AFTER full_name;
```

در بیشتر Queryهای تحلیلی، ترتیب فیزیکی ستون‌ها اهمیتی ندارد؛ نام‌گذاری روشن و طراحی صحیح مهم‌تر است.

## ۲. اصلاح نوع داده یا Constraint با MODIFY

`MODIFY` نام ستون را تغییر نمی‌دهد؛ نوع داده یا ویژگی‌های آن را اصلاح می‌کند.

```sql
ALTER TABLE customers
MODIFY COLUMN full_name VARCHAR(160) NOT NULL;
```

## ۳. تغییر نام و تعریف ستون با CHANGE

`CHANGE` امکان تغییر نام ستون را نیز دارد و باید تعریف جدید ستون را کامل مشخص کنیم:

```sql
ALTER TABLE customers
CHANGE COLUMN full_name customer_name
VARCHAR(160) NOT NULL;
```

## ۴. تغییر نام جدول

```sql
RENAME TABLE customers TO clients;
```

یا:

```sql
ALTER TABLE clients
RENAME TO customers;
```

اگر جدول‌های دیگر به نام یا ساختار قبلی وابستگی دارند، قبل از تغییر آن‌ها را بررسی کنید.

## ۵. افزودن چند ستون

```sql
ALTER TABLE customers
    ADD COLUMN phone VARCHAR(20) NULL,
    ADD COLUMN marketing_opt_in BOOLEAN NOT NULL DEFAULT FALSE;
```

## ۶. حذف ستون

```sql
ALTER TABLE customers
DROP COLUMN marketing_opt_in;
```

حذف ستون داده‌های موجود در آن ستون را نیز از بین می‌برد. پیش از اجرا مطمئن شوید اطلاعات مورد نیاز جای دیگری نگهداری می‌شود.

## ۷. تغییر ساختار؛ با احتیاط

دستورهای DDL مانند `ALTER TABLE` ممکن است روی جدول‌های بزرگ زمان‌بر باشند یا باعث قفل و تغییرات عملیاتی شوند. قبل از اجرای تغییر روی محیط واقعی:

- از Schema و داده‌ها نسخه پشتیبان بگیرید.
- وابستگی Viewها، Queryها و برنامه‌ها را بررسی کنید.
- اثر تغییر روی داده‌های موجود را بسنجید؛ مثلاً تبدیل یک ستون به `NOT NULL` وقتی مقدار NULL دارد.
- تغییر را ابتدا روی محیط آزمایشی اجرا کنید.
- از حذف ستون یا تغییر نوع داده بدون بررسی نمونه داده‌ها خودداری کنید.

## اجرای عملی

در دیتابیس تمرینی:

```sql
-- افزودن ستون
ALTER TABLE customers
ADD COLUMN phone VARCHAR(20) NULL;

-- بزرگ‌تر کردن طول نام
ALTER TABLE customers
MODIFY COLUMN full_name VARCHAR(160) NOT NULL;

-- بررسی ساختار
DESCRIBE customers;
SHOW CREATE TABLE customers;
```

## تمرین

برای جدول `products` این تغییرها را طراحی کنید:

1. ستون `barcode` با نوع `VARCHAR(40)` اضافه کنید.
2. ستون `product_name` را به طول 160 تغییر دهید.
3. نام ستون `barcode` را به `sku` تغییر دهید.
4. Query حذف ستون `sku` را بنویسید؛ اما پیش از اجرا توضیح دهید چه زمانی حذف آن خطرناک است.

## جمع‌بندی

- `ADD` ستون جدید اضافه می‌کند.
- `MODIFY` نوع یا ویژگی ستون را تغییر می‌دهد.
- `CHANGE` امکان تغییر نام و تعریف ستون را فراهم می‌کند.
- `DROP COLUMN` ستون و داده‌های آن را حذف می‌کند.
- تغییر Schema در محیط واقعی باید با برنامه و نسخه پشتیبان انجام شود.

## مرجع

- [MySQL 8.4 — ALTER TABLE](https://dev.mysql.com/doc/refman/8.4/en/alter-table.html)
