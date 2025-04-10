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
  puts "🔵 Criando issue: #{titulo.strip}"

  if DRY_RUN
    puts "[DRY-RUN] Criar issue:"
    puts "Título: \"#{titulo.strip}\""
    puts "Body:\n#{descricao}"
    puts "Repo: #{REPO}"
    puts "---"
    return
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
  url = result["url"]
  number = result["number"]

  puts "✅ Issue criada: #{url}"

  adicionar_ao_projeto(url)
  vincular_ao_epico(number)
end

def adicionar_ao_projeto(issue_url)
  puts "📋 Adicionando no projeto..."

  if DRY_RUN
    puts "[DRY-RUN] Adicionar ao projeto:"
    puts "Project ID: #{PROJECT_ID}"
    puts "Issue URL: #{issue_url}"
    puts "---"
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
  puts "🔗 Vinculando ao épico..."

  if DRY_RUN
    puts "[DRY-RUN] Vincular ao épico:"
    puts "Issue Child: #{issue_number}"
    puts "Parent Epic: #{EPICO_ID}"
    puts "---"
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
      criar_issue(current_title, descricao_final)
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
  criar_issue(current_title, descricao_final)
end

puts "🏁 Todas as User Stories foram processadas!"
