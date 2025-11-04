SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_UTILIZAÇÃO] 
AS SELECT
HorasProgramadas.IdEmpresa 'ID EMPRESA'
,Empresa.Descricao 'EMPRESA'
,HorasProgramadas.DATA 'DATA'
--,VW_EQUIPAMENTOS.[COD EQUIPAMENTO] 'COD EQUIPAMENTO'
,HorasProgramadasEquipamento.IdEquipamento 'ID EQUIPAMENTO RJM'
,UPPER(Equipamento.Descricao) 'EQUIPAMENTO RJM'
--,UPPER(Turno.descricao) 'TURNO'
--,UPPER(TipoEquipamento.Descricao) 'TIPO EQUIPAMENTO RAJAMINE'
,VW_EQUIPAMENTOS.TIPO 'TIPO'
,VW_EQUIPAMENTOS.[KEY EQUIPAMENTO] 'KEY EQUIPAMENTO'
,VW_EQUIPAMENTOS.EQUIPAMENTO 'EQUIPAMENTO'
,SUM(oc.[#QT OCORRÊNCIAS MANUTENÇÃO]) '#QT OCORRÊNCIAS MANUTENÇÃO'
,SUM(oc.[#QT OCORRÊNCIAS UTILIZAÇÃO]) '#QT OCORRÊNCIAS UTILIZAÇÃO'
--,SUM(HorasProgramadas.Horas)'#HORAS PROGRAMADAS'
,24 AS '#HORAS PROGRAMADAS'
--,IIF(SUM(RajaMine.dbo.[Fn_HorasPassadasEquipamento](HorasProgramadas.HoraIni,HorasProgramadas.HoraFim,HorasProgramadas.Data,HorasProgramadas.Horas,equipamento.id))
--=0,SUM(HorasProgramadas.Horas),
--SUM(RajaMine.dbo.[Fn_HorasPassadasEquipamento](HorasProgramadas.HoraIni,HorasProgramadas.HoraFim,HorasProgramadas.Data,HorasProgramadas.Horas,equipamento.id)))'#HORAS PROGRAMADAS'
,IIF(HorasProgramadas.DATA>GETDATE(),NULL, COALESCE(SUM(HorasProgramadas.Horas),0)-COALESCE(IIF(ISNULL(AVG(HorasManutencao), 0) = 0, NULL, ISNULL(AVG(HorasManutencao), 0)),0)-COALESCE(IIF(ISNULL(AVG(HorasUtilizacao), 0) = 0, NULL, ISNULL(AVG(HorasUtilizacao), 0)),0)) '#HORAS TRABALHADAS'
--,ROUND(SUM(RajaMine.dbo.[Fn_HorasPassadasEquipamento](HorasProgramadas.horaini, HorasProgramadas.HoraFim, HorasProgramadas.DATA, HorasProgramadas.horas, HorasProgramadasEquipamento.IdEquipamento)), 2) '#HORAS PROGRAMADAS'
,IIF(ISNULL(AVG(HorasManutencao), 0) = 0, NULL, ISNULL(AVG(HorasManutencao), 0)) '#HORAS MANUTENÇÃO'
,IIF(ISNULL(AVG(HorasUtilizacao), 0) = 0, NULL, ISNULL(AVG(HorasUtilizacao), 0)) '#HORAS OCORRÊNCIAS'


--,_VIAGEMS_MATERIAIS.[ID MATERIAL] 'ID MATERIAL'


FROM RajaMine.dbo.HorasProgramadasEquipamento WITH (NOLOCK)
LEFT JOIN RajaMine.dbo.HorasProgramadas  WITH (NOLOCK)
ON HorasProgramadasEquipamento.IdHorasProgramadas = HorasProgramadas.Id


LEFT JOIN RajaMine.dbo.Empresa  WITH (NOLOCK)
ON RajaMine.dbo.HorasProgramadas.IdEmpresa = Empresa.Id

LEFT JOIN (
SELECT
 SUM(IIF(TipoOcorrencia.FlDisponibilidadeFisica = 'S', 1, NULL)) '#QT OCORRÊNCIAS MANUTENÇÃO'
,SUM(IIF(TipoOcorrencia.FlUtilizacao = 'S', 1, NULL)) '#QT OCORRÊNCIAS UTILIZAÇÃO'
,CONVERT(DATE, Ocorrencia.DATA, 103) dataref
,Equipamento.id IdEquipamento

,SUM(CASE
WHEN TipoOcorrencia.FlDisponibilidadeFisica = 'S' THEN (CASE
WHEN Ocorrencia.DataFim IS NULL THEN DATEDIFF(SECOND, Ocorrencia.DATA, GETDATE()) / 3600.0
ELSE Ocorrencia.SegundosOcorrenciasIndice / 3600.0
END) ELSE 0 END) HorasManutencao

,SUM(CASE
WHEN TipoOcorrencia.FlUtilizacao = 'S' THEN (CASE
WHEN Ocorrencia.DataFim IS NULL THEN DATEDIFF(SECOND, Ocorrencia.DATA, GETDATE()) / 3600.0
ELSE Ocorrencia.SegundosOcorrenciasIndice / 3600.0
END) ELSE 0 END) HorasUtilizacao

FROM RajaMine.dbo.Ocorrencia WITH (NOLOCK)

LEFT JOIN RajaMine.dbo.TipoOcorrencia WITH (NOLOCK)
ON TipoOcorrencia.id = Ocorrencia.idtipoocorrencia

LEFT JOIN RajaMine.dbo.ClasseOcorrencia WITH (NOLOCK)
ON ClasseOcorrencia.id = Ocorrencia.IdClasseOcorrencia

LEFT JOIN RajaMine.dbo.Equipamento WITH (NOLOCK)
ON Ocorrencia.IdEquipamento = Equipamento.id


WHERE YEAR(Ocorrencia.DATA)  >= 2024

GROUP BY CONVERT(DATE, Ocorrencia.DATA, 103)
,Equipamento.Id
,Equipamento.Descricao) oc


ON HorasProgramadasEquipamento.IdEquipamento = oc.IdEquipamento 
AND HorasProgramadas.DATA = oc.dataref 

LEFT JOIN  RajaMine.dbo.Equipamento WITH (NOLOCK)
ON HorasProgramadasEquipamento.IdEquipamento =  Equipamento.Id

LEFT JOIN RajaMine.dbo.TipoEquipamento  WITH (NOLOCK)
ON Equipamento.IdTipoEquipamento = TipoEquipamento.Id

LEFT JOIN BI.dbo.VW_EQUIPAMENTOS WITH (NOLOCK)
ON HorasProgramadasEquipamento.IdEquipamento =  VW_EQUIPAMENTOS.[ID EQUIPAMENTO RJM]


WHERE YEAR(HorasProgramadas.DATA)  >= 2024
--AND VW_EQUIPAMENTOS.CONTROLA = 'SIM'


GROUP BY 
HorasProgramadas.DATA
,HorasProgramadasEquipamento.IdEquipamento
,HorasProgramadas.IdEmpresa 
,Empresa.Descricao
,UPPER(Equipamento.Descricao)
,TipoEquipamento.Descricao
,VW_EQUIPAMENTOS.TIPO
,VW_EQUIPAMENTOS.[KEY EQUIPAMENTO]
,VW_EQUIPAMENTOS.EQUIPAMENTO
GO