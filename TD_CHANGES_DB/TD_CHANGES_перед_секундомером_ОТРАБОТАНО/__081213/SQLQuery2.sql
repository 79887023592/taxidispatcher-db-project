CREATE TABLE [dbo].[EVENT_TYPES](
	[ETYPE_ID] [int] IDENTITY(1,1) NOT NULL,
	[NAME] [varchar](255) NOT NULL,
	[CODE] [int] NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[EVENT_TYPES] ADD  CONSTRAINT [DF_EVENT_TYPES_NAME]  DEFAULT ('��� ������� ��� �����') FOR [NAME]
GO

ALTER TABLE [dbo].[EVENT_TYPES] ADD  CONSTRAINT [DF_EVENT_TYPES_CODE]  DEFAULT ((0)) FOR [CODE]
GO


