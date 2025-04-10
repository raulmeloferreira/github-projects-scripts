def criar_issue(titulo, descricao)
  if DRY_RUN
    body_escapado = descricao.gsub('"', '\"').gsub("\n", "\\n")
    titulo_escapado = titulo.strip.gsub('"', '\"')

    cmd = [
      "gh issue create",
      "--title \"#{titulo_escapado}\"",
      "--body \"#{body_escapado}\"",
      "--repo #{REPO}",
      "--json url,number"
    ]

    puts cmd.join(' ')
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
