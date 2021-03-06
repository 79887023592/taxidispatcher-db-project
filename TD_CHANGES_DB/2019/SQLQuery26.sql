USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[ProceedOperationRequest]    Script Date: 31.03.2019 1:48:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[ProceedOperationRequest] 
	-- Add the parameters for the stored procedure here
	(@opnm varchar(255), @prm1 int, @prm2 int, 
	 @prm3 int, @prm4 varchar(255), @prm5 varchar(255), 
	 @op_answer varchar(5000) OUT)
AS
BEGIN 

	DECLARE @dr_balance decimal(28,10), 
		@last12h_summ decimal(28,10), @use_calc_balance int, @res int, 
		@DebtSumm decimal(28,10), @DrTakeSumm decimal(28,10), @DrSumm decimal(28,10), 
		@DrFixedSumm decimal(28,10), @bold_id int, @count int, @summ decimal(28,10),
		@edate datetime, @prev_dsumm decimal(28,10), @new_dsumm decimal(28,10), 
		@driver_id int, @expire_date datetime, @use_drivers_rating smallint, 
		@order_late_rating_fine decimal(18, 5), @order_late_rating_time int,
		@order_refusal_rating_fine decimal(18, 5), @order_refusal_balance_fine decimal(18, 5),
		@order_refusal_rating_time int, @dr_rating decimal(18,5);

	SET @op_answer = '{"command":"opa","scs":"yes","opnm":"'+
		@opnm+'",';
	SET @res = -1;
	SET @DebtSumm = 0;
	SET @DrTakeSumm = 0;
	SET @DrSumm = 0;
	SET @DrFixedSumm = 0;

	SELECT TOP 1 
		@use_drivers_rating = use_drivers_rating,
		@order_late_rating_fine = order_late_rating_fine,
		@order_late_rating_time = order_late_rating_time, 
		@order_refusal_rating_fine = order_refusal_rating_fine,
		@order_refusal_balance_fine = order_refusal_balance_fine,
		@order_refusal_rating_time = order_refusal_rating_time
		FROM Objekt_vyborki_otchyotnosti
		WHERE Tip_objekta='for_drivers';

	if (@opnm='drinc')
	begin
		SELECT BOLD_ID FROM Voditelj WHERE BOLD_ID=ISNULL(@prm1,-1) AND its_manager=1;
		IF @@ROWCOUNT=1 
		BEGIN
			IF ISNUMERIC(@prm4) > 0
			BEGIN 
				SET @summ = CAST(@prm4 AS INT) 
			END
			ELSE 
			BEGIN
				SET @summ=0 
			END

			IF @summ>0 BEGIN
			SET @edate=GETDATE()
			SELECT @prev_dsumm=DRIVER_BALANCE FROM Voditelj WHERE Pozyvnoi=@prm3;
			EXEC InsertNewDriverIncome -1, 0, @summ, @edate, @prm3, @count = @count OUTPUT;
			--EXEC InsertNewDriverIncome @bold_id = @bold_id OUTPUT, @its_dayly = 0, @summ = CAST(@prm3 as decimal(28,10)), @idt = GETDATE(), @dr_num int, @count int OUT;
			SELECT @new_dsumm=DRIVER_BALANCE FROM Voditelj WHERE Pozyvnoi=@prm3;
			IF @count>0 BEGIN
				SET @op_answer = @op_answer + '"drinc":"ok",';--"omsg":"dyn summ prev '+
					--CAST(@prev_dsumm as varchar(10))+' new '+
					--CAST(@new_dsumm as varchar(10))+'",';
			END
			ELSE BEGIN
				SET @op_answer = @op_answer + '"drinc":"no",';
			END
			END
			ELSE BEGIN
			SET @op_answer = @op_answer + '"drinc":"no",';
			END
		END
		ELSE
		BEGIN
			SET @op_answer = @op_answer + '"drinc":"no",';
		END
	end

	if (@opnm='ohist')
	begin
		UPDATE Zakaz SET tmhistory=(@prm4+', посл сумма '+@prm5) WHERE BOLD_ID=@prm3;
		SET @op_answer = @op_answer + '"oh":"ok",';
	end

	if (@opnm='acst')
	begin
		UPDATE Zakaz SET status_accumulate=status_accumulate+(' '+CAST(DATEPART( hh,GETDATE()) as varchar(2))+':'+CAST(DATEPART( n,GETDATE()) as varchar(2))+'['+@prm4+']') WHERE BOLD_ID=@prm3;
		SET @op_answer = @op_answer + '"acst":"ok",';
	end

	if (@opnm='lcc')
	begin

		UPDATE Voditelj SET cc_updated = 1 
		WHERE (last_lat <> @prm4 OR last_lon <> @prm5) AND BOLD_ID = ISNULL(@prm1,-1);

		UPDATE Voditelj SET last_lat=@prm4, last_lon=@prm5, last_cctime=GETDATE() WHERE BOLD_ID=ISNULL(@prm1,-1);
		SET @op_answer = @op_answer + '"lcc":"ok",';
	end
		
	if (@opnm='dr_bal')
	begin
	
		SET @dr_balance =0;
		SET @last12h_summ=0;
		SET @dr_rating = 0;

		IF ISNULL(@prm1,-1) > 0 AND @use_drivers_rating = 1 BEGIN
			SET @dr_rating = dbo.GetDriverRating(ISNULL(@prm1,-1));
		END;
	
		SELECT @dr_balance=ISNULL(DRIVER_BALANCE,0),
			@last12h_summ=dbo.GetDrLastHoursSumm(ISNULL(@prm1,-1),-12),
			@prm2 = Pozyvnoi 
		from Voditelj
		WHERE BOLD_ID=ISNULL(@prm1,-1);
		
		select @use_calc_balance=dbo.GetDrUseDynBByNumWithSettParam(@prm2);
		
		if (@use_calc_balance<>1)
		BEGIN
			EXEC GetDrDateCalcBalance @prm2, @res = @res OUTPUT, @DebtSumm = @DebtSumm OUTPUT, 
				@DrTakeSumm = @DrTakeSumm OUTPUT, @DrSumm = @DrSumm OUTPUT, 
				@DrFixedSumm = @DrFixedSumm OUTPUT;
			SET @dr_balance=@DebtSumm;
		END;
		
		SET @op_answer = @op_answer + '"dr_bal":"'+
			CAST(CAST(@dr_balance as INT) as VARCHAR(255)) + '",' + '"lst12hs":"'+
			CAST(CAST(@last12h_summ as INT) as VARCHAR(255)) + '",';

		IF @use_drivers_rating = 1 BEGIN
			SET @op_answer = @op_answer + '"dr_rating":"'+
			CAST(ISNULL(@dr_rating, 0) as VARCHAR(255)) + '",';
		END;
	end

	if (@opnm='dr_refuse')
	begin
		SET @driver_id = ISNULL(@prm1,-1);

		IF @driver_id > 0 BEGIN 
			IF @order_refusal_rating_time > 0 AND 
				@order_refusal_rating_fine > 0 AND @use_drivers_rating = 1
			BEGIN
				SET @order_refusal_rating_fine = -@order_refusal_rating_fine;
				SET @expire_date = DATEADD(MINUTE, @order_refusal_rating_time, GETDATE());
				EXEC InsertDriverRating @driver_id, @expire_date, 
					'dr_refuse', @order_refusal_rating_fine, 0;
			END;

			IF @order_refusal_balance_fine > 0 BEGIN
				UPDATE Voditelj 
				SET DRIVER_BALANCE = DRIVER_BALANCE - @order_refusal_balance_fine
				WHERE BOLD_ID = @driver_id;
			END;
		END;

		SET @op_answer = @op_answer + '"dr_refuse":"ok",';
	end

	if (@opnm='dr_order_late')
	begin
		SET @driver_id = ISNULL(@prm1,-1);

		IF @driver_id > 0 AND @order_late_rating_fine > 0 AND 
			@order_late_rating_time > 0 AND @use_drivers_rating = 1
		BEGIN
			SET @order_late_rating_fine = -@order_late_rating_fine;
			SET @expire_date = DATEADD(MINUTE, @order_late_rating_time, GETDATE());
			EXEC InsertDriverRating @driver_id, @expire_date, 
				'dr_order_late', @order_late_rating_fine, 0;
		END;

		SET @op_answer = @op_answer + '"dr_order_late":"ok",';
	end

	if (@opnm='wtl')
	begin
		SET @op_answer = @op_answer + '"wtl":"ok",' + dbo.GetJSONWaitTimesList();
	end
	
	SET @op_answer = @op_answer + '"msg_end":"ok"}';
	
END



