USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[GetDrLockOnCalcDebt]    Script Date: 30.03.2019 2:00:47 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[GetDrLockOnCalcDebt]  ( @dr_num int, @res int OUT)
AS
BEGIN
   declare @dr_count int, @use_dr_lock smallint, @driver_id int;
   
   SET @res=-1
   
   SELECT @dr_count=COUNT(*) FROM Voditelj
   WHERE Pozyvnoi=@dr_num;
   
   if (@dr_count=1) and (@dr_num>0) begin
		SELECT @use_dr_lock=rlock_on_calc_debt, @driver_id=BOLD_ID FROM Voditelj 
		WHERE Pozyvnoi=@dr_num;
		if @use_dr_lock<>1 begin
			SET @res=-1
		end
		else begin
		
			DECLARE @db_version INT, @drcalc_start_date date,
			@ftime_tariff decimal(28,10), @min_debt decimal(28,10);
	
			SELECT TOP 1 @db_version=ISNULL(db_version,3),
			@drcalc_start_date=ISNULL(drcalc_start_date,GETDATE()),
			@min_debt=ISNULL(MIN_DEBET,0)
			FROM Objekt_vyborki_otchyotnosti
			WHERE Tip_objekta='for_drivers';
			
			if @drcalc_start_date>GETDATE()
			begin
				SET @drcalc_start_date=GETDATE();
			end
			
			DECLARE @emploee_date DATE, @free_days_count int;
			
			begin try
				SELECT @free_days_count=CONVERT(int,Udostoverenie_nom) from Voditelj
				where BOLD_ID=@driver_id;
			end try
			begin catch
				SET @free_days_count=0;
			end catch 
			
			SET @free_days_count=ISNULL(@free_days_count, 0);
			
			begin try
				SELECT @emploee_date=CONVERT(DATE, Klass_vodit, 104) from Voditelj
				where BOLD_ID=@driver_id;
			end try
			begin catch
				SET @emploee_date=@drcalc_start_date;
			end catch
			
			SET @emploee_date=ISNULL(@emploee_date, GETDATE());
			
			if @emploee_date>GETDATE()
			begin
				SET @emploee_date=GETDATE();
			end
			
			if @emploee_date<@drcalc_start_date begin
				SET @emploee_date=@drcalc_start_date;
			end
			else begin
				SET @drcalc_start_date=@emploee_date;
			end
			
			DECLARE @DrTakeSumm decimal(28,10), @DrSumm decimal(28,10), 
				@DrFixedSumm decimal(28,10), @DebtSumm decimal(28,10);
			
			select @DrTakeSumm=SUM(Summa) from  Vyruchka_ot_voditelya 
			where Pozyvnoi=@dr_num and Data_postupleniya>=@drcalc_start_date
			
			SET @DrTakeSumm = ISNULL(@DrTakeSumm,0);

			select @DrSumm=(SUM(Uslovn_stoim)*dbo.GetDrTakePercent(@dr_num, 0)) 
			from Zakaz where Nachalo_zakaza_data>@drcalc_start_date and
			Pozyvnoi_ustan=@dr_num AND Arhivnyi=0 and Zavershyon=1 AND
			Soobsheno_voditelyu=0
			
			SET @DrSumm = ISNULL(@DrSumm,0);

			select @DrFixedSumm=(dbo.GetDriverDaysFixedSumm(@dr_num, @emploee_date, @free_days_count) + 
			dbo.GetDrOrderFixedSumm(@dr_num, @emploee_date));
			
			SET @DrFixedSumm = ISNULL(@DrFixedSumm,0);
			
			SET @DebtSumm = @DrTakeSumm - @DrSumm - @DrFixedSumm;
			--PRINT @DebtSumm;
			--PRINT '---';
			--PRINT @DrTakeSumm;
			--PRINT '---';
			--PRINT @DrSumm;
			--PRINT '---';
			--PRINT @DrFixedSumm;
			
			if @DebtSumm<@min_debt begin
				SET @res=1;
			end
			else begin
				SET @res=-2;
			end
			
		end
   end

   RETURN(@res)
END