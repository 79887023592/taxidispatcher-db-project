USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetJSONSectorList]    Script Date: 15.10.2018 22:59:51 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER FUNCTION [dbo].[GetJSONSectorList] (@driver_id int)
RETURNS varchar(max)
AS
BEGIN
	declare @res varchar(max);
	DECLARE @CURSOR cursor;
	DECLARE @company_id int, @sector_id int, @sector_count int,
		@sector_name varchar(255), @counter int, @for_all smallint, 
		@scompany_id int;
   
	SET @res='{"command":"s_lst","s_cnt":"';
	SET @counter = 0;

	SELECT @company_id=otnositsya_k_gruppe  
	FROM Voditelj
	WHERE BOLD_ID = @driver_id;

	SET @company_id = ISNULL(@company_id, 0);
	
	SELECT @sector_count=COUNT(*)  
	FROM Sektor_raboty ws JOIN Spravochnik dict 
	ON ws.BOLD_ID=dict.BOLD_ID
	WHERE ws.company_id = @company_id OR ws.company_id < 0;

	IF (@sector_count>0)
	BEGIN
	
	SET @res=@res+CAST(@sector_count as varchar(20))+'"';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ws.BOLD_ID, dict.Naimenovanie, ws.for_all, ws.company_id  
	FROM Sektor_raboty ws JOIN Spravochnik dict 
	ON ws.BOLD_ID=dict.BOLD_ID
	WHERE ws.company_id = @company_id OR ws.company_id < 0;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @sector_id, @sector_name, @for_all, @scompany_id
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

        SET @res=@res+',"id'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sector_id as varchar(20));

		IF (@for_all = 1) BEGIN
		SET @res=@res + '","fal'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@for_all as varchar(20));
		END;

		IF (@scompany_id > 0) BEGIN
		SET @res=@res + '","cm'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@scompany_id as varchar(20));
		END;

		SET @res=@res + '","nm'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@sector_name,'"',' '),'''',' ')+'"'+
			dbo.GetSectorAreaCoords(@sector_id, @counter);
        SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @sector_id, @sector_name, @for_all, @scompany_id
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
