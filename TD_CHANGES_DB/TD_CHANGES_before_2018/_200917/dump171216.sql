USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_ORDER_INSERT]    Script Date: 20.09.2017 13:43:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[AFTER_ORDER_INSERT_PRIORITY] 
   ON  [dbo].[Zakaz] 
   AFTER INSERT
AS 
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @db_version int, @use_fordbroadcast_priority smallint;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@use_fordbroadcast_priority = use_fordbroadcast_priority 
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	if(@db_version>=5 AND @use_fordbroadcast_priority=1)
	BEGIN	
		
		DECLARE @CURSOR cursor, @DRID int, @ORDID int, @priority int;
				
		SELECT BOLD_ID FROM Voditelj;
		IF @@ROWCOUNT>0
		BEGIN

			SELECT @ORDID=a.BOLD_ID
			FROM inserted a

			SET @CURSOR  = CURSOR SCROLL
			FOR SELECT BOLD_ID, [Priority] FROM Voditelj;
					
			/*Открываем курсор*/
			OPEN @CURSOR
			/*Выбираем первую строку*/
			FETCH NEXT FROM @CURSOR INTO @DRID, @priority;
			/*Выполняем в цикле перебор строк*/
			WHILE @@FETCH_STATUS = 0
			BEGIN
				INSERT INTO DR_ORD_PRIORITY VALUES(@DRID, @ORDID, @priority);
				FETCH NEXT FROM @CURSOR INTO @DRID, @priority;
			END
			CLOSE @CURSOR
		END
	END;	

END
