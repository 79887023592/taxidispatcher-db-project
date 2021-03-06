USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[DecrementDrOrdPriorities]    Script Date: 22.09.2017 10:48:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[RefreshDrOrdPriorityBroadcasts] 
	-- Add the parameters for the stored procedure here
AS
BEGIN 
	DECLARE @CURSOR cursor, @DRID int, @priority int;
				
			SELECT BOLD_ID FROM Voditelj WHERE V_rabote=1;
			IF @@ROWCOUNT>0
			BEGIN

				SET @CURSOR  = CURSOR SCROLL
				FOR SELECT BOLD_ID FROM Voditelj;
					
				/*Открываем курсор*/
				OPEN @CURSOR
				/*Выбираем первую строку*/
				FETCH NEXT FROM @CURSOR INTO @DRID;
				/*Выполняем в цикле перебор строк*/
				WHILE @@FETCH_STATUS = 0
				BEGIN
					UPDATE Voditelj SET forders_wbroadcast = ISNULL(dbo.GetJSONDriverOrdersBCasts(@DRID),'');
					FETCH NEXT FROM @CURSOR INTO @DRID;
				END
				CLOSE @CURSOR

				UPDATE Objekt_vyborki_otchyotnosti 
			    SET has_ford_wbroadcast=1;
			END
END


