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

def executar_comando(cmd_array)
  puts "🔹 Comando a executar:"
  puts cmd_array.map { |c| c.include?(' ') ? "\"#{c}\"" : c }.join(' ')
  puts "-----------------------------------"

  if DRY_RUN
    return
  end

  stdout, stderr, status = Open3.capture3(*cmd_array)

  unless status.success?
    puts "❌ Erro na execução: #{stderr}"
    exit 1
  end

  stdout
end

def criar_issue(titulo, descricao)
  titulo_escapado = titulo.strip.gsub('"', '\"')
  body_escapado = descricao.gsub('"', '\"').gsub("\n", "\\n")

  cmd = [
    "gh", "issue", "create",
    "--title", titulo_escapado,
    "--body", body_escapado,
    "--repo", REPO
  ]

  stdout = executar_comando(cmd)

  unless DRY_RUN
    puts stdout
    puts "👉 Informe o número da issue criada (visível no GitHub, ou na saída acima):"
    print "> "
    issue_number = gets.strip
    issue_number
  else
    nil
  end
end

def adicionar_ao_projeto(issue_url)
  cmd = [
    "gh", "project", "item-add",
    PROJECT_ID,
    "--url", issue_url
  ]

  executar_comando(cmd)
end

def vincular_ao_epico(issue_number)
  cmd = [
    "gh", "issue", "edit",
    issue_number,
    "--add-linked-issue", EPICO_ID,
    "--link-type", "parent"
  ]

  executar_comando(cmd)
end

def processar_user_story(titulo, descricao)
  issue_number = criar_issue(titulo, descricao)

  if issue_number.nil? && DRY_RUN
    puts "# Depois que criar a issue acima, pegue a URL e o número para seguir:"
    puts "gh project item-add #{PROJECT_ID} --url <url-da-issue>"
    puts "gh issue edit <numero-da-issue> --add-linked-issue #{EPICO_ID} --link-type parent"
    puts "---"
  elsif issue_number
    issue_url = "https://github.com/#{REPO}/issues/#{issue_number}"

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
