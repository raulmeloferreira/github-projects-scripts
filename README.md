# Criar User Stories a partir de um Arquivo de Épico

Este script em Ruby permite:
- Ler um arquivo com várias User Stories
- Criar issues automaticamente no GitHub
- Adicionar cada issue a um ProjectV2
- Vincular cada issue como "child" de um Épico existente

## Como usar

1. Edite o script para configurar:
   - `REPO`: seu repositório (ex: `sua-org/seu-repo`)
   - `PROJECT_ID`: ID do seu projeto (formato `PVT_xxx`)
   - `EPICO_ID`: número da issue do épico pai

2. Tenha um arquivo `.md` estruturado assim:

```markdown
User Story 1: Exemplo de User Story

Description:
Como um usuário, quero fazer algo para alcançar algum objetivo.

Acceptance Criteria:
- [ ] Critério 1
- [ ] Critério 2

Tasks:
- Tarefa 1
- Tarefa 2

User Story 2: Outro exemplo

Description:
...
```

3. Execute o script:

```bash
ruby criar_user_stories_do_epico.rb caminho/para/arquivo.md
```

4. (Opcional) Para apenas visualizar os comandos sem executar:

```bash
ruby criar_user_stories_do_epico.rb caminho/para/arquivo.md --dry-run
```

## Pré-requisitos

- Ruby instalado
- GitHub CLI (`gh`) instalado e autenticado
- Permissão para criar issues e editar projetos

## Observações

- Cada User Story no arquivo deve começar com "User Story"
- O script cria as issues, adiciona ao projeto e vincula ao épico automaticamente

---
