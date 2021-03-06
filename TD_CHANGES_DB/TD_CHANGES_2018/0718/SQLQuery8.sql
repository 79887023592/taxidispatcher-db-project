USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[SetOrderCompleteAttemptStatus3]    Script Date: 15.07.2018 12:07:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SetOrderCompleteAttemptStatus3] 
	-- Add the parameters for the stored procedure here
	(@order_id int,  @driver_id int, @summ float, @count int OUT, @status int, @order_time int, @tm_distance int)
AS
BEGIN 
	DECLARE @dont_reset_time smallint,
		@bonusUse decimal(28, 10);
	SET @count = 0;

	SELECT @count=COUNT(*) FROM Zakaz
	WHERE ((Zakaz.REMOTE_SET=8) OR 
	(Zakaz.REMOTE_SET=10)) AND 
	(Zakaz.BOLD_ID=@order_id) AND
	(Zakaz.vypolnyaetsya_voditelem=@driver_id);
	
	IF(@count>0)
	BEGIN

	EXEC CalcBonusSumm @order_id, 0, @bonusUse = @bonusUse OUTPUT;
	
	UPDATE Zakaz 
	SET Zakaz.REMOTE_SET=@status,
	Zakaz.REMOTE_SUMM=@summ,
	Zakaz.Uslovn_stoim=@summ,
	Zakaz.CLIENT_SMS_SEND_STATE=3,
	Zakaz.fixed_time=@order_time,
	Zakaz.tm_distance=@tm_distance 
	WHERE  
	(Zakaz.BOLD_ID=@order_id);
	
	SET @dont_reset_time = ISNULL(@dont_reset_time, 0)

	IF @driver_id > 0 BEGIN
		SELECT @dont_reset_time = dont_reset_time 
		FROM Voditelj 
		WHERE BOLD_ID = @driver_id;
	END
	
	IF @dont_reset_time <> 1 BEGIN
		UPDATE Voditelj 
		SET Vremya_poslednei_zayavki=CURRENT_TIMESTAMP 
		WHERE BOLD_ID=@driver_id;
	END
	
	SET @count=@@ROWCOUNT;
	
	EXEC CheckDriverBusy @driver_id;
	
	END
	
END


