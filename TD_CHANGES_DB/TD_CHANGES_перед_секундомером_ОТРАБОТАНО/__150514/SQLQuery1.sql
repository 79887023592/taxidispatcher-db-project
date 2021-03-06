USE [TD5R1]
GO

/****** Object:  Table [dbo].[TD_DAY_CALENDAR]    Script Date: 05/15/2014 16:32:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TD_DAY_CALENDAR](
	[CDAY_ITEM_ID] [int] IDENTITY(1,1) NOT NULL,
	[DAY_DATE] [date] NOT NULL,
	[ON_DAY_SUMM_FIXED] [smallint] NOT NULL
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[TD_DAY_CALENDAR] ADD  CONSTRAINT [DF_TD_DAY_CALENDAR_DAY_DATE]  DEFAULT (getdate()) FOR [DAY_DATE]
GO

ALTER TABLE [dbo].[TD_DAY_CALENDAR] ADD  CONSTRAINT [DF_TD_DAY_CALENDAR_ON_DAY_SUMM_FIXED]  DEFAULT ((0)) FOR [ON_DAY_SUMM_FIXED]
GO


