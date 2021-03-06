USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_INCOME_UPDATE]    Script Date: 02/18/2015 23:37:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[AFTER_INCOME_UPDATE] 
   ON  [dbo].[Vyruchka_ot_voditelya] 
   AFTER UPDATE
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
		@summOldValue decimal(28,10), @pNewValue INT,
		@pOldValue int;
		
		
	SELECT @nOldValue=b.BOLD_ID,
	@summNewValue=a.Summa,
	@summOldValue=b.Summa,
	@pNewValue=a.Pozyvnoi,
	@pOldValue=b.Pozyvnoi
	FROM inserted a, deleted b

	IF (((@pNewValue<>@pOldValue) OR (@summNewValue<>@summOldValue)) 
		AND (@pNewValue>0))
	BEGIN
		IF (@pNewValue=@pOldValue)
		BEGIN
		UPDATE Voditelj SET DRIVER_BALANCE=DRIVER_BALANCE+(@summNewValue-@summOldValue) 
		WHERE use_dyn_balance=1 AND Pozyvnoi=@pNewValue;
		END
		ELSE
		BEGIN
		UPDATE Voditelj SET DRIVER_BALANCE=DRIVER_BALANCE+@summNewValue 
		WHERE use_dyn_balance=1 AND Pozyvnoi=@pNewValue;
		UPDATE Voditelj SET DRIVER_BALANCE=DRIVER_BALANCE-@summOldValue 
		WHERE use_dyn_balance=1 AND Pozyvnoi=@pOldValue;
		END
	END;

	END;
	
	
	
END

