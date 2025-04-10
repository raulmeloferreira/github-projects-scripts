#!/usr/bin/env ruby

require 'open3'
require 'json'

# ======= CONFIGURAÇÕES =======
REPO = "sua-org/seu-repo" # <-- ajuste seu repositório
PROJECT_ID = "PVT_abc123XYZ" # <-- ajuste seu Project ID
EPICO_ID = "123" # <-- ajuste o número da issue do épico
ARQUIVO_EPICO = ARGV[0]
DRY_RUN = ARGV.include?('--dry-run')

if ARQUIVO_EPICO.nil? || ARQUIVO_EPICO.start_with?('--')
  puts "Uso: ruby criar_user_stories_do_epico.rb <arquivo-epico.md> [--dry-run]"
  exit 1
end

# ======= FUNÇÕES =======

def criar_issue(titulo, descricao)
  titulo_escapado = titulo.strip.gsub('"', '\"')
  body_escapado = descricao.strip.gsub('"', '\"').gsub("\n", "\\n")

  if DRY_RUN
    puts "gh issue create --title \"#{titulo_escapado}\" --body \"#{body_escapado}\" --repo #{REPO} --json url,number"
    return nil
  end

  cmd_create = [
    "gh", "issue", "create",
    "--title", titulo.strip,
    "--body", descricao,
    "--repo", REPO,
    "--json", "url,number"
  ]

  stdout, stderr, status = Open3.capture3(*cmd_create)

  unless status.success?
    puts "❌ Erro ao criar issue: #{stderr}"
    exit 1
  end

  result = JSON.parse(stdout)
  result
end

def adicionar_ao_projeto(issue_url)
  if DRY_RUN
    puts "gh project item-add #{PROJECT_ID} --url #{issue_url}"
    return
  end

  cmd_add = [
    "gh", "project", "item-add", PROJECT_ID,
    "--url", issue_url
  ]

  stdout, stderr, status = Open3.capture3(*cmd_add)

  unless status.success?
    puts "❌ Erro ao adicionar no projeto: #{stderr}"
    exit 1
  end
end

def vincular_ao_epico(issue_number)
  if DRY_RUN
    puts "gh issue edit #{issue_number} --add-linked-issue #{EPICO_ID} --link-type parent"
    return
  end

  cmd_link = [
    "gh", "issue", "edit", issue_number.to_s,
    "--add-linked-issue", EPICO_ID,
    "--link-type", "parent"
  ]

  stdout, stderr, status = Open3.capture3(*cmd_link)

  unless status.success?
    puts "❌ Erro ao vincular ao épico: #{stderr}"
    exit 1
  end
end

# ======= PROCESSAR ARQUIVO =======

current_title = nil
current_description = ""
buffer = []

def processar_descricao(buffer)
  buffer.join
end

File.foreach(ARQUIVO_EPICO) do |linha|
  if linha.start_with?("User Story")
    if current_title
      descricao_final = processar_descricao(buffer)
      processar_user_story(current_title, descricao_final)
    end
    current_title = linha.chomp
    buffer = []
  else
    buffer << linha
  end
end

# Criar a última user story
if current_title
  descricao_final = processar_descricao(buffer)
  processar_user_story(current_title, descricao_final)
end

puts "🏁 Todas as User Stories foram processadas!"

# ======= PROCESSAR UMA USER STORY =======

def processar_user_story(titulo, descricao)
  result = criar_issue(titulo, descricao)

  if DRY_RUN
    # No dry-run, temos que simular os comandos seguintes manualmente
    # Assumimos que o número da issue será conhecido depois da criação
    puts "# Depois que criar a issue acima, usar o número retornado para adicionar ao projeto e vincular ao épico:"
    puts "gh project item-add #{PROJECT_ID} --url <url-da-issue>"
    puts "gh issue edit <numero-da-issue> --add-linked-issue #{EPICO_ID} --link-type parent"
    puts "---"
  else
    issue_url = result["url"]
    issue_number = result["number"]

    adicionar_ao_projeto(issue_url)
    vincular_ao_epico(issue_number)
  end
end
