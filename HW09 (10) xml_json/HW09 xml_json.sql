/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName).

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

----OPENXML-------------------------------------------------------------------------------------------------------------
DECLARE @xmlDocument XML;

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\Otus\Курсы\otus\W10\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
AS data;

SELECT @xmlDocument AS [@xmlDocument];

DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

SELECT @docHandle AS docHandle;

SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] NVARCHAR(100) '@Name',
	[SupplierID] INT 'SupplierID',

	[UnitPackageID] INT 'Package/UnitPackageID',
	[OuterPackageID] INT 'Package/OuterPackageID',
	[QuantityPerOuter] INT 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] Decimal(18,3) 'Package/TypicalWeightPerUnit',
	[Package] Decimal(18,3) 'Package',

	[LeadTimeDays] INT 'LeadTimeDays',
	[IsChillerStock] BIT 'IsChillerStock',
	[TaxRate] Decimal(18,3) 'TaxRate',
	[UnitPrice] Decimal(18,2) 'UnitPrice');

DROP TABLE IF EXISTS #StockItems;

CREATE TABLE #StockItems( 
	[StockItemName] NVARCHAR(100),
	[SupplierID] INT,

	[UnitPackageID] INT,
	[OuterPackageID] INT,
	[QuantityPerOuter] INT,
	[TypicalWeightPerUnit] Decimal(18,3),

	[LeadTimeDays] INT,
	[IsChillerStock] BIT,
	[TaxRate] Decimal(18,3),
	[UnitPrice] Decimal(18,2)
);

INSERT INTO #StockItems
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] NVARCHAR(100) '@Name',
	[SupplierID] INT 'SupplierID',

	[UnitPackageID] INT 'Package/UnitPackageID',
	[OuterPackageID] INT 'Package/OuterPackageID',
	[QuantityPerOuter] INT 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] Decimal(18,3) 'Package/TypicalWeightPerUnit',

	[LeadTimeDays] INT 'LeadTimeDays',
	[IsChillerStock] BIT 'IsChillerStock',
	[TaxRate] Decimal(18,3) 'TaxRate',
	[UnitPrice] Decimal(18,2) 'UnitPrice');

EXEC sp_xml_removedocument @docHandle;

SELECT * FROM #StockItems;

MERGE Warehouse.StockItems as target
USING #StockItems as source
ON (target.StockItemName = source.StockItemName)

WHEN MATCHED THEN
       UPDATE SET 
	    target.StockItemName = source.StockItemName,
        target.SupplierID = source.SupplierID,
		target.UnitPackageID = source.UnitPackageID,
		target.OuterPackageID = source.OuterPackageID,
		target.QuantityPerOuter = source.QuantityPerOuter,
		target.TypicalWeightPerUnit = source.TypicalWeightPerUnit,
		target.LeadTimeDays = source.LeadTimeDays,
		target.IsChillerStock = source.IsChillerStock,
		target.TaxRate = source.TaxRate,
		target.UnitPrice = source.UnitPrice

WHEN NOT MATCHED 
		THEN INSERT
		(StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays,
		IsChillerStock,TaxRate,UnitPrice) 
			VALUES (source.StockItemName, source.SupplierID, source.UnitPackageID, source.OuterPackageID, source.QuantityPerOuter,
			source.TypicalWeightPerUnit, source.LeadTimeDays, source.IsChillerStock,source.TaxRate,source.UnitPrice); 

--DROP TABLE IF EXISTS #StockItems;
--GO

----XQuery-------------------------------------------------------------------------------------------------------------

DECLARE @x XML;
SET @x = (SELECT * FROM OPENROWSET (BULK 'C:\Otus\Курсы\otus\W10\StockItems-188-1fb5df.xml', SINGLE_BLOB)  AS d);

SELECT  
		t.StockItems.value('(@Name)[1]', 'NVARCHAR(100)') AS [StockItemName],
		t.StockItems.value('(SupplierID)[1]', 'int') AS [SupplierID],

		t.StockItems.value('(Package/UnitPackageID)[1]', 'int') AS [UnitPackageID],
		t.StockItems.value('(Package/OuterPackageID)[1]', 'int') AS [OuterPackageID],
		t.StockItems.value('(Package/QuantityPerOuter)[1]', 'int') AS [QuantityPerOuter],
		t.StockItems.value('(Package/TypicalWeightPerUnit)[1]', 'Decimal(18,3)') AS [TypicalWeightPerUnit],

		t.StockItems.value('(LeadTimeDays)[1]', 'int') AS [LeadTimeDays],
		t.StockItems.value('(IsChillerStock)[1]', 'BIT') AS [IsChillerStock],
		t.StockItems.value('(TaxRate)[1]', 'Decimal(18,3)') AS [TaxRate],
		t.StockItems.value('(UnitPrice)[1]', 'Decimal(18,2)') AS [UnitPrice],

		t.StockItems.query('.')
FROM @x.nodes('/StockItems/Item') AS t(StockItems);

GO

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

select
	[StockItemName] AS [@Name],
	[SupplierID] AS [SupplierID],
	[StockItemID]  AS  [StockItemID],
	[ColorID]  AS  [ColorID],
	[Brand]  AS  [Brand],
	[Size]  AS [Size],
	[Barcode]  AS  [Barcode],
	[MarketingComments]  AS  [MarketingComments],

	[UnitPackageID] AS [Package/UnitPackageID],
	[OuterPackageID] AS [Package/OuterPackageID],
	[QuantityPerOuter] AS [Package/QuantityPerOuter],
	[TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit],

	[LeadTimeDays] AS [LeadTimeDays],
	[IsChillerStock] AS [IsChillerStock],
	[TaxRate] AS [TaxRate],
	[UnitPrice] AS [UnitPrice],
	[RecommendedRetailPrice]  AS  [RecommendedRetailPrice],
	[InternalComments]  AS  [InternalComments],
	[Photo]  [Photo],
	[CustomFields]  AS  [CustomFields],
	[Tags]  AS  [Tags],
	[SearchDetails]  AS [SearchDetails]
from Warehouse.StockItems
FOR XML PATH('StockItems'), ROOT('StockItems');

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT StockItemID,
StockItemName,
  JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
  JSON_VALUE(CustomFields, '$.Tags[0]') AS Tag
FROM Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

SELECT StockItemID,
StockItemName,
Tags.value
FROM Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields, '$.Tags') Tags
WHERE Tags.value = 'Vintage'
