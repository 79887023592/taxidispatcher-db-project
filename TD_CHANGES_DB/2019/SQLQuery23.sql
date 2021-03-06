USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetDrTakePercent]    Script Date: 30.03.2019 1:54:00 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER FUNCTION [dbo].[GetDrTakePercent]  (@Drnum int, @daily_percent decimal(18, 5))
RETURNS decimal(28, 10)
AS
BEGIN
   DECLARE @percent decimal(28, 10),
           @all_percent decimal(28, 10),
           @dr_count int,
           @res decimal(28, 10)
   
   SET @percent=0
   SET @all_percent=0
   SET @dr_count=0
   
   select @dr_count=COUNT(*) from Voditelj
   where Pozyvnoi=@Drnum 
   
   IF @dr_count=0 BEGIN
     SET @res=0
   END
    ELSE
   BEGIN
     select @percent=dr.Individ_procent from Voditelj dr
     where Pozyvnoi=@Drnum
     
     if @percent>0 begin
		SET @res=@percent
	 end
	 else
	 begin
		IF @daily_percent > 0 BEGIN
			SET @res=@daily_percent
		END ELSE BEGIN
			select @res=ovo.Procent_otchisleniya from Objekt_vyborki_otchyotnosti ovo
			where ovo.Tip_objekta='for_drivers';
		END;
	 end
     
   END  

   RETURN(@res)
END

