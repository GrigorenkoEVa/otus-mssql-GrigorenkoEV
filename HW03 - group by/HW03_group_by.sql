/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
year(inv.InvoiceDate) as OrderYear,
month(inv.InvoiceDate) as OrderMonth,
avg (invln.UnitPrice) as AvPrice,
sum (invln.ExtendedPrice) as SumSales
from
Sales.Invoices inv, Sales.InvoiceLines invln
where inv.InvoiceID = invln.InvoiceID
group by year(inv.InvoiceDate), month(inv.InvoiceDate)
order by year(inv.InvoiceDate), month(inv.InvoiceDate)
/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
year(inv.InvoiceDate) as OrderYear,
month(inv.InvoiceDate) as OrderMonth,
avg (invln.UnitPrice) as AvPrice,
sum (invln.ExtendedPrice) as SumSales
from
Sales.Invoices inv, Sales.InvoiceLines invln
where inv.InvoiceID = invln.InvoiceID
group by year(inv.InvoiceDate), month(inv.InvoiceDate)
HAVING sum (invln.ExtendedPrice) > 4600000
order by year(inv.InvoiceDate), month(inv.InvoiceDate)

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
year(inv.InvoiceDate) as OrderYear,
month(inv.InvoiceDate) as OrderMonth,
invln.Description,
--avg (invln.UnitPrice) as AvPrice,
sum (invln.ExtendedPrice) as SumSales,
min (inv.InvoiceDate) as FirstInvoiceDate,
sum (invln.Quantity) as Quantity
from
Sales.Invoices inv, Sales.InvoiceLines invln
where inv.InvoiceID = invln.InvoiceID
group by year(inv.InvoiceDate), month(inv.InvoiceDate), invln.Description
HAVING sum (invln.Quantity) < 50

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/