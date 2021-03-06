USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetJSONTarifAndOptionsList]    Script Date: 01.11.2018 4:34:38 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER FUNCTION [dbo].[GetJSONTarifAndOptionsList] (@driver_id int)
RETURNS varchar(max)
AS
BEGIN
	declare @res varchar(max);
	DECLARE @CURSOR cursor;
	DECLARE @sid int, @scount int,
		@sname varchar(255), @counter int,
		@timetr decimal(28,10), @tmetrtr decimal(28,10),
		@os_coeff decimal(28,10), @os_comp decimal(28,10),
		@tplan_id int, @short_name varchar(20), 
		@miss_every_nkm int, @policy_id int;
   
	SET @res='{"command":"to_lst","t_cnt":"';
	SET @counter = 0;
	SET @policy_id = -1;

	SELECT @policy_id = gv.PR_POLICY_ID
	FROM Voditelj dr INNER JOIN Gruppa_voditelei gv ON dr.otnositsya_k_gruppe = gv.BOLD_ID
	WHERE dr.BOLD_ID = @driver_id;

	IF @@ROWCOUNT <= 0 BEGIN
		SET @policy_id = -1;
		SELECT @policy_id = dr.PR_POLICY_ID
		FROM Voditelj dr
		WHERE dr.BOLD_ID = @driver_id;

		IF @@ROWCOUNT <= 0 BEGIN
			SET @policy_id = -1;
		END;
	END;
	
	SELECT @scount=COUNT(*)  
	FROM ORDER_TARIF WHERE PR_POLICY_ID = @policy_id OR @policy_id <= 0;
	
	DECLARE @fmt_str1 varchar(50), @fmt_str2 varchar(50), 
		@fmt_str3 varchar(50), @fmt_str4 varchar(50), 
		@dist_part int, @dpart_tarif decimal(28, 10), 
		@stop_tarif decimal(28, 10), @dist_start int,
		@otarid int, @otplid int, @miss_every_nkm_json varchar(100);
	
	IF (@scount>0)
	BEGIN
	
	SET @res=@res+CAST(@scount as varchar(20))+'"';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ID, TARIF_NAME, TIME_TARIF, TMETER_TARIF, PR_POLICY_ID, SHORT_NAME, DISTANCE_PART, DPART_TARIF, STOP_TARIF, DISTANCE_START, outher_tarid, outher_tplid, miss_every_nkm  
	FROM ORDER_TARIF WHERE PR_POLICY_ID = @policy_id OR @policy_id <= 0 ORDER BY ID ASC;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @sid, @sname, @timetr, @tmetrtr, @tplan_id, @short_name, @dist_part, @dpart_tarif, @stop_tarif, @dist_start, @otarid, @otplid, @miss_every_nkm
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

        
        IF (CHARINDEX('.',CAST(@tmetrtr as varchar(20)))+2<=
			LEN(CAST(@tmetrtr as varchar(20))))
		BEGIN
			SET @fmt_str1=LEFT(CAST(@tmetrtr as varchar(20)),
				CHARINDEX('.',CAST(@tmetrtr as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str1=CAST(@tmetrtr as varchar(20));
		END
		
		IF (CHARINDEX('.',CAST(@timetr as varchar(20)))+2<=
			LEN(CAST(@timetr as varchar(20))))
		BEGIN
			SET @fmt_str2=LEFT(CAST(@timetr as varchar(20)),
				CHARINDEX('.',CAST(@timetr as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str2=CAST(@timetr as varchar(20));
		END
		
		IF (CHARINDEX('.',CAST(@dpart_tarif as varchar(20)))+2<=
			LEN(CAST(@dpart_tarif as varchar(20))))
		BEGIN
			SET @fmt_str3=LEFT(CAST(@dpart_tarif as varchar(20)),
				CHARINDEX('.',CAST(@dpart_tarif as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str3=CAST(@dpart_tarif as varchar(20));
		END
		
		IF (CHARINDEX('.',CAST(@stop_tarif as varchar(20)))+2<=
			LEN(CAST(@stop_tarif as varchar(20))))
		BEGIN
			SET @fmt_str4=LEFT(CAST(@stop_tarif as varchar(20)),
				CHARINDEX('.',CAST(@stop_tarif as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str4=CAST(@stop_tarif as varchar(20));
		END

		SET @miss_every_nkm_json = ''
		IF @miss_every_nkm > 0 BEGIN
			SET @miss_every_nkm_json = '","mek'+
				CAST(@counter as varchar(20))+'":"'+
				CAST(@miss_every_nkm as varchar(20));
		END
		
        SET @res=@res+',"tid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sid as varchar(20))+'","tn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@sname,'"',' '),'''',' ')+'","tmt'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str2+'","txt'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str1+'","ttpi'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@tplan_id as varchar(20))+'","tdip'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@dist_part as varchar(20))+'","tstds'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@dist_start as varchar(20))+'","tdpt'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str3+'","tspt'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str4+'","tshn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@short_name,'"',' '),'''',' ')+'","otarid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@otarid as varchar(20))+'","otplid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@otplid as varchar(20)) + @miss_every_nkm_json + '"'+
			dbo.GetTarifAreaCoords(@sid, @counter);
        SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @sid, @sname, @timetr, @tmetrtr, @tplan_id, @short_name, @dist_part, @dpart_tarif, @stop_tarif, @dist_start, @otarid, @otplid, @miss_every_nkm
	END
	CLOSE @CURSOR
	
	END
	ELSE
	BEGIN
		SET @res=@res+'0"';	
	END;
	
	SELECT @scount=COUNT(*)  
	FROM ORDER_OPTION WHERE PR_POLICY_ID = @policy_id OR @policy_id <= 0;
	
	SET @res=@res+',"op_cnt":"';
	SET @counter = 0;
	
	IF (@scount>0)
	BEGIN
	
	SET @res=@res+CAST(@scount as varchar(20))+'"';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ID, OPTION_NAME, OSUMM_COEFF, OS_COMPOSED, PR_POLICY_ID, SHORT_NAME  
	FROM ORDER_OPTION WHERE PR_POLICY_ID = @policy_id OR @policy_id <= 0 ORDER BY ID ASC;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @sid, @sname, @os_coeff, @os_comp, @tplan_id, @short_name
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

        IF (CHARINDEX('.',CAST(@os_coeff as varchar(20)))+2<=
			LEN(CAST(@os_coeff as varchar(20))))
		BEGIN
			SET @fmt_str1=LEFT(CAST(@os_coeff as varchar(20)),
				CHARINDEX('.',CAST(@os_coeff as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str1=CAST(@os_coeff as varchar(20));
		END
		IF (CHARINDEX('.',CAST(@os_comp as varchar(20)))+2<=
			LEN(CAST(@os_comp as varchar(20))))
		BEGIN
			SET @fmt_str2=LEFT(CAST(@os_comp as varchar(20)),
				CHARINDEX('.',CAST(@os_comp as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str2=CAST(@os_comp as varchar(20));
		END
        
        SET @res=@res+',"oid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sid as varchar(20))+'","on'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@sname,'"',' '),'''',' ')+'","oscf'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str1+'","oscm'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str2+'","otpi'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@tplan_id as varchar(20))+'","oshn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@short_name,'"',' '),'''',' ')+'"';
        SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @sid, @sname, @os_coeff, @os_comp, @tplan_id, @short_name
	END
	CLOSE @CURSOR
	
	END
	ELSE
	BEGIN
		SET @res=@res+'0"';	
	END;
	
	-----------------------
	SELECT @scount=COUNT(*)  
	FROM PRICE_POLICY WHERE ID = @policy_id OR @policy_id <= 0;
	
	SET @res=@res+',"tpl_cnt":"';
	SET @counter = 0;
	
	IF (@scount>0)
	BEGIN
	
	SET @res=@res+CAST(@scount as varchar(20))+'"';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ID, POLICY_NAME, SHORT_NAME  
	FROM PRICE_POLICY WHERE ID = @policy_id OR @policy_id <= 0 ORDER BY ID ASC;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @sid, @sname, @short_name
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

        SET @res=@res+',"tpid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sid as varchar(20))+'","tpn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@sname,'"',' '),'''',' ')+'","tpshn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@short_name,'"',' '),'''',' ')+'"';
        SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @sid, @sname, @short_name
	END
	CLOSE @CURSOR
	
	END
	ELSE
	BEGIN
		SET @res=@res+'0"';	
	END;
	------------------------------
	
	SET @res=@res+',"msg_end":"ok"}';

	RETURN(@res)
END
