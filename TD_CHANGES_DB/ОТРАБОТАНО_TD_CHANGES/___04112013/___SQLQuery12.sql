ALTER PROCEDURE [dbo].[GetDriverQueuePosition] 
	-- Add the parameters for the stored procedure here
	(@driver_id int, @pos_msg varchar(255) OUT)
AS
BEGIN 

	DECLARE @sector_id int;
	DECLARE @sector_name varchar(255);
	DECLARE @last_order_time datetime;
	DECLARE @position int;
	DECLARE @driver_num int;
	
	SET @pos_msg='Не определен сектор водителя!';
	SET @sector_id=-1;
	SET @sector_name='НЕ ОПРЕДЕЛЕН';
	SET @last_order_time=GETDATE();
	
	SELECT TOP 1 @sector_id=Voditelj.
	rabotaet_na_sektore, @last_order_time=
	Voditelj.Vremya_poslednei_zayavki,
	@driver_num=Voditelj.Pozyvnoi 
	FROM Voditelj 
	WHERE Voditelj.BOLD_ID=@driver_id;
	
	IF(@sector_id>0)
	BEGIN
		SELECT @sector_name=sp.Naimenovanie 
		FROM  Spravochnik sp 
		WHERE sp.BOLD_ID=@sector_id;
		
		SELECT @position=COUNT(*)+1 
		FROM Voditelj dr WHERE
		dr.Vremya_poslednei_zayavki<
		@last_order_time AND 
		dr.rabotaet_na_sektore=@sector_id
		AND dr.V_rabote=1 AND dr.Pozyvnoi>0 
		and S_klass=0 and Zanyat_drugim_disp=0 and Na_pereryve=0;
		
		SET @pos_msg='Водитель '+
			CAST(@driver_num as varchar(50))+
			' на секторе "'+
			@sector_name +
			'" место в очереди - '+
			CAST(@position as varchar(50));
		
	END
	
END
