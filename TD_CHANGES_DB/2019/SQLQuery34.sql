USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetOrderOnPlaceAMICommand]    Script Date: 24.04.2019 21:56:38 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


ALTER FUNCTION [dbo].[GetOrderOnPlaceAMICommand]  ( @oid int)
RETURNS varchar(2000)
AS
BEGIN
   declare @res varchar(2000), @dr_id int, @clphone varchar(255),
	@avar1 smallint, @avar2 smallint, @avar3 smallint, @avar4 smallint,
	@avar5 smallint, @avar6 smallint, @avar7 smallint, @avar8 smallint,
	@avar9 smallint, @avar10 smallint, @test_phone varchar(50), @disp_phone varchar(50),
	@manager_phone varchar(50), @call_demon_locsip_name varchar(50),
	@call_demon_netsip_name varchar(50), @demon_call_ctx varchar(50),
	@demon_call_virtext varchar(50), @demon_call_priority varchar(20),
	@demon_call_timeout varchar(20), @demon_callerid varchar(50),
	@onplace_first_song_code int, @state_phone_code varchar(50);
   
   select @call_demon_locsip_name=call_demon_locsip_name,
		@demon_call_ctx=demon_call_ctx, @demon_call_virtext=demon_call_virtext,
		@demon_call_priority=demon_call_priority, @demon_call_timeout=demon_call_timeout,
		@demon_callerid=demon_callerid, 
		@onplace_first_song_code = onplace_first_song_code, 
		@state_phone_code = state_phone_code
   from Objekt_vyborki_otchyotnosti where Tip_objekta='for_drivers'

   SET @state_phone_code = ISNULL(@state_phone_code, '+7');
   
   IF (@@ROWCOUNT>0) BEGIN
   SELECT @clphone=Telefon_klienta, @dr_id=vypolnyaetsya_voditelem 
   FROM Zakaz WHERE BOLD_ID=@oid;
   
   IF (@@ROWCOUNT>0) BEGIN
   SELECT @avar1=avar1, @avar2=avar2, @avar3=avar3, @avar4=avar4,
   @avar5=avar5, @avar6=avar6, @avar7=avar7, @avar8=avar8, @avar9=avar9, @avar10=avar10 
   FROM Voditelj WHERE BOLD_ID=@dr_id;
   
   SET @res = ISNULL(@res, 'NONE');
   IF (@@ROWCOUNT > 0 AND ISNULL(@avar2, 0) > 0) BEGIN
		SET @res = 'Action: Originate***___CRLF'+
		'Channel: SIP/'+@call_demon_locsip_name + '/' + @state_phone_code + @clphone+'***___CRLF'+
		'Context: '+@demon_call_ctx+'***___CRLF'+
		'Exten: '+@demon_call_virtext+'***___CRLFPriority: '+
		@demon_call_priority+'***___CRLF'+
		'Callerid: '+@demon_callerid+'***___CRLFTimeout: '+
		@demon_call_timeout+'***___CRLF'+
		'Variable: v1='+CAST(@onplace_first_song_code as varchar(50))+
		'***___CRLFVariable: v2='+CAST(@avar2 as varchar(50))+'***___CRLF'+
		'Variable: v3='+CAST(@avar3 as varchar(50))+
		'***___CRLFVariable: v4='+CAST(@avar4 as varchar(50))+'***___CRLF'+
		'Variable: v5='+CAST(@avar5 as varchar(50))+
		'***___CRLFVariable: v6='+CAST(@avar6 as varchar(50))+'***___CRLF'+
		'Variable: v7='+CAST(@avar7 as varchar(50))+'***___CRLF***___CRLF'
   END
   END
   END

   if @res=NULL begin
       SET @res='NONE'
   end  

   RETURN(@res)
END

