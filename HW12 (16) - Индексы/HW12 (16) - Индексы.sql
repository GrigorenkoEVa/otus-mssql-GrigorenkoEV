USE [ReestrRP]
GO

--PK Создан для каждой таблицы при их создании
--ALTER TABLE purpose_voc ADD PRIMARY KEY CLUSTERED (code ASC);
CREATE CLUSTERED INDEX PK_purpose_voc_code ON purpose_voc (code);

--Индексы для FK
CREATE INDEX FK_rights_rights_voc_code_Index1 ON rights (rights_voc_code ASC);
CREATE INDEX FK_rights_objects_id_Index2 ON rights (objects_id ASC);

--Индекс COLUMNSTORE для поиска субъектов по дате рождения/создания
CREATE COLUMNSTORE INDEX IX_entities_s_date ON entities (s_date);

 --Для поиска по наименованию/ФИО + дате рождения/создания + номеру документа
CREATE INDEX IX_entities_name_s_date_doc_num on entities (id) INCLUDE (name,s_date,doc_num);

--Для поиска прав по номеру права
CREATE COLUMNSTORE INDEX IX_rights_reg_no ON rights (reg_no);

/*Для поиска по адресу объекта (не уверена, что тут нужен полнотекстовый индекс, о котором подумала вначале,
поправьте меня, пожалуйста, если я ошиблась)*/
CREATE INDEX IX_objects_adress ON [objects] (adress);
