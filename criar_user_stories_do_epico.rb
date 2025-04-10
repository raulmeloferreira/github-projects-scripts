#!/usr/bin/env ruby

require 'open3'
require 'json'

# ======= CONFIGURAÇÕES =======
REPO = "sua-org/seu-repo"          # <-- ajuste seu repositório
PROJECT_ID = "PVT_abc123XYZ"       # <-- ajuste seu Project ID
OWNER = "sua-org-ou-usuario"       # <-- ajuste o owner do projeto
EPICO_ID = "123"                   # <-- ajuste o número da issue do épico
ARQUIVO_EPICO = ARGV[0]
DRY_RUN = ARGV.include?('--dry-run')

if ARQUIVO_EPICO.nil? || ARQUIVO_EPICO.start_with?('--')
  puts "Uso: ruby criar_user_stories_do_epico.rb <arquivo-epico.md> [--dry-run]"
  exit 1
end

# ======= FUNÇÕES =======

def executar_comando(cmd_array)
  puts "🔹 Comando a executar:"
  puts cmd_array.map { |c| c.include?(' ') ? "\"#{c}\"" : c }.join(' ')
  puts "-----------------------------------"

  return "" if DRY_RUN

  stdout, stderr, status = Open3.capture3(*cmd_array)

  unless status.success?
    puts "❌ Erro na execução: #{stderr}"
    exit 1
  end

  stdout.strip
end

def criar_issue(titulo, descricao)
  titulo_limpo = titulo.strip

  cmd_create = [
    "gh", "issue", "create",
    "--title", titulo_limpo,
    "--body", descricao,
    "--repo", REPO
  ]

  url_da_issue = executar_comando(cmd_create)

  return nil if DRY_RUN

  # Agora, da URL extraímos o número da issue
  if url_da_issue =~ %r{issues/(\d+)}
    issue_number = $1
    { "url" => url_da_issue, "number" => issue_number }
  else
    puts "❌ Não foi possível extrair o número da issue da URL: #{url_da_issue}"
    exit 1
  end
end

def adicionar_ao_projeto(issue_url)
  cmd = [
    "gh", "project", "item-add",
    PROJECT_ID,
    "--owner", OWNER,
    "--url", issue_url
  ]

  executar_comando(cmd)
end

def vincular_ao_epico(issue_number)
  cmd = [
    "gh", "issue", "edit",
    issue_number.to_s,
    "--add-linked-issue", EPICO_ID,
    "--link-type", "parent"
  ]

  executar_comando(cmd)
end

def processar_user_story(titulo, descricao)
  issue_info = criar_issue(titulo, descricao)

  if DRY_RUN
    puts "# Depois que criar a issue acima, pegue a URL e o número para seguir:"
    puts "gh project item-add #{PROJECT_ID} --owner #{OWNER} --url <url-da-issue>"
    puts "gh issue edit <numero-da-issue> --add-linked-issue #{EPICO_ID} --link-type parent"
    puts "---"
  elsif issue_info
    issue_url = issue_info["url"]
    issue_number = issue_info["number"]

    adicionar_ao_projeto(issue_url)
    vincular_ao_epico(issue_number)
  end
end

def processar_descricao(buffer)
  buffer.join
end

# ======= PROCESSAR ARQUIVO =======

current_title = nil
buffer = []

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
