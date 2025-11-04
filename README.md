# DB-SM-BI

## Overview
- Empresa: Vesperttine (vesperttine.com)
- Desenvolvedor responsável: Leandro Assis
- Cliente atendido: SM Metais
- Escopo: Camada central de Business Intelligence que consolida dados corporativos da SM Metais.
- Papel do projeto: integra processos de ETL e armazenamento analítico unificando informações provenientes dos ERPs SAPIENS, Rajamine, Engeman e demais fontes estratégicas.

## Arquitetura e Integrações
- Rotinas de ETL extraem e harmonizam dados das diversas plataformas operacionais da SM Metais, aplicando regras de limpeza, transformação e enriquecimento antes do carregamento.
- Organização recomendada em camadas: *staging* (dados brutos por origem), *core* (modelagem unificada relacional/dimensional) e *analytics* (estruturas voltadas a dashboards corporativos e indicadores executivos).
- Novas integrações devem respeitar contratos de dados definidos na camada *core*, garantindo rastreabilidade e versionamento entre sistemas.

## Estrutura Inicial do Repositório
```
DB-SM-BI/
├─ README.md
└─ (scripts ETL, dicionários de dados e diagramas serão adicionados conforme evolução)
```

## Como Começar
1. Clone o repositório: `git clone https://github.com/LeandroCassis/DB-SM-BI.git`
2. Solicite credenciais e parâmetros de conexão conforme padrões internos da Vesperttine.
3. Documente novos scripts ETL com comentários concisos e atualize o README ao introduzir rotinas ou estruturas relevantes.

## Governança
- Utilize *issues* e *pull requests* para versionar alterações de ETL e schema.
- Siga convenções de nomenclatura da Vesperttine para tabelas, *views* e jobs.
- Documente dependências externas (drivers, pacotes, agendadores) nos repositórios compartilhados do time de BI.

## Suporte
- Site corporativo: [vesperttine.com](https://vesperttine.com)
- Demandas operacionais devem ser direcionadas ao time de BI da Vesperttine.
