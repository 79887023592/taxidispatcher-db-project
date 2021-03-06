USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[DecrementDrOrdPriorities]    Script Date: 20.09.2017 15:21:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[DecrementDrOrdPriorities] 
	-- Add the parameters for the stored procedure here
AS
BEGIN 
	DECLARE @CURSOR cursor, @ORDID int;
				
			SELECT driver_id FROM DR_ORD_PRIORITY;
			IF @@ROWCOUNT>0
			BEGIN

				SET @CURSOR  = CURSOR SCROLL
				FOR SELECT order_id FROM DR_ORD_PRIORITY dop 
				INNER JOIN Zakaz ord ON ord.BOLD_ID=dop.order_id
				WHERE ord.Zavershyon=1;
					
				/*Открываем курсор*/
				OPEN @CURSOR
				/*Выбираем первую строку*/
				FETCH NEXT FROM @CURSOR INTO @ORDID;
				/*Выполняем в цикле перебор строк*/
				WHILE @@FETCH_STATUS = 0
				BEGIN
					DELETE FROM DR_ORD_PRIORITY WHERE order_id = @ORDID;
					FETCH NEXT FROM @CURSOR INTO @ORDID;
				END
				CLOSE @CURSOR

				UPDATE DR_ORD_PRIORITY SET [priority] = [priority] - 1

			END
END


