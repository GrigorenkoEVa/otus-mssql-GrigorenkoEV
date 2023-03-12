/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO Sales.Customers

	  ([CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID]
      ,[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage]
      ,[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber]
	  ,[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL]
      ,[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode]
      ,[DeliveryLocation],[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy]
     )
	  values

('Tailspin Toys (Head Office2)',1,3,1,1001,1002,3,19586,19586,NULL,'2013-01-01',0,'False','False',7,'(308) 555-0100',
'(308) 555-0101','','','http://www.tailspintoys.com','Shop 38','1877 Mittal Road','90410',null,'PO Box 8975','Ribeiroville','90410',1),
('Tailspin Toys (Sylvanite, MT2)',1,3,1,1003,1004,3,33475,33475,NULL,'2013-02-02',0,'False','False',7,'(406) 555-0100',
'(406) 555-0101','','','http://www.tailspintoys.com/Sylvanite','Shop 245','705 Dita Lane','90216',null,'PO Box 259','Jogiville','90216',1),
('Tailspin Toys (Peeples Valley, AZ2)',1,3,1,1005,1006,3,26483,26483,NULL,'2013-03-03',0,'False','False',7,'(480) 555-0100',
'(480) 555-0101','','','http://www.tailspintoys.com/PeeplesValley','Unit 217','1970 Khandke Road','90205',null,'PO Box 3648','Lucescuville','90205',1),
('Tailspin Toys (Medicine Lodge, KS2)',1,3,1,1007,1008,3,21692,26483,NULL,'2013-04-04',0,'False','False',7,'(316) 555-0100',
'(316) 555-0101','','','http://www.tailspintoys.com/MedicineLodge','Suite 164','967 Riutta Boulevard','90152',null,'PO Box 5065','Maciasville','90152',1),
('Tailspin Toys (Gasport, NY2)',1,3,1,1009,1009,3,12748,12748,NULL,'2013-04-04',0,'False','False',7,'()) 555-0100',
'(316) 555-0101','','','http://www.tailspintoys.com/Gasport','Unit 176','1674 Skujins Boulevard','90261',null,'PO Box 6294','Kellnerovaville','90261',1)
; 

--select top 5 * from Sales.Customers order by CustomerID desc

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM	Sales.Customers
WHERE CustomerName = 'Tailspin Toys (Gasport, NY2)';

DELETE FROM	Sales.Customers
WHERE CustomerID in
(select top 5 CustomerID from Sales.Customers order by CustomerID desc)

--select * from Sales.Customers c where c.CustomerName = 'Tailspin Toys (Gasport, NY2)'

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

Update Sales.Customers
SET 
	PhoneNumber = '(316) 555-0102',
	FaxNumber = '(316) 555-0102'
WHERE CustomerID = 1067;

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
--select * into Sales.CustomersCopy from Sales.Customers

MERGE Sales.Customers as target
USING Sales.CustomersCopy as source
ON (target.CustomerID = source.CustomerID)

WHEN MATCHED AND (target.CustomerName = 'Tailspin Toys (Head Office2)') THEN
       UPDATE SET 
        target.AccountOpenedDate = '2013-06-06'

WHEN NOT MATCHED 
		THEN INSERT
			  ([CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID]
      ,[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage]
      ,[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber]
	  ,[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL]
      ,[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode]
      ,[DeliveryLocation],[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy]
     )
	  values
('Tailspin Toys (Head Office2)',1,3,1,1001,1002,3,19586,19586,NULL,'2013-06-06',0,'False','False',7,'(308) 555-0100',
'(308) 555-0101','','','http://www.tailspintoys.com','Shop 38','1877 Mittal Road','90410',null,'PO Box 8975','Ribeiroville','90410',1)
	OUTPUT deleted.*, $action, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out  "c:\Otus\bulk\Customers.txt" -T -w -t"@e$" -S DESKTOP-8HMPV99\MSSQL2019'

BULK INSERT [WideWorldImporters].Sales.CustomersBulk
				   FROM "c:\Otus\bulk\Customers.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@e$',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );

select Count(*) from Sales.CustomersBulk;

TRUNCATE TABLE Sales.CustomersBulk;