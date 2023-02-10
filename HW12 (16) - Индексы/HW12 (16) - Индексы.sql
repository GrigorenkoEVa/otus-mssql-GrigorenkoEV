USE [ReestrRP]
GO

--PK ������ ��� ������ ������� ��� �� ��������
--ALTER TABLE purpose_voc ADD PRIMARY KEY CLUSTERED (code ASC);
CREATE CLUSTERED INDEX PK_purpose_voc_code ON purpose_voc (code);

--������� ��� FK
CREATE INDEX FK_rights_rights_voc_code_Index1 ON rights (rights_voc_code ASC);
CREATE INDEX FK_rights_objects_id_Index2 ON rights (objects_id ASC);

--������ COLUMNSTORE ��� ������ ��������� �� ���� ��������/��������
CREATE COLUMNSTORE INDEX IX_entities_s_date ON entities (s_date);

 --��� ������ �� ������������/��� + ���� ��������/�������� + ������ ���������
CREATE INDEX IX_entities_name_s_date_doc_num on entities (id) INCLUDE (name,s_date,doc_num);

--��� ������ ���� �� ������ �����
CREATE COLUMNSTORE INDEX IX_rights_reg_no ON rights (reg_no);

/*��� ������ �� ������ ������� (�� �������, ��� ��� ����� �������������� ������, � ������� �������� �������,
��������� ����, ����������, ���� � ��������)*/
CREATE INDEX IX_objects_adress ON [objects] (adress);
