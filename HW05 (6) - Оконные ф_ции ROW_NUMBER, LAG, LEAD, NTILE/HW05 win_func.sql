/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

--Без оконной функции нарастающий итог по месяцам не получается.
--Подскажите, пожалуйста, какой функцией это можно сделать

select DATEFROMPARTS(year(inv.InvoiceDate),month(inv.InvoiceDate),'01') as InvoiceMonth,
--inv.InvoiceDate,--inv.InvoiceID,cust.CustomerName,
--invln.ExtendedPrice,
--DATEFROMPARTS(year(inv2.InvoiceDate),month(inv2.InvoiceDate),'01') as month2,
--sum(ExtendedPrice) OVER () AS TotalSum,
sum(ExtendedPrice) OVER (PARTITION BY FORMAT(DATEFROMPARTS(year(inv.InvoiceDate),month(inv.InvoiceDate),'01') , 'dd.MM.yyyy')) AS PartitionSum,
sum(ExtendedPrice) AS SumSum
from
Sales.InvoiceLines invln
join Sales.Invoices inv on inv.InvoiceID = invln.InvoiceID and inv.InvoiceDate > '2014-12-31'
--join Sales.Invoices inv2 on inv2.InvoiceID = invln.InvoiceID
--	 and DATEFROMPARTS(year(inv2.InvoiceDate),month(inv2.InvoiceDate),'01') <= DATEFROMPARTS(year(inv.InvoiceDate),month(inv.InvoiceDate),'01')
--join Sales.Customers cust on cust.CustomerID = inv.CustomerID
group by DATEFROMPARTS(year(inv.InvoiceDate),month(inv.InvoiceDate),'01'),ExtendedPrice
order by DATEFROMPARTS(year(inv.InvoiceDate),month(inv.InvoiceDate),'01')

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

/*
select  --inv.InvoiceID, cust.CustomerName, 
inv.InvoiceDate, invln.ExtendedPrice,
sum (invln.ExtendedPrice) as SumSales,
SUM(invln.ExtendedPrice) OVER(order by inv.InvoiceDate range unbounded preceding) AS RsumD,
SUM(invln.ExtendedPrice) OVER(order by month(inv.InvoiceDate) range unbounded preceding) AS RsumMonth
--SUM(invln.ExtendedPrice) OVER(PARTITION BY inv.InvoiceDate) AS sumcust
from
Sales.Invoices inv, Sales.InvoiceLines invln--, Sales.Customers cust
where inv.InvoiceID = invln.InvoiceID  and inv.InvoiceDate > '2014-12-31'
--and cust.CustomerID = inv.CustomerID
--group by year(inv.InvoiceDate), inv.InvoiceDate--month(inv.InvoiceDate)
group by inv.InvoiceDate,invln.ExtendedPrice
order by year(inv.InvoiceDate), inv.InvoiceDate
*/
------------------------------------------------

select FORMAT(DATEFROMPARTS(year(inv.InvoiceDate),month(inv.InvoiceDate),'01') , 'dd.MM.yyyy') as InvoiceMonth,
inv.InvoiceDate,inv.InvoiceID,cust.CustomerName,
invln.ExtendedPrice,
sum(ExtendedPrice) OVER () AS TotalSum,
sum(ExtendedPrice) OVER (PARTITION BY FORMAT(DATEFROMPARTS(year(inv.InvoiceDate),month(inv.InvoiceDate),'01') , 'dd.MM.yyyy')) AS PartitionSum,
sum(ExtendedPrice) OVER (ORDER BY year(inv.InvoiceDate),month(inv.InvoiceDate)) AS SumSum
from
Sales.InvoiceLines invln
join Sales.Invoices inv on inv.InvoiceID = invln.InvoiceID and inv.InvoiceDate > '2014-12-31'
join Sales.Customers cust on cust.CustomerID = inv.CustomerID

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select * from (
select orl.Description, orl.Quantity, --ord.OrderDate, --month(ord.OrderDate) as Months,
ROW_NUMBER() over(partition by month(ord.OrderDate) order by orl.Quantity desc) as customertransrank
from Sales.Orders ord, Sales.Orderlines orl
where ord.OrderDate > = '2016-01-01' and ord.OrderDate < '2017-01-01'
and orl.OrderID = ord.OrderID
) AS O
where customertransrank<=2
--order by ord.OrderDate;

/*
select * from (
select w.StockItemName, orl.Quantity, --ord.OrderDate, --month(ord.OrderDate) as Months,
ROW_NUMBER() over(partition by month(ord.OrderDate) order by orl.Quantity desc) as customertransrank
from Sales.Orders ord, Sales.Orderlines orl, warehouse.StockItems w
where ord.OrderDate > = '2016-01-01' and ord.OrderDate < '2017-01-01'
and orl.OrderID = ord.OrderID and w.StockItemID=orl.StockItemID
) AS O
where customertransrank<=2
*/

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select w.StockItemID, w.StockItemName, w.Brand, w.UnitPrice, w.TypicalWeightPerUnit,
ROW_NUMBER() over(partition by left(w.StockItemName,1) order by w.StockItemName) as BySymb,
count (*) over() as Total_rows,
count (*) over(partition by left(w.StockItemName,1)) as CntBySymb,
LEAD (w.StockItemID) over(order by w.StockItemName) as NextID,
LAG (w.StockItemID) over(order by w.StockItemName) as PrevID,
(case when (cast (LAG (w.StockItemID,2,0) over(order by w.StockItemName) as nvarchar)) = '0'
	then 'No items'
	else cast ((LAG (w.StockItemID,2,0) over(order by w.StockItemName)) as nvarchar)
	end) as Lagg,
NTILE (30) over(order by w.TypicalWeightPerUnit) as TWeight
from Warehouse.StockItems w
--order by StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select * from (
select  ppl.PersonID, 
		ppl.FullName as SalespersonName,
		cust.CustomerID,
		cust.CustomerName,
		(orl.UnitPrice*orl.Quantity) as Price,
 		ord.OrderDate,
		ROW_NUMBER() over(partition by ppl.PersonID order by ord.OrderDate desc) as customertransrank
from Sales.Orders ord, Sales.Orderlines orl, Sales.Customers cust, Application.People ppl
where ord.SalespersonPersonID=ppl.PersonID
and cust.CustomerID=ord.CustomerID
and orl.OrderID = ord.OrderID
) AS O
where customertransrank=1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT c.CustomerID,
c.CustomerName,  O.*
FROM Sales.Customers C
OUTER APPLY (select top 2 il.UnitPrice, il.StockItemID, i.InvoiceDate
				from Sales.Invoices i, Sales.InvoiceLines il
				where i.InvoiceID = il.InvoiceID and i.CustomerID=c.CustomerID
				order by il.UnitPrice desc) AS O
ORDER BY C.CustomerName, UnitPrice desc;
--------------
select * from (
select c.CustomerID, c.CustomerName, il.UnitPrice, il.StockItemID, i.InvoiceDate,
ROW_NUMBER() over(partition by I.CustomerID order by il.UnitPrice desc) as customertransrank
				from Sales.Invoices i, Sales.InvoiceLines il,Sales.Customers C
				where i.InvoiceID = il.InvoiceID and i.CustomerID=c.CustomerID
				) AS O
where customertransrank<=2
order by CustomerName, UnitPrice desc;

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 