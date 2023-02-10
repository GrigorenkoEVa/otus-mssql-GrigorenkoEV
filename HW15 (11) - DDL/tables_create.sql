/*15 (11) DDL - Создание таблиц, индексов, констрайнтов*/

CREATE TABLE purpose_voc (
  code INT NOT NULL,
  name NVARCHAR(250) NULL,
  PRIMARY KEY(code)
);

CREATE TABLE rights_voc (
  code NUMERIC(8) NOT NULL,
  name NVARCHAR(64) NULL,
  groupp NVARCHAR(1) NULL,
  PRIMARY KEY(code)
);

CREATE TABLE entities (
  id INTEGER  identity(1,1) NOT NULL,
  citizen NVARCHAR(64),
  dept_id INTEGER  NULL,
  end_date DATE NULL,
  inn NVARCHAR(12) NULL,
  married NUMERIC(1) NULL,
  name NVARCHAR(500) NULL,
  nationals NVARCHAR(1) NULL DEFAULT 'Р',
  ogrn NVARCHAR(200) NULL,
  okpo NUMERIC(8) NULL,
  prop_type NUMERIC(3) NULL,
  r_type NVARCHAR(1) NULL DEFAULT 'Ф',
  doc_date DATE NULL,
  doc_num NVARCHAR(40) NULL,
  doc_org NVARCHAR(255) NULL,
  doc_ser NVARCHAR(40) NULL,
  doc_type NVARCHAR(100) NULL,
  comments NVARCHAR(2000) NULL,
  s_date DATE NULL,
  PRIMARY KEY(id)
);

ALTER TABLE entities ADD CONSTRAINT ent_old_constr 
  CHECK (datediff(yy, s_date, getdate()) >=18);

CREATE TABLE objects (
  id INTEGER  identity(1,1) NOT NULL,
  cad_num NVARCHAR(500) NULL,
  dept_id INTEGER  NULL,
  adress NVARCHAR(250) NULL,
  obj_num NVARCHAR(3000) NULL,
  r_type NUMERIC(2) NULL,
  stores NVARCHAR(250) NULL,
  store_no NVARCHAR(250) NULL,
  square NUMERIC(20,4) NULL,
  PRIMARY KEY(id)
);

CREATE TABLE qu_appl (
  id INTEGER  identity(1,1) NOT NULL,
  declare_desc NVARCHAR(2000) NULL,
  declare_adr NVARCHAR(255) NULL,
  declare_type NVARCHAR(1) NULL,
  end_date DATE NULL,
  incl_active_rights NVARCHAR(1) NULL DEFAULT 'Д',
  comments NVARCHAR(MAX) NULL,
  s_date DATETIME NULL,
  vol_id NUMERIC(20) NULL,
  vol_no_rec NUMERIC(20) NULL,
  ent_num NUMERIC(4) NULL,
  obj_num NUMERIC(4) NULL,
  ent_id INTEGER NULL,
  PRIMARY KEY(id),
  constraint qu_appl_entities_fk
  FOREIGN KEY (ent_id)
    REFERENCES entities(id)
      ON DELETE NO ACTION
      ON UPDATE CASCADE
);

CREATE TABLE qu_references (
  id INTEGER  identity(1,1) NOT NULL,
  qu_appl_id INTEGER  NOT NULL,
  decision NVARCHAR(1),
  original_num NUMERIC(3) NULL,
  qu_app_id INTEGER  NULL,
  reference_date DATE NULL,
  refuse_desc NVARCHAR(MAX) NULL,
  type_code NUMERIC(8) NULL,
  PRIMARY KEY(id, qu_appl_id),
  INDEX qu_references_FKIndex1(qu_appl_id),
  FOREIGN KEY(qu_appl_id)
    REFERENCES qu_appl(id)
      ON DELETE NO ACTION
      ON UPDATE CASCADE
);

CREATE TABLE purposes (
  id INTEGER  identity(1,1) NOT NULL,
  purpose_voc_Code INT NOT NULL,
  objects_id INTEGER  NOT NULL,
  re_id INTEGER  NULL,
  type_code INT NULL,
  PRIMARY KEY(id, purpose_voc_Code, objects_id),
  INDEX Purposes_FKIndex2(objects_id),
  FOREIGN KEY(purpose_voc_code)
    REFERENCES purpose_voc(Code)
      ON DELETE NO ACTION
      ON UPDATE NO ACTION,
  FOREIGN KEY(objects_id)
    REFERENCES objects(id)
      ON DELETE NO ACTION
      ON UPDATE CASCADE
);

CREATE TABLE qu_reference_voc (
  code NUMERIC(8) NOT NULL,
  qu_references_id INTEGER  NOT NULL,
  qu_references_qu_appl_id INTEGER  NOT NULL,
  name NVARCHAR(64) NULL,
  remark NVARCHAR(240) NULL,
  ent_id INTEGER  NULL,
  PRIMARY KEY(code, qu_references_id, qu_references_qu_appl_id),
  INDEX qu_reference_voc_FKIndex1(qu_references_id, qu_references_qu_appl_id),
  FOREIGN KEY(qu_references_id, qu_references_qu_appl_id)
    REFERENCES qu_references(id, qu_appl_id)
      ON DELETE NO ACTION
      ON UPDATE CASCADE
 );

CREATE TABLE rights (
  id INTEGER  identity(1,1) NOT NULL,
  rights_voc_code NUMERIC(8) NOT NULL,
  objects_id INTEGER  NOT NULL,
  brg_id INTEGER  NULL,
  condition NVARCHAR(MAX) NULL,
  con_desc NVARCHAR(2000) NULL,
  currency NUMERIC(3) NULL,
  dept_id INTEGER  NULL,
  end_reg_no NVARCHAR(40) NULL,
  part NVARCHAR(MAX) NULL,
  price NVARCHAR(MAX) NULL,
  reg_no NVARCHAR(40) NULL,
  obj_id INTEGER  NULL,
  rs_desc NVARCHAR(MAX) NULL,
  rs_end_date DATE NULL,
  r_group NVARCHAR(1) NULL,
  s_date DATE NULL,
  type_code NUMERIC(8) NULL,
  rs_s_date DATE NULL,
  PRIMARY KEY(id, rights_voc_code, objects_id),
  INDEX Rights_FKIndex1(rights_voc_code),
  INDEX Rights_FKIndex2(objects_id),
  FOREIGN KEY(rights_voc_code)
    REFERENCES rights_voc(code)
      ON DELETE NO ACTION
      ON UPDATE NO ACTION,
  FOREIGN KEY(objects_id)
    REFERENCES objects(id)
      ON DELETE NO ACTION
      ON UPDATE CASCADE
);

