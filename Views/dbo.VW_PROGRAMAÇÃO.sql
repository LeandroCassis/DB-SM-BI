SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_PROGRAMAÇÃO] 
AS SELECT 
HorasProgramadas.IdEmpresa 'ID EMPRESA',
UPPER(Empresa.descricao) 'EMPRESA',
HorasProgramadasEquipamento.Id 'ID HORAS PROGRAMADAS EQ',
--VW_EQUIPAMENTOS.[COD EQUIPAMENTO] 'COD EQUIPAMENTO',
HorasProgramadasEquipamento.IdEquipamento 'ID EQUIPAMENTO RJM',
UPPER(TipoEquipamento.Descricao) 'TIPO EQUIPAMENTO RAJAMINE',
--IIF(CHARINDEX('(Externo)', TipoEquipamento.Descricao) > 0 , 'NÃO', 'SIM') 'CONTROLA',
CONCAT_WS('-',HorasProgramadasEquipamento.IdEquipamento,UPPER(IIF(RIGHT(Equipamento.Descricao COLLATE SQL_Latin1_General_CP1_CI_AS, 5) = '(TSL)', Equipamento.Descricao COLLATE SQL_Latin1_General_CP1_CI_AS, COALESCE( VW_EQUIPAMENTOS.EQUIPAMENTO COLLATE SQL_Latin1_General_CP1_CI_AS ,'EQUIPAMENTO NÃO VINCULADO!')))) 'KEY EQUIPAMENTO',
UPPER(IIF(RIGHT(Equipamento.Descricao COLLATE SQL_Latin1_General_CP1_CI_AS, 5) = '(TSL)', Equipamento.Descricao COLLATE SQL_Latin1_General_CP1_CI_AS, COALESCE( VW_EQUIPAMENTOS.EQUIPAMENTO COLLATE SQL_Latin1_General_CP1_CI_AS ,'EQUIPAMENTO NÃO VINCULADO!'))) AS 'EQUIPAMENTO',
IIF(RIGHT(Equipamento.Descricao COLLATE SQL_Latin1_General_CP1_CI_AS, 5) = '(TSL)', 'EQUIPAMENTO DE TERCEIROS', COALESCE( VW_EQUIPAMENTOS.TIPO COLLATE SQL_Latin1_General_CP1_CI_AS ,'EQUIPAMENTO NÃO VINCULADO!')) AS 'TIPO',
--HorasProgramadasEquipamento.IdEquipamento 'ID EQUIPAMENTO',
HorasProgramadas.Id 'ID HORAS PROGRAMADAS',
HorasProgramadas.Data 'DATA',
HorasProgramadas.IdTurno 'ID TURNO',
HorasProgramadas.HoraIni 'HORA INICIO',
HorasProgramadas.HoraFim 'HORA FIM',
--IIF(
--RajaMine.dbo.[Fn_HorasPassadasEquipamento](HorasProgramadas.HoraIni,HorasProgramadas.HoraFim,HorasProgramadas.Data,HorasProgramadas.Horas,equipamento.id) 
--=0,HorasProgramadas.Horas,
--RajaMine.dbo.[Fn_HorasPassadasEquipamento](HorasProgramadas.HoraIni,HorasProgramadas.HoraFim,HorasProgramadas.Data,HorasProgramadas.Horas,equipamento.id)) '#HORAS PROGRAMADAS',
HorasProgramadas.Horas '#HORAS PROGRAMADAS',
HorasProgramadas.HorasMinutos '#MINUTOS PROGRAMADOS',
HorasProgramadas.TipoProgramacao 'TIPO PROGRAMAÇÃO'



FROM  RajaMine.dbo.equipamento  WITH (NOLOCK)
INNER JOIN  RajaMine.dbo.HorasProgramadasEquipamento
ON equipamento.Id = RajaMine.dbo.HorasProgramadasEquipamento.IdEquipamento

LEFT JOIN RajaMine.dbo.TipoEquipamento  WITH (NOLOCK)
ON Equipamento.IdTipoEquipamento = TipoEquipamento.Id

LEFT JOIN RajaMine.dbo.HorasProgramadas WITH (NOLOCK)
ON HorasProgramadasEquipamento.IdHorasProgramadas = HorasProgramadas.Id


LEFT JOIN RajaMine.dbo.Empresa ON RajaMine.dbo.HorasProgramadas.IdEmpresa = Empresa.Id


LEFT JOIN VW_EQUIPAMENTOS WITH (NOLOCK)
ON HorasProgramadasEquipamento.IdEquipamento =  VW_EQUIPAMENTOS.[ID EQUIPAMENTO RJM]

--LEFT JOIN  RajaMine.dbo.Equipamento WITH (NOLOCK)
--ON HorasProgramadasEquipamento.IdEquipamento =  Equipamento.Id

WHERE YEAR(HorasProgramadas.Data) >= 2023
--AND VW_EQUIPAMENTOS.CONTROLA = 'SIM'
--WHERE IdEquipamento = '127'
GO