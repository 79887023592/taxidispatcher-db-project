USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_INCOME_INSERT]    Script Date: 02/19/2015 01:54:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER TRIGGER [dbo].[AFTER_INCOME_INSERT] 
   ON  [dbo].[Vyruchka_ot_voditelya] 
   AFTER INSERT
AS 
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @db_version INT, @use_dr_balance_counter int;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@use_dr_balance_counter=ISNULL(use_dr_balance_counter,0)
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	IF((@db_version>=5) AND (@use_dr_balance_counter>0))
	BEGIN

	DECLARE @nOldValue int, @summNewValue decimal(28,10), 
		@pNewValue INT;
		
		
	SELECT @nOldValue=a.BOLD_ID,
	@summNewValue=a.Summa,
	@pNewValue=a.Pozyvnoi
	FROM inserted a

	IF ((@pNewValue>0) AND (@summNewValue<>0))
	BEGIN
		UPDATE Voditelj SET DRIVER_BALANCE=DRIVER_BALANCE+@summNewValue 
		WHERE use_dyn_balance=1 AND Pozyvnoi=@pNewValue;
	END;

	END;
	
	
	
END


