# ماژول ۴ — ترکیب نتایج و اتصال جدول‌ها

در دیتابیس واقعی، اطلاعات معمولاً در یک جدول واحد نگهداری نمی‌شود. مشخصات مشتری، سفارش، محصول و جزئیات خرید هرکدام جای خود را دارند. تحلیلگر باید بتواند این قطعات را درست کنار هم قرار دهد؛ بدون اینکه رکوردی را ناخواسته حذف یا چند بار شمارش کند.

در این ماژول دو مسئله‌ی متفاوت را یاد می‌گیریم:

- **ترکیب عمودی نتایج:** با `UNION` چند خروجی هم‌ساختار را زیر هم قرار می‌دهیم.
- **اتصال افقی جدول‌ها:** با `JOIN` ستون‌های مرتبط از جدول‌های مختلف را کنار هم می‌آوریم.

> نکته‌ی محوری این ماژول: قبل از نوشتن JOIN مشخص کنید هر ردیف خروجی قرار است نماینده‌ی چه چیزی باشد؛ یک مشتری، یک سفارش یا یک قلم از سفارش؟

## مسیر یادگیری

| درس | موضوع | مهارت مورد انتظار |
|---|---|---|
| [۱. UNION](./01-union.md) | ترکیب نتایج چند SELECT | ساخت یک خروجی از چند منبع هم‌ساختار |
| [۲. INNER JOIN](./02-inner-join.md) | اتصال رکوردهای دارای تطبیق | دریافت اطلاعات مرتبط از دو جدول |
| [۳. LEFT JOIN و Anti Join](./03-left-join-and-anti-join.md) | حفظ همه‌ی رکوردهای سمت چپ و یافتن موارد بدون تطبیق | پیدا کردن مشتری یا محصول بدون فعالیت |
| [۴. اتصال چند جدول و کنترل تعداد ردیف‌ها](./04-multi-table-joins-and-grain.md) | زنجیره‌کردن JOINها، Cardinality و Fanout | جلوگیری از دوباره‌شماری در KPIها |
| [۵. الگوهای تحلیلی چندجدولی](./05-analytical-join-patterns.md) | مشتری فعال، قیف تبدیل و زمان پاسخ‌گویی | تبدیل سؤال کسب‌وکار به Query |
| [۶. آزمایشگاه JOIN و UNION](./06-join-union-practice-lab.md) | تمرین مرحله‌ای و پروژه کوتاه | نوشتن Query مستقل و قابل دفاع |

## مدل داده‌ای که در تمرین‌ها استفاده می‌کنیم

برای این ماژول از همان دیتابیس تمرینی فروشگاه آنلاین استفاده کنید:

- [اسکریپت ساخت دیتابیس](../practice/retail_schema.sql)
- [راهنمای کل SQL](../README.md)

~~~mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--|{ ORDER_ITEMS : contains
    PRODUCTS ||--o{ ORDER_ITEMS : appears_in
    CUSTOMERS {
        bigint customer_id PK
        varchar full_name
        varchar city
    }
    ORDERS {
        bigint order_id PK
        bigint customer_id FK
        datetime order_date
        varchar status
    }
    ORDER_ITEMS {
        bigint order_item_id PK
        bigint order_id FK
        bigint product_id FK
        int quantity
        decimal unit_price
    }
    PRODUCTS {
        bigint product_id PK
        varchar product_name
        varchar category
    }
~~~

## پیش‌نیاز

پیش از شروع، این موارد را مرور کنید:

1. مفهوم Primary Key و Foreign Key
2. دستورهای `SELECT` و `WHERE`
3. `GROUP BY` و توابع تجمیعی
4. Subquery و مفهوم NULL

## روش پیشنهادی کار در کلاس

برای هر مثال، ابتدا پیش‌بینی کنید خروجی چند ردیف خواهد داشت. سپس Query را اجرا کنید و تعداد ردیف‌ها را با انتظار خود بسنجید. این عادت ساده بسیاری از خطاهای JOIN را پیش از تبدیل شدن به KPI اشتباه آشکار می‌کند.

## نکته درباره نسخه

مثال‌ها برای **MySQL 8.4** نوشته شده‌اند. در بخش JOIN از Syntax استاندارد `JOIN ... ON` استفاده می‌کنیم و از `NATURAL JOIN` پرهیز می‌کنیم؛ چون تغییر نام یا اضافه شدن یک ستون هم‌نام می‌تواند رفتار آن را ناخواسته عوض کند.

## منابع مرجع

- [MySQL 8.4 — JOIN Clause](https://dev.mysql.com/doc/refman/8.4/en/join.html)
- [MySQL 8.4 — UNION Clause](https://dev.mysql.com/doc/refman/8.4/en/union.html)
