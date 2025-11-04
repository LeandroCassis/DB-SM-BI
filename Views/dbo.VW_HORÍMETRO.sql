SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_HORÍMETRO] 
AS SELECT
  Empresa.Descricao 'EMPRESA'
 ,CAST(HorimetroKM.DataFim AS DATE) 'DATA'
 ,HorimetroKM.IdEquipamento 'ID EQUIPAMENTO RJM'
 ,UPPER(Equipamento.Descricao) 'EQUIPAMENTO'
 ,UPPER(Operador.Nome) 'OPERADOR'
 ,UPPER(Turno.Descricao) 'TURNO'
 ,HorimetroKM.DataIni 'DATA INICIAL'
 ,HorimetroKM.DataFim 'DATA FINAL'
 ,HorimetroKM.HorimetroIni 'HORÍMETRO INICIAL'
 ,HorimetroKM.HorimetroFim 'HORÍMETRO FINAL'
 ,HorimetroKM.HorimetroFim-HorimetroKM.HorimetroIni 'HORAS'
-- , IIF(HorimetroKM.DataFim IS NULL, NULL,
--    IIF(HorimetroKM.DataIni IS NULL, NULL, 
--  ROUND(DATEDIFF(SECOND, CAST(HorimetroKM.DataIni AS DATETIME), CAST(HorimetroKM.DataFim AS DATETIME)) / 3600.0, 2))) 'HORAS'

 ,HorimetroKM.KmIni 'KM INICIAL'
 ,HorimetroKM.KmFim 'KM FINAL'
 ,HorimetroKM.KmFim-HorimetroKM.KmIni 'KM'

FROM RajaMine.dbo.HorimetroKM WITH (NOLOCK)

LEFT OUTER JOIN RajaMine.dbo.Turno  WITH (NOLOCK)
ON Turno.Id = HorimetroKM.IdTurno

INNER JOIN RajaMine.dbo.Equipamento WITH (NOLOCK)
ON Equipamento.Id = HorimetroKM.IdEquipamento

LEFT OUTER JOIN RajaMine.dbo.Operador WITH (NOLOCK)
ON Operador.Id = HorimetroKM.IdOperador

LEFT JOIN RajaMine.dbo.Empresa WITH (NOLOCK)
ON Equipamento.IdEmpresa = Empresa.Id 


--LEFT JOIN VW_EQUIPAMENTOS
--ON HorimetroKM.IdEquipamento = VW_EQUIPAMENTOS.[ID EQUIPAMENTO RJM]
--AND VW_EQUIPAMENTOS.CONTROLA = 'SIM'
WHERE YEAR(HorimetroKM.DataFim) >= 2024
WITH CHECK OPTION
GO