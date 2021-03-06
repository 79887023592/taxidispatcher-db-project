USE [TD5R1]
GO

/****** Object:  UserDefinedFunction [dbo].[GetJSONDriverSettings]    Script Date: 24.10.2018 3:17:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[GetJSONDriverSettings]  ( @driver_id int)
RETURNS varchar(max)
AS
BEGIN
	declare @en_moving int, @use_gps smallint,
		@gtss_acct_id varchar(50), @gtss_dev_id varchar(50), 
		@reqgps smallint;
	DECLARE @curr_mver INT, @min_mver int, @mand_upd int, 
		@addit_rparams varchar(4000), @dr_addit_rparams varchar(500), @gps_srv_adr varchar(255),
		@gps_instr varchar(1000), @ftime_tariff decimal(28,10), 
		@tmeter_tariff decimal(28,10), @use_tmeter smallint,
		@use_nlocserv smallint, @use_bloc smallint, 
		@tmetr_instr varchar(1000), @tplan_id int, @gr_tplan_id int,
		@curr_sh varchar(50), @lock_free_orders_info smallint,
		@auto_detect_driver_sector smallint, @company_id int,
		@use_opengts_monitoring smallint, @on_gps_signaling smallint,
		@dnts_wait_oth_company smallint, @dnts_wait_wtout_company smallint,
		@auto_show_wait_dialog smallint, @wait_dlg_with_sectors smallint,
		@alart_order_confirm smallint, @confirm_lineout_on_exit smallint,
		@hide_other_sect_wait_orders smallint, @dont_wait_in_busy_state smallint,
		@show_all_sectwait_manual smallint, @taxm_block_wtout_onplace smallint,
		@start_free_distance int, @start_free_time int, 
		@dispatcher_phone varchar(50), @reserved_ip varchar(50);
	
	SELECT TOP 1 @curr_mver=ISNULL(curr_mob_version,2102),
	@min_mver=ISNULL(min_mob_version,2102),
	@mand_upd=ISNULL(mandatory_update,0),
	@addit_rparams=ISNULL(addit_rem_params,''),
	@gps_srv_adr=ISNULL(GPS_SRV_ADR,''),
	@curr_sh=ISNULL(currency_short,''),
	@lock_free_orders_info = lock_free_orders_info,
	@auto_detect_driver_sector = auto_detect_driver_sector,
	@use_opengts_monitoring = use_opengts_monitoring, 
	@on_gps_signaling = on_gps_signaling,
	@dnts_wait_oth_company = dnts_wait_oth_company, 
	@dnts_wait_wtout_company = dnts_wait_wtout_company,
	@auto_show_wait_dialog = auto_show_wait_dialog, 
	@wait_dlg_with_sectors = wait_dlg_with_sectors,
	@alart_order_confirm = alart_order_confirm, 
	@confirm_lineout_on_exit = confirm_lineout_on_exit,
	@hide_other_sect_wait_orders = hide_other_sect_wait_orders, 
	@dont_wait_in_busy_state = dont_wait_in_busy_state,
	@show_all_sectwait_manual = show_all_sectwait_manual, 
	@taxm_block_wtout_onplace = taxm_block_wtout_onplace,
	@start_free_distance = start_free_distance, 
	@start_free_time = start_free_time, 
	@dispatcher_phone = dispatcher_phone, 
	@reserved_ip = reserved_ip
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
   
	SET @en_moving=0;
   
	select @en_moving=ISNULL(EN_MOVING,0),
		@use_gps=ISNULL(USE_GPS,0),
		@gtss_acct_id=ISNULL(GTSS_ACCT_ID,''),
		@gtss_dev_id=ISNULL(GTSS_DEV_ID,''),
		@use_tmeter=ISNULL(use_tmeter,-1), 
		@use_nlocserv=ISNULL(use_nlocserv,-1),
		@use_bloc=ISNULL(use_bloc,-1),
		@tplan_id=PR_POLICY_ID,
		@dr_addit_rparams=ISNULL(addit_rem_params,''),
		@reqgps=require_gps,
		@company_id = ISNULL(otnositsya_k_gruppe, 0)   
	from Voditelj where BOLD_ID=@driver_id;
	
	SELECT @gr_tplan_id=gr.PR_POLICY_ID 
	FROM Voditelj dr, Gruppa_voditelei gr 
	WHERE dr.otnositsya_k_gruppe=gr.BOLD_ID AND
	dr.BOLD_ID=@driver_id;
	
	SET @tplan_id=ISNULL(@tplan_id, -1);
	SET @gr_tplan_id=ISNULL(@gr_tplan_id, -1);
	SET @reqgps=ISNULL(@reqgps, 0);
	
	SET @tmetr_instr='';
	if(@use_tmeter=0)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"iuse_tm":"no",';
	END;
	if(@use_tmeter=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"iuse_tm":"yes",';
	END;
	if(@use_nlocserv=0)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"iuse_nls":"no",';
	END;
	if(@use_nlocserv=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"iuse_nls":"yes",';
	END;
	if(@use_bloc=0)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"iuse_bl":"no",';
	END;
	if(@use_bloc=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"iuse_bl":"yes",';
	END;
	
	if(@reqgps=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"reqgps":"yes",';
	END;

	if(@use_opengts_monitoring=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"use_gps":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"use_gps":"no",';
	END; 
	
	if(@on_gps_signaling=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"SCCR":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"SCCR":"no",';
	END;
		
	if(@dnts_wait_oth_company=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"DWOC":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"DWOC":"no",';
	END; 
	
	if(@dnts_wait_wtout_company=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"DWWC":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"DWWC":"no",';
	END;
		
	if(@auto_show_wait_dialog=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"WDLGA":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"WDLGA":"no",';
	END; 
	
	if(@wait_dlg_with_sectors=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"WDLWS":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"WDLWS":"no",';
	END;
		
	if(@alart_order_confirm=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"ALOC":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"ALOC":"no",';
	END;
	
	if(@confirm_lineout_on_exit=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"cloe":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"cloe":"no",';
	END;
		
	if(@hide_other_sect_wait_orders=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"HOSWO":"yes",';
	END
	ELSE
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"HOSWO":"no",';
	END;
	
	if(@dont_wait_in_busy_state=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"DWIBS":"yes",';
	END
	ELSE 
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"DWIBS":"no",';
	END;
		
	if(@show_all_sectwait_manual=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"SASWM":"yes",';
	END
	ELSE 
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"SASWM":"no",';
	END;
	
	if(@taxm_block_wtout_onplace=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"TBWOP":"yes",';
	END
	ELSE 
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"TBWOP":"no",';
	END;
		
	if(@start_free_distance > 0)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"stbdist":"' + CAST(@start_free_distance as varchar(20)) + '",';
	END; 
	
	if(@start_free_time > 0)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"stbctm":"' + CAST(@start_free_time as varchar(20)) + '",';
	END; 
		
	if(@dispatcher_phone <> '')
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"DSPH":"' + @dispatcher_phone + '",';
	END; 
	
	if(@reserved_ip <> '')
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"ip2":"' + @reserved_ip + '",';
	END;

	if (@lock_free_orders_info = 1)
	BEGIN
		SET @tmetr_instr = @tmetr_instr+'"LCFOI":"yes",';
	END
	ELSE BEGIN
		SET @tmetr_instr = @tmetr_instr+'"LCFOI":"no",';
	END;

	if (@auto_detect_driver_sector = 1)
	BEGIN
		SET @tmetr_instr = @tmetr_instr+'"ADS":"yes",';
	END
	ELSE BEGIN
		SET @tmetr_instr = @tmetr_instr+'"ADS":"no",';
	END;

	SET @tmetr_instr = @tmetr_instr+'"cmpi":"' + CAST(@company_id as varchar(20)) + '",';
	
	SELECT @ftime_tariff=ISNULL(dbo.GetDrTimeTariff(@driver_id),0);
	SELECT @tmeter_tariff=ISNULL(dbo.GetDrTaxTariff(@driver_id),0);
	
	SET @gps_instr='"use_gps":"no",';
	if (@use_gps=1)
	BEGIN
		SET @gps_instr='"use_gps":"yes",';
		if (ISNULL(@gps_srv_adr,'')<>'')
		BEGIN
			SET @gps_instr=@gps_instr+
				'"gps_srv_adr":"'+@gps_srv_adr+'",';
		END;
		if ((ISNULL(@gtss_acct_id,'')<>'') AND 
			(ISNULL(@gtss_acct_id,'')<>'demo'))
		BEGIN
			SET @gps_instr=@gps_instr+
				'"gps_acc_id":"'+@gtss_acct_id+'",';
		END;
		if ((ISNULL(@gtss_dev_id,'')<>'') AND 
			(ISNULL(@gtss_dev_id,'')<>'demo'))
		BEGIN
			SET @gps_instr=@gps_instr+
				'"gps_dev_id":"'+@gtss_dev_id+'",';
		END;
	END;  

	RETURN('{"command":"sets","en_moving":"'+
		CAST(@en_moving as varchar(20))+'","curr_mver":"'+
		CAST(@curr_mver as varchar(20))+'","min_mver":"'+
		CAST(@min_mver as varchar(20))+'","mand_upd":"'+
		CAST(@mand_upd as varchar(20))+'","fttar":"'+
		CAST(@ftime_tariff as varchar(20))+'","txtar":"'+
		CAST(@tmeter_tariff as varchar(20))+'","tplid":"'+
		CAST(@tplan_id as varchar(20))+'","cur_shr":"'+
		CAST(@curr_sh as varchar(20))+'","grtpi":"'+
		CAST(@gr_tplan_id as varchar(20))+'",'+
		@tmetr_instr+@gps_instr+@addit_rparams+@dr_addit_rparams+
		'"msg_end":"ok"}')
END
GO

/****** Object:  StoredProcedure [dbo].[One10SecTask]    Script Date: 24.10.2018 3:16:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[One10SecTask] 
	(@success int OUT)
AS
BEGIN 

	DECLARE @auto_bsector_longorders smallint, @auto_bsectorid_longorders int,
			@auto_bsector_longtime int, @auto_bsector_onlineorders smallint,
			@auto_bsectorid_onlineorders int, @auto_bsector_onlinetime int,
			@auto_neardriver_onlineorders smallint, @auto_neardriver_onlinetime int,
			@auto_bsect_notmanual_ord smallint, @auto_close_client_canceling smallint,
			@auto_close_clcancel_time int, @auto_arh_empty_orders smallint,
			@use_fordbroadcast_priority smallint,
			@auto_for_all_tender smallint,
			@auto_for_all_longtime int,
			@auto_for_all_empty_sector smallint;
	
	SELECT TOP 1 @auto_bsector_longorders=ISNULL(auto_bsector_longorders,0),
	@auto_bsectorid_longorders=ISNULL(auto_bsectorid_longorders,-1),
	@auto_bsector_longtime=ISNULL(auto_bsector_longtime,0),
	@auto_bsector_onlineorders=ISNULL(auto_bsector_onlineorders,0),
	@auto_bsectorid_onlineorders=ISNULL(auto_bsectorid_onlineorders,-1),
	@auto_bsector_onlinetime=ISNULL(auto_bsector_onlinetime,0),
	@auto_neardriver_onlineorders=ISNULL(auto_neardriver_onlineorders,0), 
	@auto_neardriver_onlinetime=ISNULL(auto_neardriver_onlinetime,0),
	@auto_bsect_notmanual_ord=ISNULL(auto_bsect_notmanual_ord,0),
	@auto_close_client_canceling=ISNULL(auto_close_client_canceling,0),
	@auto_close_clcancel_time=ISNULL(auto_close_clcancel_time,7),
	@auto_arh_empty_orders=ISNULL(auto_arh_empty_orders,0),
	@use_fordbroadcast_priority = use_fordbroadcast_priority,
	@auto_for_all_tender = auto_for_all_tender,
	@auto_for_all_longtime = auto_for_all_longtime,
	@auto_for_all_empty_sector = auto_for_all_empty_sector
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	SET @success=0;

	if @auto_bsectorid_longorders<=-1 begin
		SELECT TOP 1 @auto_bsectorid_longorders=BOLD_ID FROM Sektor_raboty;
	end

	if @auto_bsectorid_onlineorders<=-1 begin
		SELECT TOP 1 @auto_bsectorid_onlineorders=BOLD_ID FROM Sektor_raboty;
	end

	BEGIN TRY
		if @auto_for_all_tender = 1 AND @auto_for_all_longtime > 0 BEGIN
			UPDATE dbo.Zakaz 
			SET 
			--konechnyi_sektor_raboty=(CASE WHEN (detected_sector > 0) THEN detected_sector ELSE @auto_bsectorid_longorders END), 
			--SECTOR_ID = (CASE WHEN (detected_sector > 0) THEN detected_sector ELSE @auto_bsectorid_longorders END),
			REMOTE_SET=2, Priority_counter=0, for_all_sectors = 1
			WHERE (Arhivnyi = 0) AND (Zavershyon = 0) AND (REMOTE_SET = 2)  
			and (Predvariteljnyi=0) and (rclient_status=0) AND for_all_sectors <> 1
			AND (ABS(DATEDIFF(SECOND, LAST_STATUS_TIME, GETDATE())) > @auto_for_all_longtime)
			AND Telefon_klienta<>'' AND ((Adres_vyzova_vvodim<>'' AND adr_manual_set=1) OR (@auto_bsect_notmanual_ord=1 AND adr_manual_set=0))
			
			IF @@ROWCOUNT > 0 BEGIN

			IF (@use_fordbroadcast_priority = 1) 
			BEGIN
				DELETE FROM DR_ORD_PRIORITY WHERE order_id IN 
				(SELECT BOLD_ID FROM Zakaz 
					WHERE (Arhivnyi = 0) AND (Zavershyon = 0) AND (REMOTE_SET = 2 OR REMOTE_SET = 3)  
					and (Predvariteljnyi=0) and (rclient_status=0) AND for_all_sectors <> 1
					AND (ABS(DATEDIFF(SECOND, LAST_STATUS_TIME, GETDATE())) > @auto_for_all_longtime)
					AND Telefon_klienta<>'' AND ((Adres_vyzova_vvodim<>'' AND adr_manual_set=1) OR (@auto_bsect_notmanual_ord=1 AND adr_manual_set=0)));
			END;

			EXEC SetOrdersWideBroadcasts 1, '';

			END;

			SET @success=1;
		END;

		if @auto_bsector_longorders>0 and @auto_bsector_longtime>0 and @auto_bsectorid_longorders>-1 begin
			UPDATE dbo.Zakaz SET konechnyi_sektor_raboty=(CASE WHEN (detected_sector > 0) THEN detected_sector ELSE @auto_bsectorid_longorders END), 
			SECTOR_ID = (CASE WHEN (detected_sector > 0) THEN detected_sector ELSE @auto_bsectorid_longorders END), REMOTE_SET=2, Priority_counter=0, 
			for_all_sectors = (CASE WHEN (detected_sector > 0 AND failed_adr_coords_detect <= 0 AND (dbo.GetSectorDrCount(detected_sector) > 0 OR @auto_for_all_empty_sector <> 1)) THEN 0 ELSE 1 END),
			Adres_vyzova_vvodim = CAST(CASE WHEN (adr_manual_set=0 AND @auto_bsect_notmanual_ord=1) THEN 'позвони клиенту' ELSE Adres_vyzova_vvodim END AS varchar(255))
			WHERE (Arhivnyi = 0) AND (Zavershyon = 0) AND (REMOTE_SET = 0) and (Predvariteljnyi=0) and (rclient_status=0)
			AND (ABS(DATEDIFF(SECOND, Nachalo_zakaza_data, GETDATE())) > @auto_bsector_longtime)
			AND Telefon_klienta<>'' AND ((Adres_vyzova_vvodim<>'' AND adr_manual_set=1) OR (@auto_bsect_notmanual_ord=1 AND adr_manual_set=0))
			SET @success=1;
		end
		if @auto_bsector_onlineorders>0 and @auto_bsector_onlinetime>0 and @auto_bsectorid_onlineorders>-1 begin
			UPDATE dbo.Zakaz SET konechnyi_sektor_raboty=(CASE WHEN (detected_sector > 0) THEN detected_sector ELSE @auto_bsectorid_onlineorders END), 
			SECTOR_ID=(CASE WHEN (detected_sector > 0) THEN detected_sector ELSE @auto_bsectorid_onlineorders END), REMOTE_SET=2, Priority_counter=0,
			for_all_sectors = (CASE WHEN (detected_sector > 0 AND failed_adr_coords_detect <= 0 AND (dbo.GetSectorDrCount(detected_sector) > 0 OR @auto_for_all_empty_sector <> 1)) THEN 0 ELSE 1 END)
			WHERE (Arhivnyi = 0) AND (Zavershyon = 0) AND (REMOTE_SET = 0) and (Predvariteljnyi=0) AND rclient_id>-1 and (rclient_status>0)
			AND (ABS(DATEDIFF(SECOND, Nachalo_zakaza_data, GETDATE())) > @auto_bsector_onlinetime)
			AND Telefon_klienta<>'' AND Adres_vyzova_vvodim<>''
			SET @success=1;
		end
		if @auto_close_client_canceling>0 and @auto_close_clcancel_time>0 begin
			UPDATE dbo.Zakaz SET REMOTE_SET=100, Zavershyon=1
			WHERE (Arhivnyi = 0) AND (Zavershyon = 0) AND (REMOTE_SET <= 8) and (Predvariteljnyi=0) AND (rclient_id > -1 OR src > 0) and (rclient_status=-1)
			AND (ABS(DATEDIFF(SECOND, LAST_STATUS_TIME, GETDATE())) > @auto_close_clcancel_time)
			SET @success=1;
		end
		if @auto_arh_empty_orders = 1 begin
			UPDATE dbo.Zakaz SET REMOTE_SET = 100, Zavershyon = 1, Arhivnyi = 1
			WHERE (Arhivnyi = 0) AND (Zavershyon = 0) AND (REMOTE_SET < 8) AND (Predvariteljnyi = 0) 
			AND Pozyvnoi_ustan = 0 AND (ABS(DATEDIFF(HOUR, LAST_STATUS_TIME, GETDATE())) > 5)
			SET @success = 1;
		end
	END TRY
	BEGIN CATCH
		SET @success=0;
	END CATCH;

END
GO

/****** Object:  StoredProcedure [dbo].[GetJSONDriverStatus]    Script Date: 24.10.2018 2:31:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetJSONDriverStatus] 
	-- Add the parameters for the stored procedure here
	(@driver_id int, @show_phone int, @res varchar(8000) OUT)
AS
BEGIN 

	DECLARE @CURSOR cursor;
	DECLARE @sector_id int, @dr_count int,
		@sector_name varchar(255), @counter int,
		@order_id int, @order_data varchar(255),
		@order_count int, @on_launch int, @busy int,
		@dr_status varchar(255), @rsync int, 
		@waiting int, @order_sort_dr_assign smallint,
		@tarif_id int, @opt_comb varchar(255), @tplan_id int, 
		@prev_price decimal(28,10), @cargo_desc varchar(5000), 
		@end_adres varchar(1000), @client_name varchar(500), 
		@prev_distance decimal(28,10), @prev_date datetime,
		@on_place smallint, @bonus_use decimal(28,10),
		@show_region_in_addr smallint;
	DECLARE @last_order_time datetime;
	DECLARE @position int;
	
	SET @last_order_time=GETDATE();
   
	SET @res='{"command":"driver_status","did":"';
	SET @dr_count = 0;
	SET @counter = 0;
	
	DECLARE @send_wait_info smallint;
	
	SELECT TOP 1 @send_wait_info=ISNULL(send_wait_info,0),
	@order_sort_dr_assign=ISNULL(order_sort_dr_assign,0),
	@show_region_in_addr = show_region_in_addr
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	SET @send_wait_info = ISNULL(@send_wait_info,0);
	
	SELECT @dr_count=COUNT(*) FROM
	Voditelj WHERE BOLD_ID=@driver_id;
	
	IF (@dr_count>0)
	BEGIN
	
	--UPDATE Voditelj SET V_rabote=1 
	--WHERE BOLD_ID=@driver_id;
	
	--UPDATE Voditelj SET REMOTE_STATUS=1
	--WHERE REMOTE_STATUS<=0;
	
	EXEC CheckDriverBusy @driver_id;
	
	SELECT @busy=Zanyat_drugim_disp, @on_launch=Na_pereryve,
	@last_order_time=Vremya_poslednei_zayavki 
	FROM Voditelj 
	WHERE BOLD_ID=@driver_id;
	
	SET @dr_status='free';
	
	IF(@on_launch>0)
	BEGIN
		SET @dr_status='onln';
	END;
	
	IF(@busy>0)
	BEGIN
		SET @dr_status='busy';
	END;
	
	SET @res=@res+CAST(@driver_id as varchar(20))+
		'","dst":"'+@dr_status+'"';
	
	SELECT @sector_id=ISNULL(ws.BOLD_ID,-1),
	@sector_name=REPLACE(REPLACE(
	ISNULL(dict.Naimenovanie,'НЕ ОПРЕДЕЛЕН'),'"',' '),'''',' ')  
	FROM Sektor_raboty ws JOIN Spravochnik dict 
	ON ws.BOLD_ID=dict.BOLD_ID JOIN Voditelj dr
	ON dr.rabotaet_na_sektore=ws.BOLD_ID
	WHERE dr.BOLD_ID=@driver_id;
	
	SET @res=@res+',"sid":"'+
		CAST(@sector_id as varchar(20))+'"';
		
	SELECT @position=COUNT(*)+1 
		FROM Voditelj dr WHERE
		dr.Vremya_poslednei_zayavki<
		@last_order_time AND 
		dr.rabotaet_na_sektore=@sector_id
		AND dr.V_rabote=1 AND dr.Pozyvnoi>0 
		and S_klass=0 and Zanyat_drugim_disp=0 and Na_pereryve=0;
		
	SET @res=@res+',"scn":"'+@sector_name+
		'","dp":"'+CAST(@position as varchar(20))+'","ocn":"';
	
	SELECT @order_count=COUNT(*)
	FROM Zakaz ord WHERE 
		ord.vypolnyaetsya_voditelem=@driver_id AND
		ord.Arhivnyi=0 AND ord.Soobsheno_voditelyu=0
		AND Zavershyon=0 AND NO_TRANSMITTING=0 
		AND REMOTE_SET NOT IN(0,16,26,100);
	
	IF (@order_count>0)
	BEGIN
	
		SET @res=@res+
			CAST(@order_count as varchar(20))+'"';
	
		IF (@order_sort_dr_assign=1)
		BEGIN
		IF (@show_phone>0)
		BEGIN
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
			ORDER BY ISNULL(ord.dr_assign_date,GETDATE()) ASC;
		END
		ELSE
		BEGIN
			SET @CURSOR  = CURSOR SCROLL
			FOR
			SELECT ord.BOLD_ID, ((CASE WHEN (@show_region_in_addr = 1 AND ISNULL(ds.name, '') <> '') THEN ('(' + ds.name + ') ') ELSE '' END) + ord.Adres_vyzova_vvodim) as order_data,
			ord.REMOTE_SYNC, ord.WAITING, ord.TARIFF_ID, ord.OPT_COMB_STR, ord.PR_POLICY_ID,
			ord.prev_price, ord.cargo_desc, ord.end_adres, ord.client_name, ord.prev_distance,
			ord.Data_predvariteljnaya, ord.on_place, ord.bonus_use  
			FROM Zakaz ord LEFT JOIN DISTRICTS ds ON ord.district_id = ds.id WHERE 
			ord.vypolnyaetsya_voditelem=@driver_id AND
			ord.Arhivnyi=0 AND ord.Soobsheno_voditelyu=0
			AND ord.Zavershyon=0 AND ord.NO_TRANSMITTING=0 
			AND ord.REMOTE_SET NOT IN(0,16,26,100)
			ORDER BY ISNULL(ord.dr_assign_date,GETDATE()) ASC;
		END;
		END
		ELSE
		BEGIN
		IF (@show_phone>0)
		BEGIN
			SET @CURSOR  = CURSOR SCROLL
			FOR
			SELECT ord.BOLD_ID, ((CASE WHEN (@show_region_in_addr = 1 AND ISNULL(ds.name, '') <> '') THEN ('(' + ds.name + ') ') ELSE '' END) + ord.Telefon_klienta+
			':' + ord.Adres_vyzova_vvodim) as order_data,
			ord.REMOTE_SYNC, ord.WAITING, ord.TARIFF_ID, ord.OPT_COMB_STR, ord.PR_POLICY_ID,
			ord.prev_price, ord.cargo_desc, ord.end_adres, ord.client_name, ord.prev_distance,
			ord.Data_predvariteljnaya, ord.on_place, ord.bonus_use   
			FROM Zakaz ord LEFT JOIN DISTRICTS ds ON ord.district_id = ds.id WHERE 
			ord.vypolnyaetsya_voditelem=@driver_id AND
			ord.Arhivnyi=0 AND ord.Soobsheno_voditelyu=0
			AND ord.Zavershyon=0 AND ord.NO_TRANSMITTING=0 
			AND ord.REMOTE_SET NOT IN(0,16,26,100) 
			ORDER BY ord.Nachalo_zakaza_data ASC;
		END
		ELSE
		BEGIN
			SET @CURSOR  = CURSOR SCROLL
			FOR
			SELECT ord.BOLD_ID, ((CASE WHEN (@show_region_in_addr = 1 AND ISNULL(ds.name, '') <> '') THEN ('(' + ds.name + ') ') ELSE '' END) + ord.Adres_vyzova_vvodim) as order_data,
			ord.REMOTE_SYNC, ord.WAITING, ord.TARIFF_ID, ord.OPT_COMB_STR, ord.PR_POLICY_ID,
			ord.prev_price, ord.cargo_desc, ord.end_adres, ord.client_name, ord.prev_distance,
			ord.Data_predvariteljnaya, ord.on_place, ord.bonus_use   
			FROM Zakaz ord LEFT JOIN DISTRICTS ds ON ord.district_id = ds.id WHERE 
			ord.vypolnyaetsya_voditelem=@driver_id AND
			ord.Arhivnyi=0 AND ord.Soobsheno_voditelyu=0
			AND ord.Zavershyon=0 AND ord.NO_TRANSMITTING=0 
			AND ord.REMOTE_SET NOT IN(0,16,26,100)
			ORDER BY ord.Nachalo_zakaza_data ASC;
		END;
		END;
		/*Открываем курсор*/
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
	END
	ELSE
	BEGIN
		SET @res=@res+'0"';
	END;
	
	SET @res=@res+',"msg_end":"ok"}';
	
	END
	ELSE
	BEGIN
		SET @res=@res+'-1","msg_end":"ok"}';	
	END;
	
