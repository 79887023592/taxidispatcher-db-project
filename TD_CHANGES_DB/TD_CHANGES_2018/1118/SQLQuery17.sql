USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetJSONDriverEarlyOrders]    Script Date: 01.12.2018 19:20:11 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER FUNCTION [dbo].[GetJSONDriverEarlyOrders] (@driver_id int)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @res varchar(max);
	DECLARE @CURSOR cursor;
	DECLARE @sid int, @scount int,
		@sname varchar(255), @counter int, 
		@show_region_in_addr smallint,
		@show_phone_in_orders smallint,
		@send_wait_info smallint, @sector_id int, 
		@dr_count int, @sector_name varchar(255),
		@order_id int, @order_data varchar(255),
		@order_count int, @on_launch int, @busy int,
		@dr_status varchar(255), @rsync int, 
		@waiting int, @order_sort_dr_assign smallint,
		@tarif_id int, @opt_comb varchar(255), @tplan_id int, 
		@prev_price decimal(28,10), @cargo_desc varchar(5000), 
		@end_adres varchar(1000), @client_name varchar(500), 
		@prev_distance decimal(28,10), @prev_date datetime,
		@on_place smallint, @bonus_use decimal(28,10),
		@last_order_time datetime, @position int;
   
	SET @res='{"command":"erlo"';
	SET @counter = 0;

	SELECT TOP 1 @show_phone_in_orders=ISNULL(show_phone_in_orders,0),
	@show_region_in_addr = show_region_in_addr,
	@send_wait_info=ISNULL(send_wait_info,0)
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ord.BOLD_ID, ((CASE WHEN (@show_region_in_addr = 1 AND ISNULL(ds.name, '') <> '') THEN ('(' + ds.name + ') ') ELSE '' END) + ord.Telefon_klienta+
	':'+ ord.Adres_vyzova_vvodim) as order_data,
	ord.REMOTE_SYNC, ord.WAITING, ord.TARIFF_ID, ord.OPT_COMB_STR, ord.PR_POLICY_ID,
	ord.prev_price, ord.cargo_desc, ord.end_adres, ord.client_name, ord.prev_distance,
	ord.Data_predvariteljnaya, ord.on_place, ord.bonus_use  
	FROM Zakaz ord LEFT JOIN DISTRICTS ds ON ord.district_id = ds.id WHERE 
	ord.vypolnyaetsya_voditelem=@driver_id AND
	ord.Arhivnyi=0 AND ord.Soobsheno_voditelyu=0
	AND ord.Zavershyon=0 AND ord.NO_TRANSMITTING=0 
	AND ord.REMOTE_SET NOT IN(0,16,26,100) 
	AND ord.is_early = 1 AND ord.is_started_early = 0 
	--AND ord.REMOTE_SYNC = 0
	ORDER BY ISNULL(ord.dr_assign_date,GETDATE()) ASC;	/*Открываем курсор*/
	OPEN @CURSOR

	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @order_id, @order_data, @rsync, @waiting, @tarif_id, @opt_comb, @tplan_id, @prev_price, @cargo_desc, @end_adres, @client_name, @prev_distance, @prev_date, @on_place, @bonus_use;
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @res=@res+',"oid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@order_id as varchar(20))+'","odt'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@order_data,'"',' '),'''',' ')+'"';
		IF (@rsync<>0)
		BEGIN
			SET @res=@res+',"sn'+
			CAST(@counter as varchar(20))+'":"y"';
		END;
		IF (@send_wait_info=1)
		BEGIN
			SET @res=@res+',"wtr'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@waiting as varchar(20))+'"';
		END;
		IF (@tarif_id<>0)
		BEGIN
			SET @res=@res+',"tar'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@tarif_id as varchar(20))+'"';
		END;

		SET @opt_comb=ISNULL(@opt_comb,'-');
		IF (@opt_comb='')
		BEGIN
			SET @opt_comb='-';
		END;

		SET @res=@res+',"oo'+
		CAST(@counter as varchar(20))+'":"'+
		@opt_comb+'"';

		IF (@tplan_id>=0)
		BEGIN
			SET @res=@res+',"otpid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@tplan_id as varchar(20))+'"';
		END;

		IF (@prev_price>0)
		BEGIN
			SET @res=@res+',"oppr'+
			CAST(@counter as varchar(20))+'":"'+
			convert(varchar,convert(decimal(8,2),@prev_price))+'"';
		END;

		IF (@prev_distance>0)
		BEGIN
			SET @res=@res+',"opdn'+
			CAST(@counter as varchar(20))+'":"'+
			convert(varchar,convert(decimal(8,2),@prev_distance))+'"';
		END;

		IF (@bonus_use>0)
		BEGIN
			SET @res=@res+',"obus'+
			CAST(@counter as varchar(20))+'":"'+
			convert(varchar,convert(decimal(8,2),@bonus_use))+'"';
		END;

		IF (@cargo_desc<>'')
		BEGIN
			SET @res=@res+',"ocrd'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@cargo_desc,'"',' '),'''',' ')+'"';
		END;

		IF (ISNULL(@end_adres,'')<>'')
		BEGIN
			SET @res=@res+',"oena'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(ISNULL(@end_adres,''),'"',' '),'''',' ')+'"';
		END;

		IF (ISNULL(@client_name,'')<>'')
		BEGIN
			SET @res=@res+',"ocln'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(ISNULL(@client_name,''),'"',' '),'''',' ')+'"';
		END;

		SET @res=@res+',"oprd'+
		CAST(@counter as varchar(20))+'":"'+
		CAST(DATEDIFF(second,{d '1970-01-01'},@prev_date) AS varchar(100))+'"';

		SET @res = @res + ',"dopl' +
			CAST(@counter as varchar(20)) + '":"' +
			CAST(@on_place as varchar(20)) + '"';
			
		SET @counter=@counter+1;
			/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @order_id, @order_data, @rsync, @waiting, @tarif_id, @opt_comb, @tplan_id, @prev_price, @cargo_desc, @end_adres, @client_name, @prev_distance, @prev_date, @on_place, @bonus_use;
	END
	CLOSE @CURSOR
	

	SET @res = @res + ',"cn":"' + CAST(@counter as varchar(20)) + 
		'","msg_end":"ok"}';

	RETURN(@res)
END
