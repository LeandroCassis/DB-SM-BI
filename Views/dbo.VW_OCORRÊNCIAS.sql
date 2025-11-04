SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_OCORRÊNCIAS] 
AS SELECT
Ocorrencia.Id 'ID OCORRÊNCIA',
 Empresa.Descricao 'EMPRESA'
,Equipamento.IdEmpresa 'ID EMPRESA'
,Equipamento.Id 'ID EQUIPAMENTO RJM'
,VW_EQUIPAMENTOS.TIPO 'TIPO'
,VW_EQUIPAMENTOS.[KEY EQUIPAMENTO] 'KEY EQUIPAMENTO'
,VW_EQUIPAMENTOS.EQUIPAMENTO 'EQUIPAMENTO'
,IIF(FlDisponibilidadeFisica = 'S', 'DISPONIBILIDADE',
IIF(FlUtilizacao = 'S', 'UTILIZAÇÃO', 'OUTRAS')) 'INTERFERÊNCIA' 
,UPPER(Operador.Nome) 'OPERADOR'
,UPPER(Turno.Descricao) 'TURNO'
,ClasseOcorrencia.Id 'ID CLASSE OCORRÊNCIA'
,UPPER(ClasseOcorrencia.Descricao) 'CLASSE OCORRÊNCIA'
,CASE 
WHEN ClasseOcorrencia.Tipo = 0 THEN 'red'
WHEN ClasseOcorrencia.Tipo = 2 THEN 'orange' ELSE 'green' END AS 'COR CLASSE'
,TipoOcorrencia.Id 'ID TIPO OCORRÊNCIA'
,UPPER(TipoOcorrencia.Descricao) 'TIPO OCORRÊNCIA'
,CAST(Ocorrencia.Data AS DATE) 'DATA'
,Ocorrencia.Data 'DATA INÍCIO'
,Ocorrencia.DataFim 'DATA FIM'
,ISNULL(AVG(Ocorrencia.SegundosOcorrencias / 3600.0), 0) '#HORAS OCORRÊNCIA'

,IIF(TipoOcorrencia.FlUtilizacao = 'S', 'SIM', 'NÃO') 'TIPO UTILIZAÇÃO'
,IIF(TipoOcorrencia.FlDisponibilidadeFisica = 'S', 'SIM', 'NÃO') 'TIPO DF'

 ,Ocorrencia.IdViagem 'ID VIAGEM'
-- ,VW_EQUIPAMENTOS.CONTROLA




FROM RajaMine.dbo.Ocorrencia WITH (NOLOCK)
LEFT OUTER JOIN RajaMine.dbo.HorasProgramadas  WITH (NOLOCK)
ON HorasProgramadas.IdTurno = Ocorrencia.IdTurno
AND HorasProgramadas.Data = CAST(Ocorrencia.Data AS DATE)

LEFT JOIN RajaMine.dbo.HorasProgramadasEquipamento  WITH (NOLOCK)
ON HorasProgramadasEquipamento.IdHorasProgramadas = HorasProgramadas.Id
AND HorasProgramadasEquipamento.IdEquipamento = Ocorrencia.IdEquipamento

LEFT JOIN RajaMine.dbo.Equipamento WITH (NOLOCK)
ON  Equipamento.Id = Ocorrencia.IdEquipamento

LEFT JOIN RajaMine.dbo.TipoEquipamento  WITH (NOLOCK)
ON Equipamento.IdTipoEquipamento = TipoEquipamento.Id

LEFT JOIN RajaMine.dbo.Operador WITH (NOLOCK)
ON Operador.Id = Ocorrencia.IdOperador

LEFT JOIN RajaMine.dbo.Turno  WITH (NOLOCK)
ON Turno.Id = Ocorrencia.IdTurno

LEFT JOIN RajaMine.dbo.Meta WITH (NOLOCK)
ON Meta.IdTurno = Turno.Id
AND Meta.IdTipoEquipamento =  Equipamento.IdTipoEquipamento

LEFT JOIN RajaMine.dbo.ClasseOcorrencia  WITH (NOLOCK)
ON ClasseOcorrencia.Id = Ocorrencia.IdClasseOcorrencia

LEFT JOIN RajaMine.dbo.TipoOcorrencia WITH (NOLOCK)
ON TipoOcorrencia.Id = Ocorrencia.IdTipoOcorrencia

LEFT JOIN RajaMine.dbo.Empresa WITH (NOLOCK)
ON Empresa.Id =  Equipamento.IdEmpresa


LEFT JOIN BI.dbo.VW_EQUIPAMENTOS WITH (NOLOCK)
ON Equipamento.Id =  VW_EQUIPAMENTOS.[ID EQUIPAMENTO RJM]


WHERE Ocorrencia.DataFim IS NOT NULL
AND YEAR(Ocorrencia.Data) >= 2023
--AND VW_EQUIPAMENTOS.CONTROLA = 'SIM'

GROUP BY  
Ocorrencia.Id,
Ocorrencia.Data
,TipoOcorrencia.Id
,Equipamento.IdEmpresa
,HorasProgramadas.Horas
,Equipamento.Id
,Equipamento.Descricao
,Operador.Nome
,Turno.Descricao
,ClasseOcorrencia.Descricao
,TipoOcorrencia.Descricao
,CAST(Ocorrencia.Data AS DATE)
,DataFim
,ClasseOcorrencia.Id
,SegundosOcorrencias
,Empresa.Descricao 
,TipoOcorrencia.FlUtilizacao
,TipoOcorrencia.FlDisponibilidadeFisica
,VW_EQUIPAMENTOS.TIPO 
,VW_EQUIPAMENTOS.[KEY EQUIPAMENTO]
,VW_EQUIPAMENTOS.EQUIPAMENTO
 ,Ocorrencia.IdViagem
--,VW_EQUIPAMENTOS.CONTROLA
,CASE 
WHEN ClasseOcorrencia.Tipo = 0 THEN 'red'
WHEN ClasseOcorrencia.Tipo = 2 THEN 'orange' ELSE 'green' END
GO