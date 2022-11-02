/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, JOIN".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� WideWorldImporters ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

select wsi.StockItemID, wsi.StockItemName
from Warehouse.StockItems wsi
where wsi.StockItemName like '%urgent%'
or wsi.StockItemName like 'Animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

/* ��� ������
select sup.SupplierID, sup.SupplierName
from Purchasing.Suppliers sup
where sup.SupplierID not in
(
select sup.SupplierID
from Purchasing.PurchaseOrders ord, Purchasing.Suppliers sup
where ord.SupplierID = sup.SupplierID 
)
*/

select sup.SupplierID, sup.SupplierName
from Purchasing.Suppliers sup
left join Purchasing.PurchaseOrders ord
on ord.SupplierID = sup.SupplierID
except
select sup.SupplierID, sup.SupplierName
from Purchasing.Suppliers sup
join Purchasing.PurchaseOrders ord
on ord.SupplierID = sup.SupplierID


select sup.SupplierID, sup.SupplierName
from Purchasing.Suppliers sup
left join Purchasing.PurchaseOrders ord
on ord.SupplierID = sup.SupplierID
where ord.PurchaseOrderID IS NULL

/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select ord.OrderID, 
format(ord.OrderDate, 'dd.MM.yyyy') as OrderDate,
--month(ord.OrderDate) as OrderMonth,
DateName( month , DateAdd( month , month(ord.OrderDate) , 0 ) - 1 ) as OrderNMonth,
DatePart(quarter, ord.OrderDate ) as OrderQuarter,
--format(ordln.PickingCompletedWhen, 'dd.MM.yyyy')as PickingCompletedWhen,
case when month(ord.OrderDate) < 5 then 1
	 when month(ord.OrderDate) > 4  and month(ord.OrderDate) < 9 then 2
else 3 end OrderThird,
custm.CustomerName,
ordln.Quantity,
ordln.UnitPrice
from Sales.Orders ord, Sales.OrderLines ordln, Sales.Customers custm
where custm.CustomerID=ord.CustomerID
and ord.OrderID=ordln.OrderID
and (ordln.UnitPrice>100 or ordln.Quantity>20)
and ordln.PickingCompletedWhen is not null
order by OrderQuarter,  OrderDate
offset 1000 ROWS FETCH FIRST 100 ROWS ONLY

/*
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select met.DeliveryMethodName,
format(pord.ExpectedDeliveryDate,'dd.MM.yyyy') as ExpectedDeliveryDate,
sup.SupplierName,
people.FullName
--pord.IsOrderFinalized
from Purchasing.Suppliers sup, Purchasing.PurchaseOrders pord, Application.DeliveryMethods met, Application.People people
where sup.SupplierID = pord.SupplierID
and sup.DeliveryMethodID = met.DeliveryMethodID
and pord.ContactPersonID = people.PersonID
and pord.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-02-01'
and met.DeliveryMethodName like '%Air Freight'
and pord.IsOrderFinalized = 1

/*
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/

select top 10
ord.OrderID,
		ord.OrderDate,
		cust.CustomerName, 
		ppl.FullName as SalespersonName
from Sales.Orders ord, Sales.Customers cust, Application.People ppl
where ord.SalespersonPersonID=ppl.PersonID
and cust.CustomerID=ord.CustomerID
order by ord.OrderDate desc


/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/

select distinct
	   cust.CustomerID,
	   cust.CustomerName,
	   cust.PhoneNumber
from Sales.Orders ord
INNER JOIN Sales.Customers cust ON cust.CustomerID = ord.CustomerID
INNER JOIN Sales.OrderLines ol ON ol.OrderID = ord.OrderID
INNER JOIN Warehouse.StockItems sti ON sti.StockItemID = ol.StockItemID
where sti.StockItemName = 'Chocolate frogs 250g'
order by cust.CustomerID