END
GO

/****** Object:  UserDefinedFunction [dbo].[GetJSONOrdersBCasts]    Script Date: 24.10.2018 2:55:15 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER FUNCTION [dbo].[GetJSONOrdersBCasts] ()
RETURNS varchar(max)
AS
BEGIN
	declare @res varchar(max);
	DECLARE @CURSOR cursor;
	DECLARE @order_id int, @order_adres varchar(255), @end_sect int,
		@counter int, @prev_price decimal(28,10), @cargo_desc varchar(5000), 
		@end_adres varchar(1000), @client_name varchar(500), 
		@prev_distance decimal(28,10), @prev_date datetime,
		@rating_bonus decimal(18, 5), @for_all_sectors smallint,
		@company_id int, @show_region_in_addr smallint;

	SET @show_region_in_addr = 0;

	SELECT TOP 1 @show_region_in_addr = show_region_in_addr
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
   
	SET @res='{"command":"ford"';
	SET @counter = 0;
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ord.BOLD_ID, ((CASE WHEN (@show_region_in_addr = 1 AND ISNULL(ds.name, '') <> '') THEN ('(' + ds.name + ') ') ELSE '' END) + ord.Adres_vyzova_vvodim) as Adres_vyzova_vvodim, ord.SECTOR_ID,
	ord.prev_price, ord.cargo_desc, ord.end_adres, ord.client_name, ord.prev_distance,
	ord.Data_predvariteljnaya, ord.driver_rating_diff, ord.for_all_sectors,
	ISNULL(ds.company_id, 0) as company_id FROM Zakaz ord
	LEFT JOIN DISTRICTS ds ON ord.district_id = ds.id 
	WHERE Zavershyon=0 AND REMOTE_SET>0 AND REMOTE_SET<8;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @order_id, @order_adres, @end_sect, @prev_price, @cargo_desc, @end_adres, @client_name, @prev_distance, @prev_date, @rating_bonus, @for_all_sectors, @company_id
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN
        SET @res=@res+',"id'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@order_id as varchar(20))+'","oad'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@order_adres,'"',' '),'''',' ')+'","oes'+
			CAST(@counter as varchar(20))+'":"'+CAST(@end_sect as varchar(20))+'"';
        
		IF (@rating_bonus>0)
			BEGIN
			SET @res=@res+',"orb'+
			CAST(@counter as varchar(20))+'":"'+
			convert(varchar,convert(decimal(8,2),@rating_bonus))+'"';
			END;

		IF (@for_all_sectors>0)
			BEGIN
			SET @res=@res+',"fas'+
			CAST(@counter as varchar(20))+'":"1"';
			END;

		IF (@company_id>0)
			BEGIN
			SET @res=@res+',"cmp'+
			CAST(@counter as varchar(20))+'":"' + 
			CAST(@company_id as varchar(20)) + '"';
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

			IF (@cargo_desc<>'')
			BEGIN
			SET @res=@res+',"ocrd'+
			CAST(@counter as varchar(20))+'":"'+
			@cargo_desc+'"';
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
		
		SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @order_id, @order_adres, @end_sect, @prev_price, @cargo_desc, @end_adres, @client_name, @prev_distance, @prev_date, @rating_bonus, @for_all_sectors, @company_id
	END
	CLOSE @CURSOR
	
	SET @res=@res+',"ocnt":"'+
		CAST(@counter as varchar(20))+'","msg_end":"ok"}';

	RETURN(@res)
END
GO


/****** Object:  UserDefinedFunction [dbo].[GetJSONDriverOrdersBCasts]    Script Date: 24.10.2018 2:58:53 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER FUNCTION [dbo].[GetJSONDriverOrdersBCasts] (@driver_id int)
RETURNS varchar(max)
AS
BEGIN
	declare @res varchar(max);
	DECLARE @CURSOR cursor;
	DECLARE @order_id int, @order_adres varchar(255), @end_sect int,
		@counter int, @prev_price decimal(28,10), @cargo_desc varchar(5000), 
		@end_adres varchar(1000), @client_name varchar(500), 
		@prev_distance decimal(28,10), @prev_date datetime, 
		@rating_bonus decimal(18, 5), @for_all_sectors smallint,
		@company_id int, @show_region_in_addr smallint;

	SET @show_region_in_addr = 0;

	SELECT TOP 1 @show_region_in_addr = show_region_in_addr
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
   
	SET @res='{"command":"ford"';
	SET @counter = 0;
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ord.BOLD_ID, ((CASE WHEN (@show_region_in_addr = 1 AND ISNULL(ds.name, '') <> '') THEN ('(' + ds.name + ') ') ELSE '' END) + ord.Adres_vyzova_vvodim) as Adres_vyzova_vvodim, ord.SECTOR_ID,
	ord.prev_price, ord.cargo_desc, ord.end_adres, ord.client_name, 
	ord.prev_distance, ord.Data_predvariteljnaya, ord.driver_rating_diff,
	ord.for_all_sectors, ISNULL(ds.company_id, 0) as company_id FROM Zakaz ord
	INNER JOIN DR_ORD_PRIORITY dop ON ord.BOLD_ID=dop.order_id 
	LEFT JOIN DISTRICTS ds ON ord.district_id = ds.id
	WHERE ord.Zavershyon=0 AND ord.REMOTE_SET>0 AND ord.REMOTE_SET<8 
	AND dop.priority<=0 AND dop.driver_id=@driver_id;
	--AND dop.priority>=-1
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @order_id, @order_adres, @end_sect, @prev_price, @cargo_desc, @end_adres, @client_name, @prev_distance, @prev_date, @rating_bonus, @for_all_sectors, @company_id
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN
        SET @res=@res+',"id'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@order_id as varchar(20))+'","oad'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@order_adres,'"',' '),'''',' ')+'","oes'+
			CAST(@counter as varchar(20))+'":"'+CAST(@end_sect as varchar(20))+'"';

		IF (@rating_bonus>0)
			BEGIN
			SET @res=@res+',"orb'+
			CAST(@counter as varchar(20))+'":"'+
			convert(varchar,convert(decimal(8,2),@rating_bonus))+'"';
			END;

		IF (@for_all_sectors>0)
			BEGIN
			SET @res=@res+',"fas'+
			CAST(@counter as varchar(20))+'":"1"';
			END;

		IF (@company_id>0)
			BEGIN
			SET @res=@res+',"cmp'+
			CAST(@counter as varchar(20))+'":"' + 
			CAST(@company_id as varchar(20)) + '"';
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

			IF (@cargo_desc<>'')
			BEGIN
			SET @res=@res+',"ocrd'+
			CAST(@counter as varchar(20))+'":"'+
			@cargo_desc+'"';
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
		
		SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @order_id, @order_adres, @end_sect, @prev_price, @cargo_desc, @end_adres, @client_name, @prev_distance, @prev_date, @rating_bonus, @for_all_sectors, @company_id
	END
	CLOSE @CURSOR
	
	SET @res=@res+',"ocnt":"'+
		CAST(@counter as varchar(20))+'","msg_end":"ok"}';

	IF @counter = 0 
	BEGIN
		SET @res = '';
	END

	RETURN(@res)
END
GO

/****** Object:  View [dbo].[ActiveOrders]    Script Date: 29.10.2018 3:32:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[ActiveOrders]
AS
SELECT        dbo.Zakaz.BOLD_ID, dbo.Zakaz.Yavl_pochasovym, dbo.Zakaz.Kolichestvo_chasov, dbo.Zakaz.Nachalo_zakaza_data, dbo.Zakaz.Konec_zakaza_data, dbo.Zakaz.Telefon_klienta, dbo.Zakaz.Data_podachi, 
                         dbo.Zakaz.Zavershyon, dbo.Zakaz.Arhivnyi, dbo.Zakaz.Uslovn_stoim, dbo.Zakaz.Adres_vyzova_vvodim, dbo.Zakaz.Predvariteljnyi, dbo.Zakaz.Data_predvariteljnaya, dbo.Zakaz.Zadeistv_predvarit, 
                         dbo.Zakaz.Data_po_umolchaniyu, dbo.Zakaz.Soobsheno_voditelyu, dbo.Zakaz.vypolnyaetsya_voditelem, dbo.Zakaz.otpuskaetsya_dostepcherom, dbo.Zakaz.ocenivaetsya_cherez, dbo.Zakaz.adres_sektora, 
                         dbo.Zakaz.konechnyi_sektor_raboty, dbo.Zakaz.sektor_voditelya, dbo.Zakaz.Nomer_zakaza, dbo.Zakaz.Adres_okonchaniya_zayavki, dbo.Zakaz.Pozyvnoi_ustan, dbo.Zakaz.Data_pribytie, dbo.Zakaz.Nomer_skidki, 
                         dbo.Zakaz.Ustan_pribytie, dbo.Zakaz.Primechanie, dbo.Zakaz.Slugebnyi, dbo.Zakaz.otpravlyaetsya, dbo.Zakaz.Opr_s_obsh_linii, dbo.Zakaz.Data_na_tochke, dbo.Zakaz.REMOTE_SET, dbo.Zakaz.REMOTE_INCOURSE, 
                         dbo.Zakaz.REMOTE_ACCEPTED, dbo.Zakaz.REMOTE_DRNUM, dbo.Zakaz.DRIVER_SMS_SEND_STATE, dbo.Zakaz.CLIENT_SMS_SEND_STATE, dbo.Zakaz.SMS_SEND_DRNUM, dbo.Zakaz.SMS_SEND_CLPHONE, 
                         dbo.Zakaz.Priority_counter, dbo.Zakaz.Individ_order, dbo.Zakaz.Individ_sending, dbo.Zakaz.SECTOR_ID, dbo.Zakaz.REMOTE_SUMM, dbo.Zakaz.REMOTE_SYNC, dbo.Zakaz.LAST_STATUS_TIME, 
                         dbo.Zakaz.NO_TRANSMITTING, dbo.Zakaz.RESTORED, dbo.Zakaz.AUTO_ARHIVED, dbo.Zakaz.WAITING, dbo.Zakaz.direct_sect_id, dbo.Zakaz.fixed_time, dbo.Zakaz.fixed_summ, dbo.Zakaz.on_place, 
                         dbo.Zakaz.dr_assign_date, dbo.Zakaz.tm_distance, dbo.Zakaz.tm_summ, dbo.Zakaz.TARIFF_ID, dbo.Zakaz.OPT_COMB, dbo.Zakaz.OPT_COMB_STR, dbo.Zakaz.PR_POLICY_ID, dbo.Zakaz.call_it, dbo.Zakaz.rclient_id, 
                         dbo.Zakaz.rclient_status, dbo.Zakaz.clsync, dbo.Zakaz.tmsale, dbo.Zakaz.tmhistory, dbo.Zakaz.status_accumulate, dbo.Zakaz.rclient_lat, dbo.Zakaz.rclient_lon, dbo.Zakaz.alarmed, dbo.Zakaz.adr_manual_set, 
                         dbo.Zakaz.prev_price, dbo.Zakaz.cargo_desc, dbo.Zakaz.end_adres, dbo.Zakaz.client_name, dbo.Zakaz.prev_distance, dbo.Zakaz.CLIENT_CALL_STATE, CAST(DATEPART(hh, dbo.Zakaz.Nachalo_zakaza_data) AS CHAR(2)) 
                         + ':' + CAST(DATEPART(mi, dbo.Zakaz.Nachalo_zakaza_data) AS CHAR(2)) AS start_dt, CAST(DATEPART(hh, dbo.Zakaz.Konec_zakaza_data) AS CHAR(2)) + ':' + CAST(DATEPART(mi, dbo.Zakaz.Konec_zakaza_data) AS CHAR(2)) 
                         AS end_dt, dbo.GetCustComment(dbo.Zakaz.Nomer_zakaza, dbo.Zakaz.Nachalo_zakaza_data, dbo.Zakaz.Telefon_klienta + dbo.Zakaz.Adres_vyzova_vvodim, dbo.Zakaz.otpuskaetsya_dostepcherom, 
                         dbo.Zakaz.otpravlyaetsya, dbo.Zakaz.Pozyvnoi_ustan) AS MainCComment, dbo.GetOrderINumComment(dbo.Zakaz.Adres_okonchaniya_zayavki) AS INumInfo, dbo.GetEndSectorNameByID(dbo.Zakaz.konechnyi_sektor_raboty) 
                         AS esect, dbo.GetEndSectorNameByID(dbo.Zakaz.SECTOR_ID) AS order_sect, dbo.GetEndSectorNameByID(dbo.Zakaz.direct_sect_id) AS dir_sect, dbo.GetRemoteCustComment(dbo.Zakaz.REMOTE_SET, 
                         dbo.Zakaz.REMOTE_INCOURSE, dbo.Zakaz.REMOTE_ACCEPTED, dbo.Zakaz.REMOTE_DRNUM) AS RemCustComment, dbo.GetSendSMSCustComment(dbo.Zakaz.DRIVER_SMS_SEND_STATE, 
                         dbo.Zakaz.CLIENT_SMS_SEND_STATE, dbo.Zakaz.SMS_SEND_DRNUM, dbo.Zakaz.SMS_SEND_CLPHONE) AS SendSMSCustComment, dbo.GetOrdTarifNameByTId(dbo.Zakaz.TARIFF_ID) AS tarif_name, 
                         dbo.GetRemoteOrderStatusInfo(dbo.Zakaz.REMOTE_SET, dbo.Zakaz.WAITING) AS remoteOrderStatusInfo, dbo.Zakaz.src, dbo.Zakaz.src_status_code, dbo.Zakaz.src_id, dbo.Voditelj.Marka_avtomobilya, 
                         dbo.Voditelj.Gos_nomernoi_znak, dbo.Voditelj.phone_number, ISNULL(dbo.Voditelj.full_name, '') AS driver_name, dbo.Zakaz.src_on_place, dbo.Zakaz.src_wait_sended, dbo.GetEndSectorNameByID(dbo.Zakaz.detected_sector) AS det_sect_name
FROM            dbo.Zakaz LEFT OUTER JOIN
                         dbo.Voditelj ON dbo.Zakaz.vypolnyaetsya_voditelem = dbo.Voditelj.BOLD_ID


GO

/****** Object:  StoredProcedure [dbo].[AssignDriverOnOrder]    Script Date: 29.10.2018 3:33:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[AssignDriverOnOrder] 
	-- Add the parameters for the stored procedure here
	(@order_id int, @driver_id int, @user_id int, @count int OUT)
AS
BEGIN 
	DECLARE @prev_dr_id int, 
	@on_launch int, @driverNum int,
	@min_debet decimal(28, 10);
	
	SET @count = 0;

	SELECT TOP 1 @min_debet=ISNULL(MIN_DEBET,0) 
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';

	SELECT @prev_dr_id=Zakaz.vypolnyaetsya_voditelem 
	FROM Zakaz
	WHERE Zakaz.BOLD_ID=@order_id;
	
	SELECT TOP 1 @driverNum=Pozyvnoi 
	FROM Voditelj 
	WHERE BOLD_ID=@driver_id AND ITS_REMOTE_CLIENT = 1 AND 
	Na_pereryve = 0 AND DRIVER_BALANCE > @min_debet AND 
	V_rabote = 1;
	
	if (@@ROWCOUNT>0)
	begin
	
	UPDATE Zakaz 
	SET REMOTE_SET=8,
	vypolnyaetsya_voditelem=@driver_id,
	Pozyvnoi_ustan=@driverNum,
	REMOTE_INCOURSE=0, REMOTE_ACCEPTED=0,
	Priority_counter=0, REMOTE_DRNUM=@driverNum,
	REMOTE_SYNC=1, Individ_order=1, 
	otpravlyaetsya = @user_id, adr_manual_set = 1
	WHERE BOLD_ID=@order_id AND Adres_vyzova_vvodim <> ''
	AND Telefon_klienta <> '';

	--adr_manual_set=1
	SET @count = @@ROWCOUNT;
	
	IF @count > 0 BEGIN
		UPDATE Voditelj
		SET Na_pereryve=0,
		Zanyat_drugim_disp=1
		WHERE BOLD_ID=@driver_id;

		IF @prev_dr_id > 0 BEGIN
			EXEC CheckDriverBusy @prev_dr_id;
		END;
	END;
	
	end
	
	
	
END
GO

/****** Object:  UserDefinedFunction [dbo].[GetJSONTarifAndOptionsList]    Script Date: 09.11.2018 22:28:45 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER FUNCTION [dbo].[GetJSONTarifAndOptionsList] (@driver_id int)
RETURNS varchar(max)
AS
BEGIN
	declare @res varchar(max);
	DECLARE @CURSOR cursor;
	DECLARE @sid int, @scount int,
		@sname varchar(255), @counter int,
		@timetr decimal(28,10), @tmetrtr decimal(28,10),
		@os_coeff decimal(28,10), @os_comp decimal(28,10),
		@tplan_id int, @short_name varchar(20), 
		@miss_every_nkm int, @policy_id int;
   
	SET @res='{"command":"to_lst","t_cnt":"';
	SET @counter = 0;
	SET @policy_id = -1;

	SELECT @policy_id = gv.PR_POLICY_ID
	FROM Voditelj dr INNER JOIN Gruppa_voditelei gv ON dr.otnositsya_k_gruppe = gv.BOLD_ID
	WHERE dr.BOLD_ID = @driver_id;

	IF @@ROWCOUNT <= 0 BEGIN
		SET @policy_id = -1;
		SELECT @policy_id = dr.PR_POLICY_ID
		FROM Voditelj dr
		WHERE dr.BOLD_ID = @driver_id;

		IF @@ROWCOUNT <= 0 BEGIN
			SET @policy_id = -1;
		END;
	END;
	
	SELECT @scount=COUNT(*)  
	FROM ORDER_TARIF WHERE PR_POLICY_ID = @policy_id OR @policy_id <= 0;
	
	DECLARE @fmt_str1 varchar(50), @fmt_str2 varchar(50), 
		@fmt_str3 varchar(50), @fmt_str4 varchar(50), 
		@dist_part int, @dpart_tarif decimal(28, 10), 
		@stop_tarif decimal(28, 10), @dist_start int,
		@otarid int, @otplid int, @miss_every_nkm_json varchar(100);
	
	IF (@scount>0)
	BEGIN
	
	SET @res=@res+CAST(@scount as varchar(20))+'"';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ID, TARIF_NAME, TIME_TARIF, TMETER_TARIF, PR_POLICY_ID, SHORT_NAME, DISTANCE_PART, DPART_TARIF, STOP_TARIF, DISTANCE_START, outher_tarid, outher_tplid, miss_every_nkm  
	FROM ORDER_TARIF WHERE PR_POLICY_ID = @policy_id OR @policy_id <= 0 ORDER BY ID ASC;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @sid, @sname, @timetr, @tmetrtr, @tplan_id, @short_name, @dist_part, @dpart_tarif, @stop_tarif, @dist_start, @otarid, @otplid, @miss_every_nkm
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

        
        IF (CHARINDEX('.',CAST(@tmetrtr as varchar(20)))+2<=
			LEN(CAST(@tmetrtr as varchar(20))))
		BEGIN
			SET @fmt_str1=LEFT(CAST(@tmetrtr as varchar(20)),
				CHARINDEX('.',CAST(@tmetrtr as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str1=CAST(@tmetrtr as varchar(20));
		END
		
		IF (CHARINDEX('.',CAST(@timetr as varchar(20)))+2<=
			LEN(CAST(@timetr as varchar(20))))
		BEGIN
			SET @fmt_str2=LEFT(CAST(@timetr as varchar(20)),
				CHARINDEX('.',CAST(@timetr as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str2=CAST(@timetr as varchar(20));
		END
		
		IF (CHARINDEX('.',CAST(@dpart_tarif as varchar(20)))+2<=
			LEN(CAST(@dpart_tarif as varchar(20))))
		BEGIN
			SET @fmt_str3=LEFT(CAST(@dpart_tarif as varchar(20)),
				CHARINDEX('.',CAST(@dpart_tarif as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str3=CAST(@dpart_tarif as varchar(20));
		END
		
		IF (CHARINDEX('.',CAST(@stop_tarif as varchar(20)))+2<=
			LEN(CAST(@stop_tarif as varchar(20))))
		BEGIN
			SET @fmt_str4=LEFT(CAST(@stop_tarif as varchar(20)),
				CHARINDEX('.',CAST(@stop_tarif as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str4=CAST(@stop_tarif as varchar(20));
		END

		SET @miss_every_nkm_json = ''
		IF @miss_every_nkm > 0 BEGIN
			SET @miss_every_nkm_json = '","mek'+
				CAST(@counter as varchar(20))+'":"'+
				CAST(@miss_every_nkm as varchar(20));
		END
		
        SET @res=@res+',"tid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sid as varchar(20))+'","tn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@sname,'"',' '),'''',' ')+'","tmt'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str2+'","txt'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str1+'","ttpi'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@tplan_id as varchar(20))+'","tdip'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@dist_part as varchar(20))+'","tstds'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@dist_start as varchar(20))+'","tdpt'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str3+'","tspt'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str4+'","tshn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@short_name,'"',' '),'''',' ')+'","otarid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@otarid as varchar(20))+'","otplid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@otplid as varchar(20)) + @miss_every_nkm_json + '"'+
			dbo.GetTarifAreaCoords(@sid, @counter);
        SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @sid, @sname, @timetr, @tmetrtr, @tplan_id, @short_name, @dist_part, @dpart_tarif, @stop_tarif, @dist_start, @otarid, @otplid, @miss_every_nkm
	END
	CLOSE @CURSOR
	
	END
	ELSE
	BEGIN
		SET @res=@res+'0"';	
	END;
	
	SELECT @scount=COUNT(*)  
	FROM ORDER_OPTION WHERE PR_POLICY_ID = @policy_id OR @policy_id <= 0;
	
	SET @res=@res+',"op_cnt":"';
	SET @counter = 0;
	
	IF (@scount>0)
	BEGIN
	
	SET @res=@res+CAST(@scount as varchar(20))+'"';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ID, OPTION_NAME, OSUMM_COEFF, OS_COMPOSED, PR_POLICY_ID, SHORT_NAME  
	FROM ORDER_OPTION WHERE PR_POLICY_ID = @policy_id OR @policy_id <= 0 ORDER BY ID ASC;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @sid, @sname, @os_coeff, @os_comp, @tplan_id, @short_name
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

        IF (CHARINDEX('.',CAST(@os_coeff as varchar(20)))+2<=
			LEN(CAST(@os_coeff as varchar(20))))
		BEGIN
			SET @fmt_str1=LEFT(CAST(@os_coeff as varchar(20)),
				CHARINDEX('.',CAST(@os_coeff as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str1=CAST(@os_coeff as varchar(20));
		END
		IF (CHARINDEX('.',CAST(@os_comp as varchar(20)))+2<=
			LEN(CAST(@os_comp as varchar(20))))
		BEGIN
			SET @fmt_str2=LEFT(CAST(@os_comp as varchar(20)),
				CHARINDEX('.',CAST(@os_comp as varchar(20)))+2);
		END
		ELSE
		BEGIN
			SET @fmt_str2=CAST(@os_comp as varchar(20));
		END
        
        SET @res=@res+',"oid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sid as varchar(20))+'","on'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@sname,'"',' '),'''',' ')+'","oscf'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str1+'","oscm'+
			CAST(@counter as varchar(20))+'":"'+
			@fmt_str2+'","otpi'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@tplan_id as varchar(20))+'","oshn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@short_name,'"',' '),'''',' ')+'"';
        SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @sid, @sname, @os_coeff, @os_comp, @tplan_id, @short_name
	END
	CLOSE @CURSOR
	
	END
	ELSE
	BEGIN
		SET @res=@res+'0"';	
	END;
	
	-----------------------
	SELECT @scount=COUNT(*)  
	FROM PRICE_POLICY WHERE ID = @policy_id OR @policy_id <= 0;
	
	SET @res=@res+',"tpl_cnt":"';
	SET @counter = 0;
	
	IF (@scount>0)
	BEGIN
	
	SET @res=@res+CAST(@scount as varchar(20))+'"';
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT ID, POLICY_NAME, SHORT_NAME  
	FROM PRICE_POLICY WHERE ID = @policy_id OR @policy_id <= 0 ORDER BY ID ASC;
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @sid, @sname, @short_name
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN

        SET @res=@res+',"tpid'+
			CAST(@counter as varchar(20))+'":"'+
			CAST(@sid as varchar(20))+'","tpn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@sname,'"',' '),'''',' ')+'","tpshn'+
			CAST(@counter as varchar(20))+'":"'+
			REPLACE(REPLACE(@short_name,'"',' '),'''',' ')+'"';
        SET @counter=@counter+1;
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @sid, @sname, @short_name
	END
	CLOSE @CURSOR
	
	END
	ELSE
	BEGIN
		SET @res=@res+'0"';	
	END;
	------------------------------
	
	SET @res=@res+',"msg_end":"ok"}';

	RETURN(@res)
END
GO

ALTER TABLE [dbo].[Voditelj]  WITH CHECK ADD  CONSTRAINT [CK_Voditelj] CHECK  (([Pozyvnoi]<(100000)))
GO

ALTER TABLE [dbo].[Voditelj] CHECK CONSTRAINT [CK_Voditelj]
GO

/****** Object:  UserDefinedFunction [dbo].[GetDriversCCHTTPParams]    Script Date: 09.11.2018 22:32:21 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER FUNCTION [dbo].[GetDriversCCHTTPParams] ()
RETURNS varchar(1500)
AS
BEGIN
	declare @res varchar(1500);
	DECLARE @CURSOR cursor;
	DECLARE @dr_count int,
		@lat varchar(50), @lon varchar(50), 
		@counter int, @dr_num int;
   
	SET @res='dc=0';
	SET @counter = 0;
	
	SELECT @dr_count=COUNT(*)  
	FROM Voditelj WHERE ISNULL(last_lat,'')<>'' 
	AND ISNULL(last_lon,'')<>'' AND Pozyvnoi>0 AND V_rabote = 1 
	AND (ABS(DATEDIFF(minute, last_cctime, GETDATE())) < 60);
	
	IF (@dr_count>0)
	BEGIN
	
	SET @res='dc='+CAST(@dr_count as varchar(20));
	
	SET @CURSOR  = CURSOR SCROLL
	FOR
	SELECT last_lat, last_lon, Pozyvnoi  
	FROM Voditelj WHERE ISNULL(last_lat,'')<>'' 
	AND ISNULL(last_lon,'')<>'' AND Pozyvnoi>0 AND V_rabote = 1 
	AND (ABS(DATEDIFF(minute, last_cctime, GETDATE())) < 60);
	/*Открываем курсор*/
	OPEN @CURSOR
	/*Выбираем первую строку*/
	FETCH NEXT FROM @CURSOR INTO @lat, @lon, @dr_num
	/*Выполняем в цикле перебор строк*/
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @counter=@counter+1;
        SET @res=@res+'&lat'+CAST(@counter as varchar(20))+'='+CAST(@lat as varchar(20))+
			'&lon'+CAST(@counter as varchar(20))+'='+CAST(@lon as varchar(20))+
			'&dn'+CAST(@counter as varchar(20))+'='+CAST(@dr_num as varchar(20));
        
		/*Выбираем следующую строку*/
		FETCH NEXT FROM @CURSOR INTO @lat, @lon, @dr_num
	END
	CLOSE @CURSOR
	
	END

	RETURN(@res)
END
GO

/****** Object:  StoredProcedure [dbo].[AssignDriverByNumOnOrder]    Script Date: 29.10.2018 3:34:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[AssignDriverByNumOnOrder] 
	-- Add the parameters for the stored procedure here
	(@order_id int, @driver_num int, @user_id int, @count int OUT)
AS
BEGIN 
	DECLARE @driver_id int;
	
	SET @count = 0;

	SELECT TOP 1 @driver_id = BOLD_ID
	FROM Voditelj
	WHERE Pozyvnoi = @driver_num;

	IF @@ROWCOUNT > 0 BEGIN
		EXEC dbo.AssignDriverOnOrder @order_id, @driver_id, 
			@user_id, @count = @count OUT;
	END;
	
END











GO



