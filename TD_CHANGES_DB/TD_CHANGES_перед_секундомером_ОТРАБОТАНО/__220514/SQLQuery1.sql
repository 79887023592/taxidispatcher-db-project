USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[InsertEvent]    Script Date: 05/22/2014 14:13:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[InsertEvent] 
	-- Add the parameters for the stored procedure here
	(@etype_id int, @order_id int, @driver_id int, @sector_id int, 
	@edate datetime, @description varchar(2000), @adres varchar(255), 
	@phone varchar(255), @dr_num int, @count int OUT)
AS
BEGIN 
	--DECLARE @count int;
	SET @count = 0;
	
	INSERT INTO TD_EVENTS (ETYPE_ID, ORDER_ID, DRIVER_ID, SECTOR_ID, EDATE,
		DESCRIPT, ADRES, PHONE, DR_NUM) VALUES(@etype_id, @order_id, @driver_id,
		@sector_id, @edate, @description, @adres, @phone, @dr_num);
	
	SET @count=@@ROWCOUNT;
	
	DELETE FROM TD_EVENTS WHERE CLOSED=1;
	UPDATE Voditelj SET has_active_events=1 WHERE BOLD_ID=@driver_id;
	UPDATE Personal SET EstjVneshnieManip=1, Prover_vodit=1;
	
END







