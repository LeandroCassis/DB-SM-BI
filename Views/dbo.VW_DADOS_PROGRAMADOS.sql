SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_DADOS_PROGRAMADOS] 
AS SELECT 

CAST(HorasProgramadas.DATA AS DATE) 'DATA',
CAST(DATEADD(month, DATEDIFF(month, 0, HorasProgramadas.DATA), 0) AS DATE) 'MÊS',
HorasProgramadasEquipamento.IdEquipamento 'ID EQUIPAMENTO RJM',
MAX(_RESUMO.[DIAS PROGRAMADOS MÊS]) 'DIAS PROGRAMADOS MÊS'

FROM RajaMine.dbo.HorasProgramadasEquipamento WITH (NOLOCK)
LEFT JOIN RajaMine.dbo.HorasProgramadas  WITH (NOLOCK)
ON HorasProgramadasEquipamento.IdHorasProgramadas = HorasProgramadas.Id
LEFT JOIN (
SELECT 
CAST(DATEADD(month, DATEDIFF(month, 0, HorasProgramadas.DATA), 0) AS DATE) 'INÍCIO DO MÊS',
HorasProgramadasEquipamento.IdEquipamento 'ID EQUIPAMENTO RJM',
COUNT(DISTINCT HorasProgramadas.DATA) 'DIAS PROGRAMADOS MÊS'
FROM RajaMine.dbo.HorasProgramadasEquipamento WITH (NOLOCK)
LEFT JOIN RajaMine.dbo.HorasProgramadas  WITH (NOLOCK)
ON HorasProgramadasEquipamento.IdHorasProgramadas = HorasProgramadas.Id

WHERE YEAR(HorasProgramadas.DATA)  >= 2024

GROUP BY 
CAST(DATEADD(month, DATEDIFF(month, 0, HorasProgramadas.DATA), 0) AS DATE),
HorasProgramadasEquipamento.IdEquipamento 

) _RESUMO


ON CAST(DATEADD(month, DATEDIFF(month, 0, HorasProgramadas.DATA), 0) AS DATE) = _RESUMO.[INÍCIO DO MÊS]
AND HorasProgramadasEquipamento.IdEquipamento = _RESUMO.[ID EQUIPAMENTO RJM]

LEFT JOIN VW_EQUIPAMENTOS
ON HorasProgramadasEquipamento.IdEquipamento = VW_EQUIPAMENTOS.[ID EQUIPAMENTO RJM]



WHERE YEAR(HorasProgramadas.DATA)  >= 2024
--AND VW_EQUIPAMENTOS.CONTROLA = 'SIM'

GROUP BY CAST(HorasProgramadas.DATA AS DATE), HorasProgramadasEquipamento.IdEquipamento 
GO