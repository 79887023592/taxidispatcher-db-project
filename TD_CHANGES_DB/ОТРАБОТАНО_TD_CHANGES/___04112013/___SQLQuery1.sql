CREATE FUNCTION [dbo].[GetJSONSectorsStatus] ()
RETURNS varchar(1000)
AS
BEGIN
	declare @res varchar(1000);
	DECLARE @CURSOR cursor;
	DECLARE @sector_id int, @sector_count int,
		@counter int;
   
	SET @res='{"command":"s_st","s_cnt":"';
	SET @counter = 0;
	
	SELECT @sector_count=COUNT(*)  
	FROM Sektor_raboty;
	
	IF (@sector_count>0)
	BEGIN
	
	SET @res=@res+CAST(@sector_count as varchar(20))+'"';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ws.BOLD_ID, dbo.GetSectorDrCount(ws.BOLD_ID)  
	FROM Sektor_raboty ws;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @sector_id, @sector_count
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

        SET @res=@res+',"id'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sector_id as varchar(20))+'","dc'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sector_count as varchar(20))+'"';
        SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @sector_id, @sector_count
	END
	CLOSE @CURSOR
	
	SET @res=@res+',"msg_end":"ok"}';
	
	END
	ELSE
	BEGIN
		SET @res=@res+'0","msg_end":"ok"}';	
	END;

	RETURN(@res)
END
