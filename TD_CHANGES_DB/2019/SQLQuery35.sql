USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_ORDER_PHONE_CHANGE]    Script Date: 25.04.2019 2:12:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[AFTER_ORDER_PHONE_CHANGE] 
   ON  [dbo].[Zakaz] 
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @db_version INT, 
	@phoneBonus decimal(28,10),
	@newPhone varchar(255),
	@oldPhone varchar(255), @nOldValue int,
	@first_trip_bonus decimal(28, 10), 
	@trip_bonus decimal(28, 10), @bonus_percent decimal(28, 10), 
	@percent_bonus_min_summ decimal(28, 10),
	@auto_set_bonus_value decimal(18, 5);
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@first_trip_bonus = first_trip_bonus, 
	@trip_bonus = trip_bonus, 
	@bonus_percent = bonus_percent, 
	@percent_bonus_min_summ = percent_bonus_min_summ,
	@auto_set_bonus_value = auto_set_bonus_value
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
		
	SELECT @nOldValue=b.BOLD_ID, 
	@newPhone = ISNULL(a.Telefon_klienta, ''),
	@oldPhone = b.Telefon_klienta
	FROM inserted a, deleted b

	SET @phoneBonus = 0;

	IF ((@db_version>=5) AND (@newPhone <> '') AND 
		(@newPhone <> @oldPhone) AND (@first_trip_bonus > 0  
		OR @trip_bonus > 0 OR 
		(@bonus_percent > 0 AND @percent_bonus_min_summ > 0)))
	BEGIN

		SELECT TOP 1 @phoneBonus = sp.bonus_summ
		FROM Sootvetstvie_parametrov_zakaza sp
		WHERE sp.Telefon_klienta = @newPhone;

		IF @@ROWCOUNT = 1 BEGIN

			SET @phoneBonus = ISNULL(@phoneBonus, 0);

			IF @auto_set_bonus_value < 0 BEGIN
				SET @auto_set_bonus_value = 0;
			END;

			IF @auto_set_bonus_value > 0 AND @auto_set_bonus_value > @phoneBonus
			BEGIN
				SET @auto_set_bonus_value = 0;
			END;

			UPDATE Zakaz SET bonus_all = @phoneBonus,
			bonus_use = @auto_set_bonus_value
			WHERE BOLD_ID = @nOldValue;
		END;

	END;
	
END


