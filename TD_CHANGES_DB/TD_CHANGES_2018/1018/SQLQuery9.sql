USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetJSONDriverSettings]    Script Date: 13.10.2018 22:20:29 ******/
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
	END; 
	
	if(@dnts_wait_wtout_company=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"DWWC":"yes",';
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
	END;
		
	if(@show_all_sectwait_manual=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"SASWM":"yes",';
	END;
	
	if(@taxm_block_wtout_onplace=1)
	BEGIN
		SET @tmetr_instr=@tmetr_instr+'"TBWOP":"yes",';
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
