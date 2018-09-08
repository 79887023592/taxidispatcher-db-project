USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_ORDER_COMPLETE]    Script Date: 15.07.2018 0:28:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[AFTER_ORDER_COMPLETE] 
   ON  [dbo].[Zakaz] 
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @db_version INT, @min_debet decimal(28,10), 
	@use_dr_bcounter int, @every_order_pay decimal(28,10),
	@dr_dpay decimal(28,10), @all_dr_dpay decimal(28,10), 
	@fix_ord_dpay smallint, @dr_fix_ord_dpay smallint,
	@use_fordbroadcast_priority smallint, 
	@no_percent_before_summ decimal(28,10),
	@no_percent_before_payment decimal(28,10),
	@prize_reward_summ decimal(28,10),
	@first_trip_bonus decimal(28,10),
	@trip_bonus decimal(28,10),
	@percent_bonus_min_summ decimal(28,10),
	@bonus_percent decimal(28,10),
	@orderPhone varchar(255),
	@phoneOrderCount int;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@min_debet=ISNULL(MIN_DEBET,0),
	@use_dr_bcounter=ISNULL(use_dr_balance_counter,0),
	@every_order_pay=Kolich_vyd_benzina,
	@fix_ord_dpay=fix_order_pay_with_daily_pay,
	@all_dr_dpay=day_payment,
	@use_fordbroadcast_priority = use_fordbroadcast_priority,
	@no_percent_before_summ = no_percent_before_summ,
	@no_percent_before_payment = no_percent_before_payment,
	@prize_reward_summ = prize_reward_summ,
	@first_trip_bonus = first_trip_bonus,
	@trip_bonus = trip_bonus,
	@percent_bonus_min_summ = percent_bonus_min_summ,
	@bonus_percent = bonus_percent
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	DECLARE @nOldValue int, @completeNewValue int, 
		@completeOldValue INT, @NewSyncValue INT,
		@summValue decimal(28,10), @newDrId int, @dr_num int,
		@taxSumm decimal(28,10), @priseNum int,
		@bonusSumm decimal(28,10),
		@bonusUse decimal(28,10),
		@bonusAll decimal(28,10);
		
	SELECT @nOldValue=b.BOLD_ID, 
	@completeNewValue=a.Zavershyon,
	@completeOldValue=b.Zavershyon,
	@summValue=a.Uslovn_stoim,
	@newDrId=a.vypolnyaetsya_voditelem,
	@dr_num=a.Pozyvnoi_ustan,
	@priseNum = a.Nomer_skidki,
	@orderPhone = a.Telefon_klienta,
	@bonusUse = a.bonus_use
	FROM inserted a, deleted b

	IF (@summValue IS NULL)
	BEGIN
		UPDATE Zakaz SET Uslovn_stoim=0 WHERE BOLD_ID=@nOldValue;
	END
	
	SET @summValue=ISNULL(@summValue,0);
	SET @bonusUse=ISNULL(@bonusUse,0);
	SET @bonusSumm = 0;

	IF ((@db_version>=5) AND (@completeNewValue=1) AND (@completeNewValue<>@completeOldValue) 
		AND (@newDrId>0) and (@summValue>0) AND @orderPhone<>'' AND 
		(@bonus_percent > 0 OR @first_trip_bonus > 0 OR @trip_bonus > 0)  and (@summValue>0) )
	BEGIN

		SELECT COUNT(BOLD_ID)
		FROM Sootvetstvie_parametrov_zakaza sp
		WHERE sp.Telefon_klienta = @orderPhone;

		IF @@ROWCOUNT = 1 BEGIN

			SELECT @phoneOrderCount = sp.Summarn_chislo_vyzovov, 
			@bonusAll = sp.bonus_summ
			FROM Sootvetstvie_parametrov_zakaza sp
			WHERE sp.Telefon_klienta = @orderPhone;

			IF @bonus_percent > 0 AND @percent_bonus_min_summ <= @summValue AND 
				@percent_bonus_min_summ > 0 AND @bonus_percent < 1 BEGIN
				SET @bonusSumm = @summValue * @bonus_percent;
			END
			ELSE BEGIN
				SET @phoneOrderCount = -1;

				IF @phoneOrderCount = 1 BEGIN
					SET @bonusSumm = @first_trip_bonus;
				END
				ELSE BEGIN
					SET @bonusSumm = @trip_bonus;
				END;
			END;

			UPDATE Zakaz SET bonus_add = @bonusSumm, 
			bonus_all = @bonusAll + @bonusSumm - @bonusUse
			WHERE BOLD_ID = @nOldValue;

			UPDATE Sootvetstvie_parametrov_zakaza
			SET bonus_summ = bonus_summ + @bonusSumm - @bonusUse
			WHERE Telefon_klienta = @orderPhone;
		END;

	END;

	IF((@db_version>=5) AND (@use_dr_bcounter=1))
	BEGIN

	IF ((@completeNewValue=1) AND (@completeNewValue<>@completeOldValue) 
		AND (@newDrId>0) and (@summValue>0) )
	BEGIN
	 
		SELECT @dr_fix_ord_dpay=fix_order_pay_with_daily_pay,
		@dr_dpay=day_payment
		FROM Voditelj
		WHERE BOLD_ID=@newDrId;

		SET @taxSumm = 0;
		IF @no_percent_before_summ > 0 
			AND @no_percent_before_summ >= @summValue 
			AND @summValue > 0 
			BEGIN
				SET @taxSumm = @no_percent_before_payment;
			END 
		ELSE
			BEGIN
				SET @taxSumm = @summValue*dbo.GetDrTakePercent(@dr_num);
			END

		IF @priseNum > 0 BEGIN
			SET @taxSumm = @taxSumm - @prize_reward_summ - @bonusUse;
		END

		UPDATE Voditelj SET DRIVER_BALANCE=
		DRIVER_BALANCE-@taxSumm 
		WHERE (BOLD_ID=@newDrId) and (use_dyn_balance=1);
		IF (@every_order_pay>0) and not (((@all_dr_dpay>0) OR (@dr_dpay>0)) and ((@fix_ord_dpay=0) or (@dr_fix_ord_dpay=0)))
		BEGIN
			UPDATE Voditelj SET DRIVER_BALANCE=DRIVER_BALANCE-@every_order_pay 
			WHERE (BOLD_ID=@newDrId) and (use_dyn_balance=1);
		END

		IF (@use_fordbroadcast_priority = 1)
		BEGIN
		    DELETE FROM DR_ORD_PRIORITY WHERE order_id=@nOldValue;
			--EXEC RefreshDrOrdPriorityBroadcasts;
		END;
		EXEC SetOrdersWideBroadcasts 1, '';

	END;

	END;
	
	
	
END


