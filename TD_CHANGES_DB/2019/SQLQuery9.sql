USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_ORDER_INSERT]    Script Date: 17.02.2019 0:35:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[AFTER_ORDER_INSERT] 
   ON  [dbo].[Zakaz] 
   AFTER INSERT
AS 
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @db_version int, @prize_reserved_limit smallint, 
	@lock_reserv_on_limit smallint;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@prize_reserved_limit = prize_reserved_limit,
	@lock_reserv_on_limit = lock_reserv_on_limit 
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	if(@db_version>=5)
	BEGIN	
		
		DECLARE @newId INT, @nNewValue int, 
		@order_count int, @NewArhValue int, 
		@NewComplValue int, @newDrId int,
		@dr_sect int, @newEndSect int, 
		@endSectNum int, @newPhone varchar(255), 
		@newAdr varchar(255), @newINum varchar(255),
		@ordDictItCount int,
		@view_bonus int, @view_ab_bonus int,
		@bonus_num int, @bonus_count int, 
		@ab_bonus_count int, @use_ab_account int,
		@newDrNum int,
		@prise_only_online smallint,
		@rclient_id int;
		
		SET @view_bonus=0;
		SET @view_ab_bonus=0;
		SET @bonus_count=0;
		SET @ab_bonus_count=0;
		SET @use_ab_account=0;
	
		SELECT TOP 1 @view_bonus=ISNULL(view_bonuses,0),
			@view_ab_bonus=ISNULL(view_ab_bonuses,0),
			@use_ab_account = ISNULL(use_ab_account,0),
			@prise_only_online = prise_only_online 
		FROM Objekt_vyborki_otchyotnosti
		WHERE Tip_objekta='for_drivers';
		
		SELECT @newId=a.BOLD_ID, 
		@nNewValue=a.REMOTE_SET,
		@NewArhValue=a.Arhivnyi,
		@NewComplValue=a.Zavershyon,
		@newDrId = a.vypolnyaetsya_voditelem,
		@newEndSect = a.konechnyi_sektor_raboty,
		@newPhone = a.Telefon_klienta,
		@newAdr = a.Adres_vyzova_vvodim,
		@newINum = a.Adres_okonchaniya_zayavki,
		@newDrNum = ISNULL(a.REMOTE_DRNUM,0),
		@rclient_id = a.rclient_id
		FROM inserted a
		
		UPDATE Zakaz
		SET Nachalo_zakaza_data=GETDATE()
		WHERE BOLD_ID=@newId;

		IF @nNewValue=100 
		BEGIN
			DELETE FROM ORDER_ACCEPTING WHERE 
			ORDER_ACCEPTING.ORDER_ID=@newId;
		END;
	
		DECLARE @inum_count int, @inum_int int,
			@inum_phone varchar(255), @inum_adr varchar(255);
	
		IF ((ISNULL(@newINum,'')<>'') AND (@use_ab_account>0))
		BEGIN
		
			IF (ISNUMERIC(@newINum)=1)
			BEGIN
				SET @inum_int = CAST(@newINum AS int);
				
				SET @inum_int = ISNULL(@inum_int,-1);
				
				SELECT @inum_count=COUNT(*)
				FROM Persona
				WHERE Korpus=@inum_int AND 
				Elektronnyi_adres='Индивидуальный клиент';
				
				IF (@inum_count>0)
				BEGIN
				
					--возможно использ доп усл в запросе???
					UPDATE Persona 
					SET Dom=Dom+1 
					WHERE Korpus=@inum_int AND 
					Elektronnyi_adres='Индивидуальный клиент' AND 
					(RESERVED_PRESENTS < @prize_reserved_limit OR @lock_reserv_on_limit <= 0 
					OR @prize_reserved_limit <= 0);
				
					SELECT TOP 1
					@inum_phone=Rabochii_telefon,
					@inum_adr=Ulica,
					@ab_bonus_count=Dom
					FROM Persona
					WHERE Korpus=@inum_int AND 
					Elektronnyi_adres='Индивидуальный клиент';
					
					SET @bonus_num=0;
					SET @inum_phone = ISNULL(@inum_phone,'');
					SET @inum_adr = ISNULL(@inum_adr,'');
					SET @ab_bonus_count = ISNULL(@ab_bonus_count,0);
					
					if ((@view_ab_bonus>0) AND 
						(@ab_bonus_count>0) and
						(@rclient_id > 0 OR @prise_only_online <> 1))
					begin
						SELECT @bonus_num=
							dbo.GetDiscountNumOnOrderCount
							(@ab_bonus_count);
					end;
					
					SET @bonus_num=ISNULL(@bonus_num,0);
					
					if ((ISNULL(@newPhone,'')='') AND 
						NOT (ISNULL(@inum_phone,'')=''))
					BEGIN
						UPDATE Zakaz 
						SET Telefon_klienta=@inum_phone
						FROM Zakaz JOIN inserted i
						ON Zakaz.BOLD_ID=i.BOLD_ID;
					END;
					
					if (NOT ISNULL(@newAdr,'')='')
					BEGIN
						SET @inum_adr=@newAdr;
					END;
					
					if ( ((ISNULL(@newAdr,'')='') AND 
						NOT (ISNULL(@inum_adr,'')='')) OR 
						(@bonus_num>0))
					BEGIN
						UPDATE Zakaz 
						SET Adres_vyzova_vvodim=@inum_adr,
							Nomer_skidki=@bonus_num
						FROM Zakaz JOIN inserted i
						ON Zakaz.BOLD_ID=i.BOLD_ID;
					END;
					
				END;
					
			END;
			
		END;
		
		DECLARE @dict_adr varchar(255);
		SET @dict_adr='';
		SET @inum_adr='';
		SET @inum_count=0;
		SET @inum_int=0;
	
		IF ((ISNULL(@newPhone,'')<>'') OR 
			(ISNULL(@newAdr,'')<>''))
		BEGIN
			UPDATE Zakaz 
			SET Nachalo_zakaza_data=CURRENT_TIMESTAMP,
				Data_podachi=CURRENT_TIMESTAMP
			FROM Zakaz JOIN inserted i
			ON Zakaz.BOLD_ID=i.BOLD_ID;
			
			if (ISNULL(@newPhone,'')<>'')
			begin
						
				IF(NOT (ISNULL(@newPhone,'')=''))
				BEGIN
				
					DECLARE @bad_count int,
						@bad_adr varchar(255);
						
					SET @bad_adr='';
				
					SELECT @bad_count=COUNT(*)	
					FROM Plohie_klienty 
					WHERE Telefon_klienta=@newPhone;
					
					IF (@bad_count>0)
					BEGIN
					
						SELECT TOP 1 @bad_adr=Adres_vyzova_vvodim	
						FROM Plohie_klienty 
						WHERE Telefon_klienta=@newPhone;
						
						SET @bad_adr=ISNULL(@bad_adr,'');
					
						UPDATE Zakaz 
						SET Nomer_skidki=-1000,
							Adres_vyzova_vvodim=@bad_adr
						FROM Zakaz JOIN inserted i
						ON Zakaz.BOLD_ID=i.BOLD_ID;
					END;
				
					UPDATE Sootvetstvie_parametrov_zakaza
					SET Summarn_chislo_vyzovov=
						Summarn_chislo_vyzovov+1
					WHERE Telefon_klienta=@newPhone;
					
					IF ((@use_ab_account>0) AND 
						(ISNULL(@newINum,'')=''))
					BEGIN
					
						SELECT @inum_count=COUNT(*)
						FROM Persona
						WHERE Rabochii_telefon=@newPhone AND 
						Elektronnyi_adres='Индивидуальный клиент';
						
						IF (@inum_count>0)
						BEGIN
						
							SELECT TOP 1
							@inum_adr=Ulica,
							@inum_int=Korpus
							FROM Persona
							WHERE Rabochii_telefon=@newPhone AND 
							Elektronnyi_adres='Индивидуальный клиент';
							
							SET @inum_int=ISNULL(@inum_int, 0);
							
							IF (@inum_int>0)
							BEGIN
								if ((NOT ISNULL(@newAdr,'')='') OR 
									(ISNULL(@inum_adr,'')='')) 
									
								BEGIN
									UPDATE Zakaz 
									SET Adres_okonchaniya_zayavki=@inum_int
									FROM Zakaz JOIN inserted i
									ON Zakaz.BOLD_ID=i.BOLD_ID;
								END
								ELSE
								BEGIN
									UPDATE Zakaz 
									SET Adres_vyzova_vvodim=(ISNULL(@bad_adr,'')+@inum_adr),
										Adres_okonchaniya_zayavki=@inum_int
									FROM Zakaz JOIN inserted i
									ON Zakaz.BOLD_ID=i.BOLD_ID;
								END;
							END;
							
						END;
						
					END;
				
					IF ((@inum_count=0) OR (ISNULL(@inum_adr,'')='') 
						OR (@use_ab_account<=0) OR (@inum_int<=0))
					BEGIN
					
						SELECT @ordDictItCount=COUNT(*)
						FROM Sootvetstvie_parametrov_zakaza
						WHERE Telefon_klienta=@newPhone;
							
						IF(@ordDictItCount>0)
						BEGIN
						
							SELECT TOP 1 @bonus_count=Summarn_chislo_vyzovov,
								@dict_adr=Adres_vyzova_vvodim
							FROM Sootvetstvie_parametrov_zakaza
							WHERE Telefon_klienta=@newPhone;
							
							SET @bonus_num=0;
							SET @bonus_count=ISNULL(@bonus_count, 0);
							SET @dict_adr=ISNULL(@dict_adr, '---');
						
							if ((@view_bonus>0) AND 
								(@bonus_count>0) and 
								@newPhone=REPLACE(@newPhone,'Фиктивная','') and
								(@rclient_id > 0 OR @prise_only_online <> 1))
							begin
								SELECT @bonus_num=
									dbo.GetDiscountNumOnOrderCount
									(@bonus_count);
							end;
							
							IF ((@bad_count>0) AND (ISNULL(@bonus_num,0)=0))
							BEGIN
								SET @bonus_num=-1000;
							END;
							
							SET @bonus_num=ISNULL(@bonus_num,0);
							
							if (@view_bonus>0)
							BEGIN
								if ((NOT ISNULL(@newAdr,'')='') OR 
									(ISNULL(@dict_adr,'')=''))
								BEGIN
									UPDATE Zakaz 
									SET Nomer_skidki=@bonus_num
									FROM Zakaz JOIN inserted i
									ON Zakaz.BOLD_ID=i.BOLD_ID;
								END
								ELSE
								BEGIN
									UPDATE Zakaz 
									SET Adres_vyzova_vvodim=(ISNULL(@bad_adr,'')+@dict_adr),
										Nomer_skidki=@bonus_num
									FROM Zakaz JOIN inserted i
									ON Zakaz.BOLD_ID=i.BOLD_ID;
								END;
							END
							ELSE
							BEGIN
								if ((ISNULL(@newAdr,'')='') AND 
								(ISNULL(@inum_adr,'')='') AND 
								((ISNULL(@dict_adr,'')<>'') OR 
								(ISNULL(@bonus_num,0)<>0) ) )
								BEGIN
									IF (@inum_count=0) 
									BEGIN
										UPDATE Zakaz 
										SET Adres_vyzova_vvodim=(ISNULL(@bad_adr,'')+@dict_adr),
										Nomer_skidki=@bonus_num
										FROM Zakaz JOIN inserted i
										ON Zakaz.BOLD_ID=i.BOLD_ID;
									END
									ELSE
									BEGIN
										UPDATE Zakaz 
										SET Adres_vyzova_vvodim=(ISNULL(@bad_adr,'')+@dict_adr)
										FROM Zakaz JOIN inserted i
										ON Zakaz.BOLD_ID=i.BOLD_ID;
									END;
								END;
							END;
							
						END;
								
					END;
				
				
				END;	
					
			end;
			
			if (ISNULL(@newAdr,'')<>'')
			BEGIN
				if((ISNULL(@newPhone,'')<>'') AND
					(ISNULL(@newAdr,'')<>''))
				BEGIN
					SELECT @ordDictItCount=COUNT(*)
					FROM Sootvetstvie_parametrov_zakaza
					WHERE Telefon_klienta=@newPhone;
					
					IF(@ordDictItCount=0)
					BEGIN
						EXEC InsertNewOrderDictItem 
							@newPhone, @newAdr,
							1, @ordDictItCount;
					END;
					
				END;
			END;
			
		END;
		
		UPDATE Personal SET EstjVneshnieManip=1;
	END;	

END
