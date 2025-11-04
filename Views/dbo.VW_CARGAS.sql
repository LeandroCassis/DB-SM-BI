SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_CARGAS] 
AS SELECT
  UPPER(Empresa.Descricao) 'EMPRESA'
 ,Carga.Id 'ID CARGA'
 ,Carga.IdCarregadeira 'ID EQUIPAMENTO RJM'
 ,UPPER(Equipamento.Descricao) 'EQUIPAMENTO'
 ,IIF(LEFT(Equipamento.Descricao,3) = 'ESC', 'ESCAVADEIRA'
 ,IIF(LEFT(Equipamento.Descricao,2) = 'PC', 'CARREGADEIRA', 'OUTROS')) 'TIPO EQUIPAMENTO'
 ,CAST(Carga.DataInicio AS DATE) 'DATA'
 ,Carga.DataInicio 'DATA INÍCIO'
 ,Carga.DataFim 'DATA FIM'
 ,ISNULL(Carga.TempoCarga / 3600.0, 0) '#TEMPO CARGA'
 ,Carga.IdTurno 'ID TURNO'
 ,Carga.IdOrigem 'ID ORIGEM'
 ,UPPER(COALESCE(ori.Descricao,'NÃO IDENTIFICADO')) 'ORIGEM'
 ,Carga.IdDestino 'ID DESTINO'
 ,UPPER(COALESCE(dest.Descricao,'NÃO IDENTIFICADO')) 'DESTINO'
 ,Carga.IdMaterial 'ID MATERIAL'
 ,UPPER(COALESCE(Material.Descricao, 'OCORRÊNCIA SEM MATERIAL')) 'MATERIAL'
 ,Material.IdGrupoMaterial 'ID GRUPO MATERIAL'
 ,UPPER(COALESCE(GrupoMaterial.Descricao, 'OCORRÊNCIA SEM MATERIAL')) 'GRUPO MATERIAL'
 ,UPPER(COALESCE(GRUPO_MACRO_MATERIAIS.[MACRO GRUPO], 'OCORRÊNCIA SEM MATERIAL')) 'GRUPO MACRO MATERIAL'
 ,Carga.IdOperador 'ID OPERADOR'
 ,UPPER(Operador.Nome) 'OPERADOR'
  ,REPLACE(IIF(Carga.Latitude=0,NULL,Carga.Latitude),',','.') 'LATITUDE'
 ,REPLACE(IIF(Carga.Longitude=0,NULL,Carga.Longitude),',','.') 'LONGITUDE'
 ,Carga.DataCadastro 'DATA CADASTRO'
 ,ISNULL(Carga.TempoAguardando / 3600.0, 0) '#TEMPO AGUARDANDO'
 ,Carga.IdAtividadeCarregadeira 'ID ATIVIDADE'
 ,UPPER(AtividadeCarregadeira.Descricao) 'ATIVIDADE'
 ,Carga.DataInicioEspera 'DATA INÍCIO ESPERA'
 ,Carga.DataAlteracao 'DATA ALTERAÇÃO'
 ,Carga.IdEquipamentoCarga 'ID EQUIPAMENTO CARGA'
 ,Carga.Carga 'CARGA'
 ,Carga.IdFrenteLavra 'ID FRENTE LAVRA'
 ,Carga.IdEscala 'ID ESCALA'

,CAST(SUBSTRING(cast(CAST(Carga.DataFim-Carga.DataInicio AS TIME) AS VARCHAR), 1, 2) AS DECIMAL(10, 6)) + -- Horas
(CAST(SUBSTRING(cast(CAST(Carga.DataFim-Carga.DataInicio AS TIME) AS VARCHAR), 4, 2) AS DECIMAL(10, 6)) / 60) + -- Minutos
(CAST(SUBSTRING(cast(CAST(Carga.DataFim-Carga.DataInicio AS TIME) AS VARCHAR), 7, 2) AS DECIMAL(10, 6)) / 3600) '#TEMPO ATIVIDADE'







 --,Carga.Altitude
-- ,Carga.IdCondicao
-- ,Carga.FinalizadoMovel 'FINALIZADO MÓVEL'
--,Carga.Processado 'PROCESSADO'
-- ,Carga.IdProgramacaoVenda
-- ,Carga.Placa
-- ,Carga.IdPlanta
-- ,Carga.Quantidade
-- ,Carga.IdPilhaOrigem
-- ,Carga.IdCentroCusto
-- ,Carga.IdUsuarioAlteracao
-- ,Carga.Alternancia
-- ,Carga.IdDespachoInfraestruturaAtividade
-- ,Carga.InformacaoSelecionadaExpedicao
FROM RajaMine.dbo.Carga WITH (NOLOCK)




LEFT JOIN RajaMine.dbo.Equipamento WITH (NOLOCK)
  ON Carga.IdCarregadeira = Equipamento.Id 

LEFT JOIN RajaMine.dbo.Empresa
ON RajaMine.dbo.Equipamento.IdEmpresa = Empresa.Id


LEFT JOIN RajaMine.dbo.Operador WITH (NOLOCK)
  ON Operador.Id = Carga.IdOperador

LEFT JOIN RajaMine.dbo.Local ori WITH (NOLOCK)
  ON Carga.IdOrigem = ori.Id 

LEFT JOIN RajaMine.dbo.Local dest WITH (NOLOCK)
  ON Carga.IdDestino = dest.Id

LEFT JOIN RajaMine.dbo.Material WITH (NOLOCK)
  ON Carga.IdMaterial = Material.Id 

LEFT JOIN RajaMine.dbo.GrupoMaterial WITH (NOLOCK)
  ON Material.IdGrupoMaterial = GrupoMaterial.Id

LEFT JOIN  GRUPO_MACRO_MATERIAIS WITH (NOLOCK)
ON GrupoMaterial.Id = GRUPO_MACRO_MATERIAIS.[ID GRUPO MATERIAL]

LEFT JOIN RajaMine.dbo.AtividadeCarregadeira  WITH (NOLOCK)
ON RajaMine.dbo.Carga.IdAtividadeCarregadeira = AtividadeCarregadeira.Id

--WHERE Carga.FinalizadoMovel = 'S'
GO