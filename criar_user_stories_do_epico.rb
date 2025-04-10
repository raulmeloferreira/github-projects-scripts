#!/usr/bin/env ruby

require 'open3'
require 'json'

# ======= CONFIGURAÇÕES =======
REPO = "sua-org/seu-repo" # <-- ajuste seu repositório aqui
PROJECT_ID = "PVT_abc123XYZ" # <-- ajuste seu Project ID aqui
EPICO_ID = "123" # <-- ajuste o número da issue do épico principal aqui
ARQUIVO_EPICO = ARGV[0]

if ARQUIVO_EPICO.nil?
  puts "Uso: ruby criar_user_stories_do_epico.rb <arquivo-epico.md>"
  exit 1
end

# ======= FUNÇÕES =======

def criar_issue(titulo, descricao)
  puts "🔵 Criando issue: #{titulo.strip}"

  cmd_create = [
    "gh", "issue", "create",
    "--title", titulo.strip,
    "--body", descricao.strip,
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

File.foreach(ARQUIVO_EPICO) do |linha|
  if linha.start_with?("User Story")
    if current_title
      criar_issue(current_title, current_description)
    end
    current_title = linha.chomp
    current_description = ""
  else
    current_description += linha
  end
end

# Criar a última user story
if current_title
  criar_issue(current_title, current_description)
end

puts "🏁 Todas as User Stories foram criadas com sucesso!"
