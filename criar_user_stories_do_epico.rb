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
    puts "gh issue create --title \"#{titulo_escapado}\" --body \"#{body_escapado}\" --repo #{REPO}"
    puts "# Depois de criar, pegue o número da issue e continue."
    return nil
  end

  cmd_create = [
    "gh", "issue", "create",
    "--title", titulo.strip,
    "--body", descricao,
    "--repo", REPO
  ]

  stdout, stderr, status = Open3.capture3(*cmd_create)

  unless status.success?
    puts "❌ Erro ao criar issue: #{stderr}"
    exit 1
  end

  puts stdout

  puts "👉 Informe o número da issue criada (visível no GitHub, ou pegue da saída acima):"
  print "> "
  issue_number = gets.strip

  issue_number
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
    "gh", "issue", "edit", issue_number,
    "--add-linked-issue", EPICO_ID,
    "--link-type", "parent"
  ]

  stdout, stderr, status = Open3.capture3(*cmd_link)

  unless status.success?
    puts "❌ Erro ao vincular ao épico: #{stderr}"
    exit 1
  end
end

def processar_user_story(titulo, descricao)
  issue_number = criar_issue(titulo, descricao)

  if DRY_RUN
    puts "# Depois que criar a issue acima, pegue a URL e o número para seguir:"
    puts "gh project item-add #{PROJECT_ID} --url <url-da-issue>"
    puts "gh issue edit <numero-da-issue> --add-linked-issue #{EPICO_ID} --link-type parent"
    puts "---"
  else
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
