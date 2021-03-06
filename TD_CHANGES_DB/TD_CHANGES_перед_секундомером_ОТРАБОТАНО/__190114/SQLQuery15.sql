USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetDrOrderFixedSumm]    Script Date: 01/19/2014 20:35:54 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO



ALTER FUNCTION [dbo].[GetDrOrderFixedSumm]  (@Drnum int, @start_date datetime)
RETURNS decimal(28, 10)
AS
BEGIN
   DECLARE @order_fixed decimal(28, 10),
           @order_count int,
           @dr_count int,
           @res decimal(28, 10), 
           @d_kl int
   
   SET @order_fixed=0
   SET @order_count=0
   SET @dr_count=0
   SET @res=0
   
   select @dr_count=COUNT(*) from Voditelj
   where Pozyvnoi=@Drnum 
   
   IF @dr_count=0 BEGIN
     SET @res=0
   END
    ELSE
   BEGIN
   
	 select @d_kl=D_klass from Voditelj
	 where Pozyvnoi=@Drnum
	 
	 if @d_kl=0 BEGIN
   
		 select @order_count=COUNT(*) from Zakaz ord
		 where ord.Pozyvnoi_ustan=@Drnum AND 
		 ord.Nachalo_zakaza_data>=@start_date AND
		 ord.Arhivnyi=0 and ord.Zavershyon=1 AND
		 ord.Soobsheno_voditelyu=0;
	    
		 select @order_fixed=ovo.Kolich_vyd_benzina from Objekt_vyborki_otchyotnosti ovo
		 where ovo.Tip_objekta='for_drivers';

		 SET @res=@order_fixed*@order_count;
     
     end
     
   END  

   RETURN(@res)
END



