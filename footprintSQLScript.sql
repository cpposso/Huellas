
/****** Object:  Table [dbo].[footprintItemsDin]    Script Date: 21/5/2020 20:09:30 ******/
DROP TABLE [dbo].[footprintItemsDin]
GO

/****** Object:  Table [dbo].[footprintItemsDin]    Script Date: 21/5/2020 20:09:30 ******/


CREATE TABLE [dbo].[footprintItemsDin](
	[table] [nvarchar](128) NOT NULL,
	[column] [nvarchar](128) NOT NULL
) ON [PRIMARY]
GO


/****** Object:  Table [dbo].[footprintV]    Script Date: 21/5/2020 20:09:34 ******/
DROP TABLE [dbo].[footprintV]
GO

CREATE TABLE [dbo].[footprintV](
	[id] [varchar](30) NOT NULL,
	[description] [varchar](30) NOT NULL,
 CONSTRAINT [PK_footprintV] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/****** Object:  Table [dbo].[footprint]    Script Date: 21/5/2020 20:11:01 ******/
DROP TABLE [dbo].[footprint]
GO

CREATE TABLE [dbo].[footprint](
	[rowid] [int] IDENTITY(1,1) NOT NULL,
	[id_fpv] [varchar](30) NOT NULL,
	[type] [varchar](20) NOT NULL,
	[object_name] [nvarchar](128) NOT NULL,
	[value_hash] [varbinary](128) NOT NULL,
	[ts] [timestamp] NOT NULL,
 CONSTRAINT [PK_footprint] PRIMARY KEY CLUSTERED 
(
	[id_fpv] ASC,
	[rowid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[footprint]  WITH CHECK ADD  CONSTRAINT [FK_footprint_footprint] FOREIGN KEY([id_fpv], [rowid])
REFERENCES [dbo].[footprint] ([id_fpv], [rowid])
GO

ALTER TABLE [dbo].[footprint] CHECK CONSTRAINT [FK_footprint_footprint]
GO



CREATE OR ALTER PROCEDURE [dbo].[fp_compare]
	@p_id1 varchar(30),
	@p_id2 varchar(30)
AS
BEGIN
	SET NOCOUNT ON;

	declare @tv1 TABLE (
	[f1_id_fpv] [varchar](30) ,
	[f1_type] [varchar](20) ,
	[f1_object_name] [nvarchar](128) ,
	[f1_value_hash] [varbinary](128) )

	declare @tv2 TABLE (
	[f2_id_fpv] [varchar](30) ,
	[f2_type] [varchar](20) ,
	[f2_object_name] [nvarchar](128) ,
	[f2_value_hash] [varbinary](128) )

	insert into @tv1
	select [id_fpv],[type],[object_name],[value_hash]
	from [dbo].[footprint] 
	where [id_fpv]=@p_id1

	insert into @tv2
	select [id_fpv],[type],[object_name],[value_hash]
	from [dbo].[footprint] 
	where [id_fpv]=@p_id2

		select [f1_type]Tipo_objeto,[f1_object_name]Nombre_objeto,'Objeto sin cambios'Descripcion
	from @tv1,@tv2
	where [f1_type] =[f2_type]
	and [f1_object_name]=[f2_object_name]
	and [f1_value_hash]=[f2_value_hash]
	union
	select [f1_type]Tipo_objeto,[f1_object_name]Nombre_objeto,'Objeto con diferencia'Descripcion
	from @tv1,@tv2
	where [f1_type] =[f2_type]
	and [f1_object_name]=[f2_object_name]
	and [f1_value_hash]<>[f2_value_hash]
	union
	select [f2_type]Tipo_objeto,[f2_object_name]Nombre_objeto,'Nuevo Objeto'Descripcion
	from @tv2
	where not exists(select 1 from @tv1
					where  [f1_type] =[f2_type]
					and [f1_object_name]=[f2_object_name])
	union
	select [f1_type]Tipo_objeto,[f1_object_name]Nombre_objeto,'Objeto eliminado'Descripcion
	from @tv1
	where not exists(select 1 from @tv2
					where  [f1_type] =[f2_type]
					and [f1_object_name]=[f2_object_name])


end;
GO

--exec fp_create 'prueba3'
CREATE OR ALTER PROCEDURE [dbo].[fp_create]
	@p_desc varchar(30)
	--exec [fp_create] 'prueba item config'
AS
BEGIN
	SET NOCOUNT ON;
	
	create table t_info (f_type varchar(20),
						 f_object_name nvarchar(128),
						 f_value_tohash nvarchar(4000),
						 f_value_hash varbinary(128) null)

	--definicion columnas tablas
	--insert into t_info
	declare @cur_type varchar(10),
			@cur_object_name nvarchar(128),
			@cur_value_tohash nvarchar(4000)

	insert into t_info
	select 'TABLE',TABLE_NAME, TABLE_NAME,null
	from [INFORMATION_SCHEMA].[TABLES] 
	where TABLE_NAME <>'sysdiagrams'
	and TABLE_TYPE='BASE TABLE'
	
	insert into t_info
	select 'COLUMN',TABLE_NAME+'.'+COLUMN_NAME, CONVERT(varchar(10), ORDINAL_POSITION)+isnull(COLUMN_DEFAULT,'')+IS_NULLABLE+DATA_TYPE+isnull(CONVERT(varchar(10), CHARACTER_MAXIMUM_LENGTH),''),null
	from  [INFORMATION_SCHEMA].[COLUMNS] 
	where TABLE_NAME <>'sysdiagrams'

	--informaciòn de check constraints
	insert into t_info
	select  'CONSTRAINT',CONSTRAINT_NAME,CHECK_CLAUSE ,null
	from [INFORMATION_SCHEMA].[CHECK_CONSTRAINTS]

	insert into t_info
	select 'PARAMETERS',SPECIFIC_NAME+PARAMETER_NAME ,DATA_TYPE +CONVERT (varchar(2),CHARACTER_MAXIMUM_LENGTH)+CONVERT (varchar(2),ORDINAL_POSITION)+PARAMETER_MODE ,null
	from [INFORMATION_SCHEMA].[PARAMETERS]


	insert into t_info
	select  CONSTRAINT_TYPE, t1.CONSTRAINT_NAME,convert(varchar(2),ORDINAL_POSITION)+COLUMN_NAME,null
	from  [INFORMATION_SCHEMA].[KEY_COLUMN_USAGE] t1
		inner join [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS] t2 on t1.CONSTRAINT_NAME=t2.CONSTRAINT_NAME
	where t1.TABLE_NAME <>'sysdiagrams'
	order by ORDINAL_POSITION


	--informacion vistas
	insert into t_info
	select 'VIEWS', TABLE_NAME, VIEW_DEFINITION,null
	FROM [INFORMATION_SCHEMA].[VIEWS]


	--funciones
	insert into t_info
	select ROUTINE_type,ROUTINE_NAME,ROUTINE_DEFINITION,null
	  FROM [INFORMATION_SCHEMA].[ROUTINES]
	  where ROUTINE_type='FUNCTION'
	  and ROUTINE_BODY ='SQL'
  
	 --sps
	 insert into t_info
	select ROUTINE_type,ROUTINE_NAME,ROUTINE_DEFINITION,null
	  FROM [INFORMATION_SCHEMA].[ROUTINES]
	  where ROUTINE_type='PROCEDURE'

	  --items dinamicos
	  --Los items dinamicos se han guardado en la tabla [dbo].[footprintItemsDin]
	--hacer un select dinamico
	declare @table nvarchar(128), @column nvarchar(128)
	DECLARE ProdInfo CURSOR FOR 
	select [table],[column]
	from footprintItemsDin
	OPEN ProdInfo
	FETCH NEXT FROM ProdInfo INTO @table,@column
	WHILE @@fetch_status = 0
	BEGIN
		exec( 'insert into  t_info select top 1 ''ITEMDINAMICO'','''+@table+'.'+@column +''',' +@column+',null from '+@table)
		FETCH NEXT FROM ProdInfo INTO @table,@column
	END
	CLOSE ProdInfo
	DEALLOCATE ProdInfo

	update t_info
	set f_value_hash=HASHBYTES('SHA2_256',isnull(f_value_tohash,''))
	--set f_value_hash=dbo.GetSHA256(isnull(f_value_tohash,''))
	
	declare @id varchar(30),  @Existingdate datetime=getdate()
	Set @id='v.'+CONVERT(varchar,@Existingdate,2)+CONVERT(varchar,@Existingdate,114)

	insert into [dbo].[footprintV]
	select @id,isnull(@p_desc,'Version'+CONVERT(varchar,getdate(),2))

	insert into [dbo].[footprint]([id_fpv],[type],[object_name],[value_hash])
	select @id,[f_type],[f_object_name],[f_value_hash]
	from t_info

	drop table t_info

END
GO


CREATE OR ALTER PROCEDURE [dbo].[fp_dinamicItem_add]
	@p_table nvarchar(128),
	@p_column nvarchar(128)

AS
BEGIN
	SET NOCOUNT ON;

	delete from [dbo].[footprintItemsDin]
	where [table]=@p_table
	and [column]=@p_column;

	--solo inserta el dato de la tabla si existen la tabla y la columna
	insert into [footprintItemsDin]
	select @p_table,@p_column 
	where exists(select 1 from [INFORMATION_SCHEMA].[COLUMNS] where TABLE_NAME =@p_table and COLUMN_NAME=@p_column)

end
GO

CREATE OR ALTER PROCEDURE [dbo].[fp_leer_versiones]
AS
BEGIN
	SET NOCOUNT ON;

	Select *
	from [dbo].[footprintV]

end
go

CREATE OR ALTER PROCEDURE [dbo].[fp_dinamicItem_leer]
AS
BEGIN
	SET NOCOUNT ON;

	Select *
	from [dbo].[footprintItemsDin]

end
go